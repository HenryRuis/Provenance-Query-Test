#!/bin/bash

./network.sh up -ca -i 2.2
./network.sh createChannel -c srb
./network.sh createChannel -c psb1
./network.sh createChannel -c psb2

PSB_CC_PATH=$HOME/exe/6.final/chaincode/psb
SRB_CC_PATH=$HOME/exe/6.final/chaincode/srb
./network.sh deployCC -ccn srbCC -ccp $SRB_CC_PATH -ccl go -c srb
./network.sh deployCC -ccn psb1CC -ccp $PSB_CC_PATH -ccl go -c psb1 -ccep "OR('Org3MSP.peer')"
./network.sh deployCC -ccn psb2CC -ccp $PSB_CC_PATH -ccl go -c psb2 -ccep "OR('Org4MSP.peer')"

cd addOrg
./addOrg3.sh up -ca -i 2.2 -c srb -o 3 -p 4 -cap 11054
./addOrg3.sh up -ca -i 2.2 -c psb1 -o 3 -p 4 -cap 11054
cd ..

./network.sh deployCC -ccn srbCC -ccp $SRB_CC_PATH -ccl go -c srb -o 3 -p 4
./network.sh deployCC -ccn psb1CC -ccp $PSB_CC_PATH -ccl go -ccep "OR('Org3MSP.peer')" -c psb1 -o 3 -p 4

:<<!
./addOrg3.sh up -ca -i 2.2 -c psb2 -o 4 -p 4 -cap 12049
./addOrg3.sh up -ca -i 2.2 -c srb -o 4 -p 4 -cap 12049
./addOrg3.sh up -ca -i 2.2 -c psb1 -o 4 -p 4 -cap 12049


cd ..

PSB_CC_PATH=$HOME/exe/3.4/chaincode/psb
SRB_CC_PATH=$HOME/exe/3.4/chaincode/srb

./network.sh deployCC -ccn srbCC -ccp $SRB_CC_PATH -ccl go -c srb -o 3 -p 4
./network.sh deployCC -ccn srbCC -ccp $SRB_CC_PATH -ccl go -c srb -o 4 -p 4

./network.sh deployCC -ccn psb1CC -ccp $PSB_CC_PATH -ccl go -ccep "OR('Org3MSP.peer')" -c psb1 -o 3 -p 4
./network.sh deployCC -ccn psb1CC -ccp $PSB_CC_PATH -ccl go -ccep "OR('Org3MSP.peer')" -c psb1 -o 4 -p 4

./network.sh deployCC -ccn psb2CC -ccp $PSB_CC_PATH -ccl go -ccep "OR('Org4MSP.peer')" -c psb2 -o 4 -p 4

:<<!
./network.sh deployCC -ccn srbCC -ccp $SRB_CC_PATH -ccl go -c srb
./network.sh deployCC -ccn psb1CC -ccp $PSB_CC_PATH -ccl go -c psb1
./network.sh deployCC -ccn psb2CC -ccp $PSB_CC_PATH -ccl go -c psb2
!
