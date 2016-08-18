	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h

	EXPORT mapper228init

mapbyte1 EQU mapperdata
;----------------------------------------------------------------------------
mapper228init;		Action 52 & Cheetahmen 2. PocketNES only support 256k of CHR, Action52 got 512k.
;----------------------------------------------------------------------------
	DCD write0,write0,write0,write0

	ldr r0,rommask
	cmp r0,#0x40000
	addhi r0,r0,#0x80000
	str r0,rommask		;rommask=romsize-1

	mov r0,#0
	b map89ABCDEF_
;-------------------------------------------------------
write0
;-------------------------------------------------------
	str addy,mapbyte1
	and r0,r0,#0x03
	orr r0,r0,addy,lsl#2
	mov addy,lr

	bl chr01234567_

	ldr r0,mapbyte1
	tst r0,#0x2000
	bl mirror2V_

	ldr r0,mapbyte1
	tst r0,#0x1000
	bicne r0,r0,#0x800
	
	tst r0,#0x40
	bne swap16k
	mov r0,r0,lsr#7
	mov lr,addy
	b map89ABCDEF_

swap16k
	and r1,r0,r0,lsl#1
	mov r1,r1,lsr#6
	orr r1,r1,#0xFE
	and r0,r1,r0,lsr#6
	str r0,mapbyte1
	bl mapCDEF_
	ldr r0,mapbyte1
	mov lr,addy
	b map89AB_
;-------------------------------------------------------
	END
