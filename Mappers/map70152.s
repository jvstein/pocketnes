	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h
	INCLUDE 6502.h
	INCLUDE 6502mac.h

	EXPORT mapper70init
	EXPORT mapper152init

;----------------------------------------------------------------------------
mapper70init	;Saint Seiya ..
mapper152init	;Saint Seiya ..
;----------------------------------------------------------------------------
	DCD write152,write152,write152,write152

	movs r0,#1
	b_long mirror1_

;-------------------------------------------------------
write152
;-------------------------------------------------------
	mov addy,r0,lsr#4
	stmfd sp!,{addy,lr}
	bl_long chr01234567_
	tst addy,#0x8
	bl_long mirror1_
	ldmfd sp!,{r0,lr}
	b_long map89AB_

;-------------------------------------------------------
	END
