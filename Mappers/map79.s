	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h
	INCLUDE 6502.h
	INCLUDE 6502mac.h
	INCLUDE io.h

	EXPORT mapper79init

;----------------------------------------------------------------------------
mapper79init
;----------------------------------------------------------------------------
	DCD chr01234567_,chr01234567_,chr01234567_,chr01234567_

	adr r1,write0
	str r1,writemem_tbl+8

	mov r0,#0xff
	b map89ABCDEF_
;-------------------------------------------------------
write0
;-------------------------------------------------------
	cmp addy,#0x4100
	blo IO_W

	and r1,addy,#0xE100
	cmp r1,#0x4100
	movne pc,lr

	stmfd sp!,{r0,lr}
	mov r0,r0,lsr#3
	bl map89ABCDEF_
	ldmfd sp!,{r0,lr}
	b chr01234567_

;-------------------------------------------------------
	END
