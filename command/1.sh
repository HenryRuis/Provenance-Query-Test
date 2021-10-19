#!/bin/bash
Fabric=0
Vassago=1
Multiple=2
EXPERIMENT=$Fabric
MACHINE=
MACHINE_NUM=
ORDERER_NUM=
CC_NAME=

FABRIC_PATH=$GOPATH/6.final
CC_PATH=


CAPORT=

#HOST=192.168.247.128
HOST=192.168.0.10

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


if [ $EXPERIMENT -eq $Fabric ]; then
  echo "#########################Fabric experiment#########################"
  CC_NAME=origin
  CC_PATH=$FABRIC_PATH/chaincode/$CC_NAME
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
    
    cd $GOPATH
    cp 1.sh $HOME/share
    cp 2.sh $HOME/share
    cp 3.sh $HOME/share
    cp client_pack.sh $HOME/share

    echo "step5 register character"
    cd $FABRIC_PATH/test-network/services
    node enrollAdmin.js $MACHINE
    node registerUser.js $MACHINE
    
  elif [ $MACHINE -gt 0 ]; then
    echo "------------------------"$MACHINE"Machine(Org)------------------------"
    getCA $MACHINE
    echo "step1 mount file system"
    sudo mount -t nfs $HOST:$HOME/share $HOME/share_client -o nolock
    
    echo "step2 copy org1 & orderer certification"
    cp -r $HOME/share_client/ordererOrganizations $FABRIC_PATH/test-network/organizations/
    cp -r $HOME/share_client/peerOrganizations $FABRIC_PATH/test-network/organizations/
    
    echo "step3 create org"$MACHINE" and deployCC "$CC_NAME" with CAPORT: "$CAPORT
    if [ ! $CAPORT ]; then
      echo "ERROR CA!"
      exit  1
    fi
    cd $FABRIC_PATH/test-network/addOrg
    ./addOrg3.sh up -ca -i 2.2 -o $MACHINE -p 4 -cap $CAPORT
    cd ..
    ./network.sh deployCC -ccn $CC_NAME -ccp $CC_PATH -ccl go -o $MACHINE -p 4
    
    echo "step4 register admin and user"
    cd $FABRIC_PATH/test-network/services
    node enrollAdmin.js $MACHINE
    node registerUser.js $MACHINE
  fi
elif [ $EXPERIMENT -eq $Vassago ]; then
  echo "#########################Vassago single provenance experiment#########################"
  if [ ! $MACHINE ]; then
    echo "should input machine num"
    exit 1
  fi
  if [ $MACHINE -eq 1 ]; then
    echo "------------------------first machine------------------------"
    if [ ! $ORDERER_NUM ]; then
      echo "should input orderer and machine num"
      exit 1
    fi    
    echo "step1 make fs"
    sudo /etc/init.d/nfs-kernel-server restart
    
    echo "step2 make orderer num, orderer num is "$ORDERER_NUM
    cd $FABRIC_PATH/test-network
    ./change.sh $ORDERER_NUM
    
    echo "step3 create fabric and deployCC"
    ./network.sh up createChannel -c srb -ca -i 2.2
    ./network.sh deployCC -c srb -ccn srbCC -ccp $FABRIC_PATH/chaincode/srb -ccl go
:<<!    
    for ((i=4; i<=${MACHINE_NUM}; i++))
    do
      CC_NAME=psb${i}CC
      ./network.sh createChannel -c psb${i}
      ./network.sh deployCC -ccn $CC_NAME -ccp $CC_PATH -ccl go -c psb${i}
    done
!
    CC_PATH=$FABRIC_PATH/chaincode/psb
    ./network.sh createChannel -c psb1
    ./network.sh createChannel -c psb2
    ./network.sh deployCC -ccn psb1CC -ccp $CC_PATH -ccl go -c psb1
    ./network.sh deployCC -ccn psb2CC -ccp $CC_PATH -ccl go -c psb2

    echo "step4 copy certification & command to other machine"
    cp -r organizations/ordererOrganizations $HOME/share
    cp -r organizations/peerOrganizations $HOME/share
    
    cd $GOPATH
    cp 1.sh $HOME/share
    cp 2.sh $HOME/share
    cp 3.sh $HOME/share 
    cp client_pack.sh $HOME/share

    echo "step5 register character"
    cd $FABRIC_PATH/test-network/services
    node enrollAdmin.js $MACHINE
    node registerUser.js $MACHINE
  elif [ $MACHINE -gt 1 ]; then
    echo "------------------------"$MACHINE"Machine(Org)------------------------"
    getCA $MACHINE
    echo "step1 mount file system"
    sudo mount -t nfs $HOST:$HOME/share $HOME/share_client -o nolock
    
    echo "step2 copy org1 & orderer certification"
    cp -r $HOME/share_client/ordererOrganizations $FABRIC_PATH/test-network/organizations/
    cp -r $HOME/share_client/peerOrganizations $FABRIC_PATH/test-network/organizations/
    
    echo "step3 create org"$MACHINE" and deployCC "$CC_NAME" with CAPORT: "$CAPORT
    if [ ! $CAPORT ]; then
      echo "ERROR CA!"
      exit  1
    fi
    cd $FABRIC_PATH/test-network/addOrg
    ./addOrg3.sh up -ca -i 2.2 -o $MACHINE -p 4 -cap $CAPORT -c srb
    ./addOrg3.sh up -ca -i 2.2 -o $MACHINE -p 4 -cap $CAPORT -c psb1
    ./addOrg3.sh up -ca -i 2.2 -o $MACHINE -p 4 -cap $CAPORT -c psb2
    cd ..
    ./network.sh deployCC -c srb -ccn srbCC -ccp $FABRIC_PATH/chaincode/srb -ccl go -ccl go -o $MACHINE -p 4
    ./network.sh deployCC -c psb1 -ccn psb1CC -ccp $FABRIC_PATH/chaincode/psb -ccl go -ccl go -o $MACHINE -p 4
    ./network.sh deployCC -c psb2 -ccn psb2CC -ccp $FABRIC_PATH/chaincode/psb -ccl go -ccl go -o $MACHINE -p 4

:<<!
    for ((i=4; i<=${MACHINE}; i++))
    do
      CC_NAME=psb${i}CC
      CC_PATH=$FABRIC_PATH/chaincode/psb
      cd $FABRIC_PATH/test-network/addOrg
      ./addOrg3.sh up -ca -i 2.2 -o $MACHINE -p 4 -cap $CAPORT -c psb${i}
      cd ..
      ./network.sh deployCC -c psb${i} -ccn $CC_NAME -ccp $CC_PATH -ccl go -ccl go -o $MACHINE -p 4
    done  
!
    echo "step4 register admin and user"
    cd $FABRIC_PATH/test-network/services
    node enrollAdmin.js $MACHINE
    node registerUser.js $MACHINE
  fi
elif [ $EXPERIMENT -eq $Single ]; then
  echo "#########################Storage & query multiple dependency experiment#########################"
  if [ ! $MACHINE ]; then
    echo "should input machine num"
    exit 1
  fi
  if [ $MACHINE -eq 1 ]; then
    echo "------------------------first machine------------------------"
    if [ ! $ORDERER_NUM ] || [ ! $MACHINE_NUM ]; then
      echo "should input orderer and machine num"
      exit 1
    fi    
    echo "step1 make fs"
    sudo /etc/init.d/nfs-kernel-server restart
    
    echo "step2 make orderer num, orderer num is "$ORDERER_NUM
    cd $FABRIC_PATH/test-network
    ./change.sh $ORDERER_NUM
    
    echo "step3 create fabric and deployCC"
    ./network.sh up createChannel -c srb -ca -i 2.2
    ./network.sh deployCC -ccn srb -ccp $FABRIC_PATH/chaincode/srb -ccl go -c srb
    
    for ((i=3; i<=${MACHINE_NUM}; i++))
    do
      CC_NAME=psb${i}CC
      CC_PATH=$FABRIC_PATH/chaincode/psb
      ./network.sh createChannel -c psb${i}
      ./network.sh deployCC -ccn $CC_NAME -ccp $CC_PATH -ccl go -c psb${i}
    done
    
    echo "step4 copy certification & command to other machine"
    cp -r organizations/ordererOrganizations $HOME/share
    cp -r organizations/peerOrganizations $HOME/share
    
    cd $GOPATH
    cp 1.sh $HOME/share
    cp 2.sh $HOME/share
    cp 3.sh $HOME/share 
    cp client_pack.sh $HOME/share

  elif [ $MACHINE -gt 1 ]; then
    echo "------------------------Another Machine------------------------"
    getCA $MACHINE
    echo "step1 mount file system"
    sudo mount -t nfs $HOST:$HOME/share $HOME/share_client -o nolock
    
    echo "step2 copy org1 & orderer certification"
    cp -r $HOME/share_client/ordererOrganizations $FABRIC_PATH/test-network/organizations/
    cp -r $HOME/share_client/peerOrganizations $FABRIC_PATH/test-network/organizations/
    
    echo "step3 create org"$MACHINE" and deployCC "$CC_NAME" with CAPORT: "$CAPORT
    if [ ! $CAPORT ]; then
      echo "ERROR CA!"
      exit  1
    fi
    cd $FABRIC_PATH/test-network/addOrg
    ./addOrg3.sh up -ca -i 2.2 -o $MACHINE -p 4 -cap $CAPORT -c srb
    cd ..
    ./network.sh deployCC -c psb${i} -ccn srbCC -ccp $FABRIC_PATH/chaincode/srb -ccl go -ccl go -o $MACHINE -p 4
    for ((i=3; i<=${MACHINE_NUM}; i++))
    do
      CC_NAME=psb${i}CC
      CC_PATH=$FABRIC_PATH/chaincode/psb
      cd $FABRIC_PATH/test-network/addOrg
      ./addOrg3.sh up -ca -i 2.2 -o $MACHINE -p 4 -cap $CAPORT -c psb${i}
      cd ..
      ./network.sh deployCC -c -c psb${i} -ccn $CC_NAME -ccp $CC_PATH -ccl go -ccl go -o $MACHINE -p 4
    done  
    echo "step4 register admin and user"
    cd $FABRIC_PATH/test-network/services
    node enrollAdmin.js $MACHINE
    node registerUser.js $MACHINE
  fi
fi


