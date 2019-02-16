#ifndef __ASM_ARM_MINI_IO_H
#define __ASM_ARM_MINI_IO_H


#define dmb()		__asm__ __volatile__ ("" : : : "memory")
#define __iormb()	dmb()
#define __iowmb()	dmb()
#define __arch_putl(v,a)		(*(volatile unsigned int *)(a) = (v))
#define __arch_getl(a)			(*(volatile unsigned int *)(a))

#define writel(v,c)	({ unsigned int __v = v; __iowmb(); __arch_putl(__v,c); __v; })
#define readl(c)	({ unsigned int __v = __arch_getl(c); __iormb(); __v; })

#endif /* __ASM_ARM_MINI_IO_H */
