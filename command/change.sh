#!/bin/bash
:<<!
# s1: register orderer node
# s2: define 

cd configtx
# set change configtx.yaml for generis.block to record orderer information

cd docker 
# set change docker-compose-test-net.yaml to up orderer node 

cd organizations/cryptogen
# set change crypto-config-orderer.yaml to generate crypto for ordere

cd organizations/fabric-ca
# set change registerEnroll.sh to sign orderer to generis.block
!

rOrg=$1
cp replace/${rOrg}/configtx.yaml configtx/
cp replace/${rOrg}/docker-compose-test-net.yaml docker/docker-compose-test-net.yaml
cp replace/${rOrg}/crypto-config-orderer.yaml organizations/cryptogen/
cp replace/${rOrg}/registerEnroll.sh organizations/fabric-ca/
