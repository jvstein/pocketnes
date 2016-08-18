	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h
	INCLUDE 6502.h
	INCLUDE 6502mac.h
	INCLUDE konami.h

	EXPORT mapper24init
	EXPORT mapper26init

latch EQU mapperdata+0
irqen EQU mapperdata+1
k4irq EQU mapperdata+2
counter EQU mapperdata+3
m26sel EQU mapperdata+4
;----------------------------------------------------------------------------
mapper24init	;Konami VRC6 - Akumajou Densetsu (J)...
;----------------------------------------------------------------------------
	DCD write8000,writeA000,writeC000,writeE000

	b Konami_Init
;----------------------------------------------------------------------------
mapper26init	;Konami VRC6V - Esper Dream 2, Madara (J)...
;----------------------------------------------------------------------------
	DCD write8000,writeA000,writeC000,writeE000

	mov r0,#0x02
	strb r0,m26sel
	b Konami_Init
;-------------------------------------------------------
write8000
;-------------------------------------------------------
	tst addy,#0x1000
	andeqs addy,addy,#3
	beq_long map89AB_
	movne pc,lr			; 0x900x Should really be emulation of the VRC6 soundchip.

;-------------------------------------------------------
writeA000
;-------------------------------------------------------
	tst addy,#0x1000
	moveq pc,lr			; 0xA00x Should really be emulation of the VRC6 soundchip.
	and addy,addy,#0x3
	cmp addy,#0x3			; 0xB003
	movne pc,lr			; !0xB003 Should really be emulation of the VRC6 soundchip.

	mov r0,r0,lsr#2
	b_long mirrorKonami_

;-------------------------------------------------------
writeC000
;-------------------------------------------------------
	tst addy,#0x1000
	tsteq addy,#0x3
	beq_long mapCD_
writeD000	;addy=D/E/Fxxx
writeE000
	sub r2,addy,#0xD000
	and addy,addy,#3
	ldrb r1,m26sel
	tst r1,#2
	and r1,r1,addy,lsl#1
	orrne addy,r1,addy,lsr#1
	orr r2,addy,r2,lsr#10

	tst r2,#0x08
	ldreq r1,=writeCHRTBL
	adrne r1,writeTable-8*4
	ldr pc,[r1,r2,lsl#2]

writeTable DCD KoLatch,KoCounter,KoIRQen,void
;-------------------------------------------------------
	END
