	AREA wram_code3, CODE, READWRITE

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h
	INCLUDE 6502mac.h

	EXPORT mapper9init
	EXPORT mapper9BGcheck

reg0 EQU mapperdata+0
reg1 EQU mapperdata+1
reg2 EQU mapperdata+2
reg3 EQU mapperdata+3
;----------------------------------------------------------------------------
mapper9init	;really bad Punchout hack
;----------------------------------------------------------------------------
	DCD empty_W,a000,c000,e000

	ldrb r0,cartflags
	bic r0,r0,#SCREEN4	;(many punchout roms have bad headers)
	strb r0,cartflags

	adr r0,hook
	str r0,scanlinehook

	mov r0,#-1
	b map89ABCDEF_		;everything to last bank
;------------------------------
a000
	tst addy,#0x1000
	beq map89_
b000 ;-------------------------
	strb r0,reg0
	mov pc,lr
c000 ;-------------------------
	tst addy,#0x1000
	bne d000

	strb r0,reg1
	b chr0123_
	;mov pc,lr
d000 ;-------------------------
	strb r0,reg2
	mov pc,lr
e000 ;-------------------------
	tst addy,#0x1000
	bne f000

	strb r0,reg3
	mov pc,lr
f000 ;-------------------------
	tst r0,#1
	b mirror2V_
;------------------------------
hook
;------------------------------
	ldr r0,scanline
	tst r0,#7
	bne h9
	cmp r0,#239
	bhi h9

	adr r2,latchtbl
	ldrb r0,[r2,r0,lsr#3]

	cmp r0,#0xfd
	ldreq r0,reg2
	ldrne r0,reg3
	bl chr4567_
h9
	fetch 0
;------------------------------
mapper9BGcheck ;called from PPU.s, r0=FD-FF
;------------------------------
	cmp r0,#0xff
	moveq pc,lr

	adr r1,latchtbl
	and r2,addy,#0x3f
	cmp r2,#0x10
	strlob r0,[r1,addy,lsr#6]

	mov pc,lr

latchtbl % 32
;----------------------------------------------------------------------------
	END
