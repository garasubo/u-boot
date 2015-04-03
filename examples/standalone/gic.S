
	.text

#define GICD_BASE_ADDR 0x01401000
#define GICC_BASE_ADDR 0x01402000

#define GICD_CTRL (GICD_BASE_ADDR+0x000)
#define GICD_TYPER (GICD_BASE_ADDR+0x004)
#define GICD_IIDR (GICD_BASE_ADDR+0x008)
#define GICD_IGROUPR(x) (GICD_BASE_ADDR+(0x080+0x004*(x)))
#define GICD_ISENABLER(x) (GICD_BASE_ADDR+(0x100+0x004*(x)))
#define GICD_ICENABLER(x) (GICD_BASE_ADDR+(0x180+0x004*(x)))
#define GICD_ISPENDER(x) (GICD_BASE_ADDR+(0x200+0x004*(x)))
#define GICD_ICPENDER(x) (GICD_BASE_ADDR+(0x280+0x004*(x)))
#define GICD_ISACTIVER(x) (GICD_BASE_ADDR+(0x300+0x004*(x)))
#define GICD_ICACTIVER(x) (GICD_BASE_ADDR+(0x380+0x004*(x)))
#define GICD_IPRIORITYR(x) (GICD_BASE_ADDR+(0x400+0x004*(x)))
#define GICD_ITARGETSR(x) (GICD_BASE_ADDR+(0x800+0x004*(x)))
#define GICD_ICFGR(x) (GICD_BASE_ADDR+(0xc00+0x004*(x)))
#define GICD_PPISR (GICD_BASE_ADDR+0xd00)
#define GICD_SPISR(x) (GICD_BASE_ADDR+(0xd04+0x004*(x)))
#define GICD_NSACR(x) (GICD_BASE_ADDR+(0xe00+0x004*(x)))
#define GICD_SGIR (GICD_BASE_ADDR+0xf00)
#define GICD_CPENDSGIR(x) (GICD_BASE_ADDR+(0xf10+0x004*(x)))
#define GICD_SPENDSGIR(x) (GICD_BASE_ADDR+(0xf20+0x004*(x)))

#define GICC_CTRL (GICC_BASE_ADDR+0x0000)
#define GICC_PMR (GICC_BASE_ADDR+0x0004)
#define GICC_BPR (GICC_BASE_ADDR+0x0008)
#define GICC_IAR (GICC_BASE_ADDR+0x000c)
#define GICC_EOIR (GICC_BASE_ADDR+0x0010)
#define GICC_RPR (GICC_BASE_ADDR+0x0014)
#define GICC_HPPIR (GICC_BASE_ADDR+0x0018)
#define GICC_ABPR (GICC_BASE_ADDR+0x001c)
#define GICC_AIAR (GICC_BASE_ADDR+0x0020)
#define GICC_AEOIR (GICC_BASE_ADDR+0x0024)
#define GICC_AHPPIR (GICC_BASE_ADDR+0x0028)
#define GICC_APR(x) (GICC_BASE_ADDR+(0x00d0+0x0004*(x)))
#define GICC_NSAPR(x) (GICC_BASE_ADDR+(0x00e0+0x0004*(x)))
#define GICC_IIDR (GICC_BASE_ADDR+0x00fc)
#define GICC_DIR (GICC_BASE_ADDR+0x1000)


	.org	0x00000000		// 1C : fast interrupt
	b	gic		// 00 : reset
	b	gic_end		// 04 : undefined instruction exception
	b	gic_end		// 08 : supervisor call (SVC)
	b	gic_end		// 0C : prefetch abort
	b	gic_end		// 10 : data abort
	nop				// 14 : (reserved)
	b	fiq_entry		// 18 : interrupt
	.org	0x0000001c		// 1C : fast interrupt

fiq_entry:
	push {r2-r3}
	ldr r2, =GICC_IAR 
	ldr r3, [r2]
	add r0, r0, #1
	ldr r2, =GICC_EOIR
	str r3, [r2]
	pop {r2-r3}
	subs pc, lr, #4
	.global gic
gic:
	push {r4}
	cpsid aif
	mov r0, #0
	ldr r1, =GICC_PMR
	ldr r2, =0xff-7
	str r2, [r1]
	ldr r1, =GICD_ISENABLER(0)
	ldr r2, =0xffffffff
	str r2, [r1]
	ldr r1, =GICD_ISENABLER(1)
	str r2, [r1]
	ldr r1, =GICD_ISENABLER(2)
	str r2, [r1]
	ldr r1, =GICD_ISENABLER(3)
	str r2, [r1]
	ldr ip, =GICD_IPRIORITYR(0)
gic_pri_loop:
	ldr r1, =GICD_IPRIORITYR(16)
	ldr r2, =0x0
	strb r2, [ip]
	strb r2, [ip, #0x1]
	strb r2, [ip, #0x2]
	strb r2, [ip, #0x3]
	add ip, ip, #4
	cmp ip, r1
	blt gic_pri_loop

	ldr r1, =GICC_CTRL
	ldr r2, =0x0001
	str r2, [r1]
	ldr r1, =GICD_CTRL
	ldr r2, =0x0003
	str r2, [r1]

	ldr ip, =0x82000000
	mrc	p15, 0, r4, cr12, cr0, 0
	mcr	p15, 0, ip, cr12, cr0, 0
	cpsie aif

	ldr ip, =GICD_SPENDSGIR(0)
	ldr r2, =0x01
	ldr r3, =GICD_SPENDSGIR(4)
gic_sgir_loop:
	strb r2, [ip]
	add ip, ip, #1
	cmp ip, r3
	blt gic_sgir_loop
	
	mov r1, #1
gic_wait_loop:
	cmp r1, #0
	beq gic_end
	add r1, r1, #1
	cmp r0, #0
	nop
	beq gic_wait_loop

gic_end:
	mcr p15, 0, r4, cr12, cr0, 0
	pop {r4}
	bx lr


