#include "printf.h"
#include "iomap.h"
#include "io.h"
#include "types.h"
#include "config.h"
#include "kernel_tags.h"

/*
 * Compression Types
 */
#define IH_COMP_NONE		0	/*  No	 Compression Used	*/
#define IH_COMP_GZIP		1	/* gzip	 Compression Used	*/
#define IH_COMP_BZIP2		2	/* bzip2 Compression Used	*/
#define IH_COMP_LZMA		3	/* lzma  Compression Used	*/
#define IH_COMP_LZO		4	/* lzo   Compression Used	*/

#define IH_MAGIC	0x27051956	/* Image Magic Number		*/
#define IH_NMLEN		32	/* Image Name Length		*/

/* Watchdog bite time set to default reset value */
#define RESET_WDT_BITE_TIME 0x31F3

/* Watchdog bark time value is ketp larger than the watchdog timeout
 * of 0x31F3, effectively disabling the watchdog bark interrupt
 */
#define RESET_WDT_BARK_TIME (5 * RESET_WDT_BITE_TIME)

#define	LINUX_MAX_ARGS		256

/*
 * Legacy format image header,
 * all data in network byte order (aka natural aka bigendian).
 */
typedef struct image_header {
	uint32_t	ih_magic;	/* Image Header Magic Number	*/
	uint32_t	ih_hcrc;	/* Image Header CRC Checksum	*/
	uint32_t	ih_time;	/* Image Creation Timestamp	*/
	uint32_t	ih_size;	/* Image Data Size		*/
	uint32_t	ih_load;	/* Data	 Load  Address		*/
	uint32_t	ih_ep;		/* Entry Point Address		*/
	uint32_t	ih_dcrc;	/* Image Data CRC Checksum	*/
	uint8_t		ih_os;		/* Operating System		*/
	uint8_t		ih_arch;	/* CPU architecture		*/
	uint8_t		ih_type;	/* Image Type			*/
	uint8_t		ih_comp;	/* Compression Type		*/
	uint8_t		ih_name[IH_NMLEN];	/* Image Name		*/
} image_header_t;

typedef struct image_info {
	ulong		start, end;		/* start/end of blob */
	ulong		image_start, image_len; /* start of image within blob, len of image */
	ulong		load;			/* load addr for the image */
	uint8_t		comp, type, os;		/* compression, type of image, os type */
} image_info_t;

//u32 *boot_params = (void*)(CONFIG_SYS_INIT_SP_ADDR + 0x6400000);
u32 *boot_params = (void*)(CONFIG_SYS_INIT_SP_ADDR + 0x1400000);

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

void reset_cpu(ulong addr)
{
	/* clear ps-hold bit to reset the soc */
	writel(0, GCNT_PSHOLD);
	while (1);
}


void board_init_f(unsigned long bootflag)
{
	extern char _kernel_data_start[];
	extern char _kernel_data_end[];
	void (*kernel_entry)(int zero, int arch, unsigned int params);

	/* compiler optimization barrier needed for GCC >= 3.4 */
	__asm__ __volatile__("": : :"memory");

	//reset_cpu(0);
	//writel(1, APCS_WDT0_RST);
	//printf("\n");
	writel(0, WDT_EN);
	writel(1, WDT_RST);
	serial_putc('0');
	/* while(1){
		if(z % 10000 == 0){
			for(a = 0; a < 9; a++)
				serial_putc('0' + a);
			serial_putc('-');
			serial_putc('0' + ((z / 10000) & 7));
			serial_putc('\r');
			serial_putc('\n');
		}
		z++;
		if(z > 1000 * 10000)
			reset_cpu(0);
		//serial_putc('\r');
	} */
	{
		image_header_t *image = (void*)_kernel_data_start;
		unsigned char *p = (void*)_kernel_data_start + sizeof(image_header_t);
		unsigned char *k = (void*)ntohl(image->ih_load);
		//reset_cpu(0);
		serial_putc('1');
		if(ntohl(image->ih_magic) != IH_MAGIC)
			serial_putc('!');
		for(; (void*)p < (void*)_kernel_data_end; p++, k++){
			*k = *p;
		}
		serial_putc('2');
		//reset_cpu(0);
		kernel_entry = (void*)ntohl(image->ih_ep);
	}
	printf("!%x!", kernel_entry);
	serial_putc('3');
	cleanup_before_linux();
	kernel_entry(0, 4200, 0);
	//kernel_entry(0, 1068, 0);
	reset_cpu(0);
}

void save_boot_params_default(u32 r0, u32 r1, u32 r2, u32 r3)
{
	/* boot_params[0] = r0;
	boot_params[1] = r1;
	boot_params[2] = r2;
	boot_params[3] = r3; */
	/* if(r1 == 4200){
		serial_putc('a');
	}else{
		serial_putc('b');
	} */
}

void save_boot_params(u32 r0, u32 r1, u32 r2, u32 r3)
	__attribute__((weak, alias("save_boot_params_default")));

void hang(void)
{
	printf("### ERROR ### Please RESET the board ###\n");
	for (;;);
}

int raise (int signum)
{
	/* Needs for div/mod ops */
	printf("raise: Signal # %d caught\n", signum);
	return 0;
}
