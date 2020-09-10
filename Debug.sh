#!/bin/sh

#IPQ 4 or 8
IPQ_NUMBER=8

#Uncomment this to see debug messages
DEBUG=false
RB3011_PREINITS=NONE

[ ${IPQ_NUMBER} -eq 4 ] && {
	OPENWRT_DIR=/home/prog/openwrt/lede-all/2019-openwrt-all/openwrt-ipq4xxx
	#CPU IPQ-4019(RB450Gx4)
	CPU_TYPE=IPQ4XXX
	TEXT_BASE=0x84800000
	UART=1
}
[ ${IPQ_NUMBER} -eq 8 ] && {
	OPENWRT_DIR=/home/prog/openwrt/2020-openwrt/openwrt-2020/openwrt-ipq806x
	#OPENWRT_DIR_ZW=/home/prog/openwrt/lede-all/2019-openwrt-all/ziswiler/openwrt
	#OPENWRT_DIR_OLD=/home/prog/openwrt/lede-all/2019-openwrt-all/openwrt-ipq806x
	#CPU IPQ-8064(RB3011)
	CPU_TYPE=IPQ806X
	TEXT_BASE=0x44800000
	UART=7
#	UART=NONE
	RB3011_PREINITS=YES
}

TFTPBOOT="/var/lib/tftpboot"
FAKEFNAME="linux_t1.bin"
RES_FILE=./bin/loader.elf
rm -f ${RES_FILE}
rm -f ./objs/data*.o

export STAGING_DIR=${OPENWRT_DIR}/staging_dir
export STAGING_DIR_HOST=${STAGING_DIR}/host
[ ${IPQ_NUMBER} -eq 4 ] && {
	export TOOLPATH=${STAGING_DIR}/toolchain-arm_cortex-a7+neon-vfpv4_gcc-7.4.0_musl_eabi
	export KERNEL_IMAGE=${OPENWRT_DIR}/build_dir/target-arm_cortex-a7+neon-vfpv4_musl_eabi/linux-ipq40xx/mikrotik_rb450gx4-fit-uImage.itb
	#export KERNEL_IMAGE=${OPENWRT_DIR}/bin/targets/ipq40xx/generic/openwrt-ipq40xx-mikrotik_rb450gx4-initramfs-fit-uImage.itb
	#export KERNEL_IMAGE=${OPENWRT_DIR}/bin/targets/ipq40xx/generic/old/openwrt-ipq40xx-meraki_mr33-initramfs-uImage
}
[ ${IPQ_NUMBER} -eq 8 ] && {
	export TOOLPATH=${STAGING_DIR}/toolchain-arm_cortex-a15+neon-vfpv4_gcc-8.4.0_musl_eabi
	export KERNEL_IMAGE=${OPENWRT_DIR}/bin/targets/ipq806x/generic/openwrt-ipq806x-generic-mikrotik_rb3011uias-initramfs-fit-uImage.itb
	#export KERNEL_IMAGE=${OPENWRT_DIR_ZW}/bin/targets/ipq806x/generic/openwrt-ipq806x-generic-mikrotik_rb3011uias-initramfs-fit-uImage.itb
	#export TOOLPATH=${STAGING_DIR}/toolchain-arm_cortex-a15+neon-vfpv4_gcc-7.4.0_musl_eabi
	#export KERNEL_IMAGE=${OPENWRT_DIR_OLD}/bin/targets/ipq806x/generic/openwrt-ipq806x-netgear_r7500v2-initramfs-fit-uImage.itb
}
export PATH=${TOOLPATH}/bin:${PATH}
export CROSS_COMPILE=arm-openwrt-linux-

#echo $KERNEL_IMAGE
#test for fat images
#cat $KERNEL_IMAGE > ./b1.bin
#dd if=$KERNEL_IMAGE bs=1k count=3000 >> ./b1.bin
#cat $KERNEL_IMAGE >> ./b1.bin
#cat $KERNEL_IMAGE >> ./b1.bin
#cat $KERNEL_IMAGE >> ./b1.bin
#export KERNEL_IMAGE=./b1.bin

make clean
make DEBUG=${DEBUG} CPU_TYPE=${CPU_TYPE} TEXT_BASE=${TEXT_BASE} UART=${UART} RB3011_PREINITS=${RB3011_PREINITS} $@
#make DEBUG=${DEBUG} CPU_TYPE=${CPU_TYPE} TEXT_BASE=${TEXT_BASE} UART=${UART} BLOCKSIZE=128k PAGESIZE=2048 LEBSIZE=126976 LEBCOUNT=120 $@

[ -f ${RES_FILE} -a -d ${TFTPBOOT} ] && {
	cat ${RES_FILE} > ${TFTPBOOT}/${FAKEFNAME}
	echo "\nCat ${RES_FILE} --> ${TFTPBOOT}/${FAKEFNAME}"
}

[ x"$@" = x"ubi" -a -f ./bin/loader.ubi ] && \
	ubireader_utils_info ./bin/loader.ubi -r

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
