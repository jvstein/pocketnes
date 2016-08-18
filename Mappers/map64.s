	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h
	INCLUDE 6502.h
	INCLUDE 6502mac.h

	EXPORT mapper64init

countdown EQU mapperdata+0
latch EQU mapperdata+1
irqen EQU mapperdata+2
rmode EQU mapperdata+3
cmd EQU mapperdata+4
bank0 EQU mapperdata+5
;----------------------------------------------------------------------------
mapper64init
;----------------------------------------------------------------------------
	DCD write0,write1,write2,write3

	adr r0,RAMBO_IRQ_Hook
	str r0,scanlinehook

	mov pc,lr
;----------------------------------------------------------------------------
write0		;$8000-8001
;----------------------------------------------------------------------------
	tst addy,#1
	streqb r0,cmd
w8001
	ldrb r1,cmd
	and r1,r1,#0xF
	ldrne pc,[pc,r1,lsl#2]
	mov pc,lr
;----------------------------------------------------------------------------
commandlist	DCD cmd0,cmd1,chr4_,chr5_,chr6_,chr7_,map89_,mapAB_
			DCD cmd0x,cmd1x,void,void,void,void,void,mapCD_
;----------------------------------------------------------------------------

cmd0			;0000-07ff
	ldrb r1,cmd
	tst r1,#0x20
	bne chr0_
	mov r0,r0,lsr#1
	b chr01_
cmd1			;0800-0fff
	ldrb r1,cmd
	tst r1,#0x20
	bne chr2_
	mov r0,r0,lsr#1
	b chr23_

cmd0x			;1000-17ff
	ldrb r1,cmd
	tst r1,#0x20
	moveq pc,lr
	mov r0,r0,lsr#1
	b chr1_
cmd1x			;1800-1fff
	ldrb r1,cmd
	tst r1,#0x20
	moveq pc,lr
	mov r0,r0,lsr#1
	b chr3_
;----------------------------------------------------------------------------
write1		;$A000-A001
;----------------------------------------------------------------------------
	tst addy,#1
	movne pc,lr
	tst r0,#1
	b mirror2V_
;----------------------------------------------------------------------------
write2		;C000-C001
;----------------------------------------------------------------------------
	tst addy,#1
	streqb r0,latch
	movne r0,#0
	strneb r0,countdown
	mov pc,lr
;----------------------------------------------------------------------------
write3		;E000-E001
;----------------------------------------------------------------------------
	and r0,addy,#1
	strb r0,irqen
	mov pc,lr
;----------------------------------------------------------------------------
RAMBO_IRQ_Hook
;----------------------------------------------------------------------------
;	ldrb r0,ppuctrl1
;	tst r0,#0x18		;no sprite/BG enable?  0x18
;	beq hk0			;bye..

	ldr r0,scanline
	cmp r0,#240		;not rendering?
	bhi hk0			;bye..

	ldrb r0,countdown
	subs r0,r0,#1
	ldrmib r0,latch
	strb r0,countdown
	bne hk0

	ldrb r1,irqen
	cmp r1,#0
	beq hk0

;	mov r1,#0
;	strb r1,irqen
;	b irq6502
	b CheckI
hk0
	fetch 0
	END
