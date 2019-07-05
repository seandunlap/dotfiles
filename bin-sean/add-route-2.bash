#!/bin/bash

set +x
for i in {0..4}; do
  sudo route -n flush 
done
sleep 5

sudo ifconfig en0 down
sudo ifconfig en6 down

sudo ifconfig en0 up
sudo ifconfig en6 up
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

sleep 10

sudo route -n delete default -ifscope en6
sudo route -n delete default -ifscope en0
sudo route -n add 44.0.0.0/24 44.0.15.1
sudo route -n add 10.38.0.0/16 44.0.15.1
sudo route -n add 10.39.0.0/16 44.0.15.1
sudo route -n add 10.0.0.0/8 10.24.64.1
sudo route -n delete default -ifscope en6
