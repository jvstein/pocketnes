	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE cart.h
	INCLUDE 6502.h
	INCLUDE 6502mac.h
	INCLUDE io.h

	EXPORT mapper19init
	EXPORT mapper_19_hook

counter EQU mapperdata+0
enable EQU mapperdata+4

;----------------------------------------------------------------------------
mapper19init
;----------------------------------------------------------------------------
	DCD map19_8,map19_A,map19_C,map19_E

	adr r1,write0
	str r1,writemem_tbl+8

	adr r1,map19_r
	str r1,readmem_tbl+8


	adr r0,mapper_19_hook
	str r0,scanlinehook

	mov pc,lr
;-------------------------------------------------------
write0
	cmp addy,#0x5000
	blo_long IO_W
	and r1,addy,#0x7800
	cmp r1,#0x5000
	streqb r0,counter+2
	moveq pc,lr

	cmp r1,#0x5800
	movne pc,lr
	strb r0,counter+3
	and r0,r0,#0x80
	strb r0,enable
	mov pc,lr
;-------------------------------------------------------
map19_r
	cmp addy,#0x5000
	blo_long IO_R
	and r1,addy,#0x7800

	cmp r1,#0x5000
	ldreqb r0,counter+2
	moveq pc,lr

	cmp r1,#0x5800
	ldreqb r0,counter+3
	mov pc,lr

;-------------------------------------------------------
map19_8
map19_A
	and r1,addy,#0x7800
	ldr r2,=writeCHRTBL
	ldr pc,[r2,r1,lsr#9]
map19_C				; Do NameTable RAMROM change, for mirroring.
	mov pc,lr
;-------------------------------------------------------

;-------------------------------------------------------
map19_E
;-------------------------------------------------------
	and r1,addy,#0x7800
	cmp r1,#0x6000
	beq_long map89_
	cmp r1,#0x6800
	beq_long mapAB_
	cmp r1,#0x7000
	beq_long mapCD_
	mov pc,lr

;-------------------------------------------------------
mapper_19_hook
;------------------------------------------------------
	ldrb r0,enable
	cmp r0,#0
	beq h1

	ldr r0,counter
;	adds r0,r0,#0x71aaab		;113.66667
	adds r0,r0,#0x720000
	str r0,counter
	bcc h1
	mov r0,#0
	strb r0,enable
	sub r0,r0,#0x10000
	str r0,counter
;	b irq6502
	b_long CheckI
h1
	fetch 0

;----------------------------------------------------------------------------
	END
