	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h

	EXPORT mapper72init

;----------------------------------------------------------------------------
mapper72init	;Jaleco - Pinball Quest, Moero!! Pro Tennis, Moero!! Juudou Warroirs...
;----------------------------------------------------------------------------
	DCD write72,write72,write72,write72

	mov pc,lr
;-------------------------------------------------------
write72
;-------------------------------------------------------
	stmfd sp!,{r0,lr}
	tst r0,#0x80
	blne_long map89AB_
	ldmfd sp!,{r0,lr}
	tst r0,#0x40
	bne_long chr01234567_
	mov pc,lr

;-------------------------------------------------------
	END
