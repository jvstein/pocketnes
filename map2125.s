	AREA wram_code3, CODE, READWRITE

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h
	INCLUDE 6502.h
	INCLUDE 6502mac.h

	EXPORT mapper21init
	EXPORT mapper25init

latch EQU mapperdata+0
irqen EQU mapperdata+1
counter EQU mapperdata+3
chr_xx EQU mapperdata+4 ;16 bytes
;----------------------------------------------------------------------------
mapper21init	;gradius 2, waiwai world 2..
mapper25init
;----------------------------------------------------------------------------
	DCD write8000,writeA000,writeC000,writeE000

	mov r0,#0
	str r0,latch

	adr r0,hook
	str r0,scanlinehook

	mov pc,lr
;-------------------------------------------------------
write8000
;-------------------------------------------------------
	cmp addy,#0x9000
	bmi map89_

	adr r1,write9tbl
	and addy,addy,#7
	ldr pc,[r1,addy,lsl#2]
w90
	movs r1,r0,lsr#2
	tst r0,#1
	bcc mirror2V_
	bcs mirror1_

write9tbl DCD w90,void,void,void,void,void,void,void
;-------------------------------------------------------
writeA000
;-------------------------------------------------------
	cmp addy,#0xa000
	beq mapAB_
writeC000	;addy=B/C/D/Exxx
;-------------------------------------------------------
	and r0,r0,#0x0f

	add r2,addy,#0x1000
	and r2,r2,#0x3000
	tst addy,#5
	orrne r2,r2,#0x800
	tst addy,#2
	orrne r2,r2,#0x4000

	adrl r1,chr_xx

	strb r0,[r1,r2,lsr#11]
	bic r2,r2,#0x4000
	ldrb r0,[r1,r2,lsr#11]!
	ldrb r1,[r1,#8]
	orr r0,r0,r1,lsl#4

	adr r1,chrstuff
	ldr pc,[r1,r2,lsr#9]

chrstuff DCD chr0_,chr1_,chr2_,chr3_,chr4_,chr5_,chr6_,chr7_
;-------------------------------------------------------
writeE000
;-------------------------------------------------------
	cmp addy,#0xf000
	bmi writeC000

	and addy,addy,#7
	adr r1,writeFtbl
	ldrb r2,latch
	ldr pc,[r1,addy,lsl#2]
wF0 ;- - - - - - - - - - - - - - -
	and r2,r2,#0xf0
	and r0,r0,#0x0f
	orr r0,r0,r2
	strb r0,latch
	mov pc,lr
wF1 ;- - - - - - - - - - - - - - -
	strb r0,irqen
	strb r2,counter
	mov pc,lr
wF2 ;- - - - - - - - - - - - - - -
	and r2,r2,#0x0f
	orr r0,r2,r0,lsl#4
	strb r0,latch
	mov pc,lr

writeFtbl DCD wF0,wF1,wF2,void,wF1,wF1,void,void
;-------------------------------------------------------
hook
;------------------------------------------------------
	ldr r0,latch
	tst r0,#0x200	;timer active?
	beq h1

	adds r0,r0,#0x01000000	;counter++
	bcc h0

	strb r0,counter	;copy latch to counter
	b irq6502
h0
	str r0,irqen
h1
	fetch 0
;-------------------------------------------------------
	END
