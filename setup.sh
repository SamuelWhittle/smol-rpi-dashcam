#!/bin/bash

sudo apt install rpicam-apps

mkdir logs
mkdir recording_storage_mount

sudo chown -R $USER:$USER $PWD

sudo sed "s,/path/to/working/dir,$PWD,g" ./dashcam_cron_job > /etc/cron.d/dashcam_cron_job
sudo sed "s,/path/to/working/dir,$PWD,g" ./dashcam.service > /lib/systemd/system/dashcam.service
sudo systemctl daemon-reload
sudo systemctl enable dashcam.service

