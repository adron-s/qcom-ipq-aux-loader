#!/bin/sh

#TEXT_BASE=0x87300000
#TEXT_BASE=0x80060000
#TEXT_BASE=0x41200000
#TEXT_BASE=0x41600000
#TEXT_BASE=0x89000000
#TEXT_BASE=0x80000000
#TEXT_BASE=0x80BB0000
#TEXT_BASE=0x80BB1E00
#TEXT_BASE=0x80A00000
#TEXT_BASE=0x80808000
#TEXT_BASE=0x81900000
TEXT_BASE=0x81820000
#TEXT_BASE=0x82900000
#TEXT_BASE=0x80208000
#TEXT_BASE=0x01100000
#TEXT_BASE=0x21100000
#TEXT_BASE=0x01100000
#TEXT_BASE=0x80000000
#TEXT_BASE=0xc0000000
#TEXT_BASE=0xc1200000

OPENWRT_DIR=/home/prog/openwrt/lede-all/2019-openwrt-all/openwrt-ipq4xxx
export STAGING_DIR=${OPENWRT_DIR}/staging_dir
export TOOLPATH=${STAGING_DIR}/toolchain-arm_cortex-a7+neon-vfpv4_gcc-7.4.0_musl_eabi
export PATH=${TOOLPATH}/bin:${PATH}

#KERNEL_IMAGE=${OPENWRT_DIR}/bin/targets/ipq40xx/generic/openwrt-ipq40xx-8dev_jalapeno-initramfs-uImage
#KERNEL_IMAGE=${OPENWRT_DIR}/bin/targets/ipq40xx/generic/openwrt-ipq40xx-glinet_gl-b1300-initramfs-uImage
#KERNEL_IMAGE=${OPENWRT_DIR}/bin/targets/ipq40xx/generic/openwrt-ipq40xx-compex_wpj428-initramfs-uImage
KERNEL_IMAGE=${OPENWRT_DIR}/bin/targets/ipq40xx/generic/openwrt-ipq40xx-meraki_mr33-initramfs-uImage
#KERNEL_IMAGE=${OPENWRT_DIR}/bin/targets/ipq40xx/generic/openwrt-ipq40xx-engenius_eap1300-initramfs-uImage
#KERNEL_IMAGE=${OPENWRT_DIR}/bin/targets/ipq40xx/generic/openwrt-ipq40xx-zyxel_wre6606-initramfs-uImage

CC="arm-openwrt-linux-gcc"
LD="arm-openwrt-linux-ld"
OBJDUMP="arm-openwrt-linux-objdump"
OBJCOPY="arm-openwrt-linux-objcopy"
CFLAGS="-g -Os -fno-common -ffixed-r8 -D__KERNEL__ -DCONFIG_SYS_TEXT_BASE=${TEXT_BASE} -DCONFIG_IPQ4XXX"
CFLAGS2="-fno-builtin -ffreestanding -nostdinc"
CFLAGS3="-pipe -DCONFIG_ARM -D__ARM__ -fPIC -marm -mno-thumb-interwork -mabi=aapcs-linux -march=armv7-a -mno-unaligned-access"
CFLAGS4="-Wall -Wstrict-prototypes -fno-stack-protector -Wno-format-nonliteral -Wno-format-security -fstack-usage"
GCC_SYSTEM="$TOOLPATH/lib/gcc/arm-openwrt-linux-muslgnueabi/7.4.0"
ISYSTEM="-isystem ${GCC_SYSTEM}/include"

$CC -D__ASSEMBLY__ $CFLAGS $CFLAGS2 $ISYSTEM $CFLAGS3 -o start.o start.S -c

$CC $CFLAGS $CFLAGS2 $ISYSTEM $CFLAGS3 $CFLAGS4 -o board.o board.c -c
$CC $CFLAGS $CFLAGS2 $ISYSTEM $CFLAGS3 $CFLAGS4 -o cpu.o cpu.c -c
$CC $CFLAGS $CFLAGS2 $ISYSTEM $CFLAGS3 $CFLAGS4 -o qcom_uart.o qcom_uart.c -c
$CC $CFLAGS $CFLAGS2 $ISYSTEM $CFLAGS3 $CFLAGS4 -o printf.o printf.c -c

#echo $KERNEL_IMAGE
#test for fat images
#cat $KERNEL_IMAGE > ./b1.bin
#dd if=$KERNEL_IMAGE bs=1k count=3400 >> ./b1.bin
#cat $KERNEL_IMAGE >> ./b1.bin
#cat $KERNEL_IMAGE >> ./b1.bin
#KERNEL_IMAGE=./b1.bin
#O_FORMAT=$($OBJDUMP -i | head -2 | grep elf32)
#$LD -r -b binary --oformat ${O_FORMAT} -T kernel-data.lds -o ./data.o ${KERNEL_IMAGE}
#KERNEL_IMAGE=./hello.txt
$LD -r -b binary -T kernel-data.lds -o ./data.o ${KERNEL_IMAGE}

$LD -pie -T loader.lds -Bstatic -Ttext ${TEXT_BASE} start.o \
	--start-group ./board.o ./printf.o ./qcom_uart.o ./cpu.o \
	./data.o \
	-L ${GCC_SYSTEM} \
	-lgcc -Map loader.map -o loader

#${OBJDUMP} -x ./loader > ./loader.headers
#${OBJDUMP} -D ./start.o > ./start.asm
#${OBJDUMP} -b binary -m arm -D ./loader.bin > ./loader.bin.asm

#${OBJCOPY} -O binary -R .reginfo -R .note -R .comment -R .mdebug -R .MIPS.abiflags -S ./loader ./loader.bin
#${LD} -r -b binary --oformat ${O_FORMAT} -o loader2.o loader.bin
#$CC -D__ASSEMBLY__ $CFLAGS $CFLAGS2 $ISYSTEM $CFLAGS3 -o tail.o tail.S -c
#${LD} -e startup -T loader2.lds -Ttext ${TEXT_BASE} -o loader.elf loader2.o tail.o
