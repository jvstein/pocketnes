;	AREA wram_code3, CODE, READWRITE
	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h
	INCLUDE 6502.h
	INCLUDE 6502mac.h
	INCLUDE konami.h

	EXPORT mapper21init
	EXPORT mapper25init

latch EQU mapperdata+0
irqen EQU mapperdata+1
k4irq EQU mapperdata+2
counter EQU mapperdata+3
k4sel EQU mapperdata+4
k4map1 EQU mapperdata+5
chr_xx EQU mapperdata+8 ;16 bytes
;----------------------------------------------------------------------------
mapper21init	;gradius 2, wai wai world 2..
mapper25init
;----------------------------------------------------------------------------
	DCD write8000,writeA000,writeC000,writeE000

	b Konami_Init
;-------------------------------------------------------
write8000
;-------------------------------------------------------
	tst addy,#0x1000
	bne write9000
	strb r0,k4map1
	b romswitch

write9000
	orr addy,addy,addy,lsr#2
	ands addy,addy,#3
	beq_long mirrorKonami_
	cmp addy,#1
	movne pc,lr
w91
	strb r0,k4sel
romswitch
	mov addy,lr
	ldrb r0,k4sel
	tst r0,#2
	mov r0,#-2
	bne reverseMap
	bl_long mapCD_
	mov lr,addy
	ldrb r0,k4map1
	b_long map89_
reverseMap
	bl_long map89_
	mov lr,addy
	ldrb r0,k4map1
	b_long mapCD_

;-------------------------------------------------------
writeA000
;-------------------------------------------------------
	tst addy,#0x1000
	beq_long mapAB_
writeC000	;addy=B/C/D/Exxx
;-------------------------------------------------------
	sub r2,addy,#0xB000
	and r2,r2,#0x3000
	tst addy,#0x85			;0x01 + 0x04 + 0x80
	orrne r2,r2,#0x800
	tst addy,#0x4A			;0x02 + 0x08 + 0x40
	orrne r2,r2,#0x4000

	adrl r1,chr_xx
	and r0,r0,#0x0f

	strb r0,[r1,r2,lsr#11]
	bic r2,r2,#0x4000
	ldrb r0,[r1,r2,lsr#11]!
	ldrb r1,[r1,#8]
	orr r0,r0,r1,lsl#4

	ldr r1,=writeCHRTBL
	ldr pc,[r1,r2,lsr#9]

;-------------------------------------------------------
writeE000
;-------------------------------------------------------
	cmp addy,#0xf000
	bmi writeC000

	tst addy,#0x85			;0x04 + 0x01 + 0x80
	orrne addy,addy,#0x1
	tst addy,#0x4A			;0x02 + 0x08 + 0x40
	orrne addy,addy,#0x2
	and addy,addy,#3
	adr r1,writeFtbl
	ldrb r2,latch
	ldr pc,[r1,addy,lsl#2]

writeFtbl DCD KoLatchLo,KoCounter,KoLatchHi,KoIRQen
;-------------------------------------------------------
	END
