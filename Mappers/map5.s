	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE cart.h
	INCLUDE 6502.h
	INCLUDE 6502mac.h
	INCLUDE io.h

	EXPORT mapper5init

counter EQU mapperdata+0
enable EQU mapperdata+1
prgsize EQU mapperdata+2
chrsize EQU mapperdata+3
prgpage0 EQU mapperdata+4
prgpage1 EQU mapperdata+5
prgpage2 EQU mapperdata+6
prgpage3 EQU mapperdata+7

chrpage0 EQU mapperdata+8
chrpage1 EQU mapperdata+9
chrpage2 EQU mapperdata+10
chrpage3 EQU mapperdata+11
chrpage4 EQU mapperdata+12
chrpage5 EQU mapperdata+13
chrpage6 EQU mapperdata+14
chrpage7 EQU mapperdata+15

chrpage8 EQU mapperdata+16
chrpage9 EQU mapperdata+17
chrpage10 EQU mapperdata+18
chrpage11 EQU mapperdata+19

chrbank EQU mapperdata+20
mmc5irqr EQU mapperdata+21
mmc5mul1 EQU mapperdata+22
mmc5mul2 EQU mapperdata+23
m5mirror EQU mapperdata+24
;----------------------------------------------------------------------------
mapper5init
;----------------------------------------------------------------------------
	DCD void,void,void,void

	adr r1,write0
	str r1,writemem_tbl+8

	adr r1,mmc5_r
	str r1,readmem_tbl+8

	mov r0,#3
	strb r0,prgsize
	strb r0,chrsize

	mov r0,#0x7f
	strb r0,prgpage0
	strb r0,prgpage1
	strb r0,prgpage2
	strb r0,prgpage3

	adr r0,hook
	str r0,scanlinehook

	mov pc,lr
;-------------------------------------------------------
write0
;-------------------------------------------------------
	cmp addy,#0x5000
	blo IO_W
	cmp addy,#0x5100
	blo map5Sound
	cmp addy,#0x5200
	bge mmc5_200

	ands r2,addy,#0xff
	beq _00
	cmp r2,#0x01
	beq _01
	cmp r2,#0x05
	beq _05
	cmp r2,#0x14
	movlt pc,lr		; get out.
	cmp r2,#0x17
	ble _17
	cmp r2,#0x20
	movlt pc,lr		; get out.
	cmp r2,#0x27
	ble _20
	cmp r2,#0x2b
	ble _28
	mov pc,lr		; get out.

_00
	and r0,r0,#0x03
	strb r0,prgsize
	b mmc5prg
_01
	and r0,r0,#0x03
	strb r0,chrsize
	b mmc5chrb		; both A and B?
_05
	strb r0,m5mirror
	cmp r0,#0x55
	beq mirror5_1
	cmp r0,#0
	beq mirror5_1
	cmp r0,#0xE4
	beq mirror4_
	eor r1,r0,r0,lsr#4
	ands r1,r1,#0x0C
	b mirror2V_
;	b mirrorKonami_


mirror5_1
	cmp r0,#0
	b mirror1_

_14
_15
_16
_17
	sub r2,r2,#0x14
	adrl r1,prgpage0
	strb r0,[r1,r2]
mmc5prg
	ldrb r1,prgsize
	cmp r1,#0x00
	bne not0
	ldrb r0,prgpage1
	mov r0,r0,lsr#2
	b map89ABCDEF_
not0
	str lr,[sp,#-4]!
	cmp r1,#0x01
	bne not1
	ldrb r0,prgpage1
	mov r0,r0,lsr#1
	bl map89AB_
	ldrb r0,prgpage3
	mov r0,r0,lsr#1
	ldr lr,[sp],#4
	b mapCDEF_
not1
	cmp r1,#0x02
	bne not2
	ldrb r0,prgpage1
	mov r0,r0,lsr#1
	bl map89AB_
	ldrb r0,prgpage2
	bl mapCD_
	ldrb r0,prgpage3
	ldr lr,[sp],#4
	b mapEF_
not2
	ldrb r0,prgpage0
	bl map89_
	ldrb r0,prgpage1
	bl mapAB_
	ldrb r0,prgpage2
	bl mapCD_
	ldrb r0,prgpage3
	ldr lr,[sp],#4
	b mapEF_

_20				; For sprites.
_21
_22
_23
_24
_25
_26
_27
	mov r1,#0
	strb r1,chrbank
	adrl r1,chrpage0
	sub r2,r2,#0x20
	strb r0,[r1,r2]
mmc5chra
;	mov pc,lr		; get out?
	ldrb r1,chrsize
	cmp r1,#0x00
	bne notch0
	ldrb r0,chrpage7
;	mov r0,r0,lsr#3
	b chr01234567_
notch0
	str lr,[sp,#-4]!
	cmp r1,#0x01
	bne notch1
	ldrb r0,chrpage3
;	mov r0,r0,lsr#2
	bl chr0123_
	ldr lr,[sp],#4
	ldrb r0,chrpage7
;	mov r0,r0,lsr#2
;	b chr4567_
	mov pc,lr		; get out?
notch1
	cmp r1,#0x02
	bne notch2
	ldrb r0,chrpage1
;	mov r0,r0,lsr#1
	bl chr01_
	ldrb r0,chrpage3
;	mov r0,r0,lsr#1
	bl chr23_
	ldrb r0,chrpage5
;	mov r0,r0,lsr#1
;	bl chr45_
	ldr lr,[sp],#4
	ldrb r0,chrpage7
;	mov r0,r0,lsr#1
;	b chr67_
	mov pc,lr		; get out?
notch2
	ldrb r0,chrpage0
	bl chr0_
	ldrb r0,chrpage1
	bl chr1_
	ldrb r0,chrpage2
	bl chr2_
	ldrb r0,chrpage3
	bl chr3_
	ldrb r0,chrpage4
;	bl chr4_
	ldrb r0,chrpage5
;	bl chr5_
	ldrb r0,chrpage6
;	bl chr6_
	ldr lr,[sp],#4
	ldrb r0,chrpage7
;	b chr7_
	mov pc,lr		; get out?

_28				; For background.
_29
_2a
_2b
	mov r1,#1
	strb r1,chrbank
	adrl r1,chrpage0
	sub r2,r2,#0x20
	strb r0,[r1,r2]
mmc5chrb
;	mov pc,lr		; get out?
	ldrb r1,chrsize
	cmp r1,#0x00
	bne notchb0
	ldrb r0,chrpage11
	mov r0,r0,lsr#3
	b chr01234567_
notchb0
	str lr,[sp,#-4]!
	cmp r1,#0x01
	bne notchb1
	ldrb r0,chrpage11
;	mov r0,r0,lsr#2
;	bl chr0123_
	ldr lr,[sp],#4
	ldrb r0,chrpage11
	mov r0,r0,lsr#2
	b chr4567_
	mov pc,lr
notchb1
	cmp r1,#0x02
	bne notchb2
	ldrb r0,chrpage9
;	mov r0,r0,lsr#1
;	bl chr01_
	ldrb r0,chrpage11
;	mov r0,r0,lsr#1
;	bl chr23_
	ldrb r0,chrpage9
	mov r0,r0,lsr#1
	bl chr45_
	ldr lr,[sp],#4
	ldrb r0,chrpage11
	mov r0,r0,lsr#1
	b chr67_
	mov pc,lr
notchb2
	ldrb r0,chrpage8
;	bl chr0_
	ldrb r0,chrpage9
;	bl chr1_
	ldrb r0,chrpage10
;	bl chr2_
	ldrb r0,chrpage11
;	bl chr3_
	ldrb r0,chrpage8
	bl chr4_
	ldrb r0,chrpage9
	bl chr5_
	ldrb r0,chrpage10
	bl chr6_
	ldr lr,[sp],#4
	ldrb r0,chrpage11
	b chr7_

map5Sound
	mov pc,lr
;-------------------------------------------------------
mmc5_200
	and r2,addy,#0xff
	cmp r2,#0x03
	streqb r0,counter
	moveq pc,lr

	cmp r2,#0x04
	beq setEnIrq

	cmp r2,#0x05
	streqb r0,mmc5mul1
	moveq pc,lr

	cmp r2,#0x06
	streqb r0,mmc5mul2
	mov pc,lr

setEnIrq
	and r0,r0,#0x80
	strb r0,enable
	mov pc,lr

;-------------------------------------------------------
mmc5_r		;5204,5205,5206
	cmp addy,#0x5200
	blo IO_R
	and r2,addy,#0xff
	cmp r2,#0x04
	beq MMC5IRQR
	cmp r2,#0x05
	beq MMC5MulA
	cmp r2,#0x06
	beq MMC5MulB

	mov r0,#0xff
	mov pc,lr

MMC5IRQR
	ldrb r0,mmc5irqr
	ldrb r1,enable
	cmp r1,#0
	andne r1,r0,#0x40
	strb r1,mmc5irqr
	orr nes_nz,r0,r0,lsl#24
	mov pc,lr

MMC5MulA
	ldrb r1,mmc5mul1
	ldrb r2,mmc5mul1
	mul r0,r1,r2
	and r0,r0,#0xff
	orr nes_nz,r0,r0,lsl#24
	mov pc,lr
MMC5MulB
	ldrb r1,mmc5mul1
	ldrb r2,mmc5mul1
	mul r0,r1,r2
	mov r0,r0,lsr#8
	orr nes_nz,r0,r0,lsl#24
	mov pc,lr

;-------------------------------------------------------
hook
;------------------------------------------------------
	ldrb r0,counter
	ldrb r1,scanline
	ldrb r2,mmc5irqr
	cmp r1,#239
	blt h2
	orr r2,r2,#0x40
h2
	cmp r1,#245
	bge h1

	cmp r1,r0
	ble h1

	orr r2,r2,#0x80
	strb r2,mmc5irqr

	ldrb r0,enable
	cmp r0,#0
	bne irq6502
h1
	strb r2,mmc5irqr
	fetch 0
;-------------------------------------------------------
	END
