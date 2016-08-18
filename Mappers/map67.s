	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h
	INCLUDE 6502.h
	INCLUDE 6502mac.h

	EXPORT mapper67init

countdown EQU mapperdata+0
irqen EQU mapperdata+4
suntoggle EQU mapperdata+5
;----------------------------------------------------------------------------
mapper67init	;Sunsoft, Fantazy Zone 2 (J)
;----------------------------------------------------------------------------
	DCD write0,write1,write2,write3

	adr r0,map67_IRQ_Hook
	str r0,scanlinehook

	mov pc,lr
;----------------------------------------------------------------------------
write0		;8800,9800
;----------------------------------------------------------------------------
	tst addy,#0x0800
	moveq pc,lr
	tst addy,#0x1000
	beq chr01_
	b   chr23_
;----------------------------------------------------------------------------
write1		;A800-B800
;----------------------------------------------------------------------------
	tst addy,#0x0800
	moveq pc,lr
	tst addy,#0x1000
	beq chr45_
	b   chr67_
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
	streqb r0,countdown+1
	strneb r0,countdown
	eor r1,r1,#1
	strb r1,suntoggle
	mov pc,lr
;----------------------------------------------------------------------------
write3		;E800,F800
;----------------------------------------------------------------------------
	tst addy,#0x0800
	moveq pc,lr
	tst addy,#0x1000
	bne map89AB_
	b mirrorKonami_
;----------------------------------------------------------------------------
map67_IRQ_Hook
;----------------------------------------------------------------------------
	ldrb r1,irqen
	cmp r1,#0
	beq hk0

	ldr r0,countdown
	subs r0,r0,#113
	str r0,countdown
	bpl hk0

	mov r1,#0
	strb r1,irqen
	mov r0,r0,lsr#16
	str r0,countdown
;	b irq6502
	b CheckI
hk0
	fetch 0
;----------------------------------------------------------------------------
	END
