	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h
	INCLUDE 6502.h
	INCLUDE 6502mac.h

	EXPORT mapper4init
	EXPORT mapper74init
	EXPORT mapper118init
	EXPORT mapper119init
	EXPORT mapper245init
	EXPORT mapper249init
	EXPORT MMC3_IRQ_Hook
	IMPORT empty_io_w_hook
	IMPORT g_vrommask

countdown EQU mapperdata+0
latch EQU mapperdata+1
irqen EQU mapperdata+2
rmode EQU mapperdata+3
cmd EQU mapperdata+4
bank0 EQU mapperdata+5
bank1 EQU mapperdata+6
bankadd EQU mapperdata+7
usescramble EQU mapperdata+8
lastchr EQU mapperdata+9


;----------------------------------------------------------------------------
mapper4init
mapper74init
mapper118init
mapper119init
mapper245init
mapper249init
	DCD write0,write1,write2,write3
	;note: this code modifies jump tables

	ldr r0,=MMC3_IRQ_Hook
	str r0,scanlinehook
	ldr r0,=MMC3_IRQ_midline
	str r0,midlinehook

	ldrb r0,mapper_number
	ldr r1,=commandlist
	ldr r2,writemem_tbl+16

	cmp r0,#118
	ldreq r2,=write0_118
	
	cmp r0,#245
	;Use mapper 245 for no vrom, otherwise use mapper 4
	ldreqb r3,vrompages
	cmpeq r3,#0
	ldreq r2,=write0_245
	
	[ LESSMAPPERS
	ldr r3,=cmd6
	str r3,[r1,#6*4]
	str r3,[r1,#6*4+32]
	ldr r3,=mapAB_
	str r3,[r1,#7*4]
	str r3,[r1,#7*4+32]
	|
	cmp r0,#249
	ldreq r3,=write4
	ldreq r0,=empty_io_w_hook
	streq r3,[r0]

	ldreq r2,=write0_249
	ldrne r3,=cmd6
	ldreq r3,=cmd6_249
	str r3,[r1,#6*4]
	str r3,[r1,#6*4+32]
	ldrne r3,=mapAB_
	ldreq r3,=cmd7_249
	str r3,[r1,#7*4]
	str r3,[r1,#7*4+32]
	]
	
	str r2,writemem_tbl+16
null
	mov pc,lr

write0_245
	tst addy,#1
	ldrb r1,cmd
	bne w8001_245
write0_245_even
	strb r0,cmd
	eor addy,r0,r1
	tst addy,#0x40
	bne romswitch_245
	mov pc,lr
w8001_245
	and r1,r1,#7
	ldr pc,[pc,r1,lsl#2]
	DCD 0
;----------------------------------------------------------------------------
commandlist_245 DCD cmd0_245,null,null,null,null,null,cmd6_245,cmd7_245
;----------------------------------------------------------------------------

	[ LESSMAPPERS
	|
write0_249
	tst addy,#1
	beq_long write0_even
	ldrb r1,usescramble
	tst r1,#0xFF
	mov addy,lr
	mov r2,r0
	blne unscramble1
	mov lr,addy
	b_long w8001
	]

;----------------------------------------------------------------------------
	AREA wram_code3, CODE, READWRITE
;----------------------------------------------------------------------------
write0		;$8000-8001
;----------------------------------------------------------------------------
	tst addy,#1
	bne w8001
write0_even

	ldrb r1,cmd
	strb r0,cmd
	eor addy,r0,r1
	tst addy,#0x80
	beq wr0
			;CHR base switch (0000/1000)
	ldr r1,nes_chr_map
	ldr r2,nes_chr_map+4
	str r2,nes_chr_map
	str r1,nes_chr_map+4
	stmfd sp!,{r3-r7,lr}
	adr lr,vram_map
	ldmia lr,{r0-r7}
	stmia lr!,{r4-r7}
	stmia lr,{r0-r3}
	bl_long updateBGCHR_
	ldmfd sp!,{r3-r7,lr}
wr0
	tst addy,#0x40
	bne romswitch
	mov pc,lr
w8001
	ldrb r1,cmd
	tst r1,#0x80	;reverse CHR?
	and r1,r1,#7
	orrne r1,r1,#8
	ldr pc,[pc,r1,lsl#2]
	DCD 0
;----------------------------------------------------------------------------
commandlist	DCD cmd0,cmd1,chr4_,chr5_,chr6_,chr7_,cmd6,mapAB_
		DCD cmd0x,cmd1x,chr0_,chr1_,chr2_,chr3_,cmd6,mapAB_
;----------------------------------------------------------------------------


write0_118		;$8000-8001
;----------------------------------------------------------------------------
	tst addy,#1
	beq write0_even
w8001_118
	ldrb r1,cmd
	and r2,r1,#7
	cmp r2,#6
	bge w8001
	;if r1 & 0x80 && r1<2
	tst r1,#0x80
	beq w8001_118_alttest
	cmp r2,#2
	blt w8001
	b w8001_118_noalttest
w8001_118_alttest
	cmp r2,#2
	bge w8001
w8001_118_noalttest
	ldrb r1,lastchr
	strb r0,lastchr
	eor r1,r0,r1
	tst r1,#0x80
	beq w8001
	
	tst r0,#0x80
	stmfd sp!,{lr}
	bl_long mirror1_
	ldmfd sp!,{lr}
	b w8001

cmd0			;0000-07ff
	mov r0,r0,lsr#1
	b_long chr01_
cmd1			;0800-0fff
	mov r0,r0,lsr#1
	b_long chr23_
cmd0x			;1000-17ff
	mov r0,r0,lsr#1
	b_long chr45_
cmd1x			;1800-1fff
	mov r0,r0,lsr#1
	b_long chr67_
	[ LESSMAPPERS
	|
cmd7_249
	mov r0,r2
	mov addy,lr
	bl_long unscramble3
	mov lr,addy
	b_long mapAB_
cmd6_249
	mov r0,r2
	mov addy,lr
	bl_long unscramble3
	mov lr,addy
	]
cmd6			;$8000/$C000 select
	strb r0,bank0
romswitch
	mov addy,lr
	mov r0,#-2
	ldrb r1,cmd
	tst r1,#0x40
	bne rs0

	bl_long mapCD_
	ldrb r0,bank0
	mov lr,addy
	b_long map89_
rs0
	bl_long map89_
	ldrb r0,bank0
	mov lr,addy
	b_long mapCD_

;----------------------------------------------------------------------------
write1		;$A000-A001
;----------------------------------------------------------------------------
	tst addy,#1
	movne pc,lr
	tst r0,#1
	b_long mirror2V_
;----------------------------------------------------------------------------
write2		;C000-C001
;----------------------------------------------------------------------------
	tst addy,#1
	streqb r0,latch
	movne r0,#0
	strneb r0,countdown
	mov pc,lr
;----------------------------------------------------------------------------
write3		;E000-E001
;----------------------------------------------------------------------------
	and r0,addy,#1
	strb r0,irqen
	mov pc,lr


;----------------------------------------------------------------------------
MMC3_IRQ_midline
;----------------------------------------------------------------------------
	
	;first check if we're inside the vblank period  (maybe optimize this out?)
	ldr r0,scanline
	cmp r0,#240
	bgt default_midlinehook

	;If both sprites and BG disabled, no change in address
	ldrb r0,ppuctrl1
	tst r0,#0x18
	beq default_midlinehook

	ldrb r1,countdown
	cmp r1,#1
	beq_long MMC3_finer_check
mmc3_irq_check1
	;check for rising edge:
	ldrb r0,ppuctrl0
	;BG must come from left pattern table, must be 8x16 sprites, or 8x8 sprites from right table
	tst r0,#0x10
	bne default_midlinehook
	tst r0,#0x28
	beq default_midlinehook
	
	ldr lr,=default_midlinehook
;	b MMC3_countdown
MMC3_countdown
	ldr r0,scanline
	ldrb r1,midscanline

	;now do the countdown
	ldrb r0,countdown
	subs r0,r0,#1
	ldrmib r0,latch
	strb r0,countdown
	bxne lr

	ldrb r1,irqen
	cmp r1,#0
	bne CheckI
	bx lr

;----------------------------------------------------------------------------
MMC3_IRQ_Hook
;----------------------------------------------------------------------------
	;If inside vblank, no change in address
	ldr r0,scanline
	cmp r0,#240
	bgt pcm_scanlinehook
	ldr lr,=pcm_scanlinehook
mmc3_irq_check2
	;If both sprites and BG disabled, no change in address
	ldrb r0,ppuctrl1
	tst r0,#0x18
	bxeq lr
	;check for rising edge:
	ldrb r0,ppuctrl0
	;BG must come from right pattern table, must NOT be 8x16 sprites, or 8x8 sprites from right table
	tst r0,#0x10
	bxeq lr
	tst r0,#0x28
	bxne lr
	
	b MMC3_countdown

	AREA rom_code3, CODE, READONLY
;ntsc:
;4, 68, 85
;pal:
;4, 64, 80


MMC3_finer_check
	ldr r0,cyclesperscanline2
	sub cycles,cycles,r0
	adds cycles,cycles,#4*CYCLE
	bmi MMC3_finer_timeout
	ldr r0,=MMC3_finer_timeout
	str r0,nexttimeout
	b_long default_midlinehook
MMC3_finer_timeout
	add cycles,cycles,#(324-260)*CYCLE
	ldr r0,emuflags
	tst r0,#PALTIMING
	subne cycles,cycles,#4*CYCLE

	
	
	ldr r0,=MMC3_finer_timeout2
	str r0,nexttimeout
	b_long mmc3_irq_check1
MMC3_finer_timeout2
	add cycles,cycles,#(341-324)*CYCLE
	ldr r0,emuflags
	tst r0,#PALTIMING
	subne cycles,cycles,#1*CYCLE

	ldr r0,=MMC3_dummy_IRQ_Hook
	str r0,scanlinehook
	ldr r0,line_end_timeout
	str r0,nexttimeout
	ldr lr,=default_scanlinehook
	b_long mmc3_irq_check2
MMC3_dummy_IRQ_Hook	
	ldr r0,=MMC3_IRQ_Hook
	str r0,scanlinehook
	b_long pcm_scanlinehook

	AREA rom_code2, CODE, READONLY

cmd0_245
	tst r0,#2
	moveq r1,#0
	movne r1,#1
	strb r1,bankadd
	b romswitch_245
cmd7_245
	strb r0,bank1
	b romswitch_245
cmd6_245			;$8000/$C000 select
	strb r0,bank0
romswitch_245
	mov addy,lr
	mov r0,#63
	ldrb r1,bankadd
	orr r0,r0,r1,lsl#6
	bl_long mapEF_

	ldrb r0,bank1
	ldrb r1,bankadd
	orr r0,r0,r1,lsl#6
	bl_long mapAB_

	mov r0,#62
	ldrb r1,bankadd
	orr r0,r0,r1,lsl#6

	ldrb r1,cmd
	tst r1,#0x40
	bne rs0_245

	bl_long mapCD_
	ldrb r0,bank0
	ldrb r1,bankadd
	orr r0,r0,r1,lsl#6

	mov lr,addy
	b_long map89_
rs0_245
	bl_long map89_
	ldrb r0,bank0
	ldrb r1,bankadd
	orr r0,r0,r1,lsl#6

	mov lr,addy
	b_long mapCD_

	[ LESSMAPPERS
	|
;this stuff is for mapper 249, which scrambles the bank numbers
;----------------------------------------------------------------------------
write4		;5000
;----------------------------------------------------------------------------
	cmp addy,#0x5000
	movne pc,lr
	and r0,r0,#2
	strb r0,usescramble
	mov pc,lr
unscramble1
	and r1,r0,#0x03
	tst r0,#0x04
	orrne r1,r1,#0x20
	tst r0,#0x08
	orrne r1,r1,#0x04
	tst r0,#0x10
	orrne r1,r1,#0x40
	tst r0,#0x20
	orrne r1,r1,#0x80
	tst r0,#0x40
	orrne r1,r1,#0x10
	tst r0,#0x80
	orrne r1,r1,#0x08
	mov r0,r1
	bx lr
unscramble2
	and r1,r0,#0x01
	tst r0,#0x02
	orrne r1,r1,#0x08
	tst r0,#0x04
	orrne r1,r1,#0x10
	tst r0,#0x08
	orrne r1,r1,#0x04
	tst r0,#0x10
	orrne r1,r1,#0x02
	mov r0,r1
	bx lr
unscramble3
	ldrb r1,usescramble
	tst r1,#0xFF
	bxeq lr
	cmp r0,#0x20
	blt unscramble2
	sub r0,r0,#0x20
	b unscramble1
	]
	END
