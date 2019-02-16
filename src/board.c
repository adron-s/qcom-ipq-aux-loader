#include <printf.h>
#include <iomap.h>
#include <io.h>
#include <types.h>
#include <uimage/legacy.h>
#include <uimage/fdt.h>

//u32 *boot_params = (void*)(CONFIG_SYS_INIT_SP_ADDR + 0x6400000);
//u32 *boot_params = (void*)(CONFIG_SYS_INIT_SP_ADDR + 0x1400000);

int cleanup_before_linux(void);

unsigned long int ntohl(unsigned long int d){
	unsigned long int res = 0;
	int a;
	for(a = 0; a < 3; a++){
		res |= d & 0xFF;
		res <<= 8; d >>= 8;
	}
	res |= d & 0xFF;
	return res;
}

static inline void dump_mem(unsigned char *p, char *str){
	printf("  %s(0x%08X) = %02x %02x %02x %02x %02x %02x %02x %02x\n",
		str,
		p,
		p[0] & 0xFF, p[1] & 0xFF,
		p[2] & 0xFF, p[3] & 0xFF,
		p[4] & 0xFF, p[5] & 0xFF,
		p[6] & 0xFF, p[7] & 0xFF
	);
}

extern u32 owl_get_sp(void);
void serial_putc(char c);
void watchdog_setup(int);

void reset_cpu(ulong addr)
{
	/* clear ps-hold bit to reset the soc */
	writel(0, GCNT_PSHOLD);
	while (1);
}

int handle_legacy_header(void **src, void **dst, void** kernel_entry,
void *_kernel_data_start, u32 kern_image_len){
	legacy_image_header_t *image = (void*)_kernel_data_start;
	*src = (void*)_kernel_data_start + sizeof(legacy_image_header_t);
	*dst = (void*)ntohl(image->ih_load);
	u32 kernel_body_len = ntohl(image->ih_size);

	printf("  size = %u\n", kernel_body_len);
	printf("  name = '%s'\n", image->ih_name);
	//printf("  ih_load = 0x%08x\n", ntohl(image->ih_load));
	//printf("  ih_ep = 0x%08x\n", ntohl(image->ih_ep));

	//check ih_size for adequate value
	if(kern_image_len - sizeof(legacy_image_header_t) < kernel_body_len){
		printf("\n");
		printf("Error ! Kernel sizes mismath detected !\n");
		printf("  details: %d - %d < %d !\n", kern_image_len,
			sizeof(legacy_image_header_t), kernel_body_len);
		return -99;
	}
	*kernel_entry = (void*)ntohl(image->ih_ep);

	return 0;
}

void board_init_f(u32 head_text_base)
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
	printf("  head loader TEXT_BASE = 0x%08X\n", head_text_base);
	printf("kernel loader TEXT_BASE = 0x%08X\n", CONFIG_SYS_TEXT_BASE);
	//printf("kernel_data_start = 0x%08X\n", _kernel_data_start);
	//printf("kernel_data_end = 0x%08X\n", _kernel_data_end);
	printf("\n");

	//watchdog_setup(5); for(;;);
	//reset_cpu(0);

	magic = ntohl(*_magic);
	printf("Kernel image header:\n");
	switch(magic){
		case LEGACY_IH_MAGIC:
			printf("  magic = 0x%x, Legacy uImage\n", magic);
			ret = handle_legacy_header((void**)&src, (void**)&dst,
				(void**)&kernel_entry, _kernel_data_start, kern_image_len);
			break;
		case FDT_IH_MAGIC:
			printf("  magic = 0x%x, FIT uImage\n", magic);
			break;
		default:
			printf("  magic = 0x%x, UNKNOWN !!!\n", magic);
	}
	if(ret){
		printf("\n");
		printf("Op ret = %d\n", ret);
		printf("Auto reboot in 5 sec\n");
		watchdog_setup(5); for(;;);
	}
	printf("\n");
	printf("Copy kernel...");
	for(; (void*)src + 4 <= (void*)_kernel_data_end; src += 4, dst += 4)
		*((u32*)dst) = *((u32*)src);
	for(; (void*)src < (void*)_kernel_data_end; src++, dst++)
		*dst = *src;
	printf("Done\n");

	printf("Starting kernel at 0x%08x\n", kernel_entry);
	printf("\n");
	cleanup_before_linux();
	kernel_entry(0, 4200, 0);
	reset_cpu(0);
}

void hang(void)
{
	printf("### ERROR ### Please RESET the board ###\n");
	for (;;);
}

int raise(int signum)
{
	/* Needs for div/mod ops */
	printf("raise: Signal # %d caught\n", signum);
	return 0;
}
