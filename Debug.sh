#!/bin/sh

OPENWRT_DIR=/home/prog/openwrt/lede-all/2019-openwrt-all/openwrt-ipq4xxx

TFTPBOOT="/var/lib/tftpboot"
FAKEFNAME="linux_t1.bin"
RES_FILE=./bin/loader.elf
rm -f ${RES_FILE}
rm -f ./objs/data*.o

export STAGING_DIR=${OPENWRT_DIR}/staging_dir
export TOOLPATH=${STAGING_DIR}/toolchain-arm_cortex-a7+neon-vfpv4_gcc-7.4.0_musl_eabi
export PATH=${TOOLPATH}/bin:${PATH}
export CROSS_COMPILE=arm-openwrt-linux-
export KERNEL_IMAGE=${OPENWRT_DIR}/bin/targets/ipq40xx/generic/openwrt-ipq40xx-meraki_mr33-initramfs-fit-uImage.itb
#export KERNEL_IMAGE=${OPENWRT_DIR}/bin/targets/ipq40xx/generic/old/openwrt-ipq40xx-meraki_mr33-initramfs-uImage

#echo $KERNEL_IMAGE
#test for fat images
#cat $KERNEL_IMAGE > ./b1.bin
#dd if=$KERNEL_IMAGE bs=1k count=3000 >> ./b1.bin
#cat $KERNEL_IMAGE >> ./b1.bin
#cat $KERNEL_IMAGE >> ./b1.bin
#cat $KERNEL_IMAGE >> ./b1.bin
#export KERNEL_IMAGE=./b1.bin

make $@

[ -f ${RES_FILE} -a -d ${TFTPBOOT} ] && {
	cat ${RES_FILE} > ${TFTPBOOT}/${FAKEFNAME}
	echo "\nCat ${RES_FILE} --> ${TFTPBOOT}/${FAKEFNAME}"
}

#CC="arm-openwrt-linux-gcc"
#LD="arm-openwrt-linux-ld"
#OBJDUMP="arm-openwrt-linux-objdump"
#OBJCOPY="arm-openwrt-linux-objcopy"

#-R .reginfo -R .note -R .comment -R .mdebug -R .MIPS.abiflags -S
#${OBJCOPY} -j .rodata* -S bin/loader ./loader.slim
#${OBJCOPY} -j .ARM.attributes -S bin/loader ./loader.slim
#${OBJCOPY} -j .got* -S bin/loader ./loader.slim
#${OBJCOPY} -R .got* -R .ARM.attributes -R .comment -R .debug.* -S bin/loader ./loader.slim
#${OBJDUMP} -x ./loader.slim > ./loader.slim.headers
#${OBJDUMP} -x bin/loader > ./loader.headers
#${OBJDUMP} -D objs/start.o > ./start.asm
#${OBJDUMP} -b binary -m arm -D bin/loader.bin > ./loader.bin.asm

#${OBJCOPY} -O binary -R .text -R .ARM.attributes -R .comment -R .debug.* -S bin/loader.elf bin/loader.elf.bin
#${OBJDUMP} -x ./loader.elf > ./loader.elf.headers
#${OBJCOPY} -R .data -R .ARM.attributes -R .comment -R .debug.* -S bin/loader.elf bin/loader.elf.X
#${OBJDUMP} -x bin/loader.elf.X > ./loader.elf.X.headers
