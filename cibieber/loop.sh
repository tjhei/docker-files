#!/bin/bash

docker-machine-Linux-x86_64 start
eval $(docker-machine-Linux-x86_64 env)
docker ps | exit 1

while :
do
  ./run.sh
  sleep 300
done
