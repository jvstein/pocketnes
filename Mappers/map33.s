	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h
	INCLUDE 6502.h
	INCLUDE 6502mac.h

	EXPORT mapper33init

irqen EQU mapperdata+0
counter EQU mapperdata+3
mswitch EQU mapperdata+4
pswitch EQU mapperdata+5
;----------------------------------------------------------------------------
mapper33init	;Taito... Insector X
;----------------------------------------------------------------------------
	DCD write8000,writeA000,writeC000,writeE000

	adr r0,hook
	str r0,scanlinehook

	mov pc,lr
;-------------------------------------------------------
write8000
;-------------------------------------------------------
	and addy,addy,#3
	adr r1,write8tbl
	ldr pc,[r1,addy,lsl#2]
w80
	ldr r1,mswitch
	tst r1,#0xFF
	bne map89_
	stmfd sp!,{r0,lr}
	tst r0,#0x40
	bl mirror2V_
	ldmfd sp!,{r0,lr}
	b map89_

write8tbl DCD w80,mapAB_,chr01_,chr23_
;-------------------------------------------------------
writeA000
;-------------------------------------------------------
	and addy,addy,#3
	ldr r1,=writeCHRTBL+4*4		;chr4_,chr5_,chr6_,chr7_
	ldr pc,[r1,addy,lsl#2]

;-------------------------------------------------------
writeC000
;-------------------------------------------------------
	ands addy,addy,#3
	bne wC1
	strb r0,counter
	mov pc,lr
wC1
	cmp addy,#1
	streqb r0,irqen
	mov pc,lr

;-------------------------------------------------------
writeE000
;-------------------------------------------------------
	ands addy,addy,#3
	bne wC1
	mov r1,#1
	strb r1,mswitch
	tst r0,#0x40
	b mirror2V_

;-------------------------------------------------------
hook
;------------------------------------------------------
	ldrb r0,ppuctrl1
	tst r0,#0x18		;no sprite/BG enable?
	beq h1			;bye..

	ldr r0,scanline
	cmp r0,#1		;not rendering?
	blt h1			;bye..

	ldr r0,scanline
	cmp r0,#240		;not rendering?
	bhi h1			;bye..

	ldr r0,irqen
	tst r0,#0xFF		;irq timer active?
	beq h1

	adds r0,r0,#0x01000000	;counter++
	bcc h0

	mov r0,#0
	str r0,irqen	;copy latch to counter
;	b irq6502
	b CheckI
h0
	str r0,irqen
h1
	fetch 0
;-------------------------------------------------------
	END
