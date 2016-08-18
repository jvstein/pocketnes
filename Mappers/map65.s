	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h
	INCLUDE 6502.h
	INCLUDE 6502mac.h

	EXPORT mapper65init

latch EQU mapperdata+0
counter EQU mapperdata+4
irqen EQU mapperdata+8
mswitch EQU mapperdata+9
;----------------------------------------------------------------------------
mapper65init	;Irem, Spartan X 2...
;----------------------------------------------------------------------------
	DCD write8000,writeA000,writeC000,void

	adr r0,hook
	str r0,scanlinehook

	mov pc,lr
;-------------------------------------------------------
write8000
;-------------------------------------------------------
	tst addy,#0x1000
	beq map89_

write9000
	and addy,addy,#7
	adr r1,write9tbl
	ldr pc,[r1,addy,lsl#2]

w90
	ldrb r1,mswitch
	cmp r1,#0
	movne pc,lr
	tst r0,#0x40
	b mirror2H_
w91
	mov r1,#1
	strb r1,mswitch
	tst r0,#0x80
	b mirror2V_
w93
	and r0,r0,#0x80
	strb r0,irqen
	mov pc,lr
w94
	ldr r2,latch
	str r2,counter
	mov pc,lr
w95
	strb r0,latch+1
	mov pc,lr
w96
	strb r0,latch
	mov pc,lr

write9tbl DCD w90,w91,void,w93,w94,w95,w96,void
;-------------------------------------------------------
writeA000
;-------------------------------------------------------
	tst addy,#0x1000
	beq mapAB_
writeB000
	and addy,addy,#7
	ldr r1,=writeCHRTBL
	ldr pc,[r1,addy,lsl#2]

;-------------------------------------------------------
writeC000
;-------------------------------------------------------
	cmp addy,#0xC000
	beq mapCD_
	mov pc,lr
;-------------------------------------------------------
hook
;------------------------------------------------------
	ldrb r0,irqen
	cmp r0,#0	;timer active?
	beq h1

	ldr r0,counter
	subs r0,r0,#113		;counter-A
	bhi h0

	mov r0,#0
	strb r0,irqen
	str r0,counter	;clear counter and IRQenable.
	b irq6502
h0
	str r0,counter
h1
	fetch 0
;-------------------------------------------------------
	END
