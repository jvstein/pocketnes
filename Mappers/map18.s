	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h
	INCLUDE 6502.h
	INCLUDE 6502mac.h

	EXPORT mapper18init

prg_xx EQU mapperdata+0 ;4 bytes
chr_xx EQU mapperdata+4 ;8 bytes
latch EQU mapperdata+12
counter EQU mapperdata+16
irqen EQU mapperdata+20
;----------------------------------------------------------------------------
mapper18init	;Jaleco SS8806..
;----------------------------------------------------------------------------
	DCD write8000,writeA000,writeC000,writeE000

	adr r0,hook
	str r0,scanlinehook

	mov pc,lr
;-------------------------------------------------------
write8000
;-------------------------------------------------------
writeA000
;-------------------------------------------------------
writeC000	;addy=A/B/C/Dxxx
;-------------------------------------------------------
	and r1,addy,#3
	and addy,addy,#0x7000
	orr r1,r1,addy,lsr#10
	movs r1,r1,lsr#1

	adrl addy,prg_xx
	and r0,r0,#0xF
	ldrb r2,[addy,r1]

	andcc r2,r2,#0xF0
	orrcc r0,r2,r0
	andcs r2,r2,#0xF
	orrcs r0,r2,r0,lsl#4
	strb r0,[addy,r1]

	cmp r1,#4
	ldrge addy,=writeCHRTBL-4*4
	adrlo addy,write8tbl
	ldr pc,[addy,r1,lsl#2]


write8tbl DCD map89_,mapAB_,mapCD_,void
;-------------------------------------------------------
writeE000
;-------------------------------------------------------
	and r1,addy,#3
	tst addy,#0x1000
	orrne r1,r1,#4

	and r0,r0,#0xF
	ldr r2,latch
	adr addy,writeFtbl
	ldr pc,[addy,r1,lsl#2]

wE0 ;- - - - - - - - - - - - - - -
	bic r2,r2,#0xF
	orr r0,r2,r0
	str r0,latch
	mov pc,lr
wE1 ;- - - - - - - - - - - - - - -
	bic r2,r2,#0xF0
	orr r0,r2,r0,lsl#4
	str r0,latch
	mov pc,lr
wE2 ;- - - - - - - - - - - - - - -
	bic r2,r2,#0xF00
	orr r0,r2,r0,lsl#8
	str r0,latch
	mov pc,lr
wE3 ;- - - - - - - - - - - - - - -
	bic r2,r2,#0xF000
	orr r0,r2,r0,lsl#12
	str r0,latch
	mov pc,lr
wF0 ;- - - - - - - - - - - - - - -
	str r2,counter
	mov pc,lr
wF1 ;- - - - - - - - - - - - - - -
	and r0,r0,#1
	strb r0,irqen
	mov pc,lr
wF2 ;- - - - - - - - - - - - - - -
	movs r1,r0,lsr#2
	tst r0,#1
	bcc mirror2H_
	bcs mirror1_

writeFtbl DCD wE0,wE1,wE2,wE3,wF0,wF1,wF2,void
;-------------------------------------------------------
hook
;------------------------------------------------------
	ldrb r0,irqen
	cmp r0,#0	;timer active?
	beq h1

	ldr r0,counter
	cmp r0,#0	;timer active?
	beq h1
	subs r0,r0,#113		;counter-A
	bhi h0

	mov r0,#0
	str r0,counter	;clear counter and IRQenable.
	strb r0,irqen
;	b irq6502
	b CheckI
h0
	str r0,counter
h1
	fetch 0
;-------------------------------------------------------
	END
