	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h

	EXPORT mapper11init
	EXPORT mapper66init
;----------------------------------------------------------------------------
mapper11init
;----------------------------------------------------------------------------
	DCD write11,write11,write11,write11
	mov pc,lr
;----------------------------------------------------------------------------
mapper66init
;----------------------------------------------------------------------------
	DCD write66,write66,write66,write66

	ldr r1,mapper66init
	str r1,writemem_tbl-12

	ldrb r0,cartflags
	orr r0,r0,#MIRROR	;???
	strb r0,cartflags

	mov pc,lr
;----------------------------------------------------------------------------
	AREA wram_code7, CODE, READWRITE
;----------------------------------------------------------------------------
;------------------------------
write11
;------------------------------
	stmfd sp!,{r0,lr}
	bl_long map89ABCDEF_
	ldmfd sp!,{r0,lr}
	mov r0,r0,lsr#4
	b_long chr01234567_
;------------------------------
write66
;------------------------------
	stmfd sp!,{r0,lr}
	bl_long chr01234567_
	ldmfd sp!,{r0,lr}
	mov r0,r0,lsr#4
	b_long map89ABCDEF_
;----------------------------------------------------------------------------
	END
