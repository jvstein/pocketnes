	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE cart.h
	INCLUDE io.h
	INCLUDE 6502.h

	EXPORT ppu_init
	EXPORT ppureset_
	EXPORT PPU_R
	EXPORT PPU_W
	EXPORT agb_nt_map
	EXPORT vram_map
	EXPORT vram_write_tbl
	EXPORT VRAM_chr
	EXPORT debug_
	EXPORT AGBinput
	EXPORT map_palette
	EXPORT newframe
	EXPORT agb_pal
	EXPORT ppustate
	EXPORT writeBG
	EXPORT wtop
	EXPORT oambuffer
	EXPORT ctrl1_W
	EXPORT newX

 AREA rom_code, CODE, READONLY

nes_rgb
	INCBIN nespal.bin
vs_palmaps
;castlevania/golf/machrider
	DCB 0x0f,0x27,0x18,0x3f,0x3f,0x25,0x3f,0x34,0x16,0x13,0x3f,0x3f,0x20,0x23,0x3f,0x0b
	DCB 0x3f,0x3f,0x06,0x3f,0x1b,0x3f,0x3f,0x22,0x3f,0x24,0x3f,0x3f,0x32,0x3f,0x3f,0x03
	DCB 0x3f,0x37,0x26,0x33,0x11,0x3f,0x10,0x3f,0x14,0x3f,0x00,0x09,0x12,0x0f,0x3f,0x30
	DCB 0x3f,0x3f,0x2a,0x17,0x0c,0x01,0x15,0x19,0x3f,0x3f,0x07,0x37,0x3f,0x05,0x3f,0x3f
;mario
	DCB 0x18,0x3f,0x1c,0x3f,0x3f,0x3f,0x0b,0x17,0x10,0x3f,0x14,0x3f,0x36,0x37,0x1a,0x3f
	DCB 0x25,0x3f,0x12,0x3f,0x0f,0x3f,0x3f,0x3f,0x3f,0x3f,0x22,0x19,0x3f,0x3f,0x3a,0x21
	DCB 0x3f,0x3f,0x07,0x3f,0x3f,0x3f,0x00,0x15,0x0c,0x3f,0x3f,0x3f,0x3f,0x3f,0x3f,0x3f
	DCB 0x3f,0x3f,0x07,0x16,0x3f,0x3f,0x30,0x3c,0x3f,0x27,0x3f,0x3f,0x29,0x3f,0x1b,0x09
;iceclimber
	DCB 0x18,0x3f,0x1c,0x3f,0x3f,0x3f,0x01,0x17,0x10,0x3f,0x2a,0x3f,0x36,0x37,0x1a,0x39
	DCB 0x25,0x3f,0x12,0x3f,0x0f,0x3f,0x3f,0x26,0x3f,0x3f,0x22,0x19,0x3f,0x0f,0x3a,0x21
	DCB 0x3f,0x0a,0x07,0x06,0x13,0x3f,0x00,0x15,0x0c,0x3f,0x11,0x3f,0x3f,0x38,0x3f,0x3f
	DCB 0x3f,0x3f,0x07,0x16,0x3f,0x3f,0x30,0x3c,0x0f,0x27,0x3f,0x31,0x29,0x3f,0x11,0x09
;gradius/pinball
	DCB 0x35,0x3f,0x16,0x3f,0x1c,0x3f,0x3f,0x15,0x3f,0x3f,0x27,0x05,0x04,0x3f,0x3f,0x30
	DCB 0x21,0x3f,0x3f,0x3f,0x3f,0x3f,0x36,0x12,0x3f,0x2b,0x3f,0x3f,0x3f,0x3f,0x3f,0x3f
	DCB 0x3f,0x31,0x3f,0x2a,0x2c,0x0c,0x3f,0x3f,0x3f,0x07,0x34,0x06,0x3f,0x25,0x26,0x0f
	DCB 0x3f,0x19,0x10,0x3f,0x3f,0x3f,0x3f,0x17,0x3f,0x11,0x3f,0x3f,0x3f,0x3f,0x18,0x3f
;goonies/drmario/soccer
	DCB 0x0f,0x3f,0x3f,0x10,0x3f,0x30,0x31,0x3f,0x01,0x0f,0x36,0x3f,0x3f,0x3f,0x3f,0x3c
	DCB 0x3f,0x3f,0x3f,0x12,0x19,0x3f,0x17,0x3f,0x00,0x3f,0x3f,0x02,0x16,0x3f,0x3f,0x3f
	DCB 0x3f,0x3f,0x3f,0x37,0x3f,0x27,0x26,0x20,0x3f,0x04,0x22,0x3f,0x11,0x3f,0x3f,0x3f
	DCB 0x2c,0x3f,0x3f,0x3f,0x07,0x2a,0x3f,0x3f,0x3f,0x3f,0x3f,0x38,0x13,0x3f,0x3f,0x0c
;excitebike
	DCB 0x3f,0x3f,0x3f,0x3f,0x1a,0x30,0x3c,0x09,0x0f,0x0f,0x3f,0x0f,0x3f,0x3f,0x3f,0x30
	DCB 0x32,0x1c,0x3f,0x12,0x3f,0x18,0x17,0x3f,0x0c,0x3f,0x3f,0x02,0x16,0x3f,0x3f,0x3f
	DCB 0x3f,0x3f,0x0f,0x37,0x3f,0x28,0x27,0x3f,0x29,0x3f,0x21,0x3f,0x11,0x3f,0x0f,0x3f
	DCB 0x31,0x3f,0x3f,0x3f,0x0f,0x2a,0x28,0x3f,0x3f,0x3f,0x3f,0x3f,0x13,0x3f,0x3f,0x3f
;----------------------------------------------------------------------------
map_palette	;(for VS unisys)	r0-r2,r4-r7 modified
;----------------------------------------------------------------------------
	ldr r5,=nes_rgb
	ldr r6,=MAPPED_RGB
	mov r7,#64
	ldrb r0,cartflags
	tst r0,#VS
	beq nomap

	ldr r0,memmap_tbl+7*4
	ldr r1,=NMI_VECTOR
	ldrb r1,[r0,r1]!
	ldrb r2,[r0,#1]!
	ldrb r4,[r0,#1]!
	ldrb r0,[r0,#1]
	orr r1,r1,r2,lsl#8
	orr r1,r1,r4,lsl#16
	orr r1,r1,r0,lsl#24

	adr r2,vslist
mp0	ldr r0,[r2],#8
	cmp r0,r1			;find which rom...
	beq remap
	cmp r0,#0
	bne mp0
nomap
	ldr r0,[r5],#4
	str r0,[r6],#4
	subs r7,r7,#2
	bne nomap
	mov pc,lr
remap
	ldr r1,[r2,#-4]
mp1	ldrb r0,[r1],#1
	mov r0,r0,lsl#1
	ldrh r0,[r5,r0]
	strh r0,[r6],#2
	subs r7,r7,#1
	bne mp1
	mov pc,lr

vslist	DCD 0x80008281,vs_palmaps+64*3 ;pinball			RP2C04-0001
	DCD 0xf422f492,vs_palmaps+64*3 ;gradius
	DCD 0x800080ce,vs_palmaps+64*0 ;(lady)golf		RP2C04-0002
	DCD 0x80008053,vs_palmaps+64*0 ;mach rider
	DCD 0xc008c062,vs_palmaps+64*0 ;castlevania
	DCD 0x85af863f,vs_palmaps+64*5 ;excitebike		RP2C04-0003
	DCD 0x800080ba,vs_palmaps+64*4 ;soccer
	DCD 0xf007f0a5,vs_palmaps+64*4 ;goonies
	DCD 0xff008005,vs_palmaps+64*4 ;dr mario
	DCD 0x8000810a,vs_palmaps+64*1 ;super mario bros	RP2C04-0004
	DCD 0xb578b5de,vs_palmaps+64*2 ;ice climber
	DCD 0
;----------------------------------------------------------------------------
ppu_init	;(called from main.c) only need to call once
;----------------------------------------------------------------------------
	mov addy,lr

	mov r1,#0xffffff00		;build chr decode tbl
	ldr r2,=CHR_DECODE
ppi0	mov r0,#0
	tst r1,#0x01
	orrne r0,r0,#0x10000000
	tst r1,#0x02
	orrne r0,r0,#0x01000000
	tst r1,#0x04
	orrne r0,r0,#0x00100000
	tst r1,#0x08
	orrne r0,r0,#0x00010000
	tst r1,#0x10
	orrne r0,r0,#0x00001000
	tst r1,#0x20
	orrne r0,r0,#0x00000100
	tst r1,#0x40
	orrne r0,r0,#0x00000010
	tst r1,#0x80
	orrne r0,r0,#0x00000001
	str r0,[r2],#4
	adds r1,r1,#1
	bne ppi0

	ldr r1,=AGB_IRQVECT
	ldr r2,=irqhandler
	str r2,[r1]

	mov r1,#REG_BASE
	mov r0,#0x0008
	strh r0,[r1,#REG_DISPSTAT]	;vblank en

	add r0,r1,#REG_BG0HOFS		;DMA0 always goes here
	str r0,[r1,#REG_DM0DAD]
	mov r0,#1			;1 word transfer
	strh r0,[r1,#REG_DM0CNT_L]
	ldr r0,=DMA0BUFF+4		;dmasrc=
	str r0,[r1,#REG_DM0SAD]

	str r1,[r1,#REG_DM1DAD]		;DMA1 goes here
	mov r0,#1			;1 word transfer
	strh r0,[r1,#REG_DM1CNT_L]

	add r0,r1,#REG_BG0CNT		;DMA2 goes here
	str r0,[r1,#REG_DM2DAD]
	mov r0,#1			;1 word transfer
	strh r0,[r1,#REG_DM2CNT_L]

	add r2,r1,#REG_IE
	mov r0,#-1
	strh r0,[r2,#2]		;stop pending interrupts
	mov r0,#0x11
	strh r0,[r2]		;allow vblank,timer1 irqs
	mov r0,#1
	strh r0,[r2,#8]		;master irq enable

;	ldr r0,emu
;	str r0,no_emu
;no_emu	mov pc,addy
;emu	nop
;	;..
	mov pc,addy
;----------------------------------------------------------------------------
ppureset_	;called with CPU reset
;----------------------------------------------------------------------------
	mov r0,#0
	strb r0,ppuctrl0	;NMI off
	strb r0,ppuctrl1	;screen off
	strb r0,ppustat		;flags off

	str r0,windowtop

	;strb r0,toggle
	;mov r0,#1
	;strb r0,vramaddrinc

	b map_palette	;do palette mapping (for VS)
;----------------------------------------------------------------------------
	AREA wram_code1, CODE, READWRITE
irqhandler	;r0-r3,r12 are safe to use
;----------------------------------------------------------------------------
	mov r2,#REG_BASE
	ldr r1,[r2,#REG_IE]!
	and r1,r1,r1,lsr#16	;r1=IE&IF
	;---
	;ands r0,r1,#0x10
	;bne timer1_irq
	ands r0,r1,#0x01
	bne vblank_irq
	;----
	strh r1,[r2,#2]		;IF clear
	bx lr
;----------------------------------------------------------------------------
twitch DCD 0
returnhere DCD 0
vblank_irq;
;----------------------------------------------------------------------------
	strh r0,[r2,#2]		;IF clear
	strb r0,agb_vbl
	add r1,sp,#20
	adr r0,exitirq+4
	swp r0,r0,[r1]
	sub r0,r0,#4
	str r0,returnhere
	bx lr		;exit irq immediately so it doesn't fuck up sound irq timing
exitirq ;- - - - - - - - - - - -
	stmfd sp!,{r0-r7,globalptr,lr}
	mrs lr,cpsr

	ldr globalptr,=|wram_globals0$$Base|

	ldr r2,=DMA0BUFF	;setup DMA buffer for scrolling:
	add r3,r2,#160*4
	ldr r1,dmascrollbuff
	ldrb r0,hackflags
	tst r0,#NOSCALING
	beq vbl0

	ldr r0,windowtop+12
	add r1,r1,r0,lsl#2		;(unscaled)
vbl6	ldmia r1!,{r0,r4-r7}
	stmia r2!,{r0,r4-r7}
	cmp r2,r3
	bmi vbl6
	b vbl5
vbl0					;(scaled)
	mov r4,#YSTART*65536
	add r1,r1,#2

	ldr r5,twitch
	eors r5,r5,#1
	str r5,twitch
		ldrh r5,[r1],#YSTART*4-2 ;adjust vertical scroll to avoid screen wobblies
	ldreq r0,[r1],#4
	addeq r0,r0,r4
	streq r0,[r2],#4
		ldr r0,adjustblend
		add r0,r0,r5
		ands r0,r0,#3
		beq vbl2
		cmp r0,#1
		beq vbl3
		cmp r0,#2
		beq vbl4

vbl1	ldr r0,[r1],#4
	add r0,r0,r4
	str r0,[r2],#4
vbl2	ldr r0,[r1],#4
	add r0,r0,r4
	str r0,[r2],#4
vbl3	ldr r0,[r1],#4
	add r0,r0,r4
	str r0,[r2],#4
vbl4	add r1,r1,#4
	add r4,r4,#0x10000
	cmp r2,r3
	bmi vbl1
vbl5

	ldrb r0,hackflags		;get DMA1,2 source..
	tst r0,#NOSCALING
	ldreq r3,=DMA1BUFF
	ldreq r4,=DMA2BUFF
	beq vbl7
	ldr r0,windowtop+12
	ldr r3,=DISPCNTBUFF
	ldr r4,=BG0CNTBUFF
	add r3,r3,r0,lsl#1
	add r4,r4,r0,lsl#1
vbl7
	mov r1,#REG_BASE		;setup HBLANK DMA for display scroll:
	strh r1,[r1,#REG_DM0CNT_H]		;DMA stop
	ldr r0,=DMA0BUFF
	ldr r2,[r0],#4
	str r2,[r1,#REG_BG0HOFS]		;set 1st value manually, HBL is AFTER 1st line
	ldr r0,=0xA660				;noIRQ hblank 32bit repeat incsrc inc_reloaddst
	strh r0,[r1,#REG_DM0CNT_H]		;DMA go
					;setup HBLANK DMA for DISPCNT (BG/OBJ enable)
	strh r1,[r1,#REG_DM1CNT_H]		;DMA stop
	ldrh r2,[r3],#2
	strh r2,[r1,#REG_DISPCNT]		;set 1st value manually, HBL is AFTER 1st line
	str r3,[r1,#REG_DM1SAD]			;dmasrc=
	ldr r0,=0xA240				;noIRQ hblank 16bit repeat incsrc fixeddst
	strh r0,[r1,#REG_DM1CNT_H]		;DMA go
					;setup HBLANK DMA for BG CHR
	strh r1,[r1,#REG_DM2CNT_H]		;DMA stop
	ldr r2,[r4],#2
	strh r2,[r1,#REG_BG0CNT]		;set 1st value manually, HBL is AFTER 1st line
	str r4,[r1,#REG_DM2SAD]			;dmasrc=
	ldr r0,=0xA240				;noIRQ hblank 16bit repeat incsrc fixeddst
	strh r0,[r1,#REG_DM2CNT_H]		;DMA go

	ldr r0,dmaoambuffer		;OAM transfer:
	str r0,[r1,#REG_DM3SAD]
	mov r0,#AGB_OAM
	str r0,[r1,#REG_DM3DAD]
	mov r0,#128
	strh r0,[r1,#REG_DM3CNT_L]		;128 words (512 bytes)
	mov r0,#0x8400				;noIRQ hblank 32bit repeat incsrc fixeddst
	strh r0,[r1,#REG_DM3CNT_H]		;DMA go

	msr cpsr_f,lr
	ldmfd sp!,{r0-r7,globalptr,lr}
	ldr pc,returnhere
;----------------------------------------------------------------------------
newframe	;called at line 0	(r0-r9 safe to use)
;----------------------------------------------------------------------------
	str lr,[sp,#-4]!

	bl updateOBJCHR
	ldr r0,nes_chr_map
	ldr r1,nes_chr_map+4
	str r0,old_chr_map
	str r1,old_chr_map+4
;-----------------------
	ldr r0,ctrl1old
	ldr r1,ctrl1line
	mov addy,#239
	bl ctrl1finish
	mov r0,#0
	str r0,ctrl1line
;-----------------------
	bl chrfinish
;------------------------
	ldr r0,scrollXold
	ldr r1,scrollXline
	mov addy,#239
	bl scrollXfinish
	mov r0,#0
	str r0,scrollXline
;--------------------------
	ldr r0,scrollbuff
	ldr r1,dmascrollbuff
	str r1,scrollbuff
	str r0,dmascrollbuff

	ldr r0,oambuffer
	ldr r1,tmpoambuffer
	str r0,tmpoambuffer
	str r1,dmaoambuffer

	ldr r0,windowtop
	ldr r1,windowtop+4
	ldr r2,windowtop+8
	str r0,windowtop+4
	str r1,windowtop+8
	str r2,windowtop+12

	ldr r0,scrollY
	mov r1,#0
	bl initY

	ldrb r0,hackflags		;refresh DMA1,DMA2 buffers
	tst r0,#NOSCALING			;not needed for unscaled mode..
	bne nf7					;(DMA'd directly from dispcntbuff/bg0cntbuff)

	ldr r2,=DMA1BUFF
	add r3,r2,#160*2
nf1	ldr r1,=DISPCNTBUFF+YSTART*2		;(scaled)
nf0	ldrh r0,[r1],#2
	strh r0,[r2],#2
		ldrh r0,[r1],#2
		strh r0,[r2],#2
	ldrh r0,[r1],#4
	strh r0,[r2],#2
	cmp r2,r3
	bmi nf0

	ldr r1,=BG0CNTBUFF+YSTART*2
	ldr r2,=DMA2BUFF
	add r3,r2,#160*2
nf2	ldrh r0,[r1],#2
	strh r0,[r2],#2
		ldrh r0,[r1],#2
		strh r0,[r2],#2
	ldrh r0,[r1],#4
	strh r0,[r2],#2
	cmp r2,r3
	bmi nf2
nf7
	mov r8,#AGB_PALETTE		;palette transfer
	adrl addy,agb_pal
nf8	ldmia addy!,{r0-r7}
	stmia r8,{r0,r1}
	add r8,r8,#32
	stmia r8,{r2,r3}
	add r8,r8,#32
	stmia r8,{r4,r5}
	add r8,r8,#32
	stmia r8,{r6,r7}
	add r8,r8,#0x1a0
	tst r8,#0x200
	bne nf8			;(2nd pass: sprite pal)

	ldr pc,[sp],#4
;----------------------------------------------------------------------------
PPU_R;
;----------------------------------------------------------------------------
	and r0,addy,#7
	adr r1,PPU_read_tbl
	ldr pc,[r1,r0,lsl#2]

PPU_read_tbl
	DCD empty_R	;$2000
	DCD empty_R	;$2001
	DCD stat_R	;$2002
	DCD empty_R	;$2003
	DCD empty_R	;$2004
	DCD empty_R	;$2005
	DCD empty_R	;$2006
	DCD vmdata_R	;$2007
;----------------------------------------------------------------------------
PPU_W;
;----------------------------------------------------------------------------
	and r2,addy,#7
	adr r1,PPU_write_tbl
	ldr pc,[r1,r2,lsl#2]

PPU_write_tbl
	DCD ctrl0_W	;$2000
	DCD ctrl1_W	;$2001
	DCD void	;$2002
	DCD void	;$2003
	DCD void	;$2004
	DCD bgscroll_W	;$2005
	DCD vmaddr_W	;$2006
	DCD vmdata_W	;$2007
;----------------------------------------------------------------------------
ctrl0_W		;(2000)
;----------------------------------------------------------------------------
;c02:
;	and al,[ctrl0]
;	and al,[stat]
;	jns c03
;	or [int_flags],NMI ;NMI when NMIen&VBLflag=0->1

	strb r0,ppuctrl0

	mov addy,lr
	bl updateBGCHR_		;check for tileset switch (OBJ CHR gets checked at frame end)
	mov lr,addy

	ldrb r0,ppuctrl0

	mov r1,#1			;+1/+32
	tst r0,#4
	movne r1,#32
	strb r1,vramaddrinc

	mov r1,r0,lsr#1			;Y scroll
	and r1,r1,#1
	strb r1,scrollY+1

	and r0,r0,#1			;X scroll
	ldrb r1,scrollX+1
	strb r0,scrollX+1
	eors r0,r0,r1
	moveq pc,lr
	b newX
;----------------------------------------------------------------------------
ctrl1_W		;(2001)
;----------------------------------------------------------------------------
	strb r0,ppuctrl1

	mov r1,#0x0440		;1d sprites, BG2 enable
	tst r0,#0x08		;bg en?
	orrne r1,r1,#0x0100
	tst r0,#0x10		;obj en?
	orrne r1,r1,#0x1000

	adr r2,ctrl1old
	swp r0,r1,[r2]		;r0=lastval

	adr r2,ctrl1line
	ldr addy,scanline	;addy=scanline
	cmp addy,#239
	movhi addy,#239
	swp r1,addy,[r2]	;r1=lastline, lastline=scanline
ctrl1finish
	ldr r2,=DISPCNTBUFF
	add r1,r2,r1,lsl#1
	add r2,r2,addy,lsl#1
ct1	strh r0,[r2],#-2	;fill backwards from scanline to lastline
	cmp r2,r1
	bpl ct1

	mov pc,lr

ctrl1old	DCD 0x0440	;last write
ctrl1line	DCD 0 ;when?
;----------------------------------------------------------------------------
stat_R		;(2002)
;----------------------------------------------------------------------------
	ldrb r2,hackflags	;probably in a polling loop
	tst r2,#USEPPUHACK
	movne cycles,#0		;let's help out

	mov r1,#0
	strb r1,toggle

	ldrb r0,ppustat
	ldr r1,sprite0y		;sprite0 hit?
	ldr r2,scanline
	cmp r2,r1
	orrhi r0,r0,#0x40
	bic r1,r0,#0x80		;vbl flag clear
	strb r1,ppustat

	mov pc,lr
;----------------------------------------------------------------------------
bgscroll_W	;(2005)
;----------------------------------------------------------------------------
	and r0,r0,#0xff

	ldrb r1,toggle
	eors r1,r1,#1
	strb r1,toggle
	beq bgscrollY
bgscrollX
	strb r0,scrollX
newX			;ctrl0_W, loadstate jumps here
	ldr r0,scrollX
newX2			;vmaddr_W jumps here
	adr r2,scrollXold
	swp r0,r0,[r2]		;r0=lastval

	adr r2,scrollXline
	ldr addy,scanline	;addy=scanline
	cmp addy,#239
	movhi addy,#239
	swp r1,addy,[r2]	;r1=lastline, lastline=scanline
scrollXfinish		;newframe jumps here
	add r0,r0,#8
	ldr r2,scrollbuff
	add r1,r2,r1,lsl#2
	add r2,r2,addy,lsl#2
sx1	strh r0,[r2],#-4	;fill backwards from scanline to lastline
	cmp r2,r1
	bpl sx1
	mov pc,lr

scrollXold DCD 0 ;last write
scrollXline DCD 0 ;..was when?

bgscrollY
	strb r0,scrollY

	ldr r1,vramaddr2	;hurl!
	bic r1,r1,#0x7300
	bic r1,r1,#0x00e0
	and r2,r0,#0xf8
	and r0,r0,#7
	orr r1,r1,r2,lsl#2
	orr r1,r1,r0,lsl#12
	str r1,vramaddr2

	mov pc,lr
;----------------------------------------------------------------------------
vmaddr_W	;(2006)
;----------------------------------------------------------------------------
	ldrb r1,toggle
	eors r1,r1,#1
	strb r1,toggle
	beq low
high
	and r0,r0,#0x3f
	strb r0,vramaddr2+1
	mov pc,lr
low
	strb r0,vramaddr2
	ldr r1,vramaddr2
	str r1,vramaddr

	and r0,r1,#0x7000
	and r2,r1,#0x03e0
	and addy,r1,#0x0800
	mov r0,r0,lsr#12
	orr r0,r0,r2,lsr#2
	orr r0,r0,addy,lsr#3
	str r0,scrollY

	str lr,[sp,#-4]!
	ldrb r0,scrollX
	and r0,r0,#7
	and r2,r1,#0x001f
	and addy,r1,#0x0400
	orr r0,r0,r2,lsl#3
	orr r0,r0,addy,lsr#2
	str r0,scrollX
	bl newX2
	ldr lr,[sp],#4
;- - - - - -
	ldr r1,scanline
	cmp r1,#239
	movhi pc,lr	;scanline>239: exit

	ldr r0,scrollY		;r0=y
	ldr r1,scanline		;r1=scanline
initY			;? jumps here
	stmfd sp!,{r3,r4,lr}
	and r4,r0,#0xff
	cmp r4,#239		;if(y&ff>239)
	eorhi r0,r0,#0x100	;	y^=$100
	movhi r4,#240		;	r4=240 (lines to NT end)
				;else
	rsbls r4,r4,#240	;	r4=240-y&ff
	sub r0,r0,r1		;y-=scanline
	ldr r2,windowtop+8
	add r0,r0,r2		;y+=windowtop
	ldr r2,scrollbuff
	strh r2,[r2,#2]!	;r2+=2, flag 2006 write
	add r3,r2,#240*4	;r3=end2
	add r2,r2,r1,lsl#2	;r2=base
	add r1,r2,r4,lsl#2	;r1=end1
	cmp r1,r3
	bhi xy2
xy1
	strh r0,[r2],#4
	cmp r2,r1
	blo xy1
	add r0,r0,#16	;y+16 for new page
xy2
	cmp r2,r3
	strloh r0,[r2],#4
	blo xy2
	ldmfd sp!,{r3,r4,pc}
;----------------------------------------------------------------------------
vmdata_R	;(2007)
;----------------------------------------------------------------------------
	ldr r0,vramaddr
	ldrb r1,vramaddrinc
	bic r0,r0,#0xfc000
	add r2,r0,r1
	str r2,vramaddr

	cmp r0,#0x3f00
	bhs palread

	mov r1,r0,lsr#10
	adr r2,vram_map
	ldr r1,[r2,r1,lsl#2]
	bic r0,r0,#0xfc00

	ldrb r1,[r1,r0]
	ldrb r0,readtemp
	strb r1,readtemp
	mov pc,lr
palread
	and r0,r0,#0x1f
	adr r1,nes_palette
	ldrb r0,[r1,r0]
	mov pc,lr
;----------------------------------------------------------------------------
vmdata_W	;(2007)
;----------------------------------------------------------------------------
	and r0,r0,#0xff

	ldr addy,vramaddr
	ldrb r1,vramaddrinc
	bic addy,addy,#0xfc000 ;AND $3fff
	add r2,addy,r1
	str r2,vramaddr

	mov r1,addy,lsr#10
	adr r2,vram_write_tbl
	ldr pc,[r2,r1,lsl#2]
;----------------------------------------------------------------------------
VRAM_chr;	0000-1fff
;----------------------------------------------------------------------------
	ldr r1,=NES_VRAM
	strb r0,[r1,addy]
	sub addy,addy,#15
	tst addy,#0x0f		;update AGB CHR when last byte of tile is written
	movne pc,lr

	stmfd sp!,{r3,r4,r5,lr}

objptr	RN r3 ;obj chr dst
nesptr	RN r4 ;chr src
bgptr	RN r5 ;bg chr dst

	add nesptr,r1,addy
	ldr bgptr,=AGB_VRAM
	add bgptr,bgptr,addy,lsl#1
	add objptr,bgptr,#0x10000
	tst bgptr,#0x2000
	addne bgptr,bgptr,#0x2000

	adr r2,chr_decode
chr0	ldrb r0,[nesptr],#1
	ldrb r1,[nesptr,#7]
	ldr r0,[r2,r0,lsl#2]
	ldr r1,[r2,r1,lsl#2]
	orr r0,r0,r1,lsl#1
	str r0,[bgptr],#4
	str r0,[objptr],#4
	tst bgptr,#0x1f
	bne chr0

	ldmfd sp!,{r3,r4,r5,pc}
;----------------------------------------------------------------------------
VRAM_name0	;(2000-23ff)
;----------------------------------------------------------------------------
	ldr r1,nes_nt0
	ldr r2,agb_nt0
writeBG		;loadcart jumps here
	bic addy,addy,#0xfc00	;AND $03ff
	strb r0,[r1,addy]
	cmp addy,#0x3c0
	bhs writeattrib
;writeNT
	mov addy,addy,lsl#1
	ldrh r1,[r2,addy]	;use old color
	and r1,r1,#0xf000
	orr r0,r0,r1
	strh r0,[r2,addy]	;write tile#
	mov pc,lr
writeattrib
	stmfd sp!,{r3,r4,lr}

	orr r0,r0,r0,lsl#16
	and r1,addy,#0x38
	and addy,addy,#0x07
	add addy,addy,r1,lsl#2
	add addy,r2,addy,lsl#3
	ldr r3,=0x00ff00ff
	ldr r4,=0x00030003

	ldr r1,[addy]
	and r2,r0,r4
	and r1,r1,r3
	orr r1,r1,r2,lsl#12
	str r1,[addy]
		ldr r1,[addy,#0x40]
		and r1,r1,r3
		orr r1,r1,r2,lsl#12
		str r1,[addy,#0x40]
	ldr r1,[addy,#4]
	and r2,r0,r4,lsl#2
	and r1,r1,r3
	orr r1,r1,r2,lsl#10
	str r1,[addy,#4]
		ldr r1,[addy,#0x44]
		and r1,r1,r3
		orr r1,r1,r2,lsl#10
		str r1,[addy,#0x44]
	ldr r1,[addy,#0x80]
	and r2,r0,r4,lsl#4
	and r1,r1,r3
	orr r1,r1,r2,lsl#8
	str r1,[addy,#0x80]
		ldr r1,[addy,#0xc0]
		and r1,r1,r3
		orr r1,r1,r2,lsl#8
		str r1,[addy,#0xc0]
	ldr r1,[addy,#0x84]
	and r2,r0,r4,lsl#6
	and r1,r1,r3
	orr r1,r1,r2,lsl#6
	str r1,[addy,#0x84]
		ldr r1,[addy,#0xc4]
		and r1,r1,r3
		orr r1,r1,r2,lsl#6
		str r1,[addy,#0xc4]
	ldmfd sp!,{r3,r4,pc}
;----------------------------------------------------------------------------
VRAM_name1	;(2400-27ff)
;----------------------------------------------------------------------------
	ldr r1,nes_nt1
	ldr r2,agb_nt1
	b writeBG
;----------------------------------------------------------------------------
VRAM_name2	;(2800-2bff)
;---------------------------------------------------------------------------
	ldr r1,nes_nt2
	ldr r2,agb_nt2
	b writeBG
;----------------------------------------------------------------------------
VRAM_name3	;(2c00-2fff)
;----------------------------------------------------------------------------
	ldr r1,nes_nt3
	ldr r2,agb_nt3
	b writeBG
;----------------------------------------------------------------------------
VRAM_pal	;write to VRAM palette area ($3F00-$3F1F)
;----------------------------------------------------------------------------
	cmp addy,#0x3f00
	bmi VRAM_name3

	and r0,r0,#0x3f		;(only colors 0-63 are valid)
	and addy,addy,#0x1f
	adr r1,nes_palette
	strb r0,[r1,addy]	;store in nes palette

	ldr r1,=MAPPED_RGB
	ldr r0,[r1,r0,lsl#1]	;lookup RGB
	adr r2,agb_pal
		tst addy,#0x0f
		moveq addy,#0	;$10 mirror to $00
	mov addy,addy,lsl#1
	strh r0,[r2,addy]	;store in agb palette
	mov pc,lr
;----------------------------------------------------------------------------
debug_		;debug output, r0=val, r1=line
;----------------------------------------------------------------------------
 [ DEBUG
	ldr r2,=DEBUGSCREEN
	add r2,r2,r1,lsl#6
db0
	mov r0,r0,ror#28
	and r1,r0,#0x0f
	cmp r1,#9
	addhi r1,r1,#7
	add r1,r1,#0x30
	orr r1,r1,#0x4100
	strh r1,[r2],#2
	tst r2,#15
	bne db0
	mov pc,lr
 ]
;----------------------------------------------------------------------------

vram_write_tbl	;for vmdata_W, r0=data, addy=vram addr
	DCD 0
	DCD 0
	DCD 0
	DCD 0
	DCD 0
	DCD 0
	DCD 0
	DCD 0
	DCD VRAM_name0	;$2000
	DCD VRAM_name1	;$2400
	DCD VRAM_name2	;$2800
	DCD VRAM_name3	;$2c00
	DCD VRAM_name0	;$3000
	DCD VRAM_name1	;$3400
	DCD VRAM_name2	;$3800
	DCD VRAM_pal	;$3c00

vram_map	;for vmdata_R
	DCD 0
	DCD 0
	DCD 0
	DCD 0
	DCD 0
	DCD 0
	DCD 0
	DCD 0
nes_nt0 DCD NES_VRAM+0x2000 ;$2000
nes_nt1 DCD NES_VRAM+0x2000 ;$2400
nes_nt2 DCD NES_VRAM+0x2400 ;$2800
nes_nt3 DCD NES_VRAM+0x2400 ;$2c00
	DCD NES_VRAM+0x2c00 ;$3xxx=?
	DCD NES_VRAM+0x2c00
	DCD NES_VRAM+0x2c00
	DCD NES_VRAM+0x2c00

agb_nt_map	;set thru mirror*
agb_nt0 DCD 0
agb_nt1 DCD 0
agb_nt2 DCD 0
agb_nt3 DCD 0

agb_pal		% 32*2	;copy this to real AGB palette every frame
nes_palette	% 32	;NES $3F00-$3F1F

scrollbuff DCD SCROLLBUFF1
dmascrollbuff DCD SCROLLBUFF2

oambuffer DCD OAM_BUFFER1,OAM_BUFFER2,OAM_BUFFER3	;1->2->3->1.. (loop)
tmpoambuffer DCD OAM_BUFFER1	;oam->tmpoam->dmaoam
dmaoambuffer DCD OAM_BUFFER2	;triple buffered hell!!!

;----------------------------------------------------------------------------
	AREA wram_globals1, CODE, READWRITE

AGBinput		;this label here for main.c to use
	DCD 0 ;AGBjoypad (bits 0-7 flipped)
	DCD 2 ;adjustblend
wtop	DCD 0,0,0,0 ;windowtop  (this label too)   L/R scrolling in unscaled mode
ppustate
	DCD 0 ;vramaddr
	DCD 0 ;vramaddr2 (temp)
	DCD 0 ;scrollX
	DCD 0 ;scrollY
	DCD 0 ;sprite0y

	DCB 1 ;vramaddrinc
	DCB 0 ;ppustat
	DCB 0 ;toggle
	DCB 0 ;ppuctrl0
	DCB 0 ;ppuctrl0frame	;state of $2000 at frame start
	DCB 0 ;ppuctrl1
	DCB 0 ;readtemp
;...update load/savestate if you move things around in here
;----------------------------------------------------------------------------
	END
