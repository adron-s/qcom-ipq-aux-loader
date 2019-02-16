.globl _start
_start:
	mov r7, r1 @save REAL _start addr

/* Lets clear a bss */
clear_bss:
	ldr	r0, =_bss_start
	ldr	r1, =_bss_end
	mov	r2, #0x00000000		/* clear			    */
clbss_l:
	cmp	r0, r1			/* clear loop... */
	bhs	clbss_e			/* if reached end of bss, exit */
	str	r2, [r0]
	add	r0, r0, #4
	b	clbss_l
clbss_e:

/* Set stackpointer in internal RAM to call loader_main */
call_loader_main:
	/* stack grows left! <--SP--TEXT_BASE,_start--END of program */
	ldr	sp, =(CONFIG_SYS_TEXT_BASE)
	bic	sp, sp, #7 /* 8-byte alignment for ABI compliance */
	mov r0, r7
	bl	loader_main

.globl owl_get_sp
owl_get_sp:
	mov	r0, sp
	mov	pc, lr @ back to my caller

