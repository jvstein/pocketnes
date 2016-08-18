	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h
	INCLUDE io.h

	EXPORT mapper99init
;----------------------------------------------------------------------------
mapper99init
;----------------------------------------------------------------------------
	DCD empty_W,empty_W,empty_W,empty_W

	ldrb r0,cartflags
	orr r0,r0,#VS
	strb r0,cartflags

	ldr r0,=write4016
	ldr r1,=joypad_write_ptr
	str r0,[r1]

	mov pc,lr
;----------------------------------------------------------------------------
	AREA wram_code3, CODE, READWRITE
;----------------------------------------------------------------------------
write4016
;----------------------------------------------------------------------------
	stmfd sp!,{r0,lr}

	mov r0,r0,lsr#2
	bl chr01234567_

	ldmfd sp!,{r0,lr}
	b joy0_W
;----------------------------------
	END
