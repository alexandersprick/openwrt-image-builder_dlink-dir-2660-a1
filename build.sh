#!/bin/bash

# reference: https://openwrt.org/docs/guide-user/additional-software/imagebuilder
# Note that the files under "files" might not be applicable to other devices.
# As a baseline, flash your device with the standard OpenWrt image, configure it and
# create a backup of the configuration. Then, use the backup to create the files in the 
# "files" directory.

## On a running OpenWrt system, you can find the additional installed packages with the following command
## and use them in the PACKAGES variable, to be included in your custom image:
##
# FLASH_TIME=$(opkg info busybox | grep '^Installed-Time: ')
# for i in $(opkg list-installed | cut -d' ' -f1); do
#  if [ "$(opkg info $i | grep '^Installed-Time: ')" != "$FLASH_TIME" ]; then
#   echo $i
#  fi
# done
PACKAGES="luci luci-proto-wireguard luci-app-wireguard luci-app-ksmbd block-mount kmod-fs-vfat kmod-usb-storage wget sshtunnel sshpass tmux netcat socat nmap iperf3 kmod-tun liblzo2 libqrencode qrencode tinc"

# Extra name for the image file. Note that some devices have a maximum length for the image name.
EXTRA_IMAGE_NAME="alexander-dlink-dir-2660"

# Change the following to your desired SSID and password. Note that the password must be at 
# least 8 characters long, but some special chars here can break the sed substitution
WIFI_SSID="OpenWrt"
WIFI_PASSWORD="password"

# If unknown, leave empty and run the script to get a list of available profiles
# PROFILE=
PROFILE="dlink_dir-2660-a1"

# Find your target here (see Target/Subtarget column):
# https://openwrt.org/toh/hwdata/d-link/d-link_dir-2660_a1
# Copy the URL of the imagebuilder for your target here:
# https://downloads.openwrt.org/releases/23.05.5/targets/
TARGET="https://downloads.openwrt.org/releases/23.05.5/targets/ramips/mt7621/openwrt-imagebuilder-23.05.5-ramips-mt7621.Linux-x86_64.tar.xz"

# base directory is the directory of the script
cd "$( cd "$(dirname "$0")" ; pwd -P )" || exit 1

# build the docker build image if not yet present, or if any argument is given
if test -n "$1" || ! docker images --format "{{.Repository}}:{{.Tag}}" | grep -q openwrt_builder:1 ; then
docker build --no-cache -t openwrt_builder:1 -<<-EOF
FROM debian:bookworm-slim
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        build-essential libncurses-dev zlib1g-dev gawk git \
        gettext libssl-dev xsltproc rsync wget unzip python3 python3-distutils file curl ca-certificates \
    && apt-get autoremove -y && rm -rf /var/lib/apt/lists/* \
    && useradd -m user
USER user
WORKDIR /home/user
EOF
fi

# download the imagebuilder if not yet present
test -f "$(basename $TARGET)" || wget $TARGET

# clean up and prepare the build directory
rm -rf docker-build
mkdir -p docker-build/imagebuilder
echo "extracting $(basename $TARGET)"
tar -C docker-build/imagebuilder --strip-components=1 -Jxf "$(basename $TARGET)"
cp -r files docker-build/imagebuilder

# prepare the wireless configuration with the given SSID and password
sed -i "s/@WIFI_SSID@/$WIFI_SSID/g;s/@WIFI_PASSWORD@/$WIFI_PASSWORD/g" docker-build/imagebuilder/files/etc/config/wireless

# run the build
docker rm -v openwrt-build 2>/dev/null
cat<<EOF | docker run -i --name openwrt-build --rm -v "$(pwd)/docker-build":/home/user openwrt_builder:1
cd /home/user/imagebuilder
if [ -z "$PROFILE" ] || ! make info | grep -q "$PROFILE" ; then
 make info
 echo "ERROR: profile '$PROFILE' not found. Check if you can find it in the list above."
 exit 1
fi
echo "building image..."
make image PROFILE="$PROFILE" PACKAGES="$PACKAGES" FILES=files BIN_DIR=/home/user/ EXTRA_IMAGE_NAME="$EXTRA_IMAGE_NAME"
EOF

echo "build done:"
ls -la docker-build/
