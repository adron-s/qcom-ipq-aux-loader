#ifndef _CONFIG_H
#define _CONFIG_H

//#define GENERATED_IPQ_RESERVE_SIZE (22020096) /* sizeof(ipq_mem_reserve_t) */

//#define CONFIG_SYS_SDRAM_BASE           0x40000000
//#define CONFIG_SYS_TEXT_BASE            0x41200000
//#define CONFIG_SYS_SDRAM_SIZE           0x10000000
//#define CONFIG_MAX_RAM_BANK_SIZE        CONFIG_SYS_SDRAM_SIZE
//#define CONFIG_SYS_LOAD_ADDR            (CONFIG_SYS_SDRAM_BASE + (64 << 20))

/* 30Mb stack pointer offset TEXT_BASE <---<<- SP */
#define CONFIG_SYS_INIT_SP_ADDR (CONFIG_SYS_TEXT_BASE + 0x1E00000)
//#define CONFIG_SYS_INIT_SP_ADDR (0x87300000)
/* #define CONFIG_SYS_INIT_SP_ADDR         CONFIG_SYS_SDRAM_BASE + \
	GENERATED_IPQ_RESERVE_SIZE */
/* #define CONFIG_SYS_MAXARGS              16
#define CONFIG_SYS_PBSIZE               (CONFIG_SYS_CBSIZE + \
	sizeof(CONFIG_SYS_PROMPT) + 16) */

#endif /* _CONFIG_H */
