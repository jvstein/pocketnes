		GBLL DEBUG
		GBLL SAFETY

DEBUG		SETL {FALSE}

;BUILD		SETS "DEBUG"/"GBA"	(defined at cmdline)
;----------------------------------------------------------------------------

NES_RAM		EQU 0x3004800	;$400 byte align for 6502 stack shit
NES_SRAM	EQU NES_RAM+0x0800
CHR_DECODE	EQU NES_RAM+0x2800
OAM_BUFFER1	EQU NES_RAM+0x2c00
OAM_BUFFER2	EQU NES_RAM+0x2e00
OAM_BUFFER3	EQU NES_RAM+0x3000
YSCALE_EXTRA	EQU NES_RAM+0x3200
YSCALE_LOOKUP	EQU NES_RAM+0x3250
;?		EQU NES_RAM+0x3350

NES_VRAM	EQU 0x2040000-0x3000
MAPPED_RGB	EQU NES_VRAM-64*2	;mapped NES palette (for VS unisys)
DISPCNTBUFF	EQU MAPPED_RGB-240*2
DMA1BUFF	EQU DISPCNTBUFF-164*2
BG0CNTBUFF	EQU DMA1BUFF-240*2
DMA3BUFF	EQU BG0CNTBUFF-164*2
SCROLLBUFF1	EQU DMA3BUFF-240*4
SCROLLBUFF2	EQU SCROLLBUFF1-240*4
DMA0BUFF	EQU SCROLLBUFF2-164*4
;PCMSAMPLES	EQU 256
;PCMWAV		EQU DMA0BUFF-PCMSAMPLES

AGB_IRQVECT	EQU 0x3007FFC
AGB_PALETTE	EQU 0x5000000
AGB_VRAM	EQU 0x6000000
AGB_OAM		EQU 0x7000000
AGB_BG		EQU AGB_VRAM+0xe000
DEBUGSCREEN	EQU AGB_VRAM+0x3800

REG_BASE	EQU 0x4000000
REG_DISPCNT	EQU 0x00
REG_DISPSTAT	EQU 0x04
REG_VCOUNT	EQU 0x06
REG_BG0CNT	EQU 0x08
REG_BG1CNT	EQU 0x0a
REG_BG0HOFS	EQU 0x10
REG_BG0VOFS	EQU 0x12
REG_BG1HOFS	EQU 0x14
REG_BG1VOFS	EQU 0x16
REG_BLDMOD	EQU 0x50
REG_COLEV	EQU 0x52
REG_COLY	EQU 0x54
REG_SG10_L	EQU 0x60
REG_SG10_H	EQU 0x62
REG_SG11	EQU 0x64
REG_SG20	EQU 0x68
REG_SG21	EQU 0x6C
REG_SG30_L	EQU 0x70
REG_SG30_H	EQU 0x72
REG_SG31	EQU 0x74
REG_SG40	EQU 0x78
REG_SG41	EQU 0x7c
REG_SGCNT0_L	EQU 0x80
REG_SGCNT1	EQU 0x84
REG_SGCNT0_H	EQU 0x82
REG_SGBIAS	EQU 0x88
REG_SGWR0_L	EQU 0x90
REG_DM0SAD	EQU 0xB0
REG_DM0DAD	EQU 0xB4
REG_DM0CNT_L	EQU 0xB8
REG_DM0CNT_H	EQU 0xBA
REG_DM1SAD	EQU 0xBC
REG_DM1DAD	EQU 0xC0
REG_DM1CNT_L	EQU 0xC4
REG_DM1CNT_H	EQU 0xC6
REG_DM2SAD	EQU 0xC8
REG_DM2DAD	EQU 0xCC
REG_DM2CNT_L	EQU 0xD0
REG_DM2CNT_H	EQU 0xD2
REG_DM3SAD	EQU 0xD4
REG_DM3DAD	EQU 0xD8
REG_DM3CNT_L	EQU 0xDC
REG_DM3CNT_H	EQU 0xDE
REG_SGFIFOB_L	EQU 0xA4
REG_TM0D	EQU 0x100
REG_TM0CNT	EQU 0x102
REG_IE		EQU 0x200
REG_P1		EQU 0x4000130
REG_P1CNT	EQU 0x132
REG_WSCNT	EQU 0x4000204

		;r0,r1,r2=temp regs
nes_nz		RN r3 ;bit 31=N, Z=1 if bits 0-7=0
nes_c		RN r4 ;PSR_C (everything else undefined)
nes_a		RN r5 ;bits 0-23=undefined (adc)
nes_x		RN r6 ;bits 8-31=0
nes_y		RN r7 ;bits 8-31=0
cycles		RN r8
nes_pc		RN r9
globalptr	RN r10 ;=wram_globals* ptr
nes_optbl	RN r10
nes_zpage	RN r11 ;=NES_RAM
addy		RN r12 ;keep this at r12 (scratch for APCS)
		;r13=SP
		;r14=LR
		;r15=PC
;----------------------------------------------------------------------------

 MAP 0,nes_zpage
nes_ram # 0x800
nes_sram # 0x2000
chr_decode # 0x400
oam_buffer1 # 0x200
oam_buffer2 # 0x200
oam_buffer3 # 0x200
yscale_extra # 0x50	;(240-160) extra 80 is for scrolling unscaled sprites
yscale_lookup # 0x100	;sprite Y LUT

;everything in wram_globals* areas:

 MAP 0,globalptr	;6502.s
opz # 256*4
readmem_tbl # 8*4
writemem_tbl # 8*4
memmap_tbl # 8*4
cpuregs # 7*4
nes_s # 4
nes_di # 4
nes_v # 4
lastbank # 4
nexttimeout # 4
scanline # 4
scanlinehook # 4
frame # 4
cyclesperscanline # 4
lastscanline # 4
			;ppu.s (wram_globals1)
AGBjoypad # 4
adjustblend # 4
windowtop # 16
vramaddr # 4
vramaddr2 # 4
scrollX # 4
scrollY # 4
sprite0y # 4

vramaddrinc # 1
ppustat # 1
toggle # 1
ppuctrl0 # 1
ppuctrl0frame # 1
ppuctrl1 # 1
readtemp # 1
 # 1 ;align
			;cart.s (wram_globals2)
mapperdata # 32
nes_chr_map # 8
old_chr_map # 8
agb_bg_map # 16
agb_obj_map # 8
bg_recent # 4

rombase # 4
romnumber # 4
hackflags # 4
BGmirror # 4

rommask # 4
vrombase # 4
vrommask # 4
sram_slot # 4

cartflags # 1
 # 3 ;align
;----------------------------------------------------------------------------
IRQ_VECTOR EQU 0xfffe ; IRQ/BRK interrupt vector address
RES_VECTOR EQU 0xfffc ; RESET interrupt vector address
NMI_VECTOR EQU 0xfffa ; NMI interrupt vector address
;-----------------------------------------------------------cartflags
MIRROR		EQU 0x01 ;horizontal mirroring
SRAM		EQU 0x02 ;save SRAM
TRAINER		EQU 0x04 ;trainer present
SCREEN4		EQU 0x08 ;4way screen layout
VS		EQU 0x10 ;VS unisystem
;-----------------------------------------------------------hackflags
USEPPUHACK	EQU 1	;use $2002 hack
NOCPUHACK	EQU 2	;don't use JMP hack
PALTIMING	EQU 4	;0=NTSC 1=PAL
SPRITEFOLLOW	EQU 16	;(with bits 8-23 of hackflags)
MEMFOLLOW	EQU 32	;...
NOSCALING	EQU 64	;also defined in GBA.H
SCALESPRITES	EQU 128	;also defined in GBA.H

;bits 24-31=SRAM slot
;----------------------------------------------------------------------------
CYCLE		EQU 16 ;one cycle (341*CYCLE cycles per scanline)

;cycle flags- (stored in cycles reg for speed)

BRANCH		EQU 0x01 ;branch instruction encountered
;		EQU 0x02
;		EQU 0x04
;		EQU 0x08
;----------------------------------------------------------------------------
YSTART 		EQU 13 ;scaled NES screen starts on this line

		END
