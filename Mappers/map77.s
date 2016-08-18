	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h

	EXPORT mapper77init

;----------------------------------------------------------------------------
mapper77init;	Irem mapper something...
;----------------------------------------------------------------------------
	DCD write0,write0,write0,write0

	mov r0,#0
	mov addy,lr
	bl chr01234567_
	mov lr,addy
	mov r0,#0
	b map89ABCDEF_
;----------------------------------------------------------------------------
write0
;----------------------------------------------------------------------------

	stmfd sp!,{r0,lr}
	mov r0,r0,lsr#4
	bl chr01_
	ldmfd sp!,{r0,lr}
	b map89ABCDEF_

;----------------------------------------------------------------------------
	END
