#!/bin/bash
# start_recording.sh
# find the largest block device with a file system and try to mount it to ./recording_storage_mount
# assuming all that goes well, start recording a video to the mounted folder

RUN_TIME="$(date '+%Y-%m-%d-%H-%M-%S')"
RECORDING_STORAGE_MOUNT_PATH="$PWD/recording_storage_mount"
FOUND_DEVICES=(`lsblk -bo NAME,SIZE,FSTYPE | grep -oP '(sd\w\d)\s+(\d+)\s+(\w+)' | grep -oP '(sd\w\d)\s+(\d+)'`)
LARGEST_DEVICE=""
LARGEST_SIZE=0

# helper function to test if a mount succeeded
mount_failed() {
	MAYBE_MOUNT=`mount | grep -c "$1 on $2"`
	test $MAYBE_MOUNT == 0
}

# find the largest block device
for index in ${!FOUND_DEVICES[@]}; do
	if !(( index % 2 )) && test ${FOUND_DEVICES[(( index + 1 ))]} -gt $LARGEST_SIZE; then
		LARGEST_SIZE=${FOUND_DEVICES[(( index + 1 ))]}
		LARGEST_DEVICE=${FOUND_DEVICES[$index]}
	fi
done

# stop if we did not find a block device
if [ "$LARGEST_DEVICE" == "" ]; then
	echo "Could not find a block device to store video to."
	echo "$(date '+%Y-%m-%d %H:%M:%S') : Could not find a block device to store video to." >> "$PWD/logs/run_logs.txt"
	exit 1
fi

# keep the path to the largest device
LARGEST_DEVICE_PATH="/dev/$LARGEST_DEVICE"
echo "Found device $LARGEST_DEVICE_PATH"

# ensure the device is not mounted
sudo umount $LARGEST_DEVICE_PATH

# mount largest block device
sudo mount $LARGEST_DEVICE_PATH $RECORDING_STORAGE_MOUNT_PATH

# stop if the mount failed
if mount_failed "$LARGEST_DEVICE_PATH" "$RECORDING_STORAGE_MOUNT_PATH"; then
	echo "$(date '+%Y-%m-%d %H:%M:%S') : Could not mount $LARGEST_DEVICE_PATH to $RECORDING_STORAGE_MOUNT_PATH" >> "$PWD/logs/run_logs.txt"
	exit 1
fi

echo "Successfully mounted $LARGEST_DEVICE_PATH to $RECORDING_STORAGE_MOUNT_PATH"

# start recording video to device
echo "Starting recording to $RECORDING_STORAGE_MOUNT_PATH/$RUN_TIME-chunk%04d.h264"
#rpicam-vid -c dashcam_config.txt -o recording_storage_mount/"${RUN_TIME}"-chunk%04d.h264
