	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h
	INCLUDE 6502.h
	INCLUDE 6502mac.h

	EXPORT mapper232init

mapbyte1 EQU mapperdata+0
mapbyte2 EQU mapperdata+1
;----------------------------------------------------------------------------
mapper232init
;----------------------------------------------------------------------------
	DCD w9000,write0,write0,write0

	mov r0,#0x18
	strb r0,mapbyte1

;	b_long mirror1_
	mov pc,lr
;-------------------------------------------------------
w9000
;-------------------------------------------------------
	and r0,r0,#0x18
	strb r0,mapbyte1
	b prgmap
;-------------------------------------------------------
write0
;-------------------------------------------------------
	and r0,r0,#0x03
	strb r0,mapbyte2
	ldrb r0,mapbyte1
prgmap
	mov addy,lr
	mov r1,#3
	orr r0,r1,r0,lsr#1
	bl_long mapCDEF_

	ldrb r0,mapbyte1
	ldrb r1,mapbyte2
	orr r0,r1,r0,lsr#1
	mov lr,addy
	b_long map89AB_
;-------------------------------------------------------
	END
