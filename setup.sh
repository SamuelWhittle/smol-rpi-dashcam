#!/bin/bash

sudo apt install rpicam-apps
sudo sed "s,/path/to/working/dir,$PWD,g" ./dashcam.service > /lib/systemd/system/dashcam.service
sudo systemctl daemon-reload
sudo systemctl enable dashcam.service

