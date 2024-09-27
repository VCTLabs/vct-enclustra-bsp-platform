#!/usr/bin/env bash
#
# populate sdcard partition with qspi build artifacts.
# use predfined device name file list but allow ENV override
#

set -euo pipefail

failures=0
trap 'failures=$((failures+1))' ERR

DISK=${1:-/dev/mmcblk0}
DEPLOY_DIR=${2:-build/tmp-glibc/deploy/images/me-aa1-270-2i2-d11e-nfx3}

FILES=${FILES:-"u-boot-splx4.sfp u-boot.img boot.scr devicetree.dtb socfpga_enclustra_mercury_qspi_overlay.dtbo bitstream.itb uImage"}
ROOTFS=${ROOTFS:-devel-image-minimal-me-aa1-270-2i2-d11e-nfx3.cpio.gz.u-boot}
VERBOSE="false"  # set to "true" for extra output

if [ -b "$DISK" ]; then
    storage_is_media_device=true
else
    storage_is_media_device=false
fi

find_partitions_by_id()
{
    unset DISK1 DISK2

    for device in /dev/disk/by-id/*; do
        if [ `realpath $device` = $DISK ]; then
            if echo "$device" | grep -q -- "-part[0-9]*$"; then
                echo "MMC device must not be a partition part ($device)" 1>&2
                exit 1
            fi
            for part_id in `ls "$device-part"*`; do
                local part=`realpath $part_id`
                local part_no=`echo $part_id | sed -e 's/.*-part//g'`
                if test "$part_no" = 1; then
                    DISK1=$part
                elif test "$part_no" = 3; then
                    DISK2=$part
                fi
            done
            break
        fi
    done
}

#echo "Mounting device: $DISK on /media"
#sudo mount $DISK /media
rm -rf qspi
mkdir -p qspi

for file in ${FILES}; do
    cp -v "$DEPLOY_DIR"/"$file" qspi/
done

cp -v $DEPLOY_DIR/$ROOTFS qspi/
sync

find_partitions_by_id

if ((failures != 0)); then
    echo "Something went wrong !!!"
    exit 1
fi
