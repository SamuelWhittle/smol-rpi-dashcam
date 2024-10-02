#!/bin/bash

# get the largest external block device with a filesystem
LARGEST_DEVICE=`lsblk -bnro SIZE,NAME,FSTYPE | grep -oP '(\d+)\s+(sd\w\d)\s+(\w+)' | grep -oP '(\d+)\s+(sd\w\d)' | sort -nr | head -n 1 | awk '{print $2}'`

# if there is no largest device, exit
if test "$LARGEST_DEVICE" == ""; then
	exit 0
fi

LARGEST_DEVICE_PATH="/dev/$LARGEST_DEVICE"
RECORDING_STORAGE_MOUNT_PATH=`mount | grep "$LARGEST_DEVICE" | awk '{print $3}'`

NUM_FILES_IN_DIR=`ls $RECORDING_STORAGE_MOUNT_PATH | wc -l`

# the segment length in milliseconds
SEGMENT=`cat "$RECORDING_STORAGE_MOUNT_PATH"/../dashcam_config.txt | grep segment | grep -oP '\d+'`

# if there is no set segment length
# the rpicam-vid script will just fill the partition then fail, nothing we can do
# if there is no file other than the one being recorded to, there is either no set segment length
# or there is nothing to delete, in either case, exit
if test "$SEGMENT" = "" -o $NUM_FILES_IN_DIR -lt 2; then
	exit 0
fi

# get the free space in the partition
FREE_SPACE=`df -B 1 --output=avail -k "$RECORDING_STORAGE_MOUNT_PATH" | tail -n 1`

# use the largest file size in the directory as the space threshold
FREE_SPACE_THRESHOLD=`ls -lS | head -n 2 | tail -n 1 | awk '{print $5}'`

# get the configure bitrate
MAYBE_BITRATE=`cat "$RECORDING_STORAGE_MOUNT_PATH"/../dashcam_config.txt | grep bitrate | grep -oP '\d+'`

# if there is a configured bitrate use that to calculate the threshold instead
if test "$MAYBE_BITRATE" != ""; then
	FREE_SPACE_THRESHOLD=$(( $MAYBE_BITRATE * $SEGMENT / 1000 ))
fi

# if there is more than enough free space, exit
if test $FREE_SPACE_THRESHOLD -lt $FREE_SPACE; then
	exit 0
fi

# delete the oldest file until there is enough space or only 1 file left
while test $FREE_SPACE -lt $FREE_SPACE_THRESHOLD -a $NUM_FILES_IN_DIR -gt 1; do
	sudo rm "$RECORDING_STORAGE_MOUNT_PATH"/`ls -t | tail -n 1`
	NUM_FILES_IN_DIR=`ls $RECORDING_STORAGE_MOUNT_PATH | wc -l`
	FREE_SPACE=`df -B 1 --output=avail -k "$RECORDING_STORAGE_MOUNT_PATH" | tail -n 1`
done
