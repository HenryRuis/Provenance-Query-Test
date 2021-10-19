#!/bin/bash
if [ ! $1 ]; then
  echo " should input psb num from 1 to n"
  exit 1
fi

# psb init
cd $GOPATH/6.final/test-network/services
node txn-server.js psb1 psb1CC open_loop 8801 1 > txn-server-8801.log 2>&1 &
node txn-server.js srb srbCC open__loop 8810 1 > txn-server-8810.log 2>&1 &
node txn-server.js srb srbCC closed__loop 8811 1 > txn-server-8811.log 2>&1 &

:<<!
sleep 3
cd $GOPATH/wrk
./wrk -t1 -c1 -d20s -s vassagoinit.lua http://localhost:8801

# srb init
orgNum=$1

curl --header "Content-Type: application/json" \
--request POST \
--data '{"function":"CreateAsset","args":["1","1","1"]}' \
http://localhost:8810/invoke

sleep 2
for ((i=2; i<=${orgNum}; i++))
do
  curl --header "Content-Type: application/json" \
	--request POST \
	--data '{"function":"TransferAsset","args":["1", "'${i}'"]}' \
	http://localhost:8810/invoke
sleep 2
  #curl "http://localhost:8810/query?function=GetAssetHistory&args=1"
  #currEP+=",${currLH}:$[ 8800 + $i ]"
done

#ps aux  |  grep -i txn-server  |  awk '{print $2}' | xargs kill -9
!
