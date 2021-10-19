#!/bin/bash

echo "start test"

MACHINE=
MODE=
servernum=2
DRIVER_PATH=$GOPATH/smallbank_client
SERVICE_PATH=$GOPATH/6.final/test-network/services
CC_NAME=origin
localhost=127.0.0.1
endpoint="${localhost}:8800"
CHANNEL=
CC_NAME=
EXPERIMENT=
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
  -c )
    CHANNEL="$2"
    shift;;
  * )
    echo "Unknown flag: $key"
    exit 1
    ;;
  esac
  shift
done


ps aux  |  grep -i block-server  |  awk '{print $2}' | xargs kill -9
ps aux  |  grep -i txn-server  |  awk '{print $2}' | xargs kill -9

if [ ! $EXPERIMENT ]; then
  echo " should describe the exp model"
  exit 1
fi
if [ $EXPERIMENT -eq 0 ]; then
  echo 	"fabric"

  MODE=open_loop
  CHANNEL=mychannel
  CC_NAME=origin
  if [ $MACHINE -eq -1 ]; then
    cd $SERVICE_PATH
    node block-server.js $CHANNEL 8800 $MACHINE > block-server-8800.log 2>&1 &
        
    sleep 5
    DRIVER_PATH=$GOPATH/smallbank
    cd $DRIVER_PATH
    ./driver -db fabric-v2.2 -ops 100 -threads 0 -txrate 10 -fp stat.txt -endpoint $endpoint  | tee TotalT.txt
    exit 0
  fi


  for (( i=1; i<=$servernum; i++ ))
  do
    endpoint+=",${localhost}:$[ 8800 + $i ]"
  done
  echo $endpoint

  echo "step 1, up server with open_loop to test W TPS"
  cd $SERVICE_PATH
  node block-server.js $CHANNEL 8800 $MACHINE > block-server-8800.log 2>&1 &
  node txn-server.js $CHANNEL $CC_NAME ${MODE} 8801 $MACHINE > txn-server-8801.log 2>&1 &
  node txn-server.js $CHANNEL $CC_NAME ${MODE} 8802 $MACHINE > txn-server-8802.log 2>&1 &
  node txn-server.js $CHANNEL $CC_NAME closed_loop 8803 $MACHINE > txn-server-8803.log 2>&1 &
  sleep 5
  DRIVER_PATH=$GOPATH/smallbank_client
  cd $DRIVER_PATH
  ./driver -db fabric-v2.2 -ops 100000 -threads 1 -txrate 1000 -fp stat.txt -endpoint $endpoint -rw 1 | tee res_W.txt

elif [ $EXPERIMENT -eq 1 ]; then
  echo "vassago"
  MODE=open_loop
  DRIVER_PATH=$GOPATH/smallbank
  if [ ! $CHANNEL ]; then
    CHANNEL=psb$CHANNEL
    #CC_NAME=${CHANNEL}CC
  fi
  CC_NAME=${CHANNEL}CC
  if [ $MACHINE -eq 1 ]; then
    cd $SERVICE_PATH
    node block-server.js $CHANNEL 8800 $MACHINE > block-server-8800.log 2>&1 &
    #node txn-server.js srb srbCC ${MODE} 8810 $MACHINE > txn-server-8810.log 2>&1 &
    sleep 5
    cd $DRIVER_PATH
    ./driver -db fabric-v2.2 -ops 100000 -threads 0 -txrate 10 -fp stat.txt -endpoint $endpoint  | tee TotalT.txt
    exit 0
  fi

  for (( i=1; i<=$servernum; i++ ))
  do
    endpoint+=",${localhost}:$[ 8800 + $i ]"
  done
  echo $endpoint


  echo "step 1, up server with open_loop to test W TPS"
  cd $SERVICE_PATH
  echo "channel is "$CHANNEL", CC is"$CC_NAME
  node block-server.js $CHANNEL 8800 $MACHINE > block-server-8800.log 2>&1 &
  node txn-server.js $CHANNEL $CC_NAME ${MODE} 8801 $MACHINE > txn-server-8801.log 2>&1 &
  node txn-server.js $CHANNEL $CC_NAME ${MODE} 8802 $MACHINE > txn-server-8802.log 2>&1 &
  node txn-server.js $CHANNEL $CC_NAME closed_loop 8803 $MACHINE > txn-server-8803.log 2>&1 &
  sleep 3
  DRIVER_PATH=$GOPATH/smallbank_vassago
  cd $DRIVER_PATH
  UMACHINE=$[ $MACHINE - 1 ]
  ./driver -db fabric-v2.2 -ops 5000 -threads 1 -txrate 1000 -fp stat.txt -upper $UMACHINE -curr $MACHINE  -endpoint $endpoint  | tee res_W.txt
fi


:<<!
ps aux  |  grep -i block-server  |  awk '{print $2}' | xargs kill -9
ps aux  |  grep -i txn-server  |  awk '{print $2}' | xargs kill -9
sleep 5

echo "step 2, up server with close_loop to test R latency"
cd $SERVICE_PATH
MODE=closed_loop
node block-server.js mychannel 8800 $MACHINE > block-server-8800.log 2>&1 &
node txn-server.js mychannel origin ${MODE} 8801 $MACHINE > txn-server-8801.log 2>&1 &
node txn-server.js mychannel origin ${MODE} 8802 $MACHINE > txn-server-8802.log 2>&1 &
sleep 5
cd $DRIVER_PATH
./driver -db fabric-v2.2 -ops 100 -threads 1 -txrate 10 -fp stat.txt -endpoint $endpoint -rw 0 | tee res_R.txt
!
