	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h
	INCLUDE 6502.h
	INCLUDE 6502mac.h

	EXPORT mapper16init

counter EQU mapperdata+0
latch EQU mapperdata+4
enable EQU mapperdata+8
;----------------------------------------------------------------------------
mapper16init;		Bandai
;----------------------------------------------------------------------------
	DCD write0,write0,write0,write0

	ldrb r1,cartflags		;get cartflags
	bic r1,r1,#SRAM			;don't use SRAM on this mapper
	strb r1,cartflags		;set cartflags
	ldr r1,mapper16init
	str r1,writemem_tbl+12

	ldr r0,=hook
	str r0,scanlinehook

	mov pc,lr
;----------------------------------------------------------------------------
	AREA wram_code3, CODE, READWRITE
;----------------------------------------------------------------------------
;-------------------------------------------------------
write0
;-------------------------------------------------------
	and addy,addy,#0x0f
	tst addy,#0x08
	ldreq r1,=writeCHRTBL
	adrne r1,tbl-8*4
	ldr pc,[r1,addy,lsl#2]
wA ;---------------------------
	and r0,r0,#1
	strb r0,enable
	ldr r0,latch
	str r0,counter
	mov pc,lr
wB ;---------------------------
	strb r0,latch
asdf	mov r1,#0
	strb r1,latch+2
	strb r1,latch+3
	mov pc,lr
wC ;---------------------------
	strb r0,latch+1
	b asdf

tbl DCD map89AB_,mirrorKonami_,wA,wB,wC,void,void,void
;-------------------------------------------------------
hook
;------------------------------------------------------
	ldrb r0,enable
	cmp r0,#0
	beq h1

	ldr r0,counter
	subs r0,r0,#113
	str r0,counter
;	bcc irq6502
	bcc CheckI
h1
	fetch 0
;-------------------------------------------------------
	END
