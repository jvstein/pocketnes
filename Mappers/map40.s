	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h
	INCLUDE 6502.h
	INCLUDE 6502mac.h

	EXPORT mapper40init
	EXPORT mapper_40_hook

countdown EQU mapperdata+0
irqen EQU mapperdata+4
;----------------------------------------------------------------------------
mapper40init		;SMB2j
;----------------------------------------------------------------------------
	DCD write0,write1,void,mapCD_

	mov addy,lr
	adr r0,mapper_40_hook
	str r0,scanlinehook

	ldr r0,=rom_R60			;Set ROM at $6000-$7FFF.
	str r0,readmem_tbl+12
	ldr r0,=empty_W			;ROM.
	str r0,writemem_tbl+12

	bl write0

	mov r0,#-1
	bl_long map89ABCDEF_

	mov r0,#6
	mov lr,addy
	b_long map67_
;----------------------------------------------------------------------------
write0		;$8000-$9FFF
;----------------------------------------------------------------------------
	mov r0,#36
	str r0,countdown
	mov r0,#0
	strb r0,irqen
	mov pc,lr
;----------------------------------------------------------------------------
write1		;$A000-$BFFF
;----------------------------------------------------------------------------
	mov r0,#1
	strb r0,irqen
	mov pc,lr
;----------------------------------------------------------------------------
mapper_40_hook
;----------------------------------------------------------------------------
	ldrb r0,irqen
	cmp r0,#0
	beq_long default_scanlinehook

	ldr r0,countdown
;	bmi default_scanlinehook
	subs r0,r0,#1
	str r0,countdown
	bcs_long default_scanlinehook

	mov r0,#0
	strb r0,irqen
;	b irq6502
	b_long CheckI
;----------------------------------------------------------------------------
	END
