	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h

	EXPORT mapper78init

;----------------------------------------------------------------------------
mapper78init	;Holy Diver & Uchuusen - Cosmo Carrier (J)...
;----------------------------------------------------------------------------
	DCD write78,write78,write78,write78

	mov pc,lr
;-------------------------------------------------------
write78
;-------------------------------------------------------
	stmfd sp!,{r0,lr}
	bl map89AB_
	ldmfd sp,{r0}
	mov r0,r0,lsr#4
	bl chr01234567_
	ldmfd sp!,{r0,lr}
	and addy,addy,#0xFE00
	cmp addy,#0xFE00
	moveq pc,lr
	tst r0,#0x8
	b mirror1_


;-------------------------------------------------------
	END
