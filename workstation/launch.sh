#!/usr/bin/env bash
set -e

WST_NAME=k3s-workstation
USER_FOLDER=/root

docker build -t $WST_NAME -f ./workstation/Dockerfile ./workstation

docker run -td --name $WST_NAME \
    -v ~/.aws:$USER_FOLDER/.aws \
    -v ~/.ssh:$USER_FOLDER/.ssh \
    -v $(pwd)/:/workdir \
    $WST_NAME

docker exec -it $WST_NAME bash
