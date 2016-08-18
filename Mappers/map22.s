	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h

	EXPORT mapper22init

chr_xx EQU mapperdata+4 ;8 bytes
;----------------------------------------------------------------------------
mapper22init	;Konami, Twin Bee 3...
;----------------------------------------------------------------------------
	DCD write8000,writeA000,writeC000,writeE000

	mov pc,lr
;-------------------------------------------------------
write8000
;-------------------------------------------------------
	tst addy,#0x1000
	beq map89_
write9000
	bne mirrorKonami_

;-------------------------------------------------------
writeA000
;-------------------------------------------------------
	tst addy,#0x1000
	beq mapAB_

writeC000	;addy=B/C/D/Exxx
;-------------------------------------------------------
	sub addy,addy,#0xB000
	mov r1,addy,lsr#11
	tst addy,#1
	orrne r1,r1,#1
	tst addy,#2

	adr addy,chr_xx
	and r0,r0,#0xF
	ldrb r2,[addy,r1]

	andeq r2,r2,#0x78
	orreq r0,r2,r0,lsr#1
	andne r2,r2,#0x7
	orrne r0,r2,r0,lsl#3
	strb r0,[addy,r1]

	ldr addy,=writeCHRTBL
	ldr pc,[addy,r1,lsl#2]

;-------------------------------------------------------
writeE000
;-------------------------------------------------------
	cmp addy,#0xf000
	bmi writeC000
	mov pc,lr

;-------------------------------------------------------
	END
