#!/bin/bash

ORG=
FABRIC_PATH=$GOPATH/6.final

while [[ $# -ge 1 ]] ; do
  key="$1"
  case $key in
  -o )
    ORG="$2"
    shift
    ;;
  * )
    errorln "Unknown flag: $key"
    exit 1
    ;;
  esac
  shift
done

ps aux  |  grep -i block-server  |  awk '{print $2}' | xargs kill -9
ps aux  |  grep -i txn-server  |  awk '{print $2}' | xargs kill -9

cd $FABRIC_PATH/test-network
./network.sh down -o $ORG

cd $FABRIC_PATH/test-network/services
rm -rf wallet/

docker volume prune
docker network prune

cd
sudo umount $HOME/share_client


