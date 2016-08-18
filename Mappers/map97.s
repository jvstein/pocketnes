	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h

	EXPORT mapper97init

;----------------------------------------------------------------------------
mapper97init	;Irem
;----------------------------------------------------------------------------
	DCD write97,write97,write97,write97

	mov r0,#-1
	b_long map89AB_
;-------------------------------------------------------
write97
;-------------------------------------------------------
	stmfd sp!,{r0,lr}
	bl_long mapCDEF_
	ldmfd sp!,{r0,lr}
	tst r0,#0x40
	b_long mirror2V_

;-------------------------------------------------------
	END
