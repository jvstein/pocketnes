	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h
	INCLUDE 6502.h
	INCLUDE 6502mac.h

	EXPORT mapper4init
	EXPORT mapper74init
;	EXPORT mapper64init
	EXPORT mapper119init
	EXPORT MMC3_IRQ_Hook

countdown EQU mapperdata+0
latch EQU mapperdata+1
irqen EQU mapperdata+2
rmode EQU mapperdata+3
cmd EQU mapperdata+4
bank0 EQU mapperdata+5
;----------------------------------------------------------------------------
;mapper64init
mapper4init
mapper74init
mapper119init
;----------------------------------------------------------------------------
	DCD write0,write1,write2,write3

	ldr r0,=MMC3_IRQ_Hook
	str r0,scanlinehook

	mov pc,lr
;----------------------------------------------------------------------------
	AREA wram_code3, CODE, READWRITE
;----------------------------------------------------------------------------
write0		;$8000-8001
;----------------------------------------------------------------------------
	tst addy,#1
	bne w8001

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
	adrl lr,vram_map
	ldmia lr,{r0-r7}
	stmia lr!,{r4-r7}
	stmia lr,{r0-r3}
	bl updateBGCHR_
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

cmd0			;0000-07ff
	mov r0,r0,lsr#1
	b chr01_
cmd1			;0800-0fff
	mov r0,r0,lsr#1
	b chr23_
cmd0x			;1000-17ff
	mov r0,r0,lsr#1
	b chr45_
cmd1x			;1800-1fff
	mov r0,r0,lsr#1
	b chr67_
cmd6			;$8000/$C000 select
	strb r0,bank0
;- - - - - - - -
romswitch
	mov addy,lr
	mov r0,#-2
	ldrb r1,cmd
	tst r1,#0x40
	bne rs0

	bl mapCD_
	ldrb r0,bank0
	mov lr,addy
	b map89_
rs0
	bl map89_
	ldrb r0,bank0
	mov lr,addy
	b mapCD_
;----------------------------------------------------------------------------
write1		;$A000-A001
;----------------------------------------------------------------------------
	tst addy,#1
	movne pc,lr
	tst r0,#1
	b mirror2V_
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
MMC3_IRQ_Hook
;----------------------------------------------------------------------------
	ldrb r0,ppuctrl1
	tst r0,#0x18		;no sprite/BG enable?  0x18
	beq hk0			;bye..

	ldr r0,scanline
	cmp r0,#240		;not rendering?
	bhi hk0			;bye..

	ldrb r0,countdown
	subs r0,r0,#1
	ldrmib r0,latch
	strb r0,countdown
	bne hk0

	ldrb r1,irqen
	cmp r1,#0
;	bne irq6502
	bne CheckI
hk0
	fetch 0
	END
