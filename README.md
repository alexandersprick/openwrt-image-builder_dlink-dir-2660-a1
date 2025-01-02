# openwrt-image-builder_dlink-dir-2660-a1
Script and configuration to build a customized OpenWRT image. Targets to D-Link DIR-2660 A1, but can be easily adopted to other models.
See: [https://openwrt.org/toh/hwdata/d-link/d-link_dir-2660_a1](https://openwrt.org/toh/hwdata/d-link/d-link_dir-2660_a1)

Prerequisites: Linux machine (x86_64) with bash, wget and docker


Customize using the variables in the script:
- `PACKAGES=`
- `WIFI_SSID=`
- `WIFI_PASSWORD=`

If you want to adopt this script for other devices, see the comments in the script and adjust
- `TARGET=`
- `PROFILE=`



Note that the files under "files" might not be applicable to other devices. As a baseline, flash your device with the standard OpenWrt image, configure it and create a backup of the configuration. Then, use the backup to create the files in the "files" directory.


