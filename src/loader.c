/*
 * Auxiliary kernel loader for Qualcom IPQ-4XXX/806X based boards
 *
 * Copyright (C) 2019 Sergey Sergeev <adron@mstnt.com>
 *
 * Some parts of this code was based on the OpenWrt specific lzma-loader
 * for the Atheros AR7XXX/AR9XXX based boards:
 *	Copyright (C) 2011 Gabor Juhos <juhosg@openwrt.org>
 *
 * Some structures and code has been taken from the U-Boot project.
 *	(C) Copyright 2008 Semihalf
 *	(C) Copyright 2000-2005
 *	Wolfgang Denk, DENX Software Engineering, wd@denx.de.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 as published
 * by the Free Software Foundation.
 */

#include <printf.h>
#include <iomap.h>
#include <io.h>
#include <types.h>
#include <uimage/legacy.h>

/* beyond the image end, size not known in advance */
extern unsigned char workspace[];

/* base stack poinet - 16 mb. stack grows left!
	 boot_params(12b)<--16M of stack--TEXT_BASE,_start--END of program
	 !!! TODO: replace to like workspace static mem region !!!
*/
//u32 *boot_params = (void*)(CONFIG_SYS_TEXT_BASE - 0x100000C);

int cleanup_before_linux(void);
void enable_caches(void);
extern u32 owl_get_sp(void);
void serial_putc(char c);
void watchdog_setup(int);
unsigned long int ntohl(unsigned long int);
void dump_mem(unsigned char *, char *);
void reset_cpu(ulong);
int fdt_check_header(void *, u32);
char *fdt_get_prop(void *, char *, char *, u32 *);
int lzma_gogogo(void *, void *, u32, u32 *);

int handle_legacy_header(void **src, void **dst, void** kernel_entry,
void *_kernel_data_start, u32 kern_image_len){
	legacy_image_header_t *image = (void*)_kernel_data_start;
	void *kernel_load = (void*)ntohl(image->ih_load);
	void *kernel_ep = (void*)ntohl(image->ih_ep);
	char *kernel_name = (char*)image->ih_name;
	*src = (void*)_kernel_data_start + sizeof(legacy_image_header_t);
	*dst = kernel_load;
	u32 kernel_body_len = ntohl(image->ih_size);

	printf("  size = %u\n", kernel_body_len);
	printf("  name = '%s'\n", kernel_name);
	printf("  load = 0x%08x\n", kernel_load);
	printf("  ep = 0x%08x\n", kernel_ep);

	//check ih_size for adequate value
	if(kern_image_len - sizeof(legacy_image_header_t) < kernel_body_len){
		printf("\n");
		printf("Error ! Kernel sizes mismath detected !\n");
		printf("  details: %d - %d < %d !\n", kern_image_len,
			sizeof(legacy_image_header_t), kernel_body_len);
		return -99;
	}
	*kernel_entry = kernel_ep;

	return 0;
}

/* FIT - Flattened Image Tree.
	 ! Not to be confused with an FDT - Flattened Device Tree !
	 ! MAGIC of FIT == ~MAGIC of FDT !
*/
#define FIT_KERNEL_NODE_NAME "kernel@1"
#define FIT_DTB_NODE_NAME "fdt@1"
int handle_fit_header(void **src, void **dst, void** kernel_entry,
void *_kernel_data_start, u32 kern_image_len){
	void *data = (void*)_kernel_data_start;
	void *kernel_load = NULL;
	void *kernel_ep = NULL;
	char *kernel_name = NULL;
	char *kernel_compr = NULL;
	void *dtb_data = NULL; //device tree blob
	u32 dtb_body_len = 0;
	u32 kernel_body_len = 0;
	u32 kernel_uncompr_size = 0;
	char *tmp_c;
	int ret;
	/* Do FDT header base checks */
	ret = fdt_check_header(data, kern_image_len);
	if(ret){
		printf("Error ! FDT header is corrupted! check_ret = %d\n", ret);
		return -99;
	}
	if(!(kernel_name = fdt_get_prop(data, FIT_KERNEL_NODE_NAME, "description", NULL)))
		return -98;
	if(!(tmp_c = fdt_get_prop(data, FIT_KERNEL_NODE_NAME, "load", NULL)))
		return -97;
	kernel_load = (void*)ntohl(*(u32*)tmp_c);
	*dst = kernel_load;
	if(!(tmp_c = fdt_get_prop(data, FIT_KERNEL_NODE_NAME, "entry", NULL)))
		return -96;
	kernel_ep = (void*)ntohl(*(u32*)tmp_c);
	if(!(*src = fdt_get_prop(data, FIT_KERNEL_NODE_NAME, "data", &kernel_body_len)))
		return -95;
	if(!(kernel_compr = fdt_get_prop(data, FIT_KERNEL_NODE_NAME, "compression", NULL)))
		return -94;
	if(!(dtb_data = fdt_get_prop(data, FIT_DTB_NODE_NAME, "data", &dtb_body_len)))
		return -93;

	printf("  size = %u\n", kernel_body_len);
	printf("  name = '%s'\n", kernel_name);
	printf("  load = 0x%08x\n", kernel_load);
	printf("  ep = 0x%08x\n", kernel_ep);
	printf("  compr = %s\n", kernel_compr);

	//check kernel@1->data size for adequate value
	if(kernel_body_len >= kern_image_len){
		printf("\n");
		printf("Error ! Kernel sizes mismath detected !\n");
		printf("  details: %d >= %d !\n", kernel_body_len, kern_image_len);
		return -99;
	}
	printf("\n");
	printf("LZMA extract kernel...");
	lzma_gogogo(*dst, *src, kernel_body_len, &kernel_uncompr_size);
	printf("Done\n");

	/* prepare device tree blob data for copy after kernel */
	{
		unsigned char *src = dtb_data;
		unsigned char *dst = (void*)workspace; // kernel_load + kernel_uncompr_size; //64 bit aligned !
		unsigned char *end = src + dtb_body_len;
		for(; src < end; src++, dst++){
			//printf("0x%x vs 0x%x\n", src, end);
			*dst = *src;
		}
		dump_mem(kernel_load + kernel_uncompr_size, "dtb_data:");
		printf("kernel_uncompr_size  = %u\n", kernel_uncompr_size);
	}

	*kernel_entry = kernel_ep;
	{ //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		void (*kernel_entry_x)(u32 zero, int arch, void *);
		kernel_entry_x = (void*)kernel_ep;
		printf("Try to launch kernel: 0x%x, 0x%x\n", kernel_entry_x, (void*)workspace);
		cleanup_before_linux();
		kernel_entry_x(0, 4200, (void*)workspace);
		reset_cpu(0);
	}
	return 10;
}

void loader_main(u32 head_text_base)
{
	extern char _kernel_data_start[];
	extern char _kernel_data_end[];
	u32 kern_image_len = _kernel_data_end  - _kernel_data_start;
	uint32_t *_magic = (void*)_kernel_data_start;
	void (*kernel_entry)(int zero, int arch, unsigned int params);
	unsigned char *src = NULL;
	unsigned char *dst = NULL;
	u32 magic;
	int ret = -100;

	/* compiler optimization barrier needed for GCC >= 3.4 */
	__asm__ __volatile__("": : :"memory");

	printf("\n");
	printf("OpenWrt kernel loader for Qualcom IPQ-4XXX/IPQ-806X\n");
	printf("Copyright (C) 2019 Sergey Sergeev <adron@mstnt.com>\n");

	printf("\n");
	printf("  head loader TEXT_BASE = 0x%08X\n", head_text_base);
	printf("kernel loader TEXT_BASE = 0x%08X\n", CONFIG_SYS_TEXT_BASE);
	//printf("kernel_data_start = 0x%08X\n", _kernel_data_start);
	//printf("kernel_data_end = 0x%08X\n", _kernel_data_end);
	printf("\n");

	//watchdog_setup(5); for(;;);
	//reset_cpu(0);

	/* without this all cpu operations is very very slow ! */
	watchdog_setup(30);
	enable_caches();

	magic = ntohl(*_magic);
	printf("Kernel image header:\n");
	switch(magic){
		case LEGACY_IH_MAGIC:
			printf("  magic = 0x%x, Legacy uImage\n", magic);
			ret = handle_legacy_header((void**)&src, (void**)&dst,
				(void**)&kernel_entry, _kernel_data_start, kern_image_len);
			break;
		case FIT_IH_MAGIC:
			printf("  magic = 0x%x, FIT uImage\n", magic);
			ret = handle_fit_header((void**)&src, (void**)&dst,
				(void**)&kernel_entry, _kernel_data_start, kern_image_len);
			break;
		default:
			printf("  magic = 0x%x, UNKNOWN !!!\n", magic);
	}
	if(ret < 0){
		printf("\n");
		printf("Op ret = %d\n", ret);
		printf("Auto reboot in 5 sec\n");
		watchdog_setup(5); for(;;);
	}
	if(ret != 10){
		printf("\n");
		printf("Copy kernel...");
		for(; (void*)src + 4 <= (void*)_kernel_data_end; src += 4, dst += 4)
			*((u32*)dst) = *((u32*)src);
		for(; (void*)src < (void*)_kernel_data_end; src++, dst++)
			*dst = *src;
		printf("Done\n");
	}

	printf("Starting kernel at 0x%08x\n", kernel_entry);
	printf("\n");
	cleanup_before_linux();
	kernel_entry(0, 4200, 0);
	reset_cpu(0);
}
