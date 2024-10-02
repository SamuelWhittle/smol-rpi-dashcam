#!/bin/bash
# start_recording.sh
# find the largest block device with a file system and try to mount it to ./recording_storage_mount
# assuming all that goes well, start recording a video to the mounted folder

RUN_TIME="$(date '+%Y-%m-%d-%H-%M-%S')"
RECORDING_STORAGE_MOUNT_PATH="$PWD/recording_storage_mount"
LARGEST_DEVICE=`lsblk -bnro SIZE,NAME,FSTYPE | grep -oP '(\d+)\s+(sd\w\d)\s+(\w+)' | grep -oP '(\d+)\s+(sd\w\d)' | sort -nr | head -n 1 | awk '{print $2}'`

# helper function to test if a mount succeeded
mount_failed() {
	MAYBE_MOUNT=`mount | grep -c "$1 on $2"`
	test $MAYBE_MOUNT == 0
}

# stop if we did not find a block device
if [ "$LARGEST_DEVICE" == "" ]; then
	>&2 echo "Could not find a block device to store video to."
	echo "$(date '+%Y-%m-%d %H:%M:%S') : Could not find a block device to store video to." > "$PWD/logs/run_logs.txt"
	exit 1
fi

# keep the path to the largest device
LARGEST_DEVICE_PATH="/dev/$LARGEST_DEVICE"
echo "Found device $LARGEST_DEVICE_PATH"

# disable write caching for the largest device
sudo hdparm -W 0 $LARGEST_DEVICE_PATH

# ensure the device is not mounted
sudo umount $LARGEST_DEVICE_PATH

# mount largest block device
sudo mount $LARGEST_DEVICE_PATH $RECORDING_STORAGE_MOUNT_PATH

# stop if the mount failed
if mount_failed "$LARGEST_DEVICE_PATH" "$RECORDING_STORAGE_MOUNT_PATH"; then
	>&2 echo "$(date '+%Y-%m-%d %H:%M:%S') : Could not mount $LARGEST_DEVICE_PATH to $RECORDING_STORAGE_MOUNT_PATH"
	echo "$(date '+%Y-%m-%d %H:%M:%S') : Could not mount $LARGEST_DEVICE_PATH to $RECORDING_STORAGE_MOUNT_PATH" > "$PWD/logs/run_logs.txt"
	exit 1
fi

echo "Successfully mounted $LARGEST_DEVICE_PATH to $RECORDING_STORAGE_MOUNT_PATH"

# start recording video to device
echo "Starting recording to $RECORDING_STORAGE_MOUNT_PATH/$RUN_TIME-chunk%04d.h264"
rpicam-vid -c dashcam_config.txt -o recording_storage_mount/"${RUN_TIME}"-chunk%04d.h264
