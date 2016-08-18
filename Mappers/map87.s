	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h

	EXPORT mapper87init

;----------------------------------------------------------------------------
mapper87init	;Konami - City Connection, Goonies...
;----------------------------------------------------------------------------
	DCD write87,write87,write87,write87

	adr r1,write87
	str r1,writemem_tbl+12

	mov pc,lr
;-------------------------------------------------------
write87
;-------------------------------------------------------
	mov r0,r0,lsr#1
	b chr01234567_
;-------------------------------------------------------
	END
