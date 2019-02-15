#include "io.h"

#ifdef CONFIG_IPQ4XXX
#define WDT_BASE 		0xB017000
#define WDT_RST    (WDT_BASE + 0x4)
#define WDT_EN    (WDT_BASE + 0x8)
#define WDT_STS (WDT_BASE + 0xc)
#define WDT_BARK_TIME    (WDT_BASE + 0x10)
#define WDT_BITE_TIME    (WDT_BASE + 0x14)

#define WDT_RESETUP_PERIOD 10

void watchdog_resetup(void){
	writel(0, WDT_EN);
	writel(1, WDT_RST);
	writel(WDT_RESETUP_PERIOD * 65536, WDT_BARK_TIME);
	writel(WDT_RESETUP_PERIOD * 65536, WDT_BITE_TIME);
	writel(1,  WDT_EN);
}

#endif /* CONFIG_IPQ4XXX */
