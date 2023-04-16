#!/bin/bash

if [ $# -eq 0 ]; then
    >&2 echo "Provide container directory name as argument"
    exit 1
fi

CONTAINER_NAME=$1-distrobox
CONTAINER_DIR=$(dirname "$0")/$1
echo $CONTAINER_NAME
echo $CONTAINER_DIR
distrobox stop -r -Y $1
distrobox rm -r -Y $1
sudo podman build --pull=newer --no-cache -t $CONTAINER_NAME $CONTAINER_DIR 
sudo podman image prune -f
distrobox create -n $1 -i $CONTAINER_NAME -r -Y --init-hooks "chsh -s /bin/fish sears"
distrobox enter -r $1
