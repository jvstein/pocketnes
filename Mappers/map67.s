	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h
	INCLUDE 6502.h
	INCLUDE 6502mac.h

	EXPORT mapper67init
	EXPORT map67_IRQ_Hook

countdown EQU mapperdata+0
irqen EQU mapperdata+4
suntoggle EQU mapperdata+5
;----------------------------------------------------------------------------
mapper67init	;Sunsoft, Fantazy Zone 2 (J)
;----------------------------------------------------------------------------
	DCD write0,write1,write2,write3

	ldr r0,=map67_IRQ_Hook
	str r0,scanlinehook

	mov pc,lr
;----------------------------------------------------------------------------
write0		;8800,9800
;----------------------------------------------------------------------------
	tst addy,#0x0800
	moveq pc,lr
	tst addy,#0x1000
	beq_long chr01_
	b_long chr23_
;----------------------------------------------------------------------------
write1		;A800-B800
;----------------------------------------------------------------------------
	tst addy,#0x0800
	moveq pc,lr
	tst addy,#0x1000
	beq_long chr45_
	b_long chr67_
;----------------------------------------------------------------------------
write2		;C000,C800,D800
;----------------------------------------------------------------------------
	tst addy,#0x1000
	movne r1,#0
	strneb r1,suntoggle
	strneb r0,irqen
	movne pc,lr

	ldrb r1,suntoggle
	cmp r1,#0
	streqb r0,countdown+3
	strneb r0,countdown+2
	eor r1,r1,#1
	strb r1,suntoggle
	mov pc,lr
;----------------------------------------------------------------------------
write3		;E800,F800
;----------------------------------------------------------------------------
	tst addy,#0x0800
	moveq pc,lr
	tst addy,#0x1000
	bne_long map89AB_
	b_long mirrorKonami_

	AREA wram_code7, CODE, READWRITE
;----------------------------------------------------------------------------
map67_IRQ_Hook
;----------------------------------------------------------------------------
	ldrb r1,irqen
	cmp r1,#0
	beq default_scanlinehook

	ldr r0,countdown
	ldr r1,=0x71AAAA ;341 * 65536 / 3
	subs r0,r0,r1
	str r0,countdown
	bpl default_scanlinehook

	mov r1,#0
	strb r1,irqen
	mov r0,#-1
	str r0,countdown
;	b irq6502
	b CheckI
;----------------------------------------------------------------------------
	END
