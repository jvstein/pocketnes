	AREA wram_code3, CODE, READWRITE

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h
	INCLUDE 6502.h
	INCLUDE 6502mac.h

	EXPORT mapper4init

countdown EQU mapperdata+0
latch EQU mapperdata+1
irqen EQU mapperdata+2
cmd EQU mapperdata+3
bank0 EQU mapperdata+4
bank1 EQU mapperdata+5
;----------------------------------------------------------------------------
mapper4init
;----------------------------------------------------------------------------
	DCD write0,write1,write2,write3

	mov r0,#0
	strb r0,bank0
	strb r0,bank1
	strb r0,irqen

	adr r0,hook
	str r0,scanlinehook

	mov pc,lr
;----------------------------------------------------------------------------
write0		;$8000-8001
;----------------------------------------------------------------------------
	tst addy,#1
	bne w8001

	ldrb r1,cmd
	strb r0,cmd
	eor r0,r0,r1
	tst r0,#0x80
	moveq pc,lr
			;CHR base switch (0000/1000)
	ldr r0,nes_chr_map
	ldr r1,nes_chr_map+4
	str r1,nes_chr_map
	str r0,nes_chr_map+4
	adrl addy,vram_map
	stmfd sp!,{r3-r7}
	ldmia addy,{r0-r7}
	stmia addy!,{r4-r7}
	stmia addy,{r0-r3}
	ldmfd sp!,{r3-r7}
	b updateBGCHR_
w8001
	ldrb r1,cmd
	tst r1,#0x80	;reverse CHR?
	and r1,r1,#7
	orrne r1,r1,#8
	adr r2,commandlist
	ldr pc,[r2,r1,lsl#2]
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
cmd6			;$8000/$A000 select
	strb r0,bank0
	b romswitch
cmd7			;$A000/$C000 select
	strb r0,bank1
;- - - - - - - -
romswitch
	mov addy,lr
	ldrb r0,bank1
	bl mapAB_
	mov r0,#-2
	ldrb r1,cmd
	tst r1,#0x40
	bne rs0

	bl mapCD_
	ldrb r0,bank0
	bl map89_
	mov pc,addy
rs0
	bl map89_
	ldrb r0,bank0
	bl mapCD_
	mov pc,addy
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
	streqb r0,countdown
	strneb r0,latch
	mov pc,lr
;----------------------------------------------------------------------------
write3		;E000-E001
;----------------------------------------------------------------------------
	and r0,addy,#1
	strb r0,irqen
	mov pc,lr
;----------------------------------------------------------------------------
hook
;----------------------------------------------------------------------------
	ldrb r0,ppuctrl1
	tst r0,#0x18		;no sprite/BG enable?
	beq hk0			;bye..

	ldr r0,scanline
	cmp r0,#239		;not rendering?
	bhi hk0			;bye..

	ldrb r1,irqen
	cmp r1,#0
	beq hk0

	ldrb r0,countdown
	subs r0,r0,#1
	ldrmib r0,latch
	strb r0,countdown
	bpl hk0

	mov r1,#0
	strb r1,irqen
	b irq6502
hk0
	fetch 0
;----------------------------------------------------------------------------
commandlist	DCD cmd0,cmd1,chr4_,chr5_,chr6_,chr7_,cmd6,cmd7
		DCD cmd0x,cmd1x,chr0_,chr1_,chr2_,chr3_,cmd6,cmd7
;----------------------------------------------------------------------------
	END
