#!/bin/bash
HOST=192.168.247.128
#HOST=192.168.0.10
if mountpoint -q $HOME/share_client
then
   echo "fs has mounted"
else
   echo "fs has not mounted, try to mount"
   sudo mount -t nfs $HOST:$HOME/share $HOME/share_client -o nolock
fi
cp $HOME/share_client/1.sh .
cp $HOME/share_client/2.sh .
cp $HOME/share_client/3.sh .
cp $HOME/share_client/client_pack.sh .
