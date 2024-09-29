#!/bin/bash
# start_recording.sh
# mount /dev/sda1 to recording_storage_mount
# if there is no device to mount, do nothing

RUN_TIME="$(date '+%Y-%m-%d-%H-%M-%S')"
USER="sam"
RECORDING_STORAGE_MOUNT_PATH="/home/$USER/dashcam/recording_storage_mount"
FOUND_DEVICES=(`lsblk -bo NAME,SIZE,FSTYPE | grep -oP '(sd\w\d)\s+(\d+)\s+(\w+)' | grep -oP '(sd\w\d)\s+(\d+)'`)
LARGEST_DEVICE=""
LARGEST_SIZE=0

mount_failed() {
	MAYBE_MOUNT=`mount | grep -c "$1 on $2"`
	test $MAYBE_MOUNT == 0
}

for index in ${!FOUND_DEVICES[@]}; do
	if !(( index % 2 )) && test ${FOUND_DEVICES[(( index + 1 ))]} -gt $LARGEST_SIZE; then
		LARGEST_SIZE=${FOUND_DEVICES[(( index + 1 ))]}
		LARGEST_DEVICE=${FOUND_DEVICES[$index]}
	fi
done

if [ "$LARGEST_DEVICE" == "" ]; then
	echo "Could not find a block device to store video to."
	echo "$(date '+%Y-%m-%d %H:%M:%S') : Could not find a block device to store video to." >> /home/sam/dashcam/logs/run_logs.txt
	exit 1
fi

LARGEST_DEVICE_PATH="/dev/$LARGEST_DEVICE"
echo "Found device $LARGEST_DEVICE_PATH"

# ensure the device is not mounted
sudo umount $LARGEST_DEVICE_PATH

# mount largest block device
sudo mount $LARGEST_DEVICE_PATH $RECORDING_STORAGE_MOUNT_PATH

if mount_failed "$LARGEST_DEVICE_PATH" "$RECORDING_STORAGE_MOUNT_PATH"; then
	echo "$(date '+%Y-%m-%d %H:%M:%S') : Could not mount $LARGEST_DEVICE_PATH to $RECORDING_STORAGE_MOUNT_PATH" >> /home/sam/dashcam/logs/run_logs.txt
	exit 1
fi

echo "Successfully mounted $LARGEST_DEVICE_PATH to $RECORDING_STORAGE_MOUNT_PATH"

# cd to dashcam folder
cd /home/$USER/dashcam

# start recording video to device
echo "Starting recording to $RECORDING_STORAGE_MOUNT_PATH/$RUN_TIME.h264"
rpicam-vid -c dashcam_config.txt -o recording_storage_mount/"${RUN_TIME}".h264
