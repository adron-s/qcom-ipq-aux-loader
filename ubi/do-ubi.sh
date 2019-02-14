#!/bin/sh

STAGING_DIR=/home/prog/openwrt/lede-all/2019-openwrt-all/openwrt-ipq4xxx/staging_dir
export PATH=${STAGING_DIR}/host/bin:${PATH}

cat ../loader > ./ubi-rootdir/kernel
#-c defines size in LEBs
mkfs.ubifs -m 4096 -e 253952 -c 60 -x none -f 8 -k r5 -p 1 -l 3 -r ./ubi-rootdir img-3521347800_0.ubifs
ubinize -p 262144 -m 4096 -O 4096 -s 4096 -x 1 -Q 3521347800 -o img-3521347800.ubi img-3521347800.ini
echo "Now do #ubiformat /dev/mtd0 -y -f /tmp/kernel.ubi on target device"
