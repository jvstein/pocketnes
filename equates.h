		GBLL DEBUG
		GBLL SAFETY
		GBLL CHEATFINDER
		GBLL MOVIEPLAYER
		GBLL VERSION_IN_ROM
		GBLL SAVE32
		GBLL DIRTYTILES
		GBLL SPRITESCAN
		GBLL RTCSUPPORT
		GBLL CARTSAVE
		GBLL MIXED_VRAM_VROM
		GBLL LESSMAPPERS
		GBLL APACK
		GBLL VISOLY
		GBLL USE_BG_CACHE
		GBLL RESET_ALL
		GBLL LINK
		GBLL SAVESTATES

		GBLL HAPPY_CPU_TESTER
HAPPY_CPU_TESTER SETL {FALSE}

	[ VERSION = "COMPY"
LINK SETL {FALSE}
RESET_ALL SETL {FALSE}
USE_BG_CACHE SETL {FALSE}
CARTSAVE SETL {FALSE}
RTCSUPPORT SETL {FALSE}
DEBUG		SETL {FALSE}
CHEATFINDER	SETL {FALSE}
MOVIEPLAYER	SETL {FALSE}
VERSION_IN_ROM	SETL {FALSE}
SAVE32 SETL {FALSE}
DIRTYTILES SETL {FALSE}
SPRITESCAN SETL {FALSE}
MIXED_VRAM_VROM SETL {FALSE}
LESSMAPPERS SETL {TRUE}
APACK	SETL	{TRUE}
VISOLY SETL {FALSE}
  |
  [ VERSION = "GBAMP"
LINK SETL {TRUE}
RESET_ALL SETL {TRUE}
USE_BG_CACHE SETL {TRUE}
CARTSAVE SETL {FALSE}
RTCSUPPORT SETL {FALSE}
DEBUG		SETL {FALSE}
CHEATFINDER	SETL {FALSE}
MOVIEPLAYER	SETL {TRUE}
VERSION_IN_ROM	SETL {TRUE}
SAVE32 SETL {FALSE}
DIRTYTILES SETL {TRUE}
SPRITESCAN SETL {TRUE}
MIXED_VRAM_VROM SETL {TRUE}
LESSMAPPERS SETL {FALSE}
APACK	SETL	{FALSE}
VISOLY SETL {FALSE}
  |
LINK SETL {TRUE}
RESET_ALL SETL {TRUE}
USE_BG_CACHE SETL {TRUE}
CARTSAVE SETL {TRUE}
RTCSUPPORT SETL {TRUE}
DEBUG		SETL {FALSE}
CHEATFINDER	SETL {TRUE}
MOVIEPLAYER	SETL {FALSE}
VERSION_IN_ROM	SETL {TRUE}
DIRTYTILES SETL {TRUE}
SPRITESCAN SETL {TRUE}
MIXED_VRAM_VROM SETL {TRUE}
LESSMAPPERS SETL {FALSE}
APACK	SETL	{TRUE}
  [ NOCASH
SAVE32 SETL {TRUE}
VISOLY SETL {FALSE}
  |
SAVE32 SETL {FALSE}
VISOLY SETL {TRUE}
  ]

  ]
  ]

	[ CARTSAVE
SAVESTATES SETL {TRUE}
	]
	[ MOVIEPLAYER
SAVESTATES SETL {TRUE}
	]

SPR_CACHE_START EQU 8
SPR_CACHE_OFFSET EQU SPR_CACHE_START*2048
	[ USE_BG_CACHE
BG_CACHE_SIZE EQU 512
	]

	[ DIRTYTILES
MAX_RECENT_TILES EQU 20  ;Battletoads updates up to 20 tiles per frame
	]


;BUILD		SETS "DEBUG"/"GBA"	(defined at cmdline)
;----------------------------------------------------------------------------

	INCLUDE macro.h

	GBLL IWRAM_GROWDOWN
IWRAM_GROWDOWN SETL {FALSE}

 [ {FALSE}

NES_RAM			EQU 0x3005000		;800	;keep $400 byte aligned for 6502 stack shit
NES_SRAM		EQU NES_RAM+0x0800	;2000
CHR_DECODE		EQU NES_SRAM+0x2000	;400

 [ IWRAM_GROWDOWN
END_OF_IWRAM	EQU CHR_DECODE+0x400

YSCALE_LOOKUP	EQU NES_RAM-0x108
YSCALE_EXTRA	EQU YSCALE_LOOKUP-0x50

START_OF_IWRAM	EQU YSCALE_EXTRA
 |
YSCALE_EXTRA	EQU CHR_DECODE+0x400
YSCALE_LOOKUP	EQU YSCALE_EXTRA+0x50
END_OF_IWRAM	EQU YSCALE_LOOKUP+0x108
START_OF_IWRAM	EQU NES_RAM
 ]
;stack has 48 bytes of breathing room left!
 ]

;;	[ VERSION="COMPY"
;;PCMWAVSIZE		EQU 128
;;;PCMWAV			EQU YSCALE_EXTRA-PCMWAVSIZE
;;PCMWAV			EQU NES_RAM-PCMWAVSIZE
;;MAPPED_RGB		EQU PCMWAV-0xC0
;;	]

;YSCALE_EXTRA	EQU CHR_DECODE+0x400	;50
;YSCALE_LOOKUP	EQU YSCALE_EXTRA+0x50	;108
;PCMWAVSIZE		EQU 128
;PCMWAV			EQU YSCALE_LOOKUP+0x100	;80
;MAPPED_RGB 	EQU PCMWAV+PCMWAVSIZE   	;C0

;06002020 - $03E0  ;184 (B8) remaining
;06006000 - $2000  ;328 (148) remaining
;0600A000 - $2000  ;free
;06014000 - $4000  ;4608 (1200) remaining, free if no cheatfinder used
SCROLLBUFF1		EQU 0x6002400-240*4

DMA0BUFF		EQU 0x06003800-164*4  ;;48 remaining  ;scaled SCROLLBUFF, scrolling
DMA3BUFF		EQU 0x06004000-164*2	;scaled BG0CNTBUFF, mirroring, bg bank selection
DMA1BUFF		EQU DMA3BUFF-164*2    ;;112 remaining	;scaled DISPCNTBUFF, bg&sprite on/off

SPEEDHACK_FIND_BEQ_BUF		EQU 0x06006800-128
SPEEDHACK_FIND_BNE_BUF		EQU 0x06007000-128

	GBLA	NEXT

MEM_END	EQU 0x02040000
NESOAMBUFF2 EQU MEM_END-256
NESOAMBUFF1 EQU NESOAMBUFF2-256

NEXT SETA NESOAMBUFF1

	[ DIRTYTILES
RECENT_TILES1	EQU NEXT-(MAX_RECENT_TILES*16)
RECENT_TILES2	EQU RECENT_TILES1-(MAX_RECENT_TILES*16)

NEXT SETA RECENT_TILES2
	]

	[ USE_BG_CACHE
BG_CACHE	EQU NEXT-BG_CACHE_SIZE

NEXT SETA BG_CACHE
	]

SPEEDHACK_FIND_JMP_BUF	EQU	NEXT-128
;SPEEDHACK_FIND_BEQ_BUF	;already defined
;SPEEDHACK_FIND_BNE_BUF	;already defined
SPEEDHACK_FIND_BCS_BUF	EQU	SPEEDHACK_FIND_JMP_BUF-128
SPEEDHACK_FIND_BCC_BUF	EQU	SPEEDHACK_FIND_BCS_BUF-128
SPEEDHACK_FIND_BVS_BUF	EQU	SPEEDHACK_FIND_BCC_BUF-128
SPEEDHACK_FIND_BVC_BUF	EQU	SPEEDHACK_FIND_BVS_BUF-128
SPEEDHACK_FIND_BMI_BUF	EQU	SPEEDHACK_FIND_BVC_BUF-128
SPEEDHACK_FIND_BPL_BUF	EQU	SPEEDHACK_FIND_BMI_BUF-128

BG0CNTBUFF1	EQU SPEEDHACK_FIND_BPL_BUF-240*2
BG0CNTBUFF2	EQU BG0CNTBUFF1-240*2
DISPCNTBUFF1	EQU BG0CNTBUFF2-240*2
DISPCNTBUFF2	EQU DISPCNTBUFF1-240*2
;SCROLLBUFF1	;already defined
SCROLLBUFF2		EQU DISPCNTBUFF2-240*4
;DMA3BUFF	;already defined
;DMA1BUFF	;already defined
;DMA0BUFF	;already defined

BANKBUFFER1  EQU SCROLLBUFF2-30*8
BANKBUFFER2  EQU BANKBUFFER1-30*8

;chr_rom_table EQU BANKBUFFER2-1024
spr_cache_map EQU BANKBUFFER2-256
spr_cache_disp	EQU spr_cache_map-16	;Must be immediately AFTER spr_cache in memory
spr_cache	EQU spr_cache_disp-16

NEXT SETA spr_cache

	[ DIRTYTILES
RECENT_TILENUM1	EQU NEXT-(MAX_RECENT_TILES+2)*2
RECENT_TILENUM2	EQU RECENT_TILENUM1-(MAX_RECENT_TILES+2)*2
dirty_rows  EQU RECENT_TILENUM2-32		;Must be immediately AFTER dirty_tiles in memory
dirty_tiles EQU dirty_rows -516

NEXT SETA dirty_tiles

	]

;	[ VERSION <> "COMPY"
PCMWAVSIZE		EQU 128
PCMWAV			EQU NEXT-PCMWAVSIZE
MAPPED_RGB		EQU PCMWAV-0xC0
NEXT SETA MAPPED_RGB
;	]

	[ CARTSAVE
CachedConfig	EQU NEXT-48
NEXT SETA CachedConfig
	]

NES_VRAM2   EQU NEXT-2048
NES_VRAM	EQU NES_VRAM2-0x2000
NES_VRAM4   EQU NES_VRAM-2048
FREQTBL2			EQU NES_VRAM4-0x1000
END_OF_EXRAM	EQU FREQTBL2	;!How much data is left for Multiboot to work!

MULTIBOOT_LIMIT EQU END_OF_EXRAM

;CHEATFINDER_VALUES EQU 0x6014000-10240
;CHEATFINDER_BITS EQU CHEATFINDER_VALUES-1280  ;2624 (A40) remaining
;CHEATFINDER_CHEATS EQU CHEATFINDER_BITS-900 ;must be multiple of 3 and 2 (4?)

AGB_IRQVECT		EQU 0x3007FFC
AGB_PALETTE		EQU 0x5000000
AGB_VRAM		EQU 0x6000000
AGB_OAM			EQU 0x7000000
AGB_SRAM		EQU 0xE000000
AGB_BG			EQU AGB_VRAM+0x6000
DEBUGSCREEN		EQU AGB_VRAM+0x3800

REG_BASE		EQU 0x4000000
REG_DISPCNT		EQU 0x00
REG_DISPSTAT	EQU 0x04
REG_VCOUNT		EQU 0x06
REG_BG0CNT		EQU 0x08
REG_BG1CNT		EQU 0x0A
REG_BG2CNT		EQU 0x0C
REG_BG3CNT		EQU 0x0E
REG_BG0HOFS		EQU 0x10
REG_BG0VOFS		EQU 0x12
REG_BG1HOFS		EQU 0x14
REG_BG1VOFS		EQU 0x16
REG_BG2HOFS		EQU 0x18
REG_BG2VOFS		EQU 0x1A
REG_BG3HOFS		EQU 0x1C
REG_BG3VOFS		EQU 0x1E
REG_WIN0H		EQU 0x40
REG_WIN1H		EQU 0x42
REG_WIN0V		EQU 0x44
REG_WIN1V		EQU 0x46
REG_WININ		EQU 0x48
REG_WINOUT		EQU 0x4A
REG_BLDCNT		EQU 0x50
REG_BLDALPHA	EQU 0x52
REG_BLDY		EQU 0x54
REG_SG1CNT_L	EQU 0x60
REG_SG1CNT_H	EQU 0x62
REG_SG1CNT_X	EQU 0x64
REG_SG2CNT_L	EQU 0x68
REG_SG2CNT_H	EQU 0x6C
REG_SG3CNT_L	EQU 0x70
REG_SG3CNT_H	EQU 0x72
REG_SG3CNT_X	EQU 0x74
REG_SG4CNT_L	EQU 0x78
REG_SG4CNT_H	EQU 0x7c
REG_SGCNT_L		EQU 0x80
REG_SGCNT_H		EQU 0x82
REG_SGCNT_X		EQU 0x84
REG_SGBIAS		EQU 0x88
REG_SGWR0_L		EQU 0x90
REG_FIFO_A_L	EQU 0xA0
REG_FIFO_A_H	EQU 0xA2
REG_FIFO_B_L	EQU 0xA4
REG_FIFO_B_H	EQU 0xA6
REG_DM0SAD		EQU 0xB0
REG_DM0DAD		EQU 0xB4
REG_DM0CNT_L	EQU 0xB8
REG_DM0CNT_H	EQU 0xBA
REG_DM1SAD		EQU 0xBC
REG_DM1DAD		EQU 0xC0
REG_DM1CNT_L	EQU 0xC4
REG_DM1CNT_H	EQU 0xC6
REG_DM2SAD		EQU 0xC8
REG_DM2DAD		EQU 0xCC
REG_DM2CNT_L	EQU 0xD0
REG_DM2CNT_H	EQU 0xD2
REG_DM3SAD		EQU 0xD4
REG_DM3DAD		EQU 0xD8
REG_DM3CNT_L	EQU 0xDC
REG_DM3CNT_H	EQU 0xDE
REG_TM0D		EQU 0x100
REG_TM0CNT		EQU 0x102
REG_IE			EQU 0x200
REG_IF			EQU 0x4000202
REG_P1			EQU 0x4000130
REG_P1CNT		EQU 0x132
REG_WAITCNT		EQU 0x4000204

REG_SIOMULTI0	EQU 0x20 ;+100
REG_SIOMULTI1	EQU 0x22 ;+100
REG_SIOMULTI2	EQU 0x24 ;+100
REG_SIOMULTI3	EQU 0x26 ;+100
REG_SIOCNT		EQU 0x28 ;+100
REG_SIOMLT_SEND	EQU 0x2a ;+100
REG_RCNT		EQU 0x34 ;+100

		;r0,r1,r2=temp regs
m6502_nz	RN r3 ;bit 31=N, Z=1 if bits 0-7=0
m6502_mmap	RN r4 ;memmap_tbl
m6502_a		RN r5 ;bits 0-23=0, also used to clear bytes in memory
m6502_x		RN r6 ;bits 0-23=0
m6502_y		RN r7 ;bits 0-23=0
cycles		RN r8 ;also VDIC flags
m6502_pc	RN r9
globalptr	RN r10 ;=wram_globals* ptr
m6502_optbl	RN r10
cpu_zpage	RN r11 ;=CPU_RAM
addy		RN r12 ;keep this at r12 (scratch for APCS)
		;r13=SP
		;r14=LR
		;r15=PC
zero_byte	RN r5

;----------------------------------------------------------------------------

 MAP 0,cpu_zpage
nes_ram # 0x800
nes_sram # 0x2000
;chr_decode # 0x400

;everything in wram_globals* areas:

 MAP 0,globalptr	;6502.s
 # -26*4
writemem_tbl_base # 8*4
writemem_tbl # 4

memmap_tbl # 8*4

readmem_tbl_base # 8*4
readmem_tbl # 4

opz # 256*4
;###begin cpustate
cpuregs # 7*4
m6502_s # 4
;###end cpustate
frame # 4
scanline # 4
lastbank # 4
nexttimeout # 4
line_end_timeout # 4
line_mid_timeout # 4
scanlinehook # 4
midlinehook # 4
cyclesperscanline1 # 4
cyclesperscanline2 # 4
lastscanline # 4

midscanline # 1
_dontstop # 1
hackflags3 # 1
ppuctrl1_startframe # 1

			;ppu.s (wram_globals1)
fpsvalue # 4
AGBjoypad # 4
NESjoypad # 4

;###begin ppustate
vramaddr # 4
vramaddr2 # 4
scrollX # 4
scrollY # 4
sprite0y # 4
readtemp # 4

sprite0x # 1
vramaddrinc # 1
ppustat # 1
toggle # 1
ppuctrl0 # 1
ppuctrl0frame # 1
ppuctrl1 # 1
ppuoamadr # 1
nextx # 4
;###end ppustate

scrollXold # 4
scrollXline # 4
scrollYold # 4
scrollYline # 4
ppuhack_line # 4
ppuhack_count # 1
PAL60 # 1
novblankwait_ # 1
windowtop # 1

adjustblend # 1
has_run_nes_chr_update_this_frame # 1
has_vram # 1
bankable_vrom # 1

vram_page_mask # 1
vram_page_base # 1
windowtop_scaled6_8 # 1
windowtop_scaled7_8 # 1

	[ DIRTYTILES
recent_tiles # 4
dmarecent_tiles # 4
recent_tilenum # 4
dmarecent_tilenum	# 4
	]

	[ USE_BG_CACHE
bg_cache_cursor # 4
bg_cache_base # 4
bg_cache_limit # 4
bg_cache_full # 1
bg_cache_updateok # 1
	;warning!  Missing '# 2' inside here  Maybe move the next two lines if you need to
	]

twitch # 1
flicker # 1

			;cart.s (wram_globals2)
;###begin mapperstate
mapperdata # 32
 # 3
bank6 # 1
bank8 # 1
bankA # 1
bankC # 1
bankE # 1
nes_chr_map # 8
;###end mapperstate
agb_bg_map # 16
agb_real_bg_map # 16
bg_recent # 4

rombase # 4
romnumber # 4
emuflags # 4
BGmirror # 4

rommask # 4
vrombase # 4
vrommask # 4

instant_prg_banks # 4
instant_chr_banks # 4

cartflags # 1
hackflags # 1
hackflags2 # 1
mapper_number # 1

rompages # 1
vrompages # 1
fourscreen # 1
 # 1

chrold # 4
chrline # 4

; # 0 ;align

	;sound.s (wram_globals3)

apu_4017 # 1
doframeirq # 1
 # 2

sq0freq	# 4
saveSG11 # 4
sq0timeout # 4
sq0sweepnext # 4
sweepctrl # 4
sq0envelope # 4
sq0enveloperate # 4
sq1freq	# 4
saveSG21 # 4
sq1timeout # 4
sq1sweepnext # 4
sq1envelope # 4
sq1enveloperate # 4
trifreq # 4
tritimeout1 # 4
tritimeout2 # 4
noisetimeout # 4
noiseenvelope # 4
noiseenveloperate # 4
saveSG41 # 4
pcmctrl # 4		;bit7=irqen, bit6=loop.  bit 12=PCM enable (from $4015). bits 8-15=old $4015
pcmlength # 4		;total bytes
pcmcount # 4		;bytes remaining
pcmlevel # 4
soundmask # 4		;mask for SGCNT_L
soundctrl # 4		;1st control reg for ch1-4

pcmstart # 4		;starting addr
pcmcurrentaddr # 4	;current addr
freqtbl # 4


	;io.s (wram_globals4)
sending # 4
lastsent # 4
received0 # 4
received1 # 4
received2 # 4
received3 # 4

joycfg # 4
joy0state # 1
joy1state # 1
joy2state # 1
joy3state # 1
joy0serial # 4
joy1serial # 4
nrplayers # 4

	;ppu.s (wram_globals5)

nesoamdirty # 1
consumetiles_ok # 1
frameready # 1
firstframeready	# 1

vram_write_tbl # 16*4
vram_map # 8*4
nes_nt0 # 4
nes_nt1 # 4
nes_nt2 # 4
nes_nt3 # 4
 # 4*4
;agb_nt_map # 4
;agb_nt0 # 4
;agb_nt1 # 4
;agb_nt2 # 4
;agb_nt3 # 4

agb_pal		# 32*2
nes_palette	# 32

scrollbuff		# 4
dmascrollbuff	# 4
nesoambuff		# 4
dmanesoambuff	# 4
bg0cntbuff		# 4
dmabg0cntbuff	# 4
dispcntbuff		# 4
dmadispcntbuff	# 4

bankbuffer_last # 4*2
bankbuffer		# 4
dmabankbuffer	# 4
bankbuffer_line	# 4

ctrl1old	# 4
ctrl1line	# 4

stat_r_simple_func # 4
nextnesoambuff # 4

;----------------------------------------------------------------------------
IRQ_VECTOR		EQU 0xfffe ; IRQ/BRK interrupt vector address
RES_VECTOR		EQU 0xfffc ; RESET interrupt vector address
NMI_VECTOR		EQU 0xfffa ; NMI interrupt vector address
;-----------------------------------------------------------cartflags
MIRROR			EQU 0x01 ;horizontal mirroring
SRAM			EQU 0x02 ;save SRAM
TRAINER			EQU 0x04 ;trainer present
SCREEN4			EQU 0x08 ;4way screen layout
VS				EQU 0x10 ;VS unisystem
;-----------------------------------------------------------hackflags
NoHacks			EQU 0x00
FindingHacks	EQU 0x01
BplHack			EQU 0x10
BneHack			EQU 0xD0
BeqHack			EQU 0xF0
;-----------------------------------------------------------emuflags
USEPPUHACK		EQU 1	;use $2002 hack
NOCPUHACK		EQU 2	;don't use JMP hack
PALTIMING		EQU 4	;0=NTSC 1=PAL
;?				EQU 8
;?				EQU 16
FOLLOWMEM		EQU 32  ;0=follow sprite, 1=follow mem
;?				EQU 64
;?				EQU 128

				;bits 8-15=scale type

UNSCALED_NOAUTO	EQU 0	;display types
UNSCALED_AUTO	EQU 1
SCALED			EQU 2
SCALED_SPRITES	EQU 3

				;bits 16-31=sprite follow val

;----------------------------------------------------------------------------
CYC_SHIFT		EQU 8
CYCLE			EQU 1<<CYC_SHIFT ;one cycle (341*CYCLE cycles per scanline)

;cycle flags- (stored in cycles reg for speed)

CYC_C			EQU 0x01	;Carry bit
BRANCH			EQU 0x02	;branch instruction encountered
CYC_I			EQU 0x04	;IRQ mask
CYC_D			EQU 0x08	;Decimal bit
CYC_V			EQU 0x40	;Overflow bit
CYC_MASK		EQU CYCLE-1	;Mask
;----------------------------------------------------------------------------
YSTART			EQU 16 ;scaled NES screen starts on this line

		END
