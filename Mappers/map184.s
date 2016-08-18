	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h

	EXPORT mapper184init

;----------------------------------------------------------------------------
mapper184init
;----------------------------------------------------------------------------
	DCD write184,write184,write184,write184

	adr r0,write184
	str r0,writemem_tbl+12
	mov pc,lr
;-------------------------------------------------------
write184
;-------------------------------------------------------
	mov addy,r0,lsr#4
	stmfd sp!,{addy,lr}
	bl_long chr0123_
	ldmfd sp!,{r0,lr}
	b_long chr4567_
;----------------------------------------------------------------------------
	END
