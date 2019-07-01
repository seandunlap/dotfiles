#!/bin/bash

set +x
for i in {0..4}; do
  sudo route -n flush $i
done
sleep 5

#sudo ifconfig en5 down
#sudo ifconfig en6 down

#sudo ifconfig en5 up
#sudo ifconfig en6 up
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

sleep 10

sudo route -n add default 44.0.15.1
sudo route -n add 10.24.38.0/24 44.0.15.1
sudo route -n add 10.24.39.0/24 44.0.15.1
sudo route -n add 10.38.0.0/16 44.0.15.1
sudo route -n add 10.39.0.0/16 44.0.15.1

sudo route -n add 192.0.0.0/8 10.24.64.1
sudo route -n add 10.0.0.0/8 10.24.64.1
