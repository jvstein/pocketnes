	AREA wram_code3, CODE, READWRITE

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h

	EXPORT mapper151init
;----------------------------------------------
mapper151init
;----------------------------------------------
	DCD write0,write1,write2,write3

	ldrb r0,cartflags
	orr r0,r0,#VS
	strb r0,cartflags

	mov pc,lr
;----------------------------------------------
write0
;----------------------------------------------
	cmp addy,#0x8000
	bne empty_W
	b map89_
;----------------------------------------------
write1
;----------------------------------------------
	cmp addy,#0xa000
	bne empty_W
	b mapAB_
;----------------------------------------------
write2
;----------------------------------------------
	cmp addy,#0xc000
	bne empty_W
	b mapCD_
;----------------------------------------------
write3
;----------------------------------------------
	cmp addy,#0xe000
	beq chr0123_
	cmp addy,#0xf000
	beq chr4567_
	b empty_W
;----------------------------------------------
	END
