	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h

	EXPORT mapper32init

pswitch EQU mapperdata+0
;----------------------------------------------------------------------------
mapper32init	;Irem... Image Fight (J)
;----------------------------------------------------------------------------
	DCD write8000,writeA000,void,void

	mov pc,lr
;-------------------------------------------------------
write8000
;-------------------------------------------------------
	tst addy,#0x1000
	bne write9000
	ldr r1,pswitch
	tst r1,#0x02
	beq_long map89_
	bne_long mapCD_
write9000
	str r0,pswitch
	tst r0,#0x1
	b_long mirror2V_

;-------------------------------------------------------
writeA000
;-------------------------------------------------------
	tst addy,#0x1000
	beq_long mapAB_
	and addy,addy,#7
	ldr r1,=writeCHRTBL
	ldr pc,[r1,addy,lsl#2]

;-------------------------------------------------------
	END
