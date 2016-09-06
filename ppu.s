; games which don't load state:
;  metal max (chinese hack)

SCREEN_LEFT EQU 8
BG_VRAM EQU AGB_VRAM
SPR_VRAM_ADD EQU 0x10000
SPR_VRAM EQU AGB_VRAM+SPR_VRAM_ADD


;BUGS:
;	RC PRO AM (mapper 7 version) FAILS
;	Rad racer doesn't like PPU Hack
;	Dizzy The Adventurer gets corrupt tiles, probably also Fantastic Adventures of Dizzy as well
;		also pinbot gets them
;	pinbot high score table crash  (maybe MMC3 related)
;	High Hopes doesn't work (MM3 related)
;	Sometimes games flash crap on the screen for a frame, probably related to not displaying DISPCNTBUFF in sync with rest of buffers
;	Delete Menu displays crap when no files remaining
;	Rocket Ranger and Bill & Ted fail to boot
;	sound state still incomplete

;TODO:
;	*Speedup by copying to EWRAM
;	The 800 pound gorilla: Needs Correct MMC3 IRQs
;	fix up the scaling code, which causes artifacts which do not appear in unscaled
;	Hack for sprite priority if it detects NO$GBA
;	Software Sound for square waves
;	Maybe check at the end of frame for any obvious branch speedhacks (like Bxx 4/5)
;	Real Punchout Mode (using windowing)
;	change palette update time (or support palette changing per scanline)

;old TODO:
;	call init_cache less often
;
;	fix vertical scrolling when screen is off for some scanlines?
;
;	savestates: check "currently loaded game" first.  Also allow AP32 compressed games
;
;	fix savestates - Import old GBAMP savestates
;NOTE:
;	maybe modify PPU_R to favor status reads?  nahhhh...


	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE cart.h
	INCLUDE io.h
	INCLUDE 6502.h
	INCLUDE sound.h
	INCLUDE mappers.h
	INCLUDE link.h

	EXPORT g_nextx
	EXPORT g_scrollX
	
	EXPORT remap_pal  ;for build logs
	[ USE_BG_CACHE
	EXPORT display_bg
	]
	
	EXPORT scroll_threshhold_mod
	
	EXPORT DMA0BUFF
	EXPORT DMA3BUFF
	EXPORT DMA1BUFF
	EXPORT DISPCNTBUFF1
	EXPORT DISPCNTBUFF2
	EXPORT SCROLLBUFF1
	EXPORT SCROLLBUFF2
	EXPORT BG0CNTBUFF1
	EXPORT BG0CNTBUFF2

	[ DIRTYTILES
	EXPORT dirty_rows
	EXPORT dirty_tiles
	]
	
	[ MIXED_VRAM_VROM
	EXPORT VRAM_chr3
	]
	
;	EXPORT nesoambuff
	EXPORT MAPPED_RGB
	
	EXPORT findsprite0
	
	EXPORT spr_cache_map
	EXPORT spr_cache
	EXPORT spr_cache_disp
	
	[ USE_BG_CACHE
	EXPORT _bg_cache_full
	]
	
	EXPORT ppustat_
	EXPORT ppustat_savestate
	EXPORT update_Y_hit
	EXPORT stat_R_simple
	EXPORT stat_R_clearvbl
	EXPORT stat_R_sameline

	EXPORT g_ppuctrl0frame
	
	IMPORT recache_sprites
	IMPORT sprite_cache_size

	EXPORT NESOAMBUFF1
	EXPORT NESOAMBUFF2
	
	EXPORT BANKBUFFER1
	EXPORT BANKBUFFER2
	
	EXPORT _dmabankbuffer
	EXPORT _dmanesoambuff
	
	EXPORT update_bankbuffer

	EXPORT _nesoambuff
	EXPORT _dmanesoambuff
	
	EXPORT g_has_vram
	EXPORT g_bankable_vrom
	EXPORT g_vram_page_mask
	EXPORT g_vram_page_base
	

	[ DIRTYTILES
	EXPORT nes_chr_update
;	EXPORT recent_tiles
;	EXPORT dmarecent_tiles
;	EXPORT recent_tilenum
;	EXPORT dmarecent_tilenum
	]
	EXPORT newframe_nes_vblank
	EXPORT dma_W
	EXPORT PPU_init
	EXPORT PPU_reset
	EXPORT PPU_R
	EXPORT PPU_W
;	EXPORT agb_nt_map
	EXPORT VRAM_name0
	EXPORT VRAM_name1
	EXPORT VRAM_name2
	EXPORT VRAM_name3

	EXPORT _vram_map
	EXPORT _vram_write_tbl
	EXPORT vram_write_direct
;	EXPORT vram_read_direct
	EXPORT VRAM_chr
	EXPORT debug_
	EXPORT AGBinput
	EXPORT EMUinput
	EXPORT paletteinit
	EXPORT PaletteTxAll
	EXPORT Update_Palette
	EXPORT newframe
;	EXPORT agb_pal
	EXPORT ppustate
	EXPORT writeBG
	EXPORT wtop
	EXPORT gammavalue
	EXPORT ctrl0_W
	EXPORT ctrl1_W
	EXPORT newX
	EXPORT newY
	EXPORT newframe_set0
	EXPORT g_twitch
	EXPORT g_flicker
	EXPORT fpsenabled
	EXPORT FPSValue
	EXPORT vbldummy
	EXPORT vblankfptr
	EXPORT vblankinterrupt
	EXPORT NES_VRAM
	EXPORT _scrollbuff
	EXPORT _dmascrollbuff
	EXPORT _bg0cntbuff
	
	EXPORT g_PAL60
	EXPORT novblankwait
	
	EXPORT stat_R_ppuhack
	EXPORT PPU_read_tbl

	EXPORT build_chr_decode
	
	EXPORT _nes_palette

	EXPORT g_frameready
	EXPORT g_firstframeready


 AREA rom_code, CODE, READONLY

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
	DCB 67,47,0, 0,71,0, 0,81,0, 0,63,23, 27,63,95, 0,0,0, 0,0,0, 0,0,0
	DCB 188,188,188, 0,115,239, 35,59,239, 131,0,243, 191,0,191, 231,0,91, 219,43,0, 203,79,15
	DCB 139,115,0, 0,151,0, 0,171,0, 0,147,59, 0,131,139, 49,49,49, 0,0,0, 0,0,0
	DCB 255,255,255, 63,191,255, 95,151,255, 167,139,253, 247,123,255, 255,119,183, 255,119,99, 255,155,59
	DCB 243,191,63, 131,211,19, 79,223,75, 88,248,152, 0,235,219, 102,102,102, 0,0,0, 0,0,0
	DCB 255,255,255, 171,231,255, 199,215,255, 215,203,255, 255,199,255, 255,199,219,255, 191,179,255, 219,171
	DCB 255,231,163, 227,255,163, 171,243,191, 179,255,207, 159,255,243, 209,209,209, 0,0,0, 0,0,0

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

nes_rgb15
	INCBIN nespal.bin

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
	DCD 0, vs_palmaps+64*3 ;prevent garbage palette for non-matched rom
;----------------------------------------------------------------------------
paletteinit;	r0-r3 modified.
;called by ui.c:  void map_palette(char gammavalue)
;----------------------------------------------------------------------------
	stmfd sp!,{r4-r10,lr}
	ldr globalptr,=GLOBAL_PTR_BASE
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

	ldmfd sp!,{r4-r10,lr}
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

	mov r2,#0x1F
pxall
	adr r1,nes_palette
	ldrb r0,[r1,r2]	;load from nes palette
	;monochrome test
	tst r4,#1
	andne r0,r0,#0x30

	ldr r1,=MAPPED_RGB
	add r0,r0,r0
	ldrh r0,[r1,r0]	;lookup RGB
	adr r1,agb_pal
	mov r3,r2,lsl#1
	strh r0,[r1,r3]	;store in agb palette
	subs r2,r2,#1
	bpl pxall
	
	ldmfd sp!,{r0-r4}
	bx lr

Update_Palette
	stmfd sp!,{r0-addy}
	mov r8,#AGB_PALETTE		;palette transfer
	adr addy,agb_pal
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


build_chr_decode
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
	
	;store canary 1
	ldr r0,=0xDEADBEEF
	str r0,[r2]
	
	
	bx lr
	
	
	
	
;----------------------------------------------------------------------------
PPU_init	;(called from main.c) only need to call once
;----------------------------------------------------------------------------
	mov addy,lr

	bl build_chr_decode

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
	ldr globalptr,=GLOBAL_PTR_BASE
	mov r0,#0
	strb r0,ppuctrl0	;NMI off
	strb r0,ppuctrl1	;screen off
	
	ldr r1,=ppustat_
	strb r0,[r1]	;flags off
	ldr r2,=stat_R_simple
	ldr r1,=PPU_read_tbl+8
	str r2,[r1]
	str r2,stat_r_simple_func

	strb r0,windowtop

	;strb r0,toggle
	;mov r0,#1
	;strb r0,vramaddrinc

	mov r0,#0x0440
	adrl r1,ctrl1old
	str r0,[r1]
	orr r0,r0,r0,lsl#16
	
	;clear dispcnt buffers
	ldr r1,=DISPCNTBUFF1
	mov r2,#240/2
	bl filler_
	ldr r1,=DISPCNTBUFF2
	mov r2,#240/2
	bl filler_

	mov r0,#0
;	ldr r1,=NES_VRAM
;	mov r2,#0x3000/4
;	bl filler_
	ldr r1,=NES_VRAM2
	mov r2,#0x800/4
	bl filler_			;clear nes VRAM
;;;;might not want to do this for COMPY or GBAMP
;;;;
;	ldr r1,=NES_VRAM4
;	mov r2,#0x800/4
;	bl filler_
;;;;

	[ DIRTYTILES
	;clear dirtytiles and dirtyrows
	ldr r1,=dirty_tiles
	mov r2,#548/4
	bl filler_
	
	;clear RECENT_TILENUM
	mvn r0,#0
	ldr r1,=RECENT_TILENUM1
	mov r2,#(MAX_RECENT_TILES/2)+1
	bl filler_
	ldr r1,=RECENT_TILENUM2
	mov r2,#(MAX_RECENT_TILES/2)+1
	bl filler_
	]

	;ldr r1,=MEM_AGB_SCREEN	;clear AGB BG
	;mov r2,#32*32*2
	;bl filler_

	mov r0,#0xe0		;was 0xe0
	mov r1,#AGB_OAM
	mov r2,#0x100
	bl filler_			;no stray sprites please
	
	mov r0,#0xF0
	ldr r1,=NESOAMBUFF1
	str r1,nextnesoambuff
	mov r2,#0x40
	bl filler_

	ldr r1,=NESOAMBUFF2
	str r1,nesoambuff
	str r1,dmanesoambuff
	mov r2,#0x40
	bl filler_
	
	mvn r0,#0
	str r0,nes_chr_map
	str r0,nes_chr_map+4

	bl self_modify_reset

	;erase bankbuffer?
	;set buffer line numbers to zero?
	;erase all buffers?
	;erase GBA VRAM corresponding to graphics?
	;
	;
	bl paletteinit		;do palette mapping (for VS) & gamma
	
	
	
	ldmfd sp!,{globalptr,lr}
	bx lr

nop_instruction
	nop

self_modify_reset
	[ DIRTYTILES
	[ MIXED_VRAM_VROM
	ldrb r1,bankable_vrom
	ldrb r2,has_vram
	tst r1,r2
	

	ldrne r0,=(consume_recent_tiles_2_entry-frt_m1-8)/4
	ldreq r0,=(consume_recent_tiles_entry-frt_m1-8)/4
	ldr r1,=frt_m1
	strh r0,[r1,#frt_m1-frt_m1]

	ldrne r0,=(consume_recent_tiles_2_entry-frt_m2-8)/4
	ldreq r0,=(consume_recent_tiles_entry-frt_m2-8)/4
	strh r0,[r1,#frt_m2-frt_m1]

	ldrne r0,=(render_recent_tiles_2-frt_m3-8)/4
	ldreq r0,=(render_recent_tiles-frt_m3-8)/4
	strh r0,[r1,#frt_m3-frt_m1]
	
	]	
	]

	[ USE_BG_CACHE
	ldr r1,=writeBG_mapper_9_mod
	ldrb r0,mapper_number
	cmp r0,#9
	cmpne r0,#10
	
	mov r0,#0xEA000000  ;B
	orr r0,r0,#(writeBG_mapper_9_checks-writeBG_mapper_9_mod)/4-2
	ldrne r0,nop_instruction
	str r0,[r1]
	]
	
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

ppu2004_r
	mov r11,r11
	;fake it
	mov r0,#0
	ldr r1,scanline
	cmp r1,#241
	bxgt lr
	ldrb r1,midscanline
	movs r1,r1
	movne r0,#0xFF
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

	[ DIRTYTILES


decodeptr	RN r2 ;mem_chr_decode
nesptr		RN r4 ;chr src
r_tiles 	RN r5
r_tnum		RN r6
d_tiles		RN r7 ;dirtytiles
d_rows		RN r8 ;dirtyrows
tilenum		RN r9
;zero		RN r10 ;0
tilesleft	RN r11
agbptr  	RN r7 ;chr dst
agbptr2 	RN r8 ;chr dst2

;Store dirty tiles into a cache
nes_chr_update
	;no chr ram? bye
	ldrb r0,has_vram
	movs r0,r0
	bxeq lr

	stmfd sp!,{r0-addy,lr}
	bl store_recent_tiles
	ldmfd sp!,{r0-addy,pc}
	
store_recent_tiles
	;first - check if any tiles are dirty
	ldr d_rows,=dirty_rows
	ldmia d_rows,{r0-r7}
	orr r0,r0,r1
	orr r0,r0,r2
	orr r0,r0,r3
	orr r0,r0,r4
	orr r0,r0,r5
	orr r0,r0,r6
	orrs r0,r0,r7
	bxeq lr

	stmfd sp!,{lr}
	ldr d_tiles,=dirty_tiles
	ldr r_tiles,recent_tiles
	ldr r_tnum,recent_tilenum
	ldrh r0,[r_tnum]
	tst r0,#0x8000
	bleq flush_recent_tiles
	mov tilesleft,#MAX_RECENT_TILES

updatetiles
	;coarse version on words
	ldr decodeptr,=CHR_DECODE
;	mov zero,#0
	mov tilenum,#0
updatetiles_loop
	cmp tilenum,#512
	bge updatetiles_done
	ldr r0,[d_rows,tilenum,lsr#4]
	movs r0,r0
	bne updatetiles_fine
	add tilenum,tilenum,#64
	b updatetiles_loop

updatetiles_fine
	;fine - operates on bytes
	;jump here only from 64-aligned tilenum, r0=word from dirtyrows
	tst r0,#0x000000FF
	addeq tilenum,tilenum,#16
	tsteq r0,#0x0000FF00
	addeq tilenum,tilenum,#16
	tsteq r0,#0x00FF0000
	addeq tilenum,tilenum,#16

updaterow_loop
	ldrb r0,[d_tiles,tilenum]
	movs r0,r0
	bne store_recent_tile
	add tilenum,tilenum,#1
backto_updaterow_loop
	tst tilenum,#0x0F
	bne updaterow_loop
updatetiles_resume
	tst tilenum,#63
	beq updatetiles_loop
updatetiles_fine2
	;byte aligned version of updatetiles, jumps back once aligned
	ldrb r0,[d_rows,tilenum,lsr#4]
	movs r0,r0
	bne updaterow_loop
	add tilenum,tilenum,#16
	b updatetiles_resume

store_recent_tile
	ldr nesptr,=NES_VRAM
	add nesptr,nesptr,tilenum,lsl#4
storetileloop
	subs tilesleft,tilesleft,#1
	blmi flush_recent_tiles
	ldmia nesptr!,{r0-r3}
	stmia r_tiles!,{r0-r3}
	strh tilenum,[r_tnum],#2
	mov r0,#0
	strb r0,[d_tiles,tilenum]
	add tilenum,tilenum,#1
	ldrb r0,[d_tiles,tilenum]
	movs r0,r0
	bne storetileloop
	b backto_updaterow_loop

updatetiles_done
	mov r0,#0x8000
	strh r0,[r_tnum]
	mov r0,#0
	mov r1,#0
	mov r2,#0
	mov r3,#0
	stmia d_rows!,{r0-r3}
	stmia d_rows!,{r0-r3}
	ldmfd sp!,{pc}

consume_recent_tiles
	ldrb r0,frameready
	movs r0,r0
	bxeq lr
frt_m1	b consume_recent_tiles_entry

flush_recent_tiles
	stmfd sp!,{r4,r7-r9,lr}
frt_m2	bl consume_recent_tiles_entry
	ldr r_tiles,recent_tiles
	ldr r_tnum,recent_tilenum
	stmfd sp!,{r5,r6}
frt_m3	bl render_recent_tiles
	mov tilesleft,#MAX_RECENT_TILES-1
	ldmfd sp!,{r5,r6}
	ldmfd sp!,{r4,r7-r9,pc}

consume_recent_tiles_entry
	ldr decodeptr,=CHR_DECODE
	ldr r_tiles,dmarecent_tiles
	ldr r_tnum,dmarecent_tilenum
	mov r0,#0x8000
	ldrh tilenum,[r_tnum]
	strh r0,[r_tnum],#2
	b render_next_tile
	
render_recent_tiles
	ldr decodeptr,=CHR_DECODE
	ldrh tilenum,[r_tnum],#2
render_next_tile
	tst tilenum,#0x8000
	bxne lr
;	ldr nesptr,=NES_VRAM
;	add nesptr,nesptr,tilenum,lsl#4
	ldr agbptr,=BG_VRAM
	add agbptr,agbptr,tilenum,lsl#5
	add agbptr2,agbptr,#(SPR_VRAM-BG_VRAM)+SPR_CACHE_OFFSET ;change this to sprite memory
	tst tilenum,#0x100
	addne agbptr,agbptr,#0x2000 ;second pattern table begins at first+4000
render_tile_loop
	ldrb r0,[r_tiles],#1  ;first plane
	ldrb r1,[r_tiles,#7]  ;second plane

	ldr r0,[decodeptr,r0,lsl#2]
	ldr r1,[decodeptr,r1,lsl#2]
	orr r0,r0,r1,lsl#1
	
	str r0,[agbptr],#4
	str r0,[agbptr2],#4
	tst agbptr,#0x1F ;finished with AGB tile?
	bne render_tile_loop
	;next tile
	add r_tiles,r_tiles,#8
	add r0,tilenum,#1
	ldrh tilenum,[r_tnum],#2
	cmp r0,tilenum
	bne render_next_tile
	cmp tilenum,#256  ;crossing 256 tile boundary?
	addeq agbptr,agbptr,#0x2000 ;second pattern table begins at first+4000
	b render_tile_loop

	[ MIXED_VRAM_VROM
consume_recent_tiles_2_entry
	ldr r_tiles,dmarecent_tiles
	ldr r_tnum,dmarecent_tilenum
	stmfd sp!,{r_tnum,lr}
	bl render_recent_tiles_2
	ldmfd sp!,{r_tnum,lr}
	mov r0,#0x8000
	strh r0,[r_tnum]
	bx lr
	
	
render_recent_tiles_2
	ldrh tilenum,[r_tnum]
	tst tilenum,#0x8000
	bxne lr
	stmfd sp!,{r10,r11,r12,lr}
	sub sp,sp,#14*4
	
0
	bl render_a_kilobyte
	tst tilenum,#0x8000
	beq %b0

	add sp,sp,#14*4
	ldmfd sp!,{r10,r11,r12,lr}
	bx lr
	
 [ {FALSE}
We use a list of base addresses, because in the worst case, there could be 14 copies of the same vram page
base_addr_list[14]
base_addr_cursor=0

banknumber is not a vram page number, but a "mapper" bank number
kb is a kilobyte number from the VRAM address

kb=tilenum/1024
banknumber=vram_page_base+kb
sprite_page_number=spr_cache_map[banknumber]
if sprite_page_number is positive
	base_addr=AGB_VRAM+0x10000+SPR_CACHE_OFFSET
	base_addr+=sprite_page_number*64*32
	store base_addr

for cursor=0 to 15
	bg_page=agb_bg_map[cursor]
	bg_page&=vram_page_mask
	if banknumber == bg_page
		within_group=(cursor&3)*16*4*32
		group_base=(cursor/4)*16384
		base_addr=AGB_VRAM+within_group+group_base
		store base_addr
 ]		

render_a_kilobyte
	;translate input tilenum to AGB pointers
	
	
	;agb_bg_map, and spr_cache_map
	;base, mask

	
	 ;base_addr_list[14]
	ldr globalptr,=GLOBAL_PTR_BASE
	ldrb r11,vram_page_mask
	
	 ;base_addr_cursor=0
	mov r8,#0
	 ;kb=tilenum/64
	mov r0,tilenum,lsr#6   ;kilobyte number
	
	strb r0,%f9	;save kilobyte number for checking
	
	;banknumber=vram_page_base+kb
	ldrb r1,vram_page_base
	add r1,r0,r1
	 ;sprite_page_number=spr_cache_map[banknumber]
	ldr r2,=spr_cache_map
	ldrsb r0,[r2,r1]
	
	 ;base_addr=AGB_VRAM+0x10000+SPR_CACHE_OFFSET
	ldr r7,=SPR_VRAM ;+SPR_CACHE_OFFSET  ;not that part, because it's included from spr_cache_map
	 ;base_addr+=sprite_page_number*64*32
	adds r7,r7,r0,lsl#11
	 ;if sprite_page_number is positive
	bcs %f1
	 ;store base_addr
	str r7,[sp,r8,lsl#2]
	add r8,r8,#1
1
	 ;for cursor=0 to 15
	mov r3,#0
	adr r2,agb_real_bg_map
1	
	 ;bg_page=agb_real_bg_map[cursor]
	ldrb r0,[r2,r3]
	 ;bg_page&=vram_page_mask
	and r0,r0,r11
	 ;if banknumber == bg_page
	cmp r0,r1
	bne %f2
	 ;within_group=(cursor&3)*16*4*32
	and r0,r3,#3
	ldr r7,=BG_VRAM
	add r7,r7,r0,lsl#11
	 ;group_base=(cursor/4)*16384
	mov r0,r3,lsr#2
	add r7,r7,r0,lsl#14
	 ;store base_addr
	str r7,[sp,r8,lsl#2]
	add r8,r8,#1
2
	add r3,r3,#1
	cmp r3,#16
	blt %b1
	
	movs r8,r8
	beq skip_this_kilobyte
	;self modify something so I don't need to use so many registers
	strb r8,%f8
	subs r8,r8,#1
	strb r8,%f7

	;render the tile	
render_tiles_loop_2
	ldrh tilenum,[r_tnum]
	mov r0,tilenum,lsr#6
9	cmp r0,#255
	bxne lr
	add r_tnum,r_tnum,#2
	
	and tilenum,tilenum,#0x3F
	ldr agbptr,[sp]
	add agbptr,agbptr,tilenum,lsl#5
	ldr decodeptr,=CHR_DECODE
0
	ldrb r0,[r_tiles],#1  ;first plane
	ldrb r1,[r_tiles,#7]  ;second plane
	
	ldr r0,[decodeptr,r0,lsl#2]
	ldr r1,[decodeptr,r1,lsl#2]
	orr r0,r0,r1,lsl#1
	
	str r0,[agbptr],#4
	tst agbptr,#0x1F ;finished with AGB tile?
	bne %b0
	
	add r_tiles,r_tiles,#8
	
7	movs r0,#255	;modify, change to 0 if there are no dupes
	beq %f1	
	
	;fetch recently encoded title
	sub agbptr,agbptr,#32
	ldmia agbptr,{r0,r1,r2,r3, r4,r10,r11,r12}
	mov r8,#1
0
	ldr agbptr,[sp,r8,lsl#2]
	add agbptr,agbptr,tilenum,lsl#5
	stmia agbptr,{r0,r1,r2,r3, r4,r10,r11,r12}
	add r8,r8,#1
8	cmp r8,#255  ;modify, number of copies of the tile
	blt %b0
1	
	b render_tiles_loop_2

skip_this_kilobyte
	mov r0,tilenum,lsr#6
0
	ldrh tilenum,[r_tnum,#2]!
	add r_tiles,r_tiles,#16
	mov r1,tilenum,lsr#10
	cmp r0,r1
	beq %b0
	bx lr
	


	] ;MIXED_VRAM_VROM

	] ;DIRTYTILES

	[ USE_BG_CACHE
;
;
;

;r2 = NES_VRAM address
;addy = GBA_VRAM address
update_tile_init
	ldr r5,=0x00FF00FF
	ldr r4,=0x00030003
	bx lr

;update_one
;	ldrb r0,[r2],#1
;	ldrh r1,[addy]
;	bic r1,r1,#0xFF
;	orr r0,r0,r1
;	strh r0,[addy],#2
;	bx lr
;update_two
;	ldrh r0,[r2],#2
;	orr r0,r0,r0,lsl#8
;	bic r0,r0,#0xFF00
;	ldr r1,[addy]
;	bic r1,r1,r5 ;#0x00FF00FF
;	orr r0,r0,r1
;	str r0,[addy],#4
;	bx lr
update_attributes
	ldrb r0,[r2],#1
	orr r0,r0,r0,lsl#16

	and r3,r0,r4,lsl#2
	ldr r1,[addy,#4]
	and r1,r1,r5 ;#0x00FF00FF
	orr r1,r1,r3,lsl#10
	str r1,[addy,#4]
		ldr r1,[addy,#0x44]
		and r1,r1,r5 ;#0x00FF00FF
		orr r1,r1,r3,lsl#10
		str r1,[addy,#0x44]
	and r3,r0,r4,lsl#4
	ldr r1,[addy,#0x80]
	and r1,r1,r5 ;#0x00FF00FF
	orr r1,r1,r3,lsl#8
	str r1,[addy,#0x80]
		ldr r1,[addy,#0xC0]
		and r1,r1,r5 ;#0x00FF00FF
		orr r1,r1,r3,lsl#8
		str r1,[addy,#0xC0]
	and r3,r0,r4,lsl#6
	ldr r1,[addy,#0x84]
	and r1,r1,r5 ;#0x00FF00FF
	orr r1,r1,r3,lsl#6
	str r1,[addy,#0x84]
		ldr r1,[addy,#0xC4]
		and r1,r1,r5 ;#0x00FF00FF
		orr r1,r1,r3,lsl#6
		str r1,[addy,#0xC4]
	and r3,r0,r4,lsl#0
		ldr r1,[addy,#0x40]
		and r1,r1,r5 ;#0x00FF00FF
		orr r1,r1,r3,lsl#12
		str r1,[addy,#0x40]
	ldr r1,[addy]
	and r1,r1,r5 ;#0x00FF00FF
	orr r1,r1,r3,lsl#12
	str r1,[addy],#8
	
	bx lr
	
display_bg
	ldrb r0,bg_cache_updateok
	movs r0,r0
	bxeq lr
	mov r0,#0
	strb r0,bg_cache_updateok
	
	ldrb r0,bg_cache_full
	movs r0,r0
	bne_long display_whole_map
consume_bg_cache
	ldr r6,bg_cache_limit
	ldr r7,bg_cache_base
	cmp r6,r7
	bxeq lr
	stmfd sp!,{r10,lr}
	;bg_cache_base = end
	;bg_cache_limit = start
	bl update_tile_init
	;don't touch r4,r5
	;r0,r1,r3 get destroyed
	;r6-r11,lr free
	;r2 = src addr
	;r12 = dest addr
	
	;r6 = cursor, r7 = limit
	;r8 = cache base
	;r9 = Next tile
	ldr r8,=BG_CACHE
	ldr r10,=NES_VRAM2  ;FIXME need to add 4-screen mirroring here
	ldr r11,=AGB_BG
	mov r9,#-1

3
	cmp r6,r7
	beq %f2
1
	;r0=tile number
	ldrh r0,[r8,r6]
	add r6,r6,#2
	bic r6,r6,#BG_CACHE_SIZE
	
	bic r2,r0,#1
	cmp r2,r9
	beq %b3
	
	;test if tile is attribute tile
	bic r1,r0,#0xFC00
	cmp r1,#0x3C0
	bge do_attribute

	;do two tiles, r2=tile number
	mov r9,r2

;vram 4 hack code
	tst r2,#0x800
	mov r0,r10
	subne r0,r0,#0x3000

	ldrh r0,[r0,r2]
	orr r0,r0,r0,lsl#8
	bic r0,r0,#0xFF00
	ldr r1,[r11,r2,lsl#1]
	bic r1,r1,r5 ;#0x00FF00FF
	orr r0,r0,r1
	str r0,[r11,r2,lsl#1]

	cmp r6,r7
	bne %b1
2
	ldmfd sp!,{r10,lr}
	str r6,bg_cache_limit
	bx lr

do_attribute
	tst r2,#0x800	;vram 4 hack code

	and r1,r0,#0x7		;dest column number
	add r12,r11,r1,lsl#3	;4 tiles per attribute column
	and r1,r0,#0x38		;dest row number
	add r12,r12,r1,lsl#5	;[nes_row*8]/8*4*32*2
	and r1,r0,#0xC00
	add r12,r12,r1,lsl#1
	add r2,r10,r0

;vram 4 hack code
	subne r2,r2,#0x3000

	adr lr,%b3
	b update_attributes

;display_whole_map

update_whole_map
	stmfd sp!,{lr}
	add r6,r2,#0x3C0
0
	ldrh r0,[r2],#2
	orr r0,r0,r0,lsl#8
	bic r0,r0,#0xFF00
	ldr r1,[addy]
	bic r1,r1,r5 ;#0x00FF00FF
	orr r0,r0,r1
	str r0,[addy],#4
	cmp r2,r6
	blt %b0
	;now update attribute table
	sub addy,addy,#0x780
	mov r7,#8
1
	mov r6,#8
0
	bl update_attributes
	subs r6,r6,#1
	bne %b0
	add addy,addy,#0xC0  ;=0x100-0x40
	subs r7,r7,#1
	bne %b1

	ldmfd sp!,{pc}
	
	] ;USE_BG_CACHE

update_bankbuffer
	;destroys r3,r4,r5
	adrl r0,nes_chr_map
	adr r1,bankbuffer_last
	ldmia r0,{r2,r3}
	ldmia r1,{r4,r5}
	cmp r2,r4
	cmpeq r3,r5
	stmneia r1,{r2,r3}
	bxeq lr
	
	ldr r0,scanline
	cmp r0,#236
	bge %f0
;	add r0,r0,#0
;	movle r0,#0
	mov r0,r0,lsr#3
	cmp r0,#30
0
	movge r0,#30
	;r4,r5 = data to fill
bankbuffer_finish		;newframe jumps here
	adr r2,bankbuffer_line
	swp r1,r0,[r2]		;r1=lastline, lastline=scanline, r0=scanline
	;sl == 0 >> exit
	;sl < prev  >> prev = 0
	;sl == prev >> exit
	cmp r0,#0
	bxeq lr
	subs r0,r0,r1
	bxeq lr
	addlt r0,r0,r1  ;could this happen?
	movlt r1,#0
	;addy = number of scanlines to fill
	
	ldr r2,bankbuffer
	;should not be zero
	add r1,r2,r1,lsl#3
bbf
	stmia r1!,{r4,r5}
	subs r0,r0,#1
	bgt bbf
	bx lr
	

	[ SPRITESCAN
spritescan
	;call this before swapping buffers
	;can use r0-r9,r12
	
	;fixme
	ldr r0,dmanesoambuff
	
	mvn r2,#0
	mvn r3,#0
	mov r4,#1
	mov r5,#0
	mov r6,#0
	mov r7,#17
	ldr r1,[r0],#4
	bic r1,r1,#0xFF000000
sprscanloop
	subs r7,r7,#1
	beq_long sprscanend
	ldr r8,[r0],#4
	;filter out X coordinate
	bic r8,r8,#0xFF000000
	cmp r8,r1
	addeq r4,r4,#1
	beq sprscanloop
	cmp r8,r2
	addeq r5,r5,#1
	beq sprscanloop
	movs r5,r5
	moveq r5,#1
	moveq r2,r8
	beq sprscanloop
	cmp r8,r3
	addeq r6,r6,#1
	beq sprscanloop
	movs r6,r6
	bxne lr
	moveq r6,#1
	moveq r3,r8
	b sprscanloop
sprmask_apply_loop
	ldrh r1,[r0]
	bic r1,r1,#0x1000
	strh r1,[r0],#2
	subs r4,r4,#1
	bne sprmask_apply_loop
	bx lr
	
	AREA rom_code6, CODE, READONLY

need_to_fetch_sprite_data
	ldr r4,=alreadylooked
	ldr r4,[r4]
	movs r4,r4
	mov r4,#PRIORITY
	bxeq lr
	mov r4,#0
	ldr r0,=alreadylooked
	str r4,[r0]
	ldr lr,=update_sprites_enter
	ldr r0,=recache_sprites
	bx r0

;vram_read_direct
;	and r0,addy,#0x3c00
;	adr r1,vram_map
;	ldr r0,[r1,r0,lsr#8]
;	bic r1,addy,#0xfc00
;	ldrb r0,[r0,r1]
;	bx lr

palread
	and r0,r0,#0x1f
	adr r1,nes_palette
	ldrb r0,[r1,r0]
	mov pc,lr

	
sprscanend
	mov addy,lr
	cmp r4,#8
	bleq sprmasktherows
	cmp r5,#8
	moveq r1,r2
	bleq sprmasktherows
	cmp r6,#8
	moveq r1,r3
	bleq sprmasktherows
	bx addy
sprmasktherows
	and r1,r1,#0xFF
	add r1,r1,#1
	cmp r1,#240
	bxge lr
	
	ldrb r0,ppuctrl0frame
	tst r0,#0x20
	movne r4,#16
	moveq r4,#8

	add r0,r1,r4
	cmp r0,#240
	rsbge r4,r1,#240

	ldr r0,dispcntbuff

	add r0,r0,r1,lsl#1
	b_long sprmask_apply_loop
	|
	AREA rom_code6, CODE, READONLY
	] ;SPRITESCAN

	[ USE_BG_CACHE
display_whole_map
	mov r0,#0
	str r0,bg_cache_cursor
	str r0,bg_cache_base
	str r0,bg_cache_limit
	strb r0,bg_cache_full
	
	stmfd sp!,{lr}
	bl_long update_tile_init	
	
	ldr addy,=AGB_BG
	ldr r2,=NES_VRAM2
	bl_long update_whole_map
	ldr addy,=AGB_BG+0x800
	ldr r2,=NES_VRAM2+0x400
	bl_long update_whole_map

	ldrb r0,fourscreen
	movs r0,r0
	beq %f0
	
	ldr addy,=AGB_BG+0x1000
	ldr r2,=NES_VRAM4
	bl_long update_whole_map
	ldr addy,=AGB_BG+0x1800
	ldr r2,=NES_VRAM4+0x400
	bl_long update_whole_map
	
0
	ldmfd sp!,{pc}
	]

vrom_update_tiles
	ldrb r0,bankable_vrom
	ldrb r1,frameready
	movs r0,r0
	movnes r1,r1
	bxeq lr
	
	stmfd sp!,{lr}
	
;	ldr r8,=sprite_cache_size
;	ldr r8,[r8]
;	movs r8,r8
;	bxeq lr
	
	ldr r6,=spr_cache
	mov addy,#4
	ldr r5,=SPR_VRAM+SPR_CACHE_OFFSET
0
	ldr r0,[r6]
	ldr r1,[r6,#16]
	str r0,[r6,#16]
	eor r1,r1,r0
	bl_long im_lazy
	subs addy,addy,#1
	bne %b0

;why this code went missing for so many versions I'll never know...

	;AGB BG is dirty?
	adrl r9,agb_bg_map
	ldmia r9,{r0-r3}
	adrl r9,agb_real_bg_map
	ldmia r9,{r4-r7}
	cmp r0,r4
	cmpeq r1,r5
	cmpeq r2,r6
	cmpeq r3,r7
	beq bgmap_clean
	
	
	adrl r6,agb_bg_map
vut0
	ldr r0,[r6]
	ldr r1,[r6,#16]
	eors r1,r1,r0
	addeq r6,r6,#4
	adrnel r0,agb_bg_map
	subne r0,r6,r0
	movne r5,#BG_VRAM
	addne r5,r5,r0,lsl#12	;0000/4000/8000/C000
	blne_long im_lazy
	adrl r0,agb_bg_map+16
	cmp r6,r0
	bne vut0
	
	adrl r9,agb_bg_map
	ldmia r9,{r0-r3}
	adrl r9,agb_real_bg_map
	stmia r9,{r0-r3}
	
bgmap_clean

	
	
	ldmfd sp!,{pc}


check_canaries
	mov r11,r11
	stmfd sp!,{lr}
	ldr r1,=IWRAM_CANARY_1
	ldr r2,=0xDEADBEEF
	ldr r0,[r1]
	cmp r0,r2
	bne canary1_fail

	ldr r1,=IWRAM_CANARY_2
	ldr r2,=0xDEAFBEEF
	ldr r0,[r1]
	cmp r0,r2
	bne canary2_fail
	
	ldmfd sp!,{pc}
canary1_fail
	mov r11,r11
	;test if it's safe
	cmp r1,sp	;is canary before the stack?  Then it's safe.
	bge %f0
	bl_long build_chr_decode
	b %f1
canary2_fail
	mov r11,r11
	cmp r1,sp	;is canary before the stack?  Then it's safe.
	bge %f0
1
	ldr r0,=g_scaling
	ldrb r0,[r0]
	and r0,r0,#3
	bl_long spriteinit
0
	ldmfd sp!,{pc}

scale75
	stmfd sp!,{lr}
	;r0 = ?, r1 = ?, r2 = LTS/?, r3 = skipflags, r11 = S, r12 = S-D
	;r7 = src_xy, r8 = src_dispcnt, r9 = src_bg0cnt
	;r4 = dest_xy, r5 = dest_dispcnt, r6 = dest_bg0cnt
	ldrb r11,windowtop_scaled6_8
	
	ldr r7,dmascrollbuff
	ldr r8,dmadispcntbuff
	ldr r9,dmabg0cntbuff
	
	ldr r4,=DMA0BUFF
	ldr r5,=DMA1BUFF
	ldr r6,=DMA3BUFF
	
	mov r12,r11
	
	;self modifying code
	ldrb r0,adjustblend
	add r0,r0,#1
	and r0,r0,#3
	ldr r1,=_twitchline_mod1
	strb r0,[r1,#_twitchline_mod1-_twitchline_mod1]
	add r0,r0,#1
	strb r0,[r1,#_twitchline_mod3-_twitchline_mod1]
	and r0,r0,#3
	strb r0,[r1,#_twitchline_mod2-_twitchline_mod1]
	
	ldrb r0,twitch
	eor r0,r0,#1
	ldrb r1,flicker
	ands r1,r0,r1
	strb r0,twitch


	bne_long scale75_odd
	b_long scale75_even

	
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
		[ LINK
		bne_long serialinterrupt
		]
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

	[ {FALSE}
scale75
	;r1=dest1, r2=dest2, r3=dest3, r4=src1, r5=src2, r6=src3, r7=limit, r8=ystart, r9=temp, r11=temp
	ldr r4,dmascrollbuff
	ldr r5,dmadispcntbuff
	ldr r6,dmabg0cntbuff
	
	;sample scroll position in middle of screen for "anti-wobblie" code
	ldr r9,=120*4+2
	ldrh r9,[r9,r4]
	
	;setup source
	ldrb r8,ystart
	add r4,r4,r8,lsl#2
	add r5,r5,r8,lsl#1
	add r6,r6,r8,lsl#1
	
	;setup ystart
	mov r8,r8,lsl#16
	
	;setup destination
	ldr r1,=DMA0BUFF
	ldr r2,=DMA1BUFF
	ldr r3,=DMA3BUFF
	
	;setup limit
	add r7,r1,#160*4
	
	;do the flicker/twitch thing
	ldrb r0,flicker
	ldrb r11,twitch
	eors r0,r0,r11
	strb r0,twitch
	
	;do one copy if 'eq'
	bne %f9
	ldr r0,[r4],#4
	add r0,r0,r8
	str r0,[r1],#4
	ldrh r0,[r6],#2
	strh r0,[r3],#2
	ldrh r0,[r5],#2
	strh r0,[r2],#2
9
	ldrb r0,adjustblend
	add r0,r0,r9
	ands r0,r0,#3
;	str r0,totalblend
	beq scale75_2
	cmp r0,#2
	bhi scale75_1
	addmi r4,r4,#4
scale75loop
	;copy and move up
	ldr r0,[r4],#4
	addmi r8,r8,#1*65536
	add r0,r0,r8
	str r0,[r1],#4
	ldrh r0,[r6],#2
	strh r0,[r3],#2
	ldrh r0,[r5],#2
	strh r0,[r2],#2
scale75_1
	;copy, no skip
	ldr r0,[r4],#4
	add r0,r0,r8
	str r0,[r1],#4
	ldrh r0,[r6],#2
	strh r0,[r3],#2
	ldrh r0,[r5],#2
	strh r0,[r2],#2
scale75_2
	;copy and skip
	ldr r0,[r4],#8
	add r0,r0,r8
	str r0,[r1],#4
	ldrh r0,[r6],#4
	strh r0,[r3],#2
	ldrh r0,[r5],#4
	strh r0,[r2],#2
	;check for end
	cmp r1,r7
	bmi scale75loop
	bx lr

	]

;scale75 moved to ROM code
scale75_even
scale75_even_loop
	bl scale75_findscanline
	;r2 = line_to_skip
	sub r2,r2,#1
	mov r3,#0
0
	cmp r2,r3
	bleq scale75_skip
	blne scale75_copy
	add r3,r3,#1
	cmp r3,#4
	bne %b0
	ldr r0,=DMA0BUFF+160*4
	cmp r4,r0
	blt scale75_even_loop
scale75_exit
	ldmfd sp!,{pc}

scale75_odd
	mov r3,#0
scale75_odd_loop
	bl scale75_findscanline
	sub r2,r2,#1
	and r3,r3,#3
0
	tst r3,#1
	blne scale75_skip2
	bleq scale75_copy
	cmp r2,r3,lsr#2
	;if true, skip next
	orreq r3,r3,#1
	add r3,r3,#4
	cmp r3,#16
	blt %b0
	ldr r0,=DMA0BUFF+160*4
	cmp r4,r0
	blt scale75_odd_loop
	b scale75_exit

	
scale75_findscanline
	;find scanline to skip
	mov r2,#0
0
	;r1 = Y
	add r1,r2,r11
	add r2,r2,#1 ;inc Y1 now...
	;read Y scroll value (most significant 16 bits of table at r7)
	ldr r0,[r7,r1,lsl#2]
	add r1,r1,r0,lsr#16
	and r1,r1,#3
	;compare against twitch line
_twitchline_mod1
	cmp r1,#255
	bne %f1
	;compare against next value
	add r1,r2,r11
	ldr r0,[r7,r1,lsl#2]
	add r1,r1,r0,lsr#16
	and r1,r1,#3
_twitchline_mod2
	cmp r1,#255
	;match
	bxeq lr
1
	cmp r2,#4
	blt %b0
_twitchline_mod3
	mov r2,#255	;if it can't find a good line to jitter, jitter 'twitchline'
	bx lr

scale75_skip2
	bic r3,r3,#1
scale75_skip
	add r12,r12,#1
	add r11,r11,#1
	bx lr
scale75_copy
	;copy a line
	;XY data
	ldr r0,[r7,r11,lsl#2]
	add r0,r0,r12,lsl#16
	str r0,[r4],#4
	mov r1,r11,lsl#1
	ldrh r0,[r8,r1]
	strh r0,[r5],#2
	ldrh r0,[r9,r1]
	strh r0,[r6],#2
	add r11,r11,#1
	bx lr





vblankinterrupt;
;----------------------------------------------------------------------------
	stmfd sp!,{r4-addy,lr}
	ldr globalptr,=GLOBAL_PTR_BASE
	
	bl_long check_canaries
	

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
;fixme: copy to scaled buffers instead of using directly
	ldrb r0,windowtop
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

	ldr r3,dmadispcntbuff
	ldr r4,dmabg0cntbuff
	add r3,r3,r0,lsl#1
	add r4,r4,r0,lsl#1
	b vbl5


vblscaled					;(scaled)
	bl_long scale75
	ldr r3,=DMA1BUFF
	ldr r4,=DMA3BUFF
vbl5

	mov r5,#REG_BASE
	strh r5,[r5,#REG_DM0CNT_H]		;DMA0 stop
	strh r5,[r5,#REG_DM1CNT_H]		;DMA1 stop
	strh r5,[r5,#REG_DM3CNT_H]		;DMA3 stop

	add r7,r5,#REG_DM3SAD

;	ldr r0,dmaoambuffer				;DMA3 src, OAM transfer:
;	mov r1,#AGB_OAM					;DMA3 dst
;	mov r2,#0x84000000				;noIRQ hblank 32bit repeat incsrc fixeddst
;	orr r2,r2,#0x80					;128 words (512 bytes)
;	stmia r7,{r0-r2}				;DMA3 go

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

	ldrb r0,firstframeready
	movs r0,r0
	beq %f0
	
	bl update_sprites
	bl_long vrom_update_tiles
	[ DIRTYTILES
	bl consume_recent_tiles
	]
	[ USE_BG_CACHE
	bl display_bg
	]
	
0

	mov r0,#0
	strb r0,frameready

	ldmfd sp!,{r4-addy,pc}

;totalblend	DCD 0

newframe_set0
;called at line 1
	mov r0,#0
	str r0,ctrl1line
	str r0,chrline
	str r0,scrollXline
	str r0,scrollYline
	
	adr r1,bankbuffer_line
	str r0,[r1]
	
	;is this necessary?
;	ldr r0,scrollY			;r0=y
;	str r0,scrollYold
	mov r0,#512
	str r0,ppuhack_line
	
	
	bx lr

ystart	DCB YSTART
	DCB 0
	DCB 0
	DCB 0


;----------------------------------------------------------------------------
newframe_nes_vblank 	;called at line 242
;----------------------------------------------------------------------------
;	stmfd sp!,{r3-r11,lr}
	stmfd sp!,{lr}
	
	ldr r0,ctrl1old
	ldr r1,ctrl1line
	mov addy,#240
	bl ctrl1finish
;-----------------------
	ldr r0,scrollXold
	mov addy,#240
	bl scrollXfinish
;--------------------------
	ldr r0,scrollYold
	mov addy,#240
	bl scrollYfinish
;--------------------------
	bl chrfinish
;------------------------
	adr r2,bankbuffer_last
	ldmia r2,{r4,r5}
	mov r0,#30
	bl bankbuffer_finish
;--------------------------	
	[ SPRITESCAN
	bl spritescan
	]

	[ DIRTYTILES

	ldrb r0,has_run_nes_chr_update_this_frame
	movs r0,r0
	mov r0,#0
	strneb r0,has_run_nes_chr_update_this_frame
	bleq nes_chr_update
	
	]

	;disable GBA vblank interrupts while swapping buffers
	ldr addy,=REG_IE+REG_BASE
	ldrh r2,[addy]
	bic r2,r2,#1
	strh r2,[addy]
	;HANDS OFF R2!!!

	;flip scroll buffer
	ldr r0,scrollbuff
	ldr r1,dmascrollbuff
	str r1,scrollbuff
	str r0,dmascrollbuff
	;flip mirroring/bg bank buffer
	ldr r0,bg0cntbuff
	ldr r1,dmabg0cntbuff
	str r1,bg0cntbuff
	str r0,dmabg0cntbuff
	;flip bg/spr enable/disable buffer
	ldr r0,dispcntbuff
	ldr r1,dmadispcntbuff
	str r1,dispcntbuff
	str r0,dmadispcntbuff

	[ DIRTYTILES
	;recent tiles buffer
	ldr r0,recent_tiles
	ldr r1,dmarecent_tiles
	str r1,recent_tiles
	str r0,dmarecent_tiles
	ldr r0,recent_tilenum
	ldr r1,dmarecent_tilenum
	str r1,recent_tilenum
	str r0,dmarecent_tilenum
	]

	[ USE_BG_CACHE
	;advance bg cache
	ldr r0,bg_cache_cursor
	str r0,bg_cache_base
	mov r0,#1
	strb r0,bg_cache_updateok
	]
	
	;flip 'bank buffer'
	adrl r3,bankbuffer
	ldmia r3,{r0,r1}
	str r1,[r3,#0]
	str r0,[r3,#4]

	;NES OAM unchanged?
	ldrb r0,nesoamdirty
	movs r0,r0
	beq nesoam_was_clean
	
	mov r0,#0
	strb r0,nesoamdirty
	;flip nes sprite buffer if dirty
	ldr r0,nesoambuff
	ldr r1,dmanesoambuff
	str r1,nextnesoambuff
	str r0,dmanesoambuff
nesoam_was_clean
	mov r0,#0xFF0
	adrl r1,frameready
	strh r0,[r1]

;	mov r0,#1
;	strb r0,consumetiles_ok
	;todo:
	;copy new chr changes to buffer
	
	;copy NES map to buffer?
	
	
	;reenable GBA vblank interrupt
	orr r2,r2,#1
	strh r2,[addy]

	;wait for vblank
 [ BUILD = "DEBUG"
 |
	ldrb r4,novblankwait_
	teq r4,#1					;NoVSync?
	beq l03
l01
	mov r0,#0					;don't wait if not necessary
	mov r1,#1					;VBL wait
	swi 0x040000				; Turn of CPU until VBLIRQ if not too late already.
	ldrb r0,PAL60				;wait for AGB VBL
	cmp r0,#5
	beq l01
	teq r4,#2					;Slomo?
	moveq r4,#0
	beq l01
l03
 ]
	ldmfd sp!,{lr}
	bx lr
;	ldmfd sp!,{r3-r11,pc}


;----------------------------------------------------------------------------
newframe	;called at line 0	(r0-r9 safe to use)
;----------------------------------------------------------------------------
	ldrb r0,ppuctrl1
	strb r0,ppuctrl1_startframe
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

	bx lr

;----------------------------------------------------------------------------
dma_W	;(4014)		sprite DMA transfer
;----------------------------------------------------------------------------
PRIORITY EQU 0x800	;0x800=AGB OBJ priority 2/3
	ldr r1,=3*512*CYCLE		; was 514...
	sub cycles,cycles,r1
	
	mov r1,#1
	strb r1,nesoamdirty
	
	and r1,r0,#0xe0
	adr addy,memmap_tbl
	ldr addy,[addy,r1,lsr#3]
	and r0,r0,#0xff
	add r1,addy,r0,lsl#8	;addy=DMA source

;r0=dest, r1=src, r2=byte count

	ldr r0,nextnesoambuff
	str r0,nesoambuff
	mov r2,#256
	b memcpy32
	
	;find where sprite 0 collides
	;this is "yucky" because it only gets called once, and doesn't check again if the NES changes its graphics
findsprite0
	ldr addy,nesoambuff

	ldrb r0,ppuctrl0	;8x16?
	tst r0,#0x20
	bne hit16
;- - - - - - - - - - - - - 8x8 size
hit8
					;get sprite0 hit pos:
	tst r0,#0x08			;CHR base? (0000/1000)
	ldrb r0,[addy,#1]		;sprite tile#
	
	adr r1,vram_map
	addne r1,r1,#16
	mov r2,r0,lsr#6
	ldr r1,[r1,r2,lsl#2]
	;r1 = address of NES data
	and r0,r0,#0x3F
	add r0,r1,r0,lsl#4		;r0=NES base+tile*16
	
	mov addy,#0

	;note: does not yet factor in Y flipping

1
	ldr r2,[r0],#4
	ldr r1,[r0,#4]
	orr r1,r1,r2
	tst   r1,#0x000000FF
	addeq addy,addy,#1
	tsteq r1,#0x0000FF00
	addeq addy,addy,#1
	tsteq r1,#0x00FF0000
	addeq addy,addy,#1
	tsteq r1,#0xFF000000
	addeq addy,addy,#1
	bne %f0
	cmp addy,#8
	blt %b1
0	
	
	ldr r0,nesoambuff
	ldrb r1,[r0]
	add r1,r1,#2	;add 2, one for sprite y correction, one for dummy scanline
	add r1,r1,addy
;	moveq r1,#512			;blank tile=no hit
	cmp r1,#240
	movhi r1,#512			;no hit if Y>239
	str r1,sprite0y
	ldrb r1,[r0,#3]		;r1=sprite0 x
	strb r1,sprite0x
	bx lr
hit16
;- - - - - - - - - - - - - 8x16 size
	ldrb r0,[addy,#1]		;sprite tile#
	tst r0,#0x01
	adr r1,vram_map
	addne r1,r1,#16
	mov r2,r0,lsr#6
	ldr r1,[r1,r2,lsl#2]
	;r1 = address of NES data
	and r0,r0,#0x3E
	add r0,r1,r0,lsl#4		;r0=NES base+tile*16
	
	mov addy,#0

	;note: does not yet factor in Y flipping
1
	ldr r2,[r0],#4
	ldr r1,[r0,#4]
	orr r1,r1,r2
	tst   r1,#0x000000FF
	addeq addy,addy,#1
	tsteq r1,#0x0000FF00
	addeq addy,addy,#1
	tsteq r1,#0x00FF0000
	addeq addy,addy,#1
	tsteq r1,#0xFF000000
	addeq addy,addy,#1
	bne %f0
	tst addy,#0x04
	bne %b1
	tst addy,#0x10
	addeq r0,r0,#8
	beq %b1
0
	ldr r0,nesoambuff
	ldrb r1,[r0]
	add r1,r1,#2	;add 2, one for sprite y correction, one for dummy scanline
	add r1,r1,addy
;	moveq r1,#512			;blank tile=no hit
	cmp r1,#240
	movhi r1,#512			;no hit if Y>239
	str r1,sprite0y
	ldrb r1,[r0,#3]		;r1=sprite0 x
	strb r1,sprite0x
	bx lr

update_sprites
	;call this to finish the job
	stmfd sp!,{lr}
	mov r0,#1
	str r0,alreadylooked
	
update_sprites_enter
	
	mov r11,#PRIORITY
	
	ldr r7,dmascrollbuff
	add r7,r7,#1
	ldr r8,dmabankbuffer
	ldr r9,=spr_cache_map
	

	ldr addy,dmanesoambuff

;	ldr r2,oambuffer+4		;r2=dest
;	ldr r1,oambuffer+8
;	ldr r0,oambuffer
;	str r2,oambuffer
;	str r1,oambuffer+4
;	str r0,oambuffer+8
	mov r2,#AGB_OAM

	ldr r1,emuflags
	and r5,r1,#0x300
	cmp r5,#SCALED_SPRITES*256
	moveq r6,#0x300			;r6=rot/scale flag + double
	movne r6,#0

	cmp r5,#UNSCALED_AUTO*256	;do autoscroll
	bne dm0
	ldr r3,AGBjoypad
	ands r3,r3,#0x300
	eornes r3,r3,#0x300
	bne dm0					;stop if L or R pressed (manual scroll)
	mov r3,r1,lsr#16		;r3=follow value
	tst r1,#FOLLOWMEM
	ldreqb r0,[addy,r3,lsl#2]			;follow sprite
	ldrneb r0,[cpu_zpage,r3]			;follow memory
	cmp r0,#239
	bhi dm0
	add r0,r0,r0,lsl#2
	mov r0,r0,lsr#4
	strb r0,windowtop
dm0
	ldrb r0,windowtop ;FIXME
	ldr r5,=YSCALE_LOOKUP
	sub r5,r5,r0

	ldrb r0,ppuctrl0frame	;8x16?
	tst r0,#0x20
	bne dm4
	;-------------------------- 8 x 8 ---------------------------

;	mov r4,#PRIORITY
;	tst r0,#0x08			;CHR base? (0000/1000)
;	moveq r4,#0+PRIORITY	;r4=CHR set+AGB priority
;	movne r4,#0x100+PRIORITY
dm11
	ldr r3,[addy],#4
	and r0,r3,#0xff
	cmp r0,#239
	bhi dm10				;skip if sprite Y>239

;	spr_ptable=(scrollbuff[spr_y*4]&0x80)/0x20;
;	spr_t=oambuff[i*4+1];
;	spr_high_t=spr_t>>6;
;	spr_bank=bankbuffer[(spr_y&0xF8)+spr_ptable+spr_high_t];
; 	cache_bank=map[spr_bank];

	;(y/8)*8
	and r4,r0,#0xF8
	;fetch from scroll buffer
	ldrb r1,[r7,r0,lsl#2]
	and r1,r1,#0x80
	;add 4 if requests right pattern table
	add r4,r4,r1,lsr#5
	and r1,r3,#0xC000
	;add sprite number's KB position
	add r4,r4,r1,lsr#14
	;Get Bank number
	ldrb r4,[r8,r4]
	;Get Sprite Number/64
	ldrsb r4,[r9,r4]
	;mult by 64
	tst r4,#0x80000000
	add r4,r11,r4,lsl#6
	blne_long need_to_fetch_sprite_data
	;get tile number
	and r1,r3,#0x3F00
	add r4,r4,r1,lsr#8
	;end new code

	ldrb r0,[r5,r0]			;y = scaled y

	ands r1,r6,#0x100
	add r1,r1,#0x200
	tstne r3,#0x00400000
	addne r1,r1,#0x40

	subs r1,r3,r1,lsl#18
;#0x0c000000	;x-8
	and r1,r1,#0xff000000
	orr r0,r0,r1,lsr#8
	orrcc r0,r0,#0x01000000
	and r1,r3,#0x00c00000	;flip
	orr r0,r0,r1,lsl#6
	and r1,r3,#0x00200000	;priority
	orr r0,r0,r1,lsr#11		;Set Transp OBJ.
	orr r0,r0,r6			;rot/scale, double
	str r0,[r2],#4			;store OBJ Atr 0,1

	and r0,r3,#0x00030000
	orr r0,r4,r0,lsr#4
;	and r1,r3,#0x0000ff00	;tile#
;	and r0,r3,#0x00030000	;color
;	orr r0,r1,r0,lsl#4
;	orr r0,r4,r0,lsr#8		;tileset+priority
	strh r0,[r2],#4			;store OBJ Atr 2
dm9
	tst addy,#0xff
	bne dm11
	ldmfd sp!,{pc}
dm10
	mov r0,#0x2a0			;double, y=160
	str r0,[r2],#8
	b dm9

dm4	;----------------------- 8 x 16 -----------------------------
	orr r6,r6,#0x8000		;8x16 flag
dm12
	ldr r3,[addy],#4
	and r0,r3,#0xff
	cmp r0,#239
	bhi dm13				;skip if sprite Y>239

	;new code
	and r4,r0,#0xF8
	and r1,r3,#0x0100
	add r4,r4,r1,lsr#6
	and r1,r3,#0xC000
	add r4,r4,r1,lsr#14
	ldrb r4,[r8,r4]
	ldrsb r4,[r9,r4]
	tst r4,#0x80000000
	add r4,r11,r4,lsl#6
	blne_long need_to_fetch_sprite_data
	;get tile number
	and r1,r3,#0x3E00
	add r4,r4,r1,lsr#8
	;end new code




	tst r6,#0x300
	subne r0,r0,#5
	andne r0,r0,#0xff
	ldrb r0,[r5,r0]			;y

	ands r1,r6,#0x100
	add r1,r1,#0x200
	tstne r3,#0x00400000
	addne r1,r1,#0x40

	subs r1,r3,r1,lsl#18
;#0x0c000000	;x-8
	and r1,r1,#0xff000000
	orr r0,r0,r1,lsr#8
	orrcc r0,r0,#0x01000000
	and r1,r3,#0x00c00000	;flip
	orr r0,r0,r1,lsl#6
	and r1,r3,#0x00200000	;priority
	orr r0,r0,r1,lsr#11		;Set Transp OBJ.
	orr r0,r0,r6			;8x16+rot/scale
	str r0,[r2],#4			;store OBJ Atr 0,1
	
	and r0,r3,#0x00030000
	orr r0,r4,r0,lsr#4
;	and r1,r3,#0x0000ff00	;tile#
;	movs r0,r1,lsr#9
;	orrcs r0,r0,#0x80
;	orr r0,r4,r0,lsl#1		;priority, tile#*2
;	and r1,r3,#0x00030000	;color
;	orr r0,r0,r1,lsr#4
	strh r0,[r2],#4			;store OBJ Atr 2
dm14
	tst addy,#0xff
	bne dm12
	ldmfd sp!,{pc}
dm13
	mov r0,#0x2a0			;double, y=160
	str r0,[r2],#8
	b dm14

alreadylooked
	DCD 0
	

;----------------------------------------------------------------------------
PPU_R;
;----------------------------------------------------------------------------
	and r0,addy,#7
	ldr pc,[pc,r0,lsl#2]
	DCD 0
PPU_read_tbl
	DCD empty_PPU_R	;$2000
	DCD empty_PPU_R	;$2001
	DCD stat_R_simple ;$2002
	DCD empty_PPU_R	;$2003
	DCD ppu2004_r	;$2004
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
;	ldrb r2,scrollY+1
	strb r1,scrollY+1
;	cmp r1,r2
;	beq %f0
;	stmfd sp!,{r0,lr}
;		bl newY
;	ldmfd sp!,{r0,lr}
;0

	;hacky code for duck tales - make MSBit of gba scroll buffer equal to sprite pattern table selection
	tst r0,#8
	and r0,r0,#1			;X scroll
	orrne r0,r0,#0x80
	biceq r0,r0,#0x80
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

;	ldr r1,=0x2440		;1d sprites, BG2 enable, Window enable. DISPCNTBUFF startvalue. 0x2440
	mov r1,#0x0440		;1d sprites, BG2 enable, Window disable. DISPCNTBUFF startvalue. 0x0440
	tst r0,#0x08		;bg en?
	orrne r1,r1,#0x0100
	tst r0,#0x10		;obj en?
	orrne r1,r1,#0x1000

	adrl r2,ctrl1old
	swp r0,r1,[r2]		;r0=lastval

	;get the real scanline
	ldrb addy,midscanline
	movs addy,addy
	ldreq addy,cyclesperscanline1
	sub addy,addy,cycles
	cmp addy,#128<<CYC_SHIFT
	ldr addy,scanline	;addy=scanline
	sublt addy,addy,#1
	cmp addy,#240
	movhi addy,#240

ctrl1finish
	adrl r2,ctrl1line
	swp r1,addy,[r2]	;r1=lastline, lastline=scanline
	;sl == 0 >> exit
	;sl < prev  >> prev = 0
	;sl == prev >> exit
	cmp addy,#0
	bxeq lr
	subs addy,addy,r1
	bxeq lr
	addlt addy,addy,r1  ;could this happen?
	movlt r1,#0
	;addy = number of scanlines to fill

	ldr r2,dispcntbuff
	add r1,r2,r1,lsl#1
	b memset16
;ct1
;	strh r0,[r1],#2 	;fill forwards from lastline to scanline-1
;	subs addy,addy,#1
;	bgt ct1
;
;	mov pc,lr

update_Y_hit
	adr r1,stat_R_sameline
	str r1,PPU_read_tbl+8
	ldr r1,sprite0y
	strb r1,stat_R_Y_modify
	ldrb r1,sprite0x
	;maybe put PAL fixing code here later
	rsb r1,r1,#255
	strb r1,stat_R_X_modify
	bx lr	

stat_R_ppuhack
	ldr r0,scanline
	ldr r1,ppuhack_line
	str r0,ppuhack_line
	cmp r0,r1
	bne %f0
	ldrb r2,ppuhack_count
	add r2,r2,#1
	strb r2,ppuhack_count
	cmp r2,#5
	ble %f1
	andgt cycles,cycles,#CYC_MASK	;skip this scanline
0
	strb m6502_a,ppuhack_count
1
stat_R_simple
	strb m6502_a,toggle
ppustat_
	mov r0,#1
	bx lr

stat_R_clearvbl
	strb m6502_a,toggle
	ldr r0,stat_r_simple_func
	str r0,PPU_read_tbl+8
	ldrb r0,ppustat_
	bic r1,r0,#0x80
	strb r1,ppustat_
	bx lr

stat_R_sameline
	strb m6502_a,toggle
	ldrb r0,ppustat_
	ldr r1,scanline
stat_R_Y_modify
	cmp r1,#1
	bne stat_R_hit	;scanline doesn't match: hit
stat_R_X_modify
	cmp cycles,#255*CYCLE	;cycles < (256-X)*CYCLE  then  Hit
	bxgt lr	;no hit otherwise
stat_R_hit
	orr r0,r0,#0x40
	strb r0,ppustat_
	ldr r1,stat_r_simple_func
	str r1,PPU_read_tbl+8
	bx lr

;----------------------------------------------------------------------------
bgscroll_W	;(2005)
;----------------------------------------------------------------------------
	ldrb r1,toggle
	eors r1,r1,#1
	strb r1,toggle
	beq bgscrollY
bgscrollX
;	;set vram address - do we need this?
;	ldrb addy,vramaddr2
;	bic addy,addy,#0x1F
;	mov r1,r0,lsr#3
;	orr addy,addy,r1
;	strb addy,vramaddr2
		
	ldrb r1,nextx
	strb r0,nextx
	bic r1,r1,#0x07
	and r0,r0,#0x07
	orr r0,r1,r0
	strb r0,scrollX
newX			;ctrl0_W, loadstate jumps here
	ldr r0,scrollX
newX2			;vmaddr_W jumps here
	adr r1,scrollXold
	swp r0,r0,[r1]		;r0=lastval

	;get the real scanline
;	---------------####	Area covered by "scanline"-1
;       ###############

;       ---------------####	Area desired by "scanline"-1
;       ########.......

;       ........#######    	In this area, add 1 to scanline
	ldrb addy,midscanline
	movs addy,addy
	ldreq addy,cyclesperscanline1
	sub addy,addy,cycles
	cmp addy,#128<<CYC_SHIFT
	ldr addy,scanline	;addy=scanline
	sublt addy,addy,#1

	cmp addy,#240
	movhi addy,#240
scrollXfinish		;newframe jumps here
	adrl r2,scrollXline
	swp r1,addy,[r2]	;r1=lastline, lastline=scanline, addy=scanline
	;sl == 0 >> exit
	;sl < prev  >> prev = 0
	;sl == prev >> exit
	cmp addy,#0
	bxeq lr
	subs addy,addy,r1
	bxeq lr
	addlt addy,addy,r1  ;could this happen?
	movlt r1,#0
	;addy = number of scanlines to fill
	
	add r0,r0,#SCREEN_LEFT ;add 8 for screen offset
	ldr r2,scrollbuff
	;should not be zero
	add r1,r2,r1,lsl#2
sx1
	strh r0,[r1],#4 	;fill forwards from lastline to scanline-1
	subs addy,addy,#1
	bgt sx1
	bx lr

;scrollXold DCD 0 ;last write
;scrollXline DCD 0 ;..was when?

bgscrollY
	strb r0,scrollY

	ldr r1,vramaddr2	;the link between Y scrolling and VRAM address
	bic r1,r1,#0x7300
	bic r1,r1,#0x00e0
	and r2,r0,#0xf8
	and r0,r0,#7
	orr r1,r1,r2,lsl#2
	orr r1,r1,r0,lsl#12
	str r1,vramaddr2
	
;	b newY
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

	;look at this code again... fixme
	str lr,[sp,#-4]!
	ldr r0,scrollX
	bic r0,r0,#0x7F00
	bic r0,r0,#0x00F8
	and r2,r1,#0x001f
	and addy,r1,#0x0400
	orr r0,r0,r2,lsl#3
	orr r0,r0,addy,lsr#2
	str r0,scrollX
	strb r0,nextx
	bl newX2
	ldr lr,[sp],#4
	
	ldr r0,scrollY

;- - - - - -
newY
	;get the real scanline
	ldrb r1,midscanline
	movs r1,r1
	ldreq r1,cyclesperscanline1
	sub r1,r1,cycles
	cmp r1,#128<<CYC_SHIFT
	ldr addy,scanline	;addy=scanline
	sublt addy,addy,#1

;	ldr r0,scrollY		;r0=y, this was moved above
	blt %f0
scroll_threshhold_mod
	cmp r1,#(251-3*3)*CYCLE	;251 cycles, but the instruction leading up to this takes 3*3 PPU cycles before the write
	bge %f0
	cmp addy,#0
	
	addne r0,r0,#1
0
	
	adrl r1,scrollYold
	swp r0,r0,[r1]		;r0=lastval
	
	movs addy,addy
	movmi addy,#0
	

	cmp addy,#240
	movhi addy,#240


scrollYfinish
	adrl r2,scrollYline
	swp r1,addy,[r2]	;r1=lastline, lastline=scanline

	;sl == 0 >> exit
	;sl < prev  >> prev = 0
	;sl == prev >> exit
	cmp addy,#0
	bxeq lr
	subs addy,addy,r1
	bxeq lr
	addlt addy,addy,r1  ;could this happen?
	
	stmfd sp!,{r3,r4,lr}
	sub r3,r0,r1
	movlt r1,#0
	
	;addy = number of scanlines to fill
	ldr r2,scrollbuff
	add r1,r2,r1,lsl#2
	add r1,r1,#2

recheck239	
	;do the 239 check
	and r2,r0,#0xFF
	add r2,r2,addy
	subs r2,r2,#240
	bgt sy_goesover
sy1
	strh r3,[r1],#4
	subs addy,addy,#1
	bgt sy1
	ldmfd sp!,{r3,r4,pc}

sy_goesover
	;r2 = scanline count amount after moving down
	;addy = total scanline count
	;if addy<=r2, then source was offscreen
	subs r4,addy,r2
	ble sy_wasover
sy2
	strh r3,[r1],#4
	subs r4,r4,#1
	bgt sy2

	add r3,r3,#16
sy3
	strh r3,[r1],#4
	subs r2,r2,#1
	bgt sy3
	ldmfd sp!,{r3,r4,pc}
sy_wasover
	add r3,r3,#240
	add r0,r0,#240
	b recheck239


;scrollYold DCD 0 ;last write
;scrollYline DCD 0 ;..was when?
;----------------------------------------------------------------------------
vmdata_R	;(2007)
;----------------------------------------------------------------------------
	ldr r0,vramaddr
	ldrb r1,vramaddrinc
	bic r0,r0,#0xfc000
	add r2,r0,r1
	str r2,vramaddr

	cmp r0,#0x3f00
	bhs_long palread

	and r1,r0,#0x3c00
	adr r2,vram_map
	ldr r1,[r2,r1,lsr#8]
	bic r0,r0,#0xfc00

	ldrb r1,[r1,r0]
	ldrb r0,readtemp
	str r1,readtemp
	mov pc,lr

;----------------------------------------------------------------------------
vmdata_W	;(2007)
;----------------------------------------------------------------------------
	ldr addy,vramaddr
	ldrb r1,vramaddrinc
	bic addy,addy,#0xfc000 ;AND $3fff
	add r2,addy,r1
	str r2,vramaddr

vram_write_direct
	and r1,addy,#0x3c00
	adr r2,vram_write_tbl
	ldr pc,[r2,r1,lsr#8]
;----------------------------------------------------------------------------
VRAM_chr;	0000-1fff
;----------------------------------------------------------------------------
	ldr r2,=NES_VRAM
	strb r0,[r2,addy]
	[ DIRTYTILES
VRAM_chr_entry
	mov r0,#1
	ldr r2,=dirty_rows
	strb r0,[r2,addy,lsr#8]
	ldr r2,=dirty_tiles
	strb r0,[r2,addy,lsr#4]
	bx lr
	|
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
	add r1,r1,#BG_VRAM		;AGB BG tileset
	add addy,r1,#(SPR_VRAM-BG_VRAM)+SPR_CACHE_OFFSET
	tst r1,#0x2000		;1st or 2nd page?
	addne r1,r1,#0x2000	;0000/4000 for BG, 14000/16000 for OBJ

	str r0,[r1]
	str r0,[addy]

	bx lr
	]
	
	[ MIXED_VRAM_VROM
	[ DIRTYTILES
;----------------------------------------------------------------------------
VRAM_chr3;	0000-1fff
;----------------------------------------------------------------------------
	mov r1,addy,lsr#10
	adr r2,vram_map
	ldr r2,[r2,r1,lsl#2]
	ldr r1,=NES_VRAM
	subs r1,r2,r1
	;r2 = physical address, r1 = virtual address
	bxlt lr		;bounds checking
	cmp r1,#0x2000
	bxge lr		;bounds checking
	bic addy,addy,#0xFC00
	strb r0,[addy,r2]
	add addy,addy,r1
	b VRAM_chr_entry
	]
	]


	[ USE_BG_CACHE
;r1 = address & 0x3C00
;bits guaranteed to be set in r1: 0x2000
;r1 >> 8 = an address in a word table to a word (such as an address)
;r1 >> 10 = an address is a byte table (such as a tile number offset)

;	adr r2,some_table-32
;	ldr r1,[r2,r1,lsr#8]!
;	ldr r2,[r2,#8]

;----------------------------------------------------------------------------
VRAM_name0	;(2000-23ff)
;----------------------------------------------------------------------------
	ldr r1,=NES_VRAM2
	mov r2,#0
writeBG
	bic addy,addy,#0xFC00
	strb r0,[r1,addy]
writeBG_mapper_9_mod
	nop
writeBG_mapper_9_mod_return
	add addy,addy,r2
	ldrb r2,bg_cache_full
	movs r2,r2
	bxne lr
	;store
	ldr r2,bg_cache_cursor
	ldr r1,=BG_CACHE
	strh addy,[r1,r2]
	add r2,r2,#2
	bic r2,r2,#BG_CACHE_SIZE
	str r2,bg_cache_cursor
	;compare
	ldr r1,bg_cache_limit
	cmp r1,r2
	bxne lr
	;set full
	mov r1,#1
	strb r1,bg_cache_full
	bx lr
;----------------------------------------------------------------------------
VRAM_name1	;(2400-27ff)
;----------------------------------------------------------------------------
	ldr r1,=NES_VRAM2+0x400
	mov r2,#0x400
	b writeBG
;----------------------------------------------------------------------------
VRAM_name2	;(2800-2bff)
;---------------------------------------------------------------------------
	ldr r1,=NES_VRAM4
	mov r2,#0x800
	b writeBG
;----------------------------------------------------------------------------
VRAM_name3	;(2c00-2fff)
;----------------------------------------------------------------------------
	ldr r1,=NES_VRAM4+0x400
	mov r2,#0xC00
	b writeBG



writeBG_mapper_9_checks
	cmp r0,#0xFD
	blt writeBG_mapper_9_mod_return
	cmp addy,#0x3C0
	bge writeBG_mapper_9_mod_return
	stmfd sp!,{r0,r2,addy,lr}
	add addy,addy,addy
	bl_long mapper9BGcheck
	ldmfd sp!,{r0,r2,addy,lr}
	b writeBG_mapper_9_mod_return

	|
;----------------------------------------------------------------------------
VRAM_name0	;(2000-23ff)
;----------------------------------------------------------------------------
	ldr r1,nes_nt0
	ldr r2,=AGB_BG+0x0000
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
		bxlt lr
		ldrb r1,mapper_number
		cmp r1,#9
		cmpne r1,#10
		bxne lr
		b_long mapper9BGcheck
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
	ldr r2,=AGB_BG+0x0800
;	ldr r2,agb_nt1
	b writeBG
;----------------------------------------------------------------------------
VRAM_name2	;(2800-2bff)
;---------------------------------------------------------------------------
	ldr r1,nes_nt2
	ldr r2,=AGB_BG+0x1000
;	ldr r2,agb_nt2
	b writeBG
;----------------------------------------------------------------------------
VRAM_name3	;(2c00-2fff)
;----------------------------------------------------------------------------
	ldr r1,nes_nt3
	ldr r2,=AGB_BG+0x1800
;	ldr r2,agb_nt3
	b writeBG
	]
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

	AREA wram_globals5, CODE, READWRITE

g_nesoamdirty	DCB 0
g_consumetiles_ok	DCB 0
g_frameready	DCB 0
g_firstframeready	DCB 0

_vram_write_tbl	;for vmdata_W, r0=data, addy=vram addr
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

_vram_map	;for vmdata_R
	DCD 0
	DCD 0
	DCD 0
	DCD 0
	DCD 0
	DCD 0
	DCD 0
	DCD 0
_nes_nt0 DCD NES_VRAM2+0x0000 ;$2000
_nes_nt1 DCD NES_VRAM2+0x0000 ;$2400
_nes_nt2 DCD NES_VRAM2+0x0400 ;$2800
_nes_nt3 DCD NES_VRAM2+0x0400 ;$2c00
	DCD NES_VRAM2+0x0000 ;$3xxx=?
	DCD NES_VRAM2+0x0000
	DCD NES_VRAM2+0x0400
	DCD NES_VRAM2+0x0400

;_agb_nt_map	;set thru mirror*
;_agb_nt0 DCD 0
;_agb_nt1 DCD 0
;_agb_nt2 DCD 0
;_agb_nt3 DCD 0

_agb_pal		% 32*2	;copy this to real AGB palette every frame
_nes_palette	% 32	;NES $3F00-$3F1F

_scrollbuff DCD SCROLLBUFF1
_dmascrollbuff DCD SCROLLBUFF2
_nesoambuff	DCD NESOAMBUFF2
_dmanesoambuff	DCD NESOAMBUFF2
_bg0cntbuff	DCD BG0CNTBUFF1
_dmabg0cntbuff	DCD BG0CNTBUFF2
_dispcntbuff	DCD DISPCNTBUFF1
_dmadispcntbuff	DCD DISPCNTBUFF2

_bankbuffer_last DCD 0,0
_bankbuffer	DCD BANKBUFFER1
_dmabankbuffer	DCD BANKBUFFER2
_bankbuffer_line	DCD 0

_ctrl1old	DCD 0x0440	;last write
_ctrl1line	DCD 0 ;when?

_stat_r_simple_func	DCD 0
_nextnesoambuff	DCD NESOAMBUFF1


;----------------------------------------------------------------------------
	AREA wram_globals1, CODE, READWRITE

FPSValue
	DCD 0
AGBinput		;this label here for main.c to use
	DCD 0 ;AGBjoypad (why is this in ppu.s again?  um.. i forget)
EMUinput	DCD 0 ;NESjoypad (this is what NES sees)
;wtop	DCD 0,0,0,0 ;windowtop  (this label too)   L/R scrolling in unscaled mode

;begin ppustate
ppustate
	DCD 0 ;vramaddr
	DCD 0 ;vramaddr2 (temp)
g_scrollX	DCD 0 ;scrollX
	DCD 0 ;scrollY
	DCD 0 ;sprite0y
	DCD 0 ;readtemp

	DCB 0 ;sprite0x
	DCB 1 ;vramaddrinc
ppustat_savestate	DCB 0 ;ppustat (not used)
	DCB 0 ;toggle
	DCB 0 ;ppuctrl0
g_ppuctrl0frame
	DCB 0 ;ppuctrl0frame	;state of $2000 at frame start
g_ppuctrl1
	DCB 0 ;ppuctrl1
	DCB 0 ;ppuoamadr

g_nextx	DCD 0 ;nextx
;not in ppustate

	DCD 0 ;scrollXold
	DCD 0 ;scrollXline
	DCD 0 ;scrollYold
	DCD 0 ;scrollYline
	DCD 0 ;ppuhack_line
	DCB 0 ;ppuhack_count
g_PAL60	DCB 0 ;PAL60
novblankwait	DCB 0 ;novblankwait_
wtop	DCB 0 ;windowtop
	DCB 0 ;adjustblend
	DCB 0 ;has_run_nes_chr_update_this_frame
g_has_vram	DCB 0 ;has_vram
g_bankable_vrom	DCB 0 ;bankable_vrom

g_vram_page_mask DCB 0 ;vram_page_mask
g_vram_page_base DCB 0 ;vram_page_base
wtop_scaled6_8 DCB 16 ;windowtop_scaled6_8
wtop_scaled7_8 DCB 0 ;windowtop_scaled7_8

	[ DIRTYTILES
g_recent_tiles	DCD RECENT_TILES1
g_dmarecent_tiles	DCD RECENT_TILES2
g_recent_tilenum	DCD RECENT_TILENUM1
g_dmarecent_tilenum	DCD RECENT_TILENUM2
	]
	
	[ USE_BG_CACHE
	DCD 0 ;bg_cache_cursor
	DCD 0 ;bg_cache_base
	DCD 0 ;bg_cache_limit
	
_bg_cache_full	DCB 0 ;bg_cache_full
	DCB 0 ;bg_cache_updateok

	;these two may need to be removed from this block
g_twitch	DCB 0
g_flicker DCB 1
	]

	
	
;...update load/savestate if you move things around in here
;----------------------------------------------------------------------------
	END

