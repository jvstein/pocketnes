	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h
	INCLUDE 6502.h
	INCLUDE 6502mac.h
	INCLUDE konami.h

	EXPORT mapper85init

latch EQU mapperdata+0
irqen EQU mapperdata+1
k4irq EQU mapperdata+2
counter EQU mapperdata+3
;----------------------------------------------------------------------------
mapper85init	;Konami - Tiny Toon Adventure 2 (J)...
		; Lagrange Point, requires CHRRAM swappability  =)
;----------------------------------------------------------------------------
	DCD write85,write85,write85,write85
	b Konami_Init
VRC7
	mov pc,lr
;-------------------------------------------------------
write85
;-------------------------------------------------------
	mov r1,addy,lsr#11
	and r1,r1,#0xE
	tst addy,#0x8
	orrne r1,r1,#1
	tst addy,#0x10
	orrne r1,r1,#1

	adr addy,tbl85
	ldr pc,[addy,r1,lsl#2]
	
tbl85	DCD map89_,mapAB_,mapCD_,VRC7,chr0_,chr1_,chr2_,chr3_,chr4_,chr5_,chr6_,chr7_,mirrorKonami_,KoLatch,KoCounter,KoIRQen
;-------------------------------------------------------
	END
