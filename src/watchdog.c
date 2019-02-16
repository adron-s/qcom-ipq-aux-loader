/*
 * Auxiliary kernel loader for Qualcom IPQ-4XXX/806X based boards
 *
 * Copyright (C) 2019 Sergey Sergeev <adron@mstnt.com>
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

#include <io.h>

#ifdef CONFIG_IPQ4XXX
#define WDT_BASE 		0xB017000
#define WDT_RST    (WDT_BASE + 0x4)
#define WDT_EN    (WDT_BASE + 0x8)
#define WDT_STS (WDT_BASE + 0xc)
#define WDT_BARK_TIME    (WDT_BASE + 0x10)
#define WDT_BITE_TIME    (WDT_BASE + 0x14)

#define WDT_RESETUP_PERIOD 10

void watchdog_setup(int period){
	writel(0, WDT_EN);
	writel(1, WDT_RST);
	writel(period * 65536, WDT_BARK_TIME);
	writel(period * 65536, WDT_BITE_TIME);
	writel(1,  WDT_EN);
}

void watchdog_resetup(void){
	watchdog_setup(WDT_RESETUP_PERIOD);
}

#endif /* CONFIG_IPQ4XXX */
