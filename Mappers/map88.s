	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h

	EXPORT mapper88init

cmd EQU mapperdata
;----------------------------------------------------------------------------
mapper88init
;----------------------------------------------------------------------------
	DCD write0,void,write1,void

	mov pc,lr
;----------------------------------------------------------------------------
write0		;$8000-8001
;----------------------------------------------------------------------------
	tst addy,#1

	streqb r0,cmd
	moveq pc,lr
w8001
	ldrb r1,cmd
	and r1,r1,#7
	adr r2,commandlist
	ldr pc,[r2,r1,lsl#2]
;----------------------------------------------------------------------------
write1		;$C000
;----------------------------------------------------------------------------
	tst r0,#0
	b mirror1_

commandlist	DCD chr01_,chr23_,chr4_,chr5_,chr6_,chr7_,map89_,mapAB_
;----------------------------------------------------------------------------
	END
