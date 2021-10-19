#!/bin/bash
Fabric=0
Vassago=1
EXPERIMENT=$Fabric
MACHINE=
MACHINE_NUM=
ORDERER_NUM=
CC_NAME=

FABRIC_PATH=$GOPATH/6.final
CC_PATH=


CAPORT=

HOST=192.168.247.128
#HOST=192.168.0.10

while [[ $# -ge 1 ]] ; do
  key="$1"
  case $key in
  -e )
    EXPERIMENT="$2"
    shift
    ;;
  -vm )
    MACHINE="$2"
    shift
    ;;
  -on )
    ORDERER_NUM="$2"
    shift
    ;;
  -vmn )
    MACHINE_NUM="$2"
    shift
    ;; 
  * )
    echo "Unknown flag: $key"
    exit 1
    ;;
  esac
  shift
done

getCA() {
  inOrg=$1
  if [ ! $inOrg ]; then
    echo "ERROR inORG"
    exit 1
  fi
  if [ $inOrg -le 3 ]; then
    CAPORT=$[ 5000 + $inOrg * 2000 + 54 ]
  else
    CAPORT=$[ 12000 + $inOrg * 10 + 9]
  fi
}

echo "#########################Storage & Query Speed experiment#########################"
if [ ! $MACHINE ]; then
  echo "should input machine num"
  exit 1
fi
if [ $MACHINE -eq 1 ]; then
  echo "------------------------First Machine------------------------"
  if [ ! $ORDERER_NUM ]; then
    echo "should input orderer num"
    exit 1
fi
  echo "step1 make share file system"
  sudo /etc/init.d/nfs-kernel-server restart
    
  echo "step2 make orderer num, orderer num is "$ORDERER_NUM
  cd $FABRIC_PATH/test-network
  ./change.sh $ORDERER_NUM
    
  echo "step3 create fabric and deployCC"
  ./network.sh up createChannel -ca -i 2.2
  ./network.sh deployCC -ccn $CC_NAME -ccp $CC_PATH -ccl go
    
  echo "step4 copy certification & command to other machine"
  cp -r organizations/ordererOrganizations $HOME/share
  cp -r organizations/peerOrganizations $HOME/share
elif [ $MACHINE -gt 0 ]; then
  echo "------------------------Another Machine------------------------"
  
  echo "step1 mount file system"
  sudo mount -t nfs $HOST:$HOME/share $HOME/share_client -o nolock
  
  echo "step2 copy org1 & orderer certification"
  cp -r $HOME/share_client/ordererOrganizations $FABRIC_PATH/test-network/organizations/
  cp -r $HOME/share_client/peerOrganizations $FABRIC_PATH/test-network/organizations/
  
  echo "step3 create org"$MACHINE" and deployCC "$CC_NAME" with CAPORT: "$CAPORT
  getCA $MACHINE
  if [ ! $CAPORT ]; then
    echo "ERROR CA!"
    exit  1
  fi
  for ((i=3; i<=${MACHINE}; i++))
  do
    CC_NAME=psb${i}CC
    CC_PATH=$FABRIC_PATH/chaincode/psb
    cd $FABRIC_PATH/test-network/addOrg
    ./addOrg3.sh up -ca -i 2.2 -o $MACHINE -p 4 -cap $CAPORT -c psb${i}
    cd ..
    ./network.sh deployCC -c -c psb${i} -ccn $CC_NAME -ccp $CC_PATH -ccl go -ccl go -o $MACHINE -p 4
  done  
  cd $FABRIC_PATH/test-network/addOrg
  ./addOrg3.sh up -ca -i 2.2 -o $MACHINE -p 4 -cap $CAPORT
  cd ..
  ./network.sh deployCC -ccn $CC_NAME -ccp $CC_PATH -ccl go -o $MACHINE -p 4
  
  echo "step4 register admin and user"
  cd $FABRIC_PATH/test-network/services
  node enrollAdmin.js $MACHINE
  node registerUser.js $MACHINE
fi

