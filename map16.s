	AREA wram_code3, CODE, READWRITE

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h
	INCLUDE 6502.h
	INCLUDE 6502mac.h

	EXPORT mapper16init

counter EQU mapperdata+0
enable EQU mapperdata+4
;----------------------------------------------------------------------------
mapper16init
;----------------------------------------------------------------------------
	DCD write0,write0,write0,write0

	adr r1,write0
	str r1,writemem_tbl+12

	mov r0,#0
	strb r0,enable

	adr r0,hook
	str r0,scanlinehook

	mov pc,lr
;-------------------------------------------------------
write0
;-------------------------------------------------------
	adr r1,tbl
	and addy,addy,#15
	ldr pc,[r1,addy,lsl#2]
w9 ;---------------------------
	ands r0,r0,#3
	beq mirror2V_	;0=vertical mirror
	cmp r0,#1
	beq mirror2H_	;1=horz mirror
	cmp r0,#2	;2=2000 mirror (1-screen)
	b mirror1_	;3=2400 mirror (1-screen)
wA ;---------------------------
	and r0,r0,#1
	strb r0,enable
	mov pc,lr
wB ;---------------------------
	strb r0,counter
asdf	mov r1,#0
	strb r1,counter+2
	strb r1,counter+3
	mov pc,lr
wC ;---------------------------
	strb r0,counter+1
	b asdf

tbl DCD chr0_,chr1_,chr2_,chr3_,chr4_,chr5_,chr7_,chr7_,map89AB_,w9,wA,wB,wC,void,void,void
;-------------------------------------------------------
hook
;------------------------------------------------------
	ldrb r0,enable
	cmp r0,#0
	beq h1

	ldr r0,counter
	subs r0,r0,#114
	str r0,counter
	bcc irq6502
h1
	fetch 0
;-------------------------------------------------------
	END
