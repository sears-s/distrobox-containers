#!/bin/bash

# Must have 1 argument
if [ $# -eq 0 ]; then
    >&2 echo "Provide container directory name as argument"
    exit 1
fi
SCRIPT=$(realpath "$0")
SCRIPT_DIR=$(dirname "$SCRIPT")
CONTAINER_NAME=$1-distrobox
CONTAINER_DIR=$SCRIPT_DIR/$1

# Stop old container
distrobox stop -r -Y $1
distrobox rm -r -Y $1

# Build the image
sudo podman build --pull=newer --no-cache -t $CONTAINER_NAME \
	--build-arg USERNAME=$(whoami) \
	--build-arg UID=$(id -u) \
	--build-arg GID=$(id -g) \
	$CONTAINER_DIR || exit 1 
sudo podman image prune -f

# Setup the home directory
mkdir -p $CONTAINER/home
mapfile -t LINKS < $SCRIPT_DIR/home_links.txt
for LINK in ${LINKS[@]}; do
	SRC_DIR=~/$LINK
	DST_DIR=$CONTAINER_DIR/home/$LINK
	rm -rf $DST_DIR
	mkdir -p $(dirname "$DST_DIR")
	ln -s $SRC_DIR $DST_DIR || exit 1
done

# Start the container
SHELL=/bin/fish distrobox create -r -Y -n $1 -i $CONTAINER_NAME -H $CONTAINER_DIR/home
distrobox enter -r $1
