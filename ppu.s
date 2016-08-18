	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE cart.h
	INCLUDE io.h
	INCLUDE 6502.h
	INCLUDE sound.h
	INCLUDE mappers.h

	EXPORT PPU_init
	EXPORT PPU_reset
	EXPORT PPU_R
	EXPORT PPU_W
	EXPORT agb_nt_map
	EXPORT vram_map
	EXPORT vram_write_tbl
	EXPORT VRAM_chr
	EXPORT VRAM_chr2
	EXPORT debug_
	EXPORT AGBinput
	EXPORT EMUinput
	EXPORT paletteinit
	EXPORT PaletteTxAll
	EXPORT Update_Palette
	EXPORT newframe
	EXPORT agb_pal
	EXPORT ppustate
	EXPORT writeBG
	EXPORT wtop
	EXPORT gammavalue
	EXPORT oambuffer
	EXPORT ctrl1_W
	EXPORT newX
	EXPORT twitch
	EXPORT flicker
	EXPORT fpsenabled
	EXPORT FPSValue
	EXPORT vbldummy
	EXPORT vblankfptr
	EXPORT vblankinterrupt
	EXPORT NES_VRAM
	EXPORT scrollbuff
	EXPORT dmascrollbuff

 AREA rom_code, CODE, READONLY

nes_rgb15
	INCBIN nespal.bin
nes_rgb
;	DCB 0x6E,0x6E,0x6E, 0x27,0x19,0xA6, 0x00,0x07,0xA1, 0x44,0x00,0x96, 0xA1,0x00,0x86, 0xB2,0x00,0x28, 0xC1,0x06,0x00, 0x8C,0x17,0x00
;	DCB 0x5C,0x41,0x00, 0x10,0x47,0x00, 0x05,0x4C,0x00, 0x00,0x45,0x2E, 0x16,0x51,0x5B, 0x00,0x00,0x00, 0x21,0x21,0x21, 0x04,0x04,0x04
;	DCB 0xBF,0xBF,0xBF, 0x00,0x94,0xF7, 0x39,0x43,0xE8, 0x7D,0x16,0xF3, 0xDE,0x07,0xC9, 0xF1,0x1E,0x65, 0xE8,0x31,0x21, 0xD6,0x64,0x00
;	DCB 0xA3,0x81,0x00, 0x40,0x80,0x00, 0x05,0x8F,0x00, 0x00,0x8A,0x55, 0x05,0xA2,0xAA, 0x35,0x35,0x35, 0x09,0x09,0x09, 0x09,0x09,0x09
;	DCB 0xFF,0xFF,0xFF, 0x2F,0xD7,0xFF, 0x89,0x9E,0xF8, 0xB4,0x74,0xFB, 0xFF,0x52,0xF3, 0xFC,0x61,0x8B, 0xF7,0x7A,0x60, 0xFF,0x90,0x3D
;	DCB 0xFA,0xBC,0x2F, 0x9F,0xE3,0x26, 0x2B,0xED,0x35, 0x3C,0xE3,0x9A, 0x06,0xDB,0xE3, 0x7E,0x7E,0x7E, 0x0D,0x0D,0x0D, 0x0D,0x0D,0x0D
;	DCB 0xFF,0xFF,0xFF, 0xA6,0xE2,0xFF, 0xC3,0xD2,0xFF, 0xD2,0xAB,0xFF, 0xFF,0xA8,0xF9, 0xFF,0xB1,0xC4, 0xFF,0xBF,0xB7, 0xFF,0xE7,0xA6
;	DCB 0xFF,0xF7,0x9C, 0xD7,0xFC,0x95, 0xA6,0xFE,0xAF, 0xA2,0xF2,0xDA, 0x99,0xF7,0xFF, 0xCD,0xCD,0xCD, 0x11,0x11,0x11, 0x11,0x11,0x11

	DCB 117,117,117, 39,27,143, 0,0,171, 71,0,159, 143,0,119, 171,0,19, 167,0,0, 127,11,0
	DCB 67,47,0, 0,71,0, 0,81,0, 0,63,23, 27,63,95, 0,0,0, 31,31,31, 5,5,5
	DCB 188,188,188, 0,115,239, 35,59,239, 131,0,243, 191,0,191, 231,0,91, 219,43,0, 203,79,15
	DCB 139,115,0, 0,151,0, 0,171,0, 0,147,59, 0,131,139, 49,49,49, 9,9,9, 9,9,9
	DCB 255,255,255, 63,191,255, 95,151,255, 167,139,253, 247,123,255, 255,119,183, 255,119,99, 255,155,59
	DCB 243,191,63, 131,211,19, 79,223,75, 88,248,152, 0,235,219, 102,102,102, 13,13,13, 13,13,13
	DCB 255,255,255, 171,231,255, 199,215,255, 215,203,255, 255,199,255, 255,199,219,255, 191,179,255, 219,171
	DCB 255,231,163, 227,255,163, 171,243,191, 179,255,207, 159,255,243, 209,209,209, 17,17,17, 17,17,17

vs_palmaps
;freedomforce/gradius/hoogansalley/pinball/platoon
	DCB 0x35,0x3f,0x16,0x22,0x1c,0x09,0x30,0x15,0x30,0x00,0x27,0x05,0x04,0x28,0x08,0x30
	DCB 0x21,0x3f,0x3f,0x3f,0x3c,0x32,0x36,0x12,0x3f,0x2b,0x3f,0x3f,0x3f,0x3f,0x24,0x01
	DCB 0x3f,0x31,0x3f,0x2a,0x2c,0x0c,0x3f,0x14,0x3f,0x07,0x34,0x06,0x3f,0x02,0x26,0x0f
	DCB 0x3f,0x19,0x10,0x0a,0x3f,0x3f,0x37,0x17,0x3f,0x11,0x1a,0x3f,0x3f,0x25,0x18,0x3f
;castlevania/golf/machrider/slalom
	DCB 0x0f,0x27,0x18,0x3f,0x3f,0x25,0x3f,0x34,0x16,0x13,0x3f,0x34,0x20,0x23,0x3f,0x0b
	DCB 0x3f,0x23,0x06,0x3f,0x1b,0x27,0x3f,0x22,0x3f,0x24,0x3f,0x3f,0x32,0x08,0x3f,0x03
	DCB 0x3f,0x37,0x26,0x33,0x11,0x3f,0x10,0x22,0x14,0x3f,0x00,0x09,0x12,0x0f,0x3f,0x30
	DCB 0x3f,0x3f,0x2a,0x17,0x0c,0x01,0x15,0x19,0x3f,0x2c,0x07,0x37,0x3f,0x05,0x3f,0x3f
;excitebike/excitebike-alt (probably not complete yet)
	DCB 0x3f,0x3f,0x1c,0x3f,0x1a,0x30,0x01,0x07,0x02,0x3f,0x3f,0x30,0x3f,0x3f,0x3f,0x30
	DCB 0x32,0x1c,0x11,0x12,0x3f,0x18,0x17,0x26,0x0c,0x3f,0x3f,0x02,0x16,0x3f,0x3f,0x21
	DCB 0x3f,0x3f,0x0f,0x37,0x3f,0x28,0x27,0x3f,0x29,0x3f,0x21,0x3f,0x11,0x3f,0x0f,0x3f
	DCB 0x31,0x3f,0x3f,0x06,0x0f,0x2a,0x30,0x3f,0x3f,0x28,0x3f,0x3f,0x13,0x3f,0x3f,0x3f
;battlecity/clucluland/iceclimber/smb/starluster/topgun?
	DCB 0x18,0x3f,0x1c,0x3f,0x3f,0x3f,0x01,0x17,0x10,0x3f,0x2a,0x3f,0x36,0x37,0x1a,0x39
	DCB 0x25,0x3f,0x12,0x3f,0x0f,0x3f,0x3f,0x26,0x3f,0x1b,0x22,0x19,0x04,0x0f,0x3a,0x21
	DCB 0x3f,0x0a,0x07,0x06,0x13,0x3f,0x00,0x15,0x0c,0x3f,0x11,0x3f,0x3f,0x38,0x3f,0x3f
	DCB 0x3f,0x30,0x07,0x16,0x3f,0x3b,0x30,0x3c,0x0f,0x27,0x3f,0x31,0x29,0x3f,0x11,0x09
;drmario/goonies/soccer
	DCB 0x0f,0x3f,0x3f,0x10,0x1a,0x30,0x31,0x3f,0x01,0x0f,0x36,0x3f,0x15,0x3f,0x3f,0x3c
	DCB 0x3f,0x3f,0x3f,0x12,0x19,0x18,0x17,0x3f,0x00,0x3f,0x3f,0x02,0x16,0x3f,0x3f,0x3f
	DCB 0x3f,0x3f,0x3f,0x37,0x3f,0x27,0x26,0x20,0x3f,0x04,0x22,0x3f,0x11,0x3f,0x3f,0x3f
	DCB 0x2c,0x3f,0x3f,0x3f,0x07,0x2a,0x28,0x3f,0x0a,0x3f,0x32,0x38,0x13,0x3f,0x3f,0x0c
;smb
;	DCB 0x00,0x00,0x00,0x00,0x00,0x00,0x0b,0x00,0x00,0x00,0x14,0x00,0x00,0x00,0x00,0x00
;	DCB 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
;	DCB 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
;	DCB 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x1b,0x00
;----------------------------------------------------------------------------
remap_pal
;map_palette	;(for VS unisys)	r0-r2,r4-r7 modified
;----------------------------------------------------------------------------

	ldr r5,=nes_rgb
	ldr r6,=MAPPED_RGB
	mov r7,#64*3
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
	subs r7,r7,#4
	bne nomap
	mov pc,lr
remap
	ldr r1,[r2,#-4]
mp1	ldrb r2,[r1],#1
	add r2,r2,r2,lsl#1
	ldrb r0,[r2,r5]!
	strb r0,[r6],#1
	ldrb r0,[r2,#1]
	strb r0,[r6],#1
	ldrb r0,[r2,#2]
	strb r0,[r6],#1
	subs r7,r7,#3
	bne mp1
	mov pc,lr

vslist	DCD 0xfff3f318,vs_palmaps+64*0 ;Freedom Force	RP2C04-0001
	DCD 0xf422f492,vs_palmaps+64*0 ;Gradius				RP2C04-0001
	DCD 0x8000809c,vs_palmaps+64*0 ;Hoogans Alley		RP2C04-0001
	DCD 0x80008281,vs_palmaps+64*0 ;Pinball				RP2C04-0001
	DCD 0xfff3fd92,vs_palmaps+64*0 ;Platoon				RP2C04-0001
	DCD 0x800080ce,vs_palmaps+64*1 ;(lady)Golf			RP2C04-0002
	DCD 0x80008053,vs_palmaps+64*1 ;Mach Rider			RP2C04-0002
	DCD 0xc008c062,vs_palmaps+64*1 ;Castlevania			RP2C04-0002
	DCD 0x8050812f,vs_palmaps+64*1 ;Slalom				RP2C04-0002
	DCD 0x85af863f,vs_palmaps+64*2 ;Excitebike			RP2C04-0003
	DCD 0x859a862a,vs_palmaps+64*2 ;Excitebike(a1)		RP2C04-0003
	DCD 0x8000810a,vs_palmaps+64*3 ;Super Mario Bros	RP2C04-0004
	DCD 0xb578b5de,vs_palmaps+64*3 ;Ice Climber			RP2C04-0004
	DCD 0xc298c325,vs_palmaps+64*3 ;Clu Clu Land		RP2C04-0004
	DCD 0x804c8336,vs_palmaps+64*3 ;Star Luster			RP2C04-0004
	DCD 0xc070d300,vs_palmaps+64*3 ;Battle City			RP2C04-0004
	DCD 0xc298c325,vs_palmaps+64*3 ;Top Gun				RP2C04-0004?
	DCD 0x800080ba,vs_palmaps+64*4 ;Soccer
	DCD 0xf007f0a5,vs_palmaps+64*4 ;Goonies
	DCD 0xff008005,vs_palmaps+64*4 ;Dr. Mario
;	DCD 0xf1b8f375,vs_palmaps+64*? ;Super Sky Kid		doesn't need palette
;	DCD 0xffdac0c4,vs_palmaps+64*? ;TKO Boxing			doesn't start
;	DCD 0xf958f88f,vs_palmaps+64*3 ;Super Xevious		doesn't start
	DCD 0
;----------------------------------------------------------------------------
paletteinit;	r0-r3 modified.
;called by ui.c:  void map_palette(char gammavalue)
;----------------------------------------------------------------------------
	stmfd sp!,{r4-r8,lr}
	bl remap_pal
	ldr r8,=0x05000100
	adr r6,nes_rgb15
	mov r4,#64
gloop0
	ldrh r0,[r6],#2
	strh r0,[r8],#2
	subs r4,r4,#1
	bne gloop0

	ldr r6,=MAPPED_RGB
	mov r7,r6
	ldr r1,=gammavalue
	ldrb r1,[r1]	;gamma value = 0 -> 4
	mov r4,#64			;pce rgb, r1=R, r2=G, r3=B
gloop					;map 0bbbbbgggggrrrrr  ->  0bbbbbgggggrrrrr
	ldrb r0,[r6],#1
	bl gammaconvert
	mov r5,r0

	ldrb r0,[r6],#1
	bl gammaconvert
	orr r5,r5,r0,lsl#5

	ldrb r0,[r6],#1
	bl gammaconvert
	orr r5,r5,r0,lsl#10

	strh r5,[r7],#2
	strh r5,[r8],#2
	subs r4,r4,#1
	bne gloop

	ldmfd sp!,{r4-r8,lr}
	bx lr

;----------------------------------------------------------------------------
gammaconvert;	takes value in r0(0-0xFF), gamma in r1(0-4),returns new value in r0=0x1F
;----------------------------------------------------------------------------
	rsb r2,r0,#0x100
	mul r3,r2,r2
	rsbs r2,r3,#0x10000
	rsb r3,r1,#4
	orr r0,r0,r0,lsl#8
	mul r2,r1,r2
	mla r0,r3,r0,r2
	mov r0,r0,lsr#13

	bx lr
;----------------------------------------------------------------------------
PaletteTxAll
;----------------------------------------------------------------------------
	stmfd sp!,{r0-r4}

	;monochrome mode stuff
	ldr r4,=g_ppuctrl1
	ldrb r4,[r4]

	mov r2,#0x20
pxall
	ldr r1,=nes_palette
	ldrb r0,[r1,r2]	;load from nes palette
	;monochrome test
	tst r4,#1
	andne r0,r0,#0x30

	ldr r1,=MAPPED_RGB
	ldr r0,[r1,r0,lsl#1]	;lookup RGB
	ldr r1,=agb_pal
	mov r3,r2,lsl#1
	strh r0,[r1,r3]	;store in agb palette
	subs r2,r2,#1
	bne pxall
	
	ldmfd sp!,{r0-r4}
	bx lr

Update_Palette
	stmfd sp!,{r0-addy}
	mov r8,#AGB_PALETTE		;palette transfer
	ldr addy,=agb_pal
up8	ldmia addy!,{r0-r7}
	stmia r8,{r0,r1}
	add r8,r8,#32
	stmia r8,{r2,r3}
	add r8,r8,#32
	stmia r8,{r4,r5}
	add r8,r8,#32
	stmia r8,{r6,r7}
	add r8,r8,#0x1a0
	tst r8,#0x200
	bne up8			;(2nd pass: sprite pal)
	ldmfd sp!,{r0-addy}
	bx lr

;----------------------------------------------------------------------------
PPU_init	;(called from main.c) only need to call once
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

	mov r1,#REG_BASE
	mov r0,#0x0008
	strh r0,[r1,#REG_DISPSTAT]	;vblank en

	add r0,r1,#REG_BG0HOFS		;DMA0 always goes here
	str r0,[r1,#REG_DM0DAD]
	mov r0,#1					;1 word transfer
	strh r0,[r1,#REG_DM0CNT_L]
	ldr r0,=DMA0BUFF+4			;dmasrc=
	str r0,[r1,#REG_DM0SAD]

	str r1,[r1,#REG_DM1DAD]		;DMA1 goes here

	add r2,r1,#REG_IE
	mov r0,#-1
	strh r0,[r2,#2]		;stop pending interrupts
	ldr r0,=0x1091
	strh r0,[r2]		;key,vblank,timer1,serial interrupt enable
	mov r0,#1
	strh r0,[r2,#8]		;master irq enable

	ldr r1,=AGB_IRQVECT
	ldr r2,=irqhandler
	str r2,[r1]

	bx addy
;----------------------------------------------------------------------------
PPU_reset	;called with CPU reset
;----------------------------------------------------------------------------
	stmfd sp!,{globalptr,lr}
	ldr globalptr,=|wram_globals0$$Base|
	mov r0,#0
	strb r0,ppuctrl0	;NMI off
	strb r0,ppuctrl1	;screen off
	strb r0,ppustat		;flags off

	str r0,windowtop

	;strb r0,toggle
	;mov r0,#1
	;strb r0,vramaddrinc

	mov r0,#0x0440
	ldr r1,=ctrl1old
	str r0,[r1]
	orr r0,r0,r0,lsl#16
	ldr r1,=DMA1BUFF	;clear DISPCNT+DMA1BUFF
	mov r2,#404/2
	bl filler_

	mov r0,#0
;	ldr r1,=NES_VRAM
;	mov r2,#0x3000/4
	ldr r1,=NES_VRAM+0x2000
	mov r2,#0x1000/4
	bl filler_			;clear nes VRAM

	;ldr r1,=MEM_AGB_SCREEN	;clear AGB BG
	;mov r2,#32*32*2
	;bl filler_

	mov r0,#0xe0		;was 0xe0
	mov r1,#AGB_OAM
	mov r2,#0x100
	bl filler_			;no stray sprites please
	ldr r1,=OAM_BUFFER1
	mov r2,#0x180
	bl filler_

	bl paletteinit		;do palette mapping (for VS) & gamma
	ldmfd sp!,{globalptr,lr}
	bx lr
;----------------------------------------------------------------------------
showfps_		;fps output, r0-r3=used.
;----------------------------------------------------------------------------
	ldr r1,=fpschk
	ldrb r0,[r1]
	subs r0,r0,#1
	movmi r0,#59
	strb r0,[r1]
	bxpl lr					;End if not 60 frames has passed

	ldr r0,=fpsenabled
	ldrb r0,[r0]
	tst r0,#1
	bxeq lr					;End if not enabled

	ldr r0,fpsvalue
	cmp r0,#0
	bxeq lr					;End if fps==0, to keep it from appearing in the menu
	mov r1,#0
	str r1,fpsvalue

	mov r1,#100
	swi 0x060000			;Division r0/r1, r0=result, r1=remainder.
	add r0,r0,#0x30
	ldr r2,=fpstext+5
	strb r0,[r2]
	mov r0,r1
	mov r1,#10
	swi 0x060000			;Division r0/r1, r0=result, r1=remainder.
	add r0,r0,#0x30
	ldr r2,=fpstext+6
	strb r0,[r2]
	add r1,r1,#0x30
	ldr r2,=fpstext+7
	strb r1,[r2]
	

	ldr r0,=fpstext
	ldr r2,=DEBUGSCREEN
db1
	ldrb r1,[r0],#1
	orr r1,r1,#0x4100
	strh r1,[r2],#2
	tst r2,#15
	bne db1

	bx lr
;----------------------------------------------------------------------------
debug_		;debug output, r0=val, r1=line, r2=used.
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
 ]
	bx lr
;----------------------------------------------------------------------------
	AREA wram_code6, CODE, READWRITE
;----------------------------------------------------------------------------
;this stuff can't be in rom!
fpstext DCB "FPS:    "
fpsenabled DCB 0
fpschk	DCB 0
gammavalue DCB 0
		DCB 0
;----------------------------------------------------------------------------
VRAM_chr2;	0000-1fff
;----------------------------------------------------------------------------
; p pp__ ____ ____
; vram_address = vram_map[addy >> 10]
; find nes_char_map entry...
; nes_page = nes_char_map[addy >> 10]
; search through agb_bg_map for pages that match nes_page, update agb_vram as necessary
; 
;	cmp addy,#0x660
;	beq VRAM_chr2
	stmfd sp!,{r0-r7,lr}
	mov r2,addy,lsr#10   ;r2 = vram mapped page
	bic addy,addy,#0xFC00  ;addy = offset inside vram page
	ldr r3,=vram_map
	ldr r3,[r3,r2,lsl#2] ;r3 = vram base address
	strb r0,[addy,r3]
	adrl r4,nes_chr_map
	ldrb r4,[r4,r2]      ;r4 = vram_page in memory map
	adrl r5,agb_bg_map   ;r5 = address inside agb_bg_map
	mov r6,#0            ;r6 = page number for bg_map
	bic addy,addy,#8
bank_search_loop
	ldrb r0,[r5,r6]
	cmp r0,r4
	bleq write_new_gba_vram
	add r6,r6,#1
	cmp r6,#16
	bne bank_search_loop

	add r5,r5,#16
	mov r6,#0
bank_search_loop_2
	ldrb r0,[r5,r6]
	cmp r0,r4
	bleq write_new_gba_vram_2
	add r6,r6,#1
	cmp r6,#8
	bne bank_search_loop_2
	
	ldmfd sp!,{r0-r7,pc}
	
write_new_gba_vram_2
	;for objs
;	mov r1,r6,lsr#2
;	mov r1,r1,lsl#13
;	ldr r7,=AGB_VRAM+0x10000
;	add r7,r1,r7
	ldr r7,=AGB_VRAM+0x10000
	mov r0,r6,lsr#2
	add r7,r7,r0,lsl#13
	b write_new_gba_vram_entrypoint

write_new_gba_vram
	;r6 = page number
	;AGB_VRAM address = (pagenum & 3)*0x800 + (pagenum>>2)*0x4000
	;offset = tile*32 + row*4
	;       = (addy/16)*32 + (addy & 7)*4
	ldr r7,=AGB_VRAM
	mov r0,r6,lsr#2
	add r7,r7,r0,lsl#14
write_new_gba_vram_entrypoint
	and r0,r6,#3
	add r7,r7,r0,lsl#11


	and r0,addy,#7
	mov r1,addy,lsr#4
	add r7,r7,r0,lsl#2
	add r7,r7,r1,lsl#5
	
	mov r2,r3
	ldrb r0,[r2,addy]!	;read 1st plane
	ldrb r1,[r2,#8]		;read 2nd plane
	
	adr r2,chr_decode
	ldr r0,[r2,r0,lsl#2]
	ldr r1,[r2,r1,lsl#2]
	orr r0,r0,r1,lsl#1
	
	str r0,[r7]
	mov pc,lr


	AREA wram_code1, CODE, READWRITE
irqhandler	;r0-r3,r12 are safe to use
;----------------------------------------------------------------------------
	mov r2,#REG_BASE
	mov r3,#REG_BASE
	ldr r1,[r2,#REG_IE]!
	and r1,r1,r1,lsr#16	;r1=IE&IF
	ldrh r0,[r3,#-8]
	orr r0,r0,r1
	strh r0,[r3,#-8]

		;---these CAN'T be interrupted
		ands r0,r1,#0x80
		strneh r0,[r2,#2]		;IF clear
		bne serialinterrupt
		;---
		adr r12,irq0

		;---these CAN be interrupted
		ands r0,r1,#0x01
		ldrne r12,vblankfptr
		bne jmpintr
		ands r0,r1,#0x10
		ldrne r12,=timer1interrupt
		;----
		moveq r0,r1		;if unknown interrupt occured clear it.
jmpintr
	strh r0,[r2,#2]		;IF clear

	mrs r3,spsr
	stmfd sp!,{r3,lr}
	mrs r3,cpsr
	bic r3,r3,#0x9f
	orr r3,r3,#0x1f			;--> Enable IRQ & FIQ. Set CPU mode to System.
	msr cpsr_cf,r3
	stmfd sp!,{lr}
	adr lr,irq0

	mov pc,r12


irq0
	ldmfd sp!,{lr}
	mrs r3,cpsr
	bic r3,r3,#0x9f
	orr r3,r3,#0x92        		;--> Disable IRQ. Enable FIQ. Set CPU mode to IRQ
	msr cpsr_cf,r3
	ldmfd sp!,{r0,lr}
	msr spsr_cf,r0
vbldummy
	bx lr
;----------------------------------------------------------------------------
vblankfptr DCD vbldummy			;later switched to vblankinterrupt
twitch	DCB 0
flicker DCB 1
		DCB 0		;was PAL60
		DCB 0
vblankinterrupt;
;----------------------------------------------------------------------------
	stmfd sp!,{r4-r7,globalptr,lr}
	ldr globalptr,=|wram_globals0$$Base|

	ldr r0,emuflags
	tst r0,#PALTIMING
	beq nopal60
	ldrb r0,PAL60
	add r0,r0,#1
	cmp r0,#6
	movpl r0,#0
	strb r0,PAL60
nopal60
	bl_long showfps_


	ldr r2,=DMA0BUFF	;setup DMA buffer for scrolling:
	add r3,r2,#160*4
	ldr r1,dmascrollbuff
	ldrb r0,emuflags+1
	cmp r0,#SCALED
	bhs vblscaled

vblunscaled
	ldr r0,windowtop+12
	add r1,r1,r0,lsl#2		;(unscaled)
vbl6
	ldmia r1!,{r4-r7}
	add r4,r4,r0,lsl#16
	add r5,r5,r0,lsl#16
	add r6,r6,r0,lsl#16
	add r7,r7,r0,lsl#16
	stmia r2!,{r4-r7}
	cmp r2,r3
	bmi vbl6

	ldr r3,=DISPCNTBUFF
	ldr r4,=BG0CNTBUFF
	add r3,r3,r0,lsl#1
	add r4,r4,r0,lsl#1
	b vbl5

vblscaled					;(scaled)
	mov r4,#YSTART*65536
	add r1,r1,#2

	ldrb r5,flicker
	ldrb r0,twitch
	eors r0,r0,r5
	strb r0,twitch
		ldrh r5,[r1],#YSTART*4-2 ;adjust vertical scroll to avoid screen wobblies
	ldreq r0,[r1],#4
	addeq r0,r0,r4
	streq r0,[r2],#4
		ldr r0,adjustblend
		add r0,r0,r5
		ands r0,r0,#3
		str r0,totalblend
		beq vbl3
		cmp r0,#2
		bhi vbl2
		addmi r1,r1,#4
vbl1
		addmi r4,r4,#0x10000
		ldr r0,[r1],#4
		add r0,r0,r4
		str r0,[r2],#4
vbl2	ldr r0,[r1],#4
		add r0,r0,r4
		str r0,[r2],#4
vbl3	ldr r0,[r1],#8
		add r0,r0,r4
		str r0,[r2],#4
	cmp r2,r3
	bmi vbl1

	ldr r3,=DMA1BUFF
	ldr r4,=DMA3BUFF
vbl5

	mov r5,#REG_BASE
	strh r5,[r5,#REG_DM0CNT_H]		;DMA0 stop
	strh r5,[r5,#REG_DM1CNT_H]		;DMA1 stop
	strh r5,[r5,#REG_DM3CNT_H]		;DMA3 stop

	add r7,r5,#REG_DM3SAD

	ldr r0,dmaoambuffer				;DMA3 src, OAM transfer:
	mov r1,#AGB_OAM					;DMA3 dst
	mov r2,#0x84000000				;noIRQ hblank 32bit repeat incsrc fixeddst
	orr r2,r2,#0x80					;128 words (512 bytes)
	stmia r7,{r0-r2}				;DMA3 go

	ldr r0,=DMA0BUFF				;setup HBLANK DMA for display scroll:
	ldr r0,[r0]
	str r0,[r5,#REG_BG0HOFS]		;set 1st value manually, HBL is AFTER 1st line
	ldr r0,=0xA660					;noIRQ hblank 32bit repeat incsrc inc_reloaddst
	strh r0,[r5,#REG_DM0CNT_H]		;DMA0 go

	ldrh r0,[r3],#2					;setup HBLANK DMA for DISPCNT (BG/OBJ enable)
	strh r0,[r5,#REG_DISPCNT]		;set 1st value manually, HBL is AFTER 1st line
	str r3,[r5,#REG_DM1SAD]			;DMA1 src
	ldr r6,=0xA2400001				;noIRQ hblank 16bit repeat incsrc fixeddst, 1 word transfer
	str r6,[r5,#REG_DM1CNT_L]		;DMA1 go

	ldrh r2,[r4],#2					;setup HBLANK DMA for BG CHR
	strh r2,[r5,#REG_BG0CNT]!		;DMA3 dst
	stmia r7,{r4-r6}				;DMA3 go

	ldmfd sp!,{r4-r7,globalptr,pc}

totalblend	DCD 0
;----------------------------------------------------------------------------
newframe	;called at line 0	(r0-r9 safe to use)
;----------------------------------------------------------------------------
	str lr,[sp,#-4]!

	bl updateOBJCHR
;	ldr r0,nes_chr_map		; moved to 6502.s
;	ldr r1,nes_chr_map+4
;	str r0,old_chr_map
;	str r1,old_chr_map+4
;-----------------------
	ldr r0,ctrl1old
	ldr r1,ctrl1line
	mov addy,#239
	bl ctrl1finish
;-----------------------
	ldr r0,scrollXold
	ldr r1,scrollXline
	mov addy,#239
	bl scrollXfinish
;--------------------------
	ldr r0,scrollYold
	ldr r1,scrollYline
	mov addy,#239
	bl scrollYfinish
	mov r0,#0
	str r0,ctrl1line
	str r0,scrollXline
	str r0,scrollYline
	ldr r0,scrollY			;r0=y
	str r0,scrollYold
;--------------------------
	bl chrfinish
;------------------------
;	ldr r0,scrollY
;	mov r1,#0
;	bl initY


	ldr r0,scrollbuff
	ldr r1,dmascrollbuff
	str r1,scrollbuff
	str r0,dmascrollbuff

	ldr r0,oambuffer
	ldr r1,tmpoambuffer
	str r0,tmpoambuffer
	str r1,dmaoambuffer

	adrl r0,windowtop		;load wtop, store in wtop+4.......load wtop+8, store in wtop+12
	ldmia r0,{r1-r3}		;load with post increment
	stmib r0,{r1-r3}		;store with pre increment

	ldrb r0,emuflags+1		;refresh DMA1,DMA2 buffers
	cmp r0,#SCALED			;not needed for unscaled mode..
	bmi nf7					;(DMA'd directly from dispcntbuff/bg0cntbuff)

	ldr r1,=DISPCNTBUFF+YSTART*2		;(scaled)
	ldr r2,=DMA1BUFF
	bl nf0

	ldr r1,=BG0CNTBUFF+YSTART*2
	ldr r2,=DMA3BUFF
	adr lr,nf7

nf0	add r3,r2,#160*2
		ldrb r0,twitch
		tst r0,#1
	ldrneh r0,[r1],#2
	strneh r0,[r2],#2
		ldr r0,totalblend
		ands r0,r0,#3
		beq nf21
		cmp r0,#2
		bmi nf22
		addeq r1,r1,#2
nf20	ldrh r0,[r1],#2
		strh r0,[r2],#2
nf21	ldrh r0,[r1],#2
		strh r0,[r2],#2
nf22	ldrh r0,[r1],#4
		strh r0,[r2],#2
	cmp r2,r3
	bmi nf20
	mov pc,lr
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
	ldr pc,[pc,r0,lsl#2]
	DCD 0
PPU_read_tbl
	DCD empty_PPU_R	;$2000
	DCD empty_PPU_R	;$2001
	DCD stat_R		;$2002
	DCD empty_PPU_R	;$2003
	DCD empty_PPU_R	;$2004
	DCD empty_PPU_R	;$2005
	DCD empty_PPU_R	;$2006
	DCD vmdata_R	;$2007
;----------------------------------------------------------------------------
PPU_W;
;----------------------------------------------------------------------------
	and r2,addy,#7
	ldr pc,[pc,r2,lsl#2]
	DCD 0
PPU_write_tbl
	DCD ctrl0_W		;$2000
	DCD ctrl1_W		;$2001
	DCD void		;$2002
	DCD void		;$2003
	DCD void		;$2004
	DCD bgscroll_W	;$2005
	DCD vmaddr_W	;$2006
	DCD vmdata_W	;$2007


;----------------------------------------------------------------------------
empty_PPU_R
;----------------------------------------------------------------------------
	mov r0,#0
	mov pc,lr
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
	and r1,r1,#1			; should be 1
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
	ldrb r1,ppuctrl1
	strb r0,ppuctrl1
	;has monochrome mode bit changed?
	eor r1,r1,r0
	tst r1,#0x01
	;update palette
	mov r1,lr
	blne_long PaletteTxAll
	mov lr,r1

	mov r1,#0x0440		;1d sprites, BG2 enable. DISPCNTBUFF startvalue. 0x0440
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
	ldrb r0,emuflags       ;probably in a polling loop
	tst r0,#USEPPUHACK
	andne cycles,cycles,#CYC_MASK		;let's help out

	mov r0,#0
	strb r0,toggle

	ldr r0,sprite0y		;sprite0 hit?
	ldr r1,scanline
	cmp r1,r0
;	ble nosprh
;	ldrb r0,sprite0x	;for extra high resolution sprite0 hit
;	ldr r1,cyclesperscanline ;the store is in IO.s
;	sub r1,r1,cycles
;	cmp r1,r0
	ldrb r0,ppustat
	orrhi r0,r0,#0x40
;nosprh
	bic r1,r0,#0x80		;vbl flag clear
	strb r1,ppustat

	mov pc,lr
;----------------------------------------------------------------------------
bgscroll_W	;(2005)
;----------------------------------------------------------------------------
	ldrb r1,toggle
	eors r1,r1,#1
	strb r1,toggle
	beq bgscrollY
bgscrollX
	strb r0,scrollX
newX			;ctrl0_W, loadstate jumps here
	ldr r0,scrollX
newX2			;vmaddr_W jumps here
	adr r1,scrollXold
	swp r0,r0,[r1]		;r0=lastval

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
	ldr r0,scrollY		;r0=y
	add r0,r0,#1
	adr r1,scrollYold
	swp r0,r0,[r1]		;r0=lastval

	adr r2,scrollYline
	ldr addy,scanline	;addy=scanline
	cmp addy,#239
	movhi addy,#239
	swp r1,addy,[r2]	;r1=lastline, lastline=scanline

scrollYfinish		;newframe jumps here
	stmfd sp!,{r3,r4,lr}
	and r4,r0,#0xff
	cmp r4,#239		;if(y&ff>239)
	eorhi r0,r0,#0x100	;	y^=$100
	movhi r4,#240		;	r4=240 (lines to NT end)
				;else
	rsbls r4,r4,#240	;	r4=240-y&ff
	sub r0,r0,r1		;y-=scanline
	ldr r2,scrollbuff
	add r2,r2,#2		;r2+=2, flag 2006 write
	add r3,r2,addy,lsl#2	;r3=end2
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

scrollYold DCD 0 ;last write
scrollYline DCD 0 ;..was when?
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

	and r1,r0,#0x3c00
	adr r2,vram_map
	ldr r1,[r2,r1,lsr#8]
	bic r0,r0,#0xfc00

	ldrb r1,[r1,r0]
	ldrb r0,readtemp
	str r1,readtemp
	mov pc,lr
palread
	and r0,r0,#0x1f
	adr r1,nes_palette
	ldrb r0,[r1,r0]
	mov pc,lr
;----------------------------------------------------------------------------
vmdata_W	;(2007)
;----------------------------------------------------------------------------
	ldr addy,vramaddr
	ldrb r1,vramaddrinc
	bic addy,addy,#0xfc000 ;AND $3fff
	add r2,addy,r1
	str r2,vramaddr

	and r1,addy,#0x3c00
	adr r2,vram_write_tbl
	ldr pc,[r2,r1,lsr#8]
;----------------------------------------------------------------------------
VRAM_chr;	0000-1fff
;----------------------------------------------------------------------------
	ldr r2,=NES_VRAM
	strb r0,[r2,addy]

	bic addy,addy,#8
	ldrb r0,[r2,addy]!	;read 1st plane
	ldrb r1,[r2,#8]		;read 2nd plane

	adr r2,chr_decode
	ldr r0,[r2,r0,lsl#2]
	ldr r1,[r2,r1,lsl#2]
	orr r0,r0,r1,lsl#1

	and r2,addy,#7		;r2=tile line#
	add addy,addy,r2
	add r1,addy,addy
	add r1,r1,#AGB_VRAM		;AGB BG tileset
	add addy,r1,#0x10000
	tst r1,#0x2000		;1st or 2nd page?
	addne r1,r1,#0x2000	;0000/4000 for BG, 10000/12000 for OBJ

	str r0,[r1]
	str r0,[addy]

	mov pc,lr
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
	add addy,addy,addy	;lsl#1
	ldrh r1,[r2,addy]	;use old color
	and r1,r1,#0xf000
	orr r1,r0,r1
	strh r1,[r2,addy]	;write tile#
		cmp r0,#0xfd	;mapper 9 shit..
		bhs_long mapper9BGcheck
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
		tst addy,#0x0f
		moveq addy,#0	;$10 mirror to $00
	adr r1,nes_palette
	strb r0,[r1,addy]	;store in nes palette
	
	;monochrome mode stuff
	ldrb r1,ppuctrl1
	tst r1,#0x01
	andne r0,r0,#0x30

	add r0,r0,r0
	ldr r1,=MAPPED_RGB
;	ldr r0,[r1,r0,lsl#1]	;lookup RGB, unaligned read.
	ldrh r0,[r1,r0]			;lookup RGB
	adr r1,agb_pal
	add addy,addy,addy	;lsl#1
	strh r0,[r1,addy]	;store in agb palette
	mov pc,lr
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
	DCD NES_VRAM+0x2C00 ;$3xxx=?
	DCD NES_VRAM+0x2C00
	DCD NES_VRAM+0x2C00
	DCD NES_VRAM+0x2C00

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
FPSValue
	DCD 0
AGBinput		;this label here for main.c to use
	DCD 0 ;AGBjoypad (why is this in ppu.s again?  um.. i forget)
EMUinput	DCD 0 ;NESjoypad (this is what NES sees)
	DCD 0 ;adjustblend
wtop	DCD 0,0,0,0 ;windowtop  (this label too)   L/R scrolling in unscaled mode
ppustate
	DCD 0 ;vramaddr
	DCD 0 ;vramaddr2 (temp)
	DCD 0 ;scrollX
	DCD 0 ;scrollY
	DCD 0 ;sprite0y
	DCD 0 ;readtemp

	DCB 0 ;sprite0x
	DCB 1 ;vramaddrinc
	DCB 0 ;ppustat
	DCB 0 ;toggle
	DCB 0 ;ppuctrl0
	DCB 0 ;ppuctrl0frame	;state of $2000 at frame start
g_ppuctrl1
	DCB 0 ;ppuctrl1
	DCB 0 ;ppuoamadr
;...update load/savestate if you move things around in here
;----------------------------------------------------------------------------
	END

