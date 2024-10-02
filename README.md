# smol-rpi-dashcam
Dashcam project designed to work on a Raspberry Pi with an accompanying Pi Camera Module and flash drive for storage.  

## Things You Will Need:
1. Raspberry Pi
2. Pi Camera Module
3. Camera Cable: for plugging camera into Pi
4. Micro USB cable: for providing power to the Pi from your car
5. USB OTG cable: for plugging in the flashdrive

optional (recommended):
1. Heatsink: The Pi Zero 2 W works well for 1080p30fps video but gets HOT

## What it Does
1. Setup a `systemctl` service called `dashcam`  
The service just runs the `start_recording.sh` script and logs to `logs/systemd.log`
2. Run on boot:  
So you can plug the Pi's power directly into your car. When the car turns on and starts providing power to the device it will boot and start recording on it's own. It will stop recording when the Pi loses power. Losing power will not damage the current recording given the default encoding settings in `dashcam_config.txt`. If you so choose to adjust the rpicam-vid config file, results may vary.
3. Find your flashdrive:  
On boot the script will search for any external block devices that have file systems. It will pick the largest of these to start recording to.
WARNING: If the script cannot find a valid external block device via `lsblk`, it will not start recording.  
WARNING: I do not recommend using the FAT32 filesystem as it's maximum file size limit of 4GB would not make for very good recording.

## Installation
1. Clone the repo somewhere on the Pi
`git clone git@github.com:SamuelWhittle/smol-rpi-dashcam.git`
2. cd into the new project folder  
`cd dashcam`
3. Run the setup script as root. Root privileges are requried as the script needs to do things like install deps, interact with protected directories, and interact with systemctl.  
`sudo ./setup.sh`
4. Reboot. Technically the installation is already complete, and when you reboot the Pi should now try to start recording.

## Configuration
This project is based on `rpicam-apps`. You can view their documentation here: [rpicam-apps docs](https://www.raspberrypi.com/documentation/computers/camera_software.html)

Most `rpicam-apps` options you would want to change can be easily adjusted in `dashcam_config.txt` in the project root.  

You can view your Pi Camera Modules Hardware specs here: [Pi Camera Module specs](https://www.raspberrypi.com/documentation/accessories/camera.html#hardware-specification)

## Troubleshooting
### It doesn't do anything:
Make sure you have an external block device plugged into the Pi with at least one partition containing a valid File System, e.g.: exFat  
If there is no detectable and valid external block device, the dashcam service will exit, doing nothing.

### The service crashes due to running out of space:
Make sure that the configured segment value is larger than `60000`  
e.g.: `segment=900000`  for 15 minutes
The cron job responsible for making sure there is enough space on your flashdrive runs once every 60 seconds.
