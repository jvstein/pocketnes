	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h
	INCLUDE 6502.h
	INCLUDE 6502mac.h

	EXPORT mapper69init
	EXPORT mapper_69_hook
	EXPORT mapper69_ntsc_pal_reset

countdown EQU mapperdata+0
irqen EQU mapperdata+4
cmd EQU mapperdata+5
video EQU mapperdata+8		; number of cycles per scanline
;----------------------------------------------------------------------------
mapper69init			; Sunsoft FME-7, Batman ROTJ, Gimmick...
;----------------------------------------------------------------------------
	DCD write0,write1,void,void			;There is a music channel also

	mov r1,#-1
	str r1,countdown

	ldr r0,=mapper_69_hook
	str r0,scanlinehook

mapper69_ntsc_pal_reset
        ldr r1,emuflags
	tst r1,#PALTIMING
	;341/320
	
	
	ldrne r1,=0x6AAAAA	;PAL
	ldreq r1,=0x71AAAA	;NTSC
	str r1,video


	mov pc,lr
;----------------------------------------------------------------------------
write0		;$8000
;----------------------------------------------------------------------------
	strb r0,cmd
	mov pc,lr

;----------------------------------------------------------------------------
write1		;$A000
;----------------------------------------------------------------------------
	ldrb r1,cmd
	tst r1,#0x08
	and r1,r1,#7
	ldreq r2,=writeCHRTBL
	adrne r2,commandlist
	ldr pc,[r2,r1,lsl#2]

irqen69
	strb r0,irqen
	mov pc,lr
irqA69
	strb r0,countdown+2
	mov pc,lr
irqB69
	strb r0,countdown+3
	mov pc,lr

;----------------------------------------------------------------------------
mapJinx
;----------------------------------------------------------------------------
	tst r0,#0x40
	ldreq r1,=rom_R60			;Swap in ROM at $6000-$7FFF.
	ldrne r1,=sram_R		;Swap in sram at $6000-$7FFF.
	str r1,readmem_tbl+12
	ldreq r1,=empty_W		;ROM.
	ldrne r1,=sram_W		;sram.
	str r1,writemem_tbl+12
	beq_long map67_
	ldr r1,=NES_RAM-0x5800		;sram at $6000.
	str r1,memmap_tbl+12
	mov r0,#0xFF
	strb r0,bank6
	mov pc,lr

;----------------------------------------------------------------------------
commandlist	DCD mapJinx,map89_,mapAB_,mapCD_,mirrorKonami_,irqen69,irqA69,irqB69
;----------------------------------------------------------------------------
	AREA wram_code7, CODE, READWRITE
;----------------------------------------------------------------------------
mapper_69_hook
;----------------------------------------------------------------------------
	ldrb r1,irqen
	cmp r1,#0
	beq default_scanlinehook

	ldr r0,countdown
	ldr r1,video			; Number of cycles per scanline.
	subs r0,r0,r1
	str r0,countdown
	bhi default_scanlinehook

	mov r1,#-1
	str r1,countdown

	mov r1,#0
	strb r1,irqen
;	b irq6502
	b CheckI


	END
