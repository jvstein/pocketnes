	AREA wram_code3, CODE, READWRITE

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
;------------------------------
write11
;------------------------------
	stmfd sp!,{r0,lr}
	bl map89ABCDEF_
	ldmfd sp!,{r0,lr}
	mov r0,r0,lsr#4
	b chr01234567_
;----------------------------------------------------------------------------
mapper66init
;----------------------------------------------------------------------------
	DCD write66,write66,write66,write66

	ldrb r0,cartflags
	orr r0,r0,#MIRROR	;???
	strb r0,cartflags

	mov pc,lr
;------------------------------
write66
;------------------------------
	stmfd sp!,{r0,lr}
	bl chr01234567_
	ldmfd sp!,{r0,lr}
	mov r0,r0,lsr#4
	b map89ABCDEF_
;----------------------------------------------------------------------------
	END
