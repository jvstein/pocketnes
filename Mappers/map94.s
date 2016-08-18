	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h

	EXPORT mapper94init

;----------------------------------------------------------------------------
mapper94init	;Capcom - Senjou no Ookami
;----------------------------------------------------------------------------
	DCD void,void,void,write94
	mov pc,lr
;-------------------------------------------------------
write94
;-------------------------------------------------------
	mov r0,r0,lsr#2
	b map89AB_
;-------------------------------------------------------
	END
