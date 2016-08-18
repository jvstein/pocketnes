	AREA wram_code3, CODE, READWRITE

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h

	EXPORT mapper0init
	EXPORT mapper2init
	EXPORT mapper3init
	EXPORT mapper7init
;----------------------------------------------------------------------------
mapper0init
;----------------------------------------------------------------------------
	DCD void,void,void,void
	mov pc,lr
;----------------------------------------------------------------------------
mapper2init
;----------------------------------------------------------------------------
	DCD map89AB_,map89AB_,map89AB_,map89AB_
	mov pc,lr
;----------------------------------------------------------------------------
mapper3init
;----------------------------------------------------------------------------
	DCD chr01234567_,chr01234567_,chr01234567_,chr01234567_
	mov pc,lr
;----------------------------------------------------------------------------
mapper7init
;----------------------------------------------------------------------------
	DCD write0,write0,write0,write0
	mov pc,lr
;------------------------------
write0
;------------------------------
	stmfd sp!,{r0,lr}
	tst r0,#0x10
	bl mirror1_
	ldmfd sp!,{r0,lr}
	b map89ABCDEF_
;----------------------------------------------------------------------------
	END
