#!/bin/bash

# Must have at least 1 argument
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

# Build the image if asked
if [ $# -eq 2 ] && [ $2 == "build" ]; then

	# Figure out container command
	if command -v podman > /dev/null; then
		container_cmd="podman"
	elif command -v docker > /dev/null; then
		container_cmd="docker"
	else
		>&2 echo "No container command found"
		exit 1
	fi

	# Build
	sudo $container_cmd build --pull -f $CONTAINER_DIR/Containerfile -t $CONTAINER_NAME $CONTAINER_DIR || exit 1
	sudo $container_cmd image prune -f
fi

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
