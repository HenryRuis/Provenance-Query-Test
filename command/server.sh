#!/bin/bash
orgNum=1
MODE=close_loop

cd services
node enrollAdmin.js $orgNum
sleep 1
node registerUser.js $orgNum
wait

node txn-server.js srb srbCC ${MODE} 8801 1 > txn-server-8801.log 2>&1 &
node txn-server.js psb1 psb1CC ${MODE} 8802 1 > txn-server-8802.log 2>&1 &
node txn-server.js psb2 psb2CC ${MODE} 8803 1 > txn-server-8803.log 2>&1 &

#./driver -db fabric-v2.2 -ops 1000 -threads 1 -txrate 1 -fp stat.txt -endpoint 127.0.0.1:8800,127.0.0.1:8801
