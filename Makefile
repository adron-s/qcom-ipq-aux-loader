#
# Auxiliary kernel loader for Qualcom IPQ-4XXX/806X based boards
#
#  Copyright (C) 2019 Sergey Sergeev <adron@mstnt.com>
#
#  This program is free software; you can redistribute it and/or modify it
#  under the terms of the GNU General Public License version 2 as published
#  by the Free Software Foundation.
#

#+72M. realloc memory address
TEXT_BASE	:= 0x84800000
#RouterBOOT auto realloc flag value address. Kernel size is limited < 6M !
TEXT_BASE2 := 0x01100000
#for fat kernels <= 12M
TEXT_BASE2_FAT := 0x00000000

CC			:= $(CROSS_COMPILE)gcc
LD			:= $(CROSS_COMPILE)ld
OBJCOPY	:= $(CROSS_COMPILE)objcopy
OBJDUMP	:= $(CROSS_COMPILE)objdump

BIN_FLAGS	:= -O binary -R .reginfo -R .note -R .comment -R .mdebug -R .MIPS.abiflags -S

CFLAGS = -D__KERNEL__ -DCONFIG_SYS_TEXT_BASE=$(TEXT_BASE) -DCONFIG_IPQ4XXX \
			-DCONFIG_ARM -D__ARM__ -fPIC -Wall -Wstrict-prototypes 							 \
			-Wno-format-security -Wno-format-nonliteral 												 \
			-fno-stack-protector -fstack-usage -pipe 														 \
			-marm -mno-thumb-interwork -mabi=aapcs-linux -march=armv7-a          \
			-mno-unaligned-access -fno-builtin -ffreestanding 				           \
			-g -Os -fno-common -ffixed-r8

CFLAGS += -I./src/include

ASFLAGS		= $(CFLAGS) -D__ASSEMBLY__

LDFLAGS		= -pie -Bstatic
LDFLAGS_DATA = -r -b binary --oformat $(O_FORMAT) -o

O_FORMAT = $(shell $(OBJDUMP) -i | head -2 | grep elf32)

ldr 		:= bin/loader
ldr-bin := bin/loader.bin
ldr-elf := bin/loader.elf

tgs-h 	:= io.h iomap.h LzmaDecode.h LzmaTypes.h printf.h types.h \
           uimage/fdt.h uimage/legacy.h
tgs-lds	:= kernel-data.lds loader2.lds loader.lds
tgs-o 	:= start.o board.o cpu.o fdt.o loader.o lzma.o LzmaDecode.o \
           printf.o qcom_uart.o watchdog.o divmod.o data.o
tgs2-o	:= head.o data2.o watchdog.o
tgs-h 	:= $(tgs-h:%=src/include/%)
tgs-lds := $(tgs-lds:%=src/%)
tgs-o 	:= $(tgs-o:%=objs/%)
tgs2-o 	:= $(tgs2-o:%=objs/%)

all: $(ldr-elf)

# Don't build dependencies, this may die if $(CC) isn't gcc
dep:

install:

$(tgs-lds):
$(tgs-h):

$(tgs-o): $(tgs-lds)
$(tgs-o): $(tgs-h)

# objs/qcom_uart.o objs/printf.o - add it to *.o list for debug
$(ldr-elf): $(tgs2-o)
	$(LD) $(LDFLAGS) -e _start -Ttext $(TEXT_BASE2) -o $(ldr-elf) \
	$(tgs2-o) -Map maps/loader2.map -T src/loader2.lds

$(ldr-bin): $(ldr)
	$(OBJCOPY) $(BIN_FLAGS) $< $@

$(ldr): $(tgs-o)
	$(LD) $(LDFLAGS) -e _start -Ttext $(TEXT_BASE) \
	$(tgs-o) -Map maps/loader.map -T src/loader.lds -o $@

objs/%.o: src/%.c
	$(CC) $(CFLAGS) -o $@ $< -c

objs/%.o: src/%.S
	$(CC) $(ASFLAGS) -o $@ $< -c

objs/data2.o: $(ldr-bin)
	$(LD) $(LDFLAGS_DATA) $@ $<

objs/data.o: $(KERNEL_IMAGE)
	$(LD) $(LDFLAGS_DATA) $@ $< -T src/kernel-data.lds

mrproper: clean

clean:
	rm -f bin/* objs/* maps/*
