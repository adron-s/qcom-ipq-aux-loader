#!/bin/sh

#TEXT_BASE=0x87300000
#TEXT_BASE=0x80060000
#TEXT_BASE=0x41200000
#TEXT_BASE=0x41600000
#TEXT_BASE=0x89000000
#TEXT_BASE=0x80000000
#TEXT_BASE=0x80000000
#TEXT_BASE=0x87300000 #realloc memory address
TEXT_BASE=0x84800000 #+72M. realloc memory address
#TEXT_BASE=0x80BB0000
#TEXT_BASE=0x80BB1E00
#TEXT_BASE=0x80A00000
#TEXT_BASE=0x80808000
#TEXT_BASE=0x81900000
#TEXT_BASE=0x81820000
#TEXT_BASE=0x01100000
#TEXT_BASE=0x82900000
#TEXT_BASE=0x80208000
#TEXT_BASE=0x01100000
#TEXT_BASE=0x21100000
#TEXT_BASE=0x01100000
#TEXT_BASE=0x80000000
#TEXT_BASE=0xc0000000
#TEXT_BASE=0xc1200000

#TEXT_BASE2=0x00000000 #for fat kernels <= 12M
#TEXT_BASE2=0x80000000 #for fat kernels <= 12M
#TEXT_BASE2=0x81820000
TEXT_BASE2=0x01100000 #RouterBOOT auto realloc flag value address. Kernel size is limited < 6M !

OPENWRT_DIR=/home/prog/openwrt/lede-all/2019-openwrt-all/openwrt-ipq4xxx
export STAGING_DIR=${OPENWRT_DIR}/staging_dir
export TOOLPATH=${STAGING_DIR}/toolchain-arm_cortex-a7+neon-vfpv4_gcc-7.4.0_musl_eabi
export PATH=${TOOLPATH}/bin:${PATH}

#KERNEL_IMAGE=${OPENWRT_DIR}/bin/targets/ipq40xx/generic/old/openwrt-ipq40xx-meraki_mr33-initramfs-uImage
KERNEL_IMAGE=${OPENWRT_DIR}/bin/targets/ipq40xx/generic/openwrt-ipq40xx-meraki_mr33-initramfs-fit-uImage.itb

CC="arm-openwrt-linux-gcc"
LD="arm-openwrt-linux-ld"
OBJDUMP="arm-openwrt-linux-objdump"
OBJCOPY="arm-openwrt-linux-objcopy"
CFLAGS="-g -Os -fno-common -ffixed-r8 -D__KERNEL__ -DCONFIG_SYS_TEXT_BASE=${TEXT_BASE} -DCONFIG_IPQ4XXX"
CFLAGS2="-fno-builtin -ffreestanding -nostdinc"
CFLAGS3="-pipe -DCONFIG_ARM -D__ARM__ -fPIC -marm -mno-thumb-interwork -mabi=aapcs-linux -march=armv7-a -mno-unaligned-access"
CFLAGS4="-Wall -Wstrict-prototypes -fno-stack-protector -Wno-format-nonliteral -Wno-format-security -fstack-usage"
INCLUDE="-I./src/include"
GCC_SYSTEM="$TOOLPATH/lib/gcc/arm-openwrt-linux-muslgnueabi/7.4.0"
ISYSTEM="-isystem ${GCC_SYSTEM}/include"

$CC -D__ASSEMBLY__ $CFLAGS $CFLAGS2 $ISYSTEM $CFLAGS3 -o bin/start.o src/start.S -c

$CC $CFLAGS $CFLAGS2 $INCLUDE $ISYSTEM $CFLAGS3 $CFLAGS4 -o bin/board.o src/board.c -c
$CC $CFLAGS $CFLAGS2 $INCLUDE $ISYSTEM $CFLAGS3 $CFLAGS4 -o bin/cpu.o src/cpu.c -c
$CC $CFLAGS $CFLAGS2 $INCLUDE $ISYSTEM $CFLAGS3 $CFLAGS4 -o bin/qcom_uart.o src/qcom_uart.c -c
$CC $CFLAGS $CFLAGS2 $INCLUDE $ISYSTEM $CFLAGS3 $CFLAGS4 -o bin/printf.o src/printf.c -c
$CC $CFLAGS $CFLAGS2 $INCLUDE $ISYSTEM $CFLAGS3 $CFLAGS4 -o bin/watchdog.o src/watchdog.c -c
$CC $CFLAGS $CFLAGS2 $INCLUDE $ISYSTEM $CFLAGS3 $CFLAGS4 -o bin/fdt.o src/fdt.c -c
$CC $CFLAGS $CFLAGS2 $INCLUDE $ISYSTEM $CFLAGS3 $CFLAGS4 -o bin/LzmaDecode.o src/LzmaDecode.c -c
$CC $CFLAGS $CFLAGS2 $INCLUDE $ISYSTEM $CFLAGS3 $CFLAGS4 -o bin/lzma.o src/lzma.c -c
$CC $CFLAGS $CFLAGS2 $INCLUDE $ISYSTEM $CFLAGS3 $CFLAGS4 -o bin/loader.o src/loader.c -c

#echo $KERNEL_IMAGE
#test for fat images
#cat $KERNEL_IMAGE > ./b1.bin
#dd if=$KERNEL_IMAGE bs=1k count=2000 >> ./b1.bin
#cat $KERNEL_IMAGE >> ./b1.bin
#cat $KERNEL_IMAGE >> ./b1.bin
#cat $KERNEL_IMAGE >> ./b1.bin
#KERNEL_IMAGE=./b1.bin
O_FORMAT=$($OBJDUMP -i | head -2 | grep elf32)
$LD -r -b binary -T src/kernel-data.lds -o bin/data.o ${KERNEL_IMAGE}

$LD -pie -T src/loader.lds -Bstatic -Ttext ${TEXT_BASE} bin/start.o \
	--start-group bin/loader.o bin/printf.o bin/qcom_uart.o bin/cpu.o \
	bin/board.o bin/watchdog.o bin/fdt.o bin/LzmaDecode.o bin/lzma.o bin/data.o \
	-L ${GCC_SYSTEM} \
	-lgcc -Map bin/loader.map -o bin/loader

#${OBJCOPY} --only-section=.bss -S bin/loader bin/loader.slim
#${OBJCOPY} -R .text -R .data -R .ARM.attributes -R .comment -R .debug.* -S bin/loader bin/loader.slim
#${OBJDUMP} -x bin/loader.slim > bin/loader.slim.headers
#${OBJDUMP} -x bin/loader > bin/loader.headers
#${OBJDUMP} -D bin/start.o > ./start.asm
#${OBJDUMP} -b binary -m arm -D bin/loader.bin > ./loader.bin.asm
#${OBJDUMP} bin/start.o -D > ./start.o.asm

${OBJCOPY} -O binary -R .reginfo -R .note -R .comment -R .mdebug -R .MIPS.abiflags -S bin/loader bin/loader.bin
${LD} -r -b binary --oformat ${O_FORMAT} -o bin/loader2.o bin/loader.bin
$CC -D__ASSEMBLY__ $CFLAGS $CFLAGS2 $ISYSTEM $CFLAGS3 -o bin/head.o src/head.S -c
# bin/qcom_uart.o bin/printf.o -L ${GCC_SYSTEM} -lgcc
${LD} -e startup -T src/loader2.lds -Ttext ${TEXT_BASE2} -o bin/loader.elf bin/loader2.o \
	bin/head.o bin/watchdog.o -Map bin/loader2.map

#${OBJCOPY} -O binary -R .text -R .ARM.attributes -R .comment -R .debug.* -S bin/loader.elf bin/loader.elf.bin
#${OBJDUMP} -x ./loader.elf > ./loader.elf.headers
#${OBJCOPY} -R .data -R .ARM.attributes -R .comment -R .debug.* -S bin/loader.elf bin/loader.elf.X
#${OBJDUMP} -x bin/loader.elf.X > ./loader.elf.X.headers
