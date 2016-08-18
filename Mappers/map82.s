	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h

	EXPORT mapper82init

cmd EQU mapperdata
;----------------------------------------------------------------------------
mapper82init;		Taito something...
;----------------------------------------------------------------------------
	DCD void,void,void,void

	adr r1,write0
	str r1,writemem_tbl+12
	mov pc,lr
;----------------------------------------------------------------------------
write0		;$8000-8001
;----------------------------------------------------------------------------
	tst addy,#1
	bne w8001

	strb r0,cmd
	mov pc,lr
w8001
	ldrb r1,cmd
	and r1,r1,#7
	adr r2,commandlist
	ldr pc,[r2,r1,lsl#2]

commandlist	DCD void,void,chr01_,chr23_,chr45_,chr67_,map89_,mapAB_
;----------------------------------------------------------------------------
write1		;$A000
;----------------------------------------------------------------------------
	tst addy,#1
	movne pc,lr
	tst r0,#1
	b mirror2V_
;----------------------------------------------------------------------------
	END
