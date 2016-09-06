	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h
	INCLUDE 6502.h
	INCLUDE 6502mac.h

	EXPORT mapper42init

countdown EQU mapperdata+0
rombank EQU mapperdata+1

;----------------------------------------------------------------------------
mapper42init
;----------------------------------------------------------------------------
	DCD chr01234567_,void,void,write3
	mov addy,lr

	ldr r1,=rom_R60			;Swap in ROM at $6000-$7FFF.
	str r1,readmem_tbl-12
	ldr r1,=empty_W		;ROM.
	str r1,writemem_tbl-12
	
	mov r0,#-1
	bl_long map89ABCDEF_
	
;	ldr r0,=MMC3_IRQ_Hook
;	str r0,scanlinehook

	mov r0,#0
	bl_long map67_

	mov pc,addy

;----------------------------------------------------------------------------
write0		;$8000-8001
;----------------------------------------------------------------------------
;	tst addy,#3
;	movne pc,lr
	b_long chr01234567_
;----------------------------------------------------------------------------
write3		;E000-E003
;----------------------------------------------------------------------------
	and r1,addy,#3
	ldr pc,[pc,r1,lsl#2]
nothing
	mov pc,lr
;----------------------------------------------------------------------------
commandlist	DCD map67_,cmd1,nothing,nothing
cmd0
;	strb r1,rombank
;	and r0,r0,#0xF
	b_long map67_
cmd1
	tst r0,#0x08
	beq_long mirror2H_
	b_long mirror2V_
cmd2
cmd3
	END
