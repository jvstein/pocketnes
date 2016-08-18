	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h

	EXPORT mapper34init

;----------------------------------------------------------------------------
mapper34init	;Impossible Mission 2 & Deadly Towers
;----------------------------------------------------------------------------
	DCD map89ABCDEF_,map89ABCDEF_,map89ABCDEF_,map89ABCDEF_		; Deadly Towers

	adr r1,write0
	str r1,writemem_tbl+12

	mov r0,#0
	b_long map89ABCDEF_
;-------------------------------------------------------
write0			;Impossible Mission 2
;-------------------------------------------------------
	ldr r1,=0x7fff
	cmp addy,r1		;7FFF
	beq_long chr4567_
	sub r1,r1,#1
	cmp addy,r1		;7FFE
	beq_long chr0123_
	sub r1,r1,#1
	cmp addy,r1		;7FFD
	beq_long map89ABCDEF_
	b_long sram_W
;-------------------------------------------------------
	END
