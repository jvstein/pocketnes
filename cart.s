	INCLUDE equates.h
	INCLUDE mappers.h
	INCLUDE memory.h
	INCLUDE 6502mac.h
	INCLUDE 6502.h
	INCLUDE ppu.h
	INCLUDE io.h
	INCLUDE sound.h

	IMPORT findrom ;from main.c
	IMPORT init_sprite_cache
	IMPORT init_cache
	IMPORT loadcart
	
	IMPORT update_bankbuffer

	EXPORT im_lazy
	[ RESET_ALL
	EXPORT reset_all
	]

	EXPORT g_BGmirror
	EXPORT g_rommask
	EXPORT g_rompages
	EXPORT g_vrompages
	EXPORT g_fourscreen
	EXPORT loadcart_asm
	EXPORT hardreset
	EXPORT map67_
	EXPORT map89_
	EXPORT mapAB_
	EXPORT mapCD_
	EXPORT mapEF_
	EXPORT map89AB_
	EXPORT mapCDEF_
	EXPORT map89ABCDEF_
	EXPORT chr0_
	EXPORT chr1_
	EXPORT chr2_
	EXPORT chr3_
	EXPORT chr4_
	EXPORT chr5_
	EXPORT chr6_
	EXPORT chr7_
	EXPORT chr01_
	EXPORT chr23_
	EXPORT chr45_
	EXPORT chr67_
	EXPORT chr0123_
	EXPORT chr4567_
	EXPORT chr01234567_
	EXPORT writeCHRTBL
	EXPORT updateBGCHR_
;	EXPORT updateOBJCHR
	EXPORT mirror1_
	EXPORT mirror2V_
	EXPORT mirror2H_
	EXPORT mirror4_
	EXPORT mirrorKonami_
	EXPORT chrfinish
	[ CARTSAVE
	EXPORT CachedConfig
	]
	[ SAVESTATES
	EXPORT loadstate_gfx
	]

	EXPORT g_emuflags
	EXPORT romstart
	EXPORT romnum
	EXPORT g_scaling
	EXPORT g_cartflags
	EXPORT g_hackflags
	EXPORT g_hackflags2
	EXPORT g_rompages
	EXPORT g_mapper_number
	EXPORT g_rombase
	EXPORT g_vrombase
	EXPORT g_vrommask
	EXPORT g_vrompages
	
	EXPORT END_OF_EXRAM
	EXPORT g_instant_prg_banks
	EXPORT g_instant_chr_banks
	EXPORT g_bank6
	EXPORT g_bank8
	EXPORT g_Cbank0
	EXPORT g_nes_chr_map
	EXPORT g_vrompages
	EXPORT g_rompages
	EXPORT NES_VRAM
	EXPORT NES_VRAM2
	EXPORT NES_VRAM4
	
	EXPORT mapperstate
	EXPORT FREQTBL2
	
;----------------------------------------------------------------------------
 AREA rom_code, CODE, READONLY
;----------------------------------------------------------------------------

mappertbl
	DCB 0
	DCB 1
	DCB 2
	DCB 3
	DCB 4
	[ LESSMAPPERS
	|
	DCB 5
	]
	DCB 7
	DCB 9
	DCB 10
	DCB 11
	[ LESSMAPPERS
	|
	DCB 15
	]
	DCB 16
	DCB 17
	DCB 18
	DCB 19
	DCB 21
	DCB 22
	DCB 23
	DCB 24
	DCB 25
	DCB 26
	DCB 32
	DCB 33
	DCB 34
	DCB 40
	DCB 42
	DCB 64
	DCB 65
	DCB 66
	DCB 67
	DCB 68
	DCB 69
	DCB 70
	DCB 71
	DCB 72
	DCB 73
	DCB 74
	DCB 75
	DCB 76
	DCB 77
	DCB 78
	DCB 79
	DCB 80
	DCB 85
	DCB 86
	DCB 87
	DCB 92
	DCB 93
	DCB 94
	DCB 97
	DCB 99
	[ LESSMAPPERS
	|
	DCB 105
	]
	DCB 118
	DCB 119
	DCB 140
	DCB 151
	DCB 152
	DCB 158
	DCB 178
	DCB 180
	DCB 184
	DCB 187
	[ LESSMAPPERS
	|
	DCB 228
	]
	DCB 232
	DCB 245
	DCB 249
	DCB 252
	DCB 254
mappertbl2
	DCD mapper0init 	;0
	DCD mapper1init 	;1
	DCD mapper2init 	;2
	DCD mapper3init 	;3
	DCD mapper4init 	;4
	[ LESSMAPPERS
	|
	DCD mapper5init 	;5
	]
	DCD mapper7init 	;7
	DCD mapper9init 	;9
	DCD mapper10init	;10
	DCD mapper11init	;11
	[ LESSMAPPERS
	|
	DCD mapper15init	;15
	]
	DCD mapper16init	;16
	DCD mapper17init	;17
	DCD mapper18init	;18
	DCD mapper19init	;19
	DCD mapper21init	;21
	DCD mapper22init	;22
	DCD mapper23init	;23
	DCD mapper24init	;24
	DCD mapper25init	;25
	DCD mapper26init	;26
	DCD mapper32init	;32
	DCD mapper33init	;33
	DCD mapper34init	;34
	DCD mapper40init	;40
	DCD mapper42init	;42
	DCD mapper64init	;64
	DCD mapper65init	;65
	DCD mapper66init	;66
	DCD mapper67init	;67
	DCD mapper68init	;68
	DCD mapper69init	;69
	DCD mapper70init	;70
	DCD mapper71init	;71
	DCD mapper72init	;72
	DCD mapper73init	;73
	DCD mapper74init	;74
	DCD mapper75init	;75
	DCD mapper76init	;76
	DCD mapper77init	;77
	DCD mapper78init	;78
	DCD mapper79init	;79
	DCD mapper80init	;80
	DCD mapper85init	;85
	DCD mapper86init	;86
	DCD mapper87init	;87
	DCD mapper92init	;92
	DCD mapper93init	;93
	DCD mapper94init	;94
	DCD mapper97init	;97
	DCD mapper99init	;99
	[ LESSMAPPERS
	|
	DCD mapper105init	;105
	]
	DCD mapper118init	;118
	DCD mapper119init	;119
	DCD mapper66init	;140
	DCD mapper151init	;151
	DCD mapper152init	;152
	DCD mapper64init	;158
	DCD mapper4init 	;178
	DCD mapper180init	;180
	DCD mapper184init	;184
	DCD mapper4init 	;187
	[ LESSMAPPERS
	|
	DCD mapper228init	;228
	]
	DCD mapper232init	;232
	DCD mapper245init	;245
	DCD mapper249init	;249
	DCD mapper4init 	;252
	DCD mapper4init 	;254
	DCD mapper0init		;default
thumbcall_r1_b
	bx r1

;----------------------------------------------------------------------------
loadcart_asm ;called from C
;----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}

	ldr globalptr,=GLOBAL_PTR_BASE	;need ptr regs init'd
	ldr cpu_zpage,=NES_RAM

	;Set video memory writability
	ldrb r2,has_vram
	movs r2,r2
	ldr r0,=void
	ldrne r0,=VRAM_chr
	ldrb r1,bankable_vrom
	tst r1,r2
	ldrne r0,=VRAM_chr3

	adr r1,vram_write_tbl
	mov r2,#8
	bl filler_
	
	mov r0,#-1			;reset all CHR
	adrl r1,agb_bg_map
	mov r2,#8			;agb_bg_map, agb_real_bg_map
	bl filler_
	ldr r0,=0x0004080c
	str r0,bg_recent
	mov r0,#0			;default CHR mapping
	adrl r2,chrold
	ldr r1,=0x03020100
	str r1,[r2],#4
	str r0,[r2] ;chrline
;	bl_long chr01234567_

	ldr r4,nes_chr_map
	ldr r5,nes_chr_map+4
;	str r4,old_chr_map
;	str r4,new_chr_map
;	str r5,old_chr_map+4
;	str r5,new_chr_map+4

	ldr r2,vrommask		;if vromsize=0
	tst r2,#0x80000000
	bpl lc2
	str r4,agb_bg_map		;setup BG map so it won't change
	str r5,agb_bg_map+4
lc2
	mov m6502_pc,#0		;(eliminates any encodePC errors during mapper*init)
	str m6502_pc,lastbank
	adr m6502_mmap,memmap_tbl

	mov r0,#0			;default ROM mapping
	bl_long map89AB_			;89AB=1st 16k

	mov r0,#-1
	bl_long mapCDEF_			;CDEF=last 16k

;	ldr r0,=default_scanlinehook
	ldr r0,=pcm_scanlinehook
	str r0,scanlinehook	;no mapper irq
	ldr r0,=default_midlinehook
	str r0,midlinehook

	ldr r0,=joy0_W
	ldr r1,=joypad_write_ptr
	str r0,[r1]				;reset 4016 write (mapper99 messes with it)
	
	ldr r1,=empty_W                 ;mapper 249 needs address 5000
	ldr r0,=empty_io_w_hook
	str r1,[r0]
	ldr r1,=IO_R			;reset other writes..
	str r1,readmem_tbl-8
	ldr r1,=sram_R			;reset other writes..
	str r1,readmem_tbl-12
	ldr r1,=IO_W			;reset other writes..
	str r1,writemem_tbl-8
	ldr r1,=sram_W
	str r1,writemem_tbl-12
	ldr r1,=NES_RAM-0x5800	;$6000 for mapper 40, 69 & 90 that has rom here.
	str r1,memmap_tbl+12

	bl PPU_reset
	bl IO_reset
	bl Sound_reset
	;move initial CHR bankswitch to come after ppu reset
	mov r0,#0
	bl_long chr01234567_

	ldrb r0,mapper_number
							;lookup mapper*init
	adr r1,mappertbl
	adr r5,mappertbl2
lc0
	ldrb r2,[r1],#1
	cmp r2,r0
	beq lc1
	cmp r1,r5
	bne lc0
lc1				;call mapper*init
	adrl r4,mappertbl
	sub r1,r1,r4
	add r1,r5,r1,lsl#2
	
	adr lr,%F0
	adr r5,writemem_tbl-16
	ldr r0,[r1,#-4]
	ldmia r0!,{r1-r4}
	str r1,[r5],#-4
	str r2,[r5],#-4
	str r3,[r5],#-4
	str r4,[r5],#-4
	adr m6502_mmap,memmap_tbl ;r4 gets clobbered, reset it here
	mov pc,r0			;Jump to MapperInit
0
	ldrb r1,cartflags
	tst r1,#MIRROR		;set default mirror
	bl_long mirror2H_		;(call after mapperinit to allow mappers to set up cartflags first)

	bl CPU_reset		;reset everything else - Call AFTER mapperinit

	ldmfd sp!,{r4-r11,lr}
	bx lr

hardreset
	ldr r12,=loadcart
	ldr r0,=romnum
	ldr r0,[r0]
	ldr r1,=g_emuflags
	ldr r1,[r1]
	mov r2,#0
	bx r12
	

	[ SAVESTATES
	EXPORT tags
tags
	DCB "VERS"
	DCB "CPUS"
	DCB "GFXS"
	DCB "RAM "
	DCB "SRAM"
	DCB "VRM1"
	DCB "VRM2"
	DCB "VRM4"
	DCB "MAPR"
	DCB "PAL2"
	DCB "MIR2"
	DCB "OAM "
	DCB "SND0"
	DCB "NOPE"


;----------------------------------------------------------------------------
loadstate_gfx	
;void loadstate_gfx(void)
;----------------------------------------------------------------------------
	stmfd sp!,{r0-addy,lr}
	
	ldr globalptr,=GLOBAL_PTR_BASE

	bl_long resetBGCHR
;	bl_long update_bankbuffer
	bl_long updateBGCHR_
	
	;restore rest of vram_map, agb_nt_map
	ldr r0,BGmirror
	movs r1,r0,lsr#14
	bne %f0
	;single screen
	tst r0,#0x100
	ldrne r0,=m1111
	ldreq r0,=m0000
	b %f1
0
	cmp r1,#1
	ldreq r0,=m0101  ;vertical mirroring
	cmp r1,#2
	ldreq r0,=m0011  ;horizontal mirroring
	ldrgt r0,=m0123  ;four screen
1
	bl_long mirrorchange

	ldrb r0,ppuctrl1
	bl_long ctrl1_W
	
	ldr r0,=stat_R_clearvbl
	ldr r1,=PPU_read_tbl+8
	str r0,[r1]
	
	bl_long findsprite0
	
	ldr r0,scrollX
	str r0,scrollXold
	ldr r0,scrollY
	str r0,scrollYold
	
	adrl r2,nes_chr_map
	ldmia r2,{r0,r1}
	adr r2,bankbuffer_last
	ldmia r2,{r0,r1}


;	ldr r5,=NES_VRAM
;	add r3,r5,#0x2000	;init nametbl+attrib
;	add r4,r3,#0x1000
;	
;ls3
;	sub addy,r3,r5
;	bl_long vram_read_direct
;	bl_long vram_write_direct
;	add r3,r3,#1
;	cmp r3,r4
;	blt ls3
	
	
;	ldrb r0,vrompages
;	cmp r0,#0
;	bne ls5
;	
;	ldr r5,=NES_VRAM
;	add r3,r5,#0x0000	;init nametbl+attrib
;	add r4,r3,#0x2000
;ls4	
;	sub addy,r3,r5
;	bl_long vram_read_direct
;	bl_long vram_write_direct
;	add r3,r3,#1
;	cmp r3,r4
;	blt ls4
;ls5	
	bl_long updateBGCHR_
	
	ldmfd sp!,{r0-addy,lr}
	bx lr

	[ {FALSE}

;----------------------------------------------------------------------------
savestate	;called from ui.c.
;int savestate(void *here): copy state to <here>, return size
;----------------------------------------------------------------------------
	stmfd sp!,{r4-r6,globalptr,lr}

	ldr globalptr,=GLOBAL_PTR_BASE

	ldr r2,rombase
	rsb r2,r2,#0			;adjust rom maps,etc so they aren't based on rombase
	bl fixromptrs			;(so savestates are valid after moving roms around)

	mov r6,r0			;r6=where to copy state
	mov r0,#0			;r0 holds total size (return value)

	adr r4,savelst			;r4=list of stuff to copy
	mov r3,#(lstend-savelst)/8	;r3=items in list
ss1	ldr r2,[r4],#4				;r2=what to copy
	ldr r1,[r4],#4				;r1=how much to copy
	add r0,r0,r1
ss0	ldr r5,[r2],#4
	str r5,[r6],#4
	subs r1,r1,#4
	bne ss0
	subs r3,r3,#1
	bne ss1

	ldr r2,rombase
	bl fixromptrs

	ldmfd sp!,{r4-r6,globalptr,lr}
	bx lr

savelst	DCD rominfo,8,NES_RAM,0x2800,NES_VRAM,0x3000,agb_pal,96
	DCD vram_map,64,agb_nt_map,16,mapperstate,48,rommap,16,cpustate,44,ppustate,32
lstend

fixromptrs	;add r2 to some things
	adr r1,memmap_tbl+16
	ldmia r1,{r3-r6}
	add r3,r3,r2
	add r4,r4,r2
	add r5,r5,r2
	add r6,r6,r2
	stmia r1,{r3-r6}

	ldr r3,lastbank
	add r3,r3,r2
	str r3,lastbank

	ldr r3,cpuregs+6*4	;6502 PC
	add r3,r3,r2
	str r3,cpuregs+6*4

	mov pc,lr
;----------------------------------------------------------------------------
loadstate	;called from ui.c
;void loadstate(int rom#,u32 *stateptr)	 (stateptr must be word aligned)
;----------------------------------------------------------------------------
	stmfd sp!,{r4-r7,globalptr,lr}

	mov r6,r1		;r6=where state is at
	ldr globalptr,=GLOBAL_PTR_BASE

        ldr r1,[r6]             ;emuflags
	bl loadcart		;cart init

	mov r0,#(lstend-savelst)/8	;read entire state
	adr r4,savelst
ls1	ldr r2,[r4],#4
	ldr r1,[r4],#4
ls0	ldr r5,[r6],#4
	str r5,[r2],#4
	subs r1,r1,#4
	bne ls0
	subs r0,r0,#1
	bne ls1

	ldr r2,rombase		;adjust ptr shit (see savestate above)
	bl fixromptrs

	ldr r3,=NES_VRAM2	;init nametbl+attrib
	ldr r4,=AGB_BG
ls4	mov r5,#0
ls3	mov r1,r3
	mov r2,r4
	mov addy,r5
	ldrb r0,[r1,addy]
	bl_long writeBG
	add r5,r5,#1
	tst r5,#0x400
	beq ls3
	add r3,r3,#0x400
	add r4,r4,#0x800
	tst r4,#0x10000
	beq ls4

;--------------------------------
	ldr r2,vrommask		;if vromsize=0
	tst r2,#0x80000000
	bne lc3

	mov r0,#-1			;reset all CHR
	adrl r1,agb_bg_map
	mov r2,#6			;agb_bg_map,agb_obj_map
	bl filler_
	ldr r0,=0x0004080c
	str r0,bg_recent
lc3
;--------------------------------


	mov r1,#-1			;init BG CHR
	ldr r5,=AGB_VRAM
	adrl r6,nes_chr_map
	bl_long im_lazy
	mov r1,#-1
	ldr r5,=AGB_VRAM+0x4000
	adrl r6,nes_chr_map+4
	bl_long im_lazy

	ldrb r0,ppuctrl1	;prep buffered DMA stuff
	bl_long ctrl1_W
	bl_long newX
	bl_long resetBGCHR
	
	ldr globalptr,=GLOBAL_PTR_BASE
	ldrb r0,mapperdata+23
	subs r0,r0,#1

	ldrpl r1,=rom_R60			;Swap in ROM at $6000-$7FFF.
	ldrmi r1,=sram_R		;Swap in sram at $6000-$7FFF.
	str r1,readmem_tbl-12
	ldrpl r1,=empty_W		;ROM.
	ldrmi r1,=sram_W		;sram.
	str r1,writemem_tbl-12
	ldrmi r1,=NES_RAM-0x5800		;sram at $6000.
	strmi r1,memmap_tbl-12
	blpl_long map67_


	

	ldmfd sp!,{r4-r7,globalptr,lr}
	bx lr
	]
	]

;----------------------------------------------------------------------------
m0000	DCD 0x0C02,NES_VRAM2+0x0000,NES_VRAM2+0x0000,NES_VRAM2+0x0000,NES_VRAM2+0x0000
	DCD VRAM_name0, VRAM_name0, VRAM_name0, VRAM_name0
m1111	DCD 0x0D02,NES_VRAM2+0x0400,NES_VRAM2+0x0400,NES_VRAM2+0x0400,NES_VRAM2+0x0400
	DCD VRAM_name1, VRAM_name1, VRAM_name1, VRAM_name1
m0101	DCD 0x4C02,NES_VRAM2+0x0000,NES_VRAM2+0x0400,NES_VRAM2+0x0000,NES_VRAM2+0x0400
	DCD VRAM_name0, VRAM_name1, VRAM_name0, VRAM_name1
m0011	DCD 0x8C02,NES_VRAM2+0x0000,NES_VRAM2+0x0000,NES_VRAM2+0x0400,NES_VRAM2+0x0400
	DCD VRAM_name0, VRAM_name0, VRAM_name1, VRAM_name1
m0123	DCD 0xCC02,NES_VRAM2+0x0000,NES_VRAM2+0x0400,NES_VRAM4+0x0000,NES_VRAM4+0x0400
	DCD VRAM_name0, VRAM_name1, VRAM_name2, VRAM_name3
;----------------------------------------------------------------------------
 AREA wram_code4, CODE, READWRITE
;----------------------------------------------------------------------------
mirrorKonami_
	movs r1,r0,lsr#2
	tst r0,#1
	bcc mirror2V_
;	bcs mirror1_
mirror1_
	ldrne r0,=m1111
	ldreq r0,=m0000
	b mirrorchange
mirror2V_
	ldreq r0,=m0101
	ldrne r0,=m0011
	b mirrorchange
mirror2H_
	ldreq r0,=m0011
	ldrne r0,=m0101
	b mirrorchange
mirror4_
	ldr r0,=m0123
mirrorchange
	ldrb r1,cartflags
	tst r1,#SCREEN4+VS
	ldrne r0,=m0123		;force 4way mirror for SCREEN4 or VS flags

	stmfd sp!,{r0,r3-r5,lr}

	ldr r0,chrold
	ldr r1,chrline

	;get the real scanline
	ldrb r2,midscanline
	movs r2,r2
	ldreq r2,cyclesperscanline1
	sub r2,r2,cycles
	cmp r2,#128<<CYC_SHIFT
	ldr r2,scanline	;addy=scanline
	sublt r2,r2,#1
	cmp r2,#240
	movhi r2,#240

	bl ubg2_	;allow mid-frame change

	ldr r0,[sp],#4	;???
	ldr r3,[r0],#4
	str r3,BGmirror

	adr r1,vram_map+32
	ldmia r0!,{r2-r5}
	stmia r1,{r2-r5}
	adr r1,vram_write_tbl+8*4
	ldmia r0!,{r2-r5}
	stmia r1!,{r2-r5}
	stmia r1,{r2-r4}
	ldmfd sp!,{r3-r5,pc}
;----------------------------------------------------------------------------
map67_	;rom paging.. r0=page#
;----------------------------------------------------------------------------
	ldr r1,rommask
	and r0,r0,r1,lsr#13
	strb r0,bank6
	ldr r1,instant_prg_banks
	ldr r2,[r1,r0,lsl#2]
	subs r2,r2,#0x6000
;	bmi need_to_use_cache
	str r2,memmap_tbl+12
	b flush
;----------------------------------------------------------------------------
map89_	;rom paging.. r0=page#
;----------------------------------------------------------------------------
	ldr r1,rommask
	and r0,r0,r1,lsr#13
	strb r0,bank8
	ldr r1,instant_prg_banks
	ldr r2,[r1,r0,lsl#2]
	subs r2,r2,#0x8000
;	bmi need_to_use_cache
	str r2,memmap_tbl+16
	b flush
;----------------------------------------------------------------------------
mapAB_
;----------------------------------------------------------------------------
	ldr r1,rommask
	and r0,r0,r1,lsr#13
	strb r0,bankA
	ldr r1,instant_prg_banks
	ldr r2,[r1,r0,lsl#2]
	subs r2,r2,#0xA000
;	bmi need_to_use_cache
	str r2,memmap_tbl+20
	b flush
;----------------------------------------------------------------------------
mapCD_
;----------------------------------------------------------------------------
	ldr r1,rommask
	and r0,r0,r1,lsr#13
	strb r0,bankC
	ldr r1,instant_prg_banks
	ldr r2,[r1,r0,lsl#2]
	subs r2,r2,#0xC000
;	bmi need_to_use_cache
	str r2,memmap_tbl+24
	b flush
;----------------------------------------------------------------------------
mapEF_
;----------------------------------------------------------------------------
	ldr r1,rommask
	and r0,r0,r1,lsr#13
	strb r0,bankE
	ldr r1,instant_prg_banks
	ldr r2,[r1,r0,lsl#2]
	subs r2,r2,#0xE000
;	bmi need_to_use_cache
	str r2,memmap_tbl+28
	b flush
;----------------------------------------------------------------------------
map89AB_
;----------------------------------------------------------------------------
	ldr r1,rommask
	and r0,r0,r1,lsr#14
	mov r0,r0,lsl#1
	strb r0,bank8
	add r2,r0,#1
	strb r2,bankA
	ldr r1,instant_prg_banks
	ldr r0,[r1,r0,lsl#2]!
	subs r0,r0,#0x8000
;	bmi need_to_use_cache
;;don't bother with checking if page is whole
;;	ldr r2,[r1!,#4]!
;;	subs r2,r2,#0xA000
;;	cmp r0,r2
;;	bne need_to_use_cache
	str r0,memmap_tbl+16
	str r0,memmap_tbl+20
flush		;update nes_pc & lastbank
	ldr r1,lastbank
	sub m6502_pc,m6502_pc,r1
	encodePC
	bx lr
;----------------------------------------------------------------------------
mapCDEF_
;----------------------------------------------------------------------------
	ldr r1,rommask
	and r0,r0,r1,lsr#14
	mov r0,r0,lsl#1
	strb r0,bankC
	add r2,r0,#1
	strb r2,bankE
	ldr r1,instant_prg_banks
	ldr r0,[r1,r0,lsl#2]!
	subs r0,r0,#0xC000
;	bmi need_to_use_cache
;;don't bother with checking if page is whole
;;	ldr r2,[r1,#4]!
;;	subs r2,r2,#0xE000
;;	cmp r0,r2
;;	bne need_to_use_cache
	str r0,memmap_tbl+24
	str r0,memmap_tbl+28
	b flush
;----------------------------------------------------------------------------
map89ABCDEF_
;----------------------------------------------------------------------------
	ldr r1,rommask
	and r0,r0,r1,lsr#15
	ldr r1,=0x03020100
	orr r2,r0,r0,lsl#8
	orr r2,r2,r2,lsl#16
	orr r2,r1,r2,lsl#2
	str r2,bank8
;	strb r0,bank8
;	add r2,r0,#1
;	strb r2,bankA
;	add r2,r2,#1
;	strb r2,bankC
;	add r2,r2,#1
;	strb r2,bankE
	ldr r1,instant_prg_banks
;	ldr r0,[r1,r0,lsl#2]!
	ldr r0,[r1,r0,lsl#4]!
	subs r0,r0,#0x8000
;	bmi need_to_use_cache
;;don't bother with checking if page is whole
;;	ldr r2,[r1,#4]!
;;	subs r2,r2,#0xA000
;;	cmp r0,r2
;;	bne need_to_use_cache
;;	ldr r2,[r1,#4]!
;;	subs r2,r2,#0xC000
;;	cmp r0,r2
;;	bne need_to_use_cache
;;	ldr r2,[r1,#4]!
;;	subs r2,r2,#0xE000
;;	cmp r0,r2
;;	bne need_to_use_cache
	str r0,memmap_tbl+16
	str r0,memmap_tbl+20
	ldr r0,[r1,#8]!
	subs r0,r0,#0xC000
	str r0,memmap_tbl+24
	str r0,memmap_tbl+28
	b flush
	
;----------------------------------------------------------------------------
writeCHRTBL	DCD chr0_,chr1_,chr2_,chr3_,chr4_,chr5_,chr6_,chr7_
;----------------------------------------------------------------------------


;----------------------------------------------------------------------------
chr0_
;----------------------------------------------------------------------------
	ldr r2,vrommask
	and r0,r0,r2,lsr#10

	strb r0,nes_chr_map
	ldr r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#2]
	str r1,vram_map
	b updateBGCHR_
;----------------------------------------------------------------------------
chr1_
;----------------------------------------------------------------------------
	ldr r2,vrommask
	and r0,r0,r2,lsr#10

	strb r0,nes_chr_map+1
	ldr r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#2]
	str r1,vram_map+4
	b updateBGCHR_
;----------------------------------------------------------------------------
chr2_
;----------------------------------------------------------------------------
	ldr r2,vrommask
	and r0,r0,r2,lsr#10

	strb r0,nes_chr_map+2
	ldr r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#2]
	str r1,vram_map+8
	b updateBGCHR_
;----------------------------------------------------------------------------
chr3_
;----------------------------------------------------------------------------
	ldr r2,vrommask
	and r0,r0,r2,lsr#10

	strb r0,nes_chr_map+3
	ldr r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#2]
	str r1,vram_map+12
	b updateBGCHR_
;----------------------------------------------------------------------------
chr4_
;----------------------------------------------------------------------------
	ldr r2,vrommask
	and r0,r0,r2,lsr#10

	strb r0,nes_chr_map+4
	ldr r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#2]
	str r1,vram_map+16
	b updateBGCHR_
;----------------------------------------------------------------------------
chr5_
;----------------------------------------------------------------------------
	ldr r2,vrommask
	and r0,r0,r2,lsr#10

	strb r0,nes_chr_map+5
	ldr r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#2]
	str r1,vram_map+20
	b updateBGCHR_
;----------------------------------------------------------------------------
chr6_
;----------------------------------------------------------------------------
	ldr r2,vrommask
	and r0,r0,r2,lsr#10

	strb r0,nes_chr_map+6
	ldr r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#2]
	str r1,vram_map+24
	b updateBGCHR_
;----------------------------------------------------------------------------
chr7_
;----------------------------------------------------------------------------
	ldr r2,vrommask
	and r0,r0,r2,lsr#10

	strb r0,nes_chr_map+7
	ldr r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#2]
	str r1,vram_map+28
	b updateBGCHR_
;----------------------------------------------------------------------------
chr01_
;----------------------------------------------------------------------------
	mov r0,r0,lsl#1
	ldr r2,vrommask
	and r0,r0,r2,lsr#10

	strb r0,nes_chr_map
	orr r2,r0,#1
	strb r2,nes_chr_map+1

	ldr r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#2]

	str r1,vram_map
	add r1,r1,#0x400
	str r1,vram_map+4
	b updateBGCHR_
;----------------------------------------------------------------------------
chr23_
;----------------------------------------------------------------------------
	mov r0,r0,lsl#1
	ldr r2,vrommask
	and r0,r0,r2,lsr#10

	strb r0,nes_chr_map+2
	orr r2,r0,#1
	strb r2,nes_chr_map+3

	ldr r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#2]

	str r1,vram_map+8
	add r1,r1,#0x400
	str r1,vram_map+12
	b updateBGCHR_
;----------------------------------------------------------------------------
chr45_
;----------------------------------------------------------------------------
	mov r0,r0,lsl#1
	ldr r2,vrommask
	and r0,r0,r2,lsr#10

	strb r0,nes_chr_map+4
	orr r2,r0,#1
	strb r2,nes_chr_map+5

	ldr r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#2]

	str r1,vram_map+16
	add r1,r1,#0x400
	str r1,vram_map+20
	b updateBGCHR_
;----------------------------------------------------------------------------
chr67_
;----------------------------------------------------------------------------
	mov r0,r0,lsl#1
	ldr r2,vrommask
	and r0,r0,r2,lsr#10

	strb r0,nes_chr_map+6
	orr r2,r0,#1
	strb r2,nes_chr_map+7

	ldr r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#2]

	str r1,vram_map+24
	add r1,r1,#0x400
	str r1,vram_map+28
	b updateBGCHR_
;----------------------------------------------------------------------------
chr0123_
;----------------------------------------------------------------------------
	ldr r2,vrommask
	and r0,r0,r2,lsr#12

	orr r1,r0,r0,lsl#8
	orr r1,r1,r1,lsl#16
	ldr r2,=0x03020100
	orr r2,r2,r1,lsl#2
	str r2,nes_chr_map

	ldr r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#4]

	adrl r0,vram_map
	add r2,r1,#0x400
	stmia r0!,{r1,r2}
	add r1,r2,#0x400
	add r2,r1,#0x400
	stmia r0!,{r1,r2}
	b updateBGCHR_
;----------------------------------------------------------------------------
chr01234567_
;----------------------------------------------------------------------------
	ldr r2,vrommask
	and r0,r0,r2,lsr#13

	orr r1,r0,r0,lsl#8
	orr r1,r1,r1,lsl#16
	ldr r2,=0x03020100
	orr r2,r2,r1,lsl#3
	str r2,nes_chr_map
	ldr r2,=0x07060504
	orr r2,r2,r1,lsl#3
	str r2,nes_chr_map+4

	ldr r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#5]

	adrl r0,vram_map
	add r2,r1,#0x400
	stmia r0!,{r1,r2}
	add r1,r2,#0x400
	add r2,r1,#0x400
	stmia r0!,{r1,r2}
	add r1,r2,#0x400
	b _4567
;----------------------------------------------------------------------------
chr4567_
;----------------------------------------------------------------------------
	ldr r2,vrommask
	and r0,r0,r2,lsr#12

	orr r1,r0,r0,lsl#8
	orr r1,r1,r1,lsl#16
	ldr r2,=0x03020100
	orr r2,r2,r1,lsl#2
	str r2,nes_chr_map+4

	ldr r1,instant_chr_banks
	ldr r1,[r1,r0,lsl#4]
	
	adrl r0,vram_map+16
_4567
	add r2,r1,#0x400
	stmia r0!,{r1,r2}
	add r1,r2,#0x400
	add r2,r1,#0x400
	stmia r0!,{r1,r2}
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
updateBGCHR_	;see if BG CHR needs to change, setup BGxCNTBUFF
;----------------------------------------------------------------------------
	stmfd sp!,{r3-r5,lr}
	bl update_bankbuffer
	ldmfd sp!,{r3-r5,lr}
	
	
	ldrb r2,ppuctrl0
	tst r2,#0x10
	ldreq r0,nes_chr_map
	ldrne r0,nes_chr_map+4	;r0=new bg chr group

	adrl r1,chrold
	swp r0,r0,[r1]

	ldr r1,chrline

	ldrb r2,midscanline
	movs r2,r2
	ldreq r2,cyclesperscanline1
	sub r2,r2,cycles
	cmp r2,#128<<CYC_SHIFT
	ldr r2,scanline	;addy=scanline
	sublt r2,r2,#1
	cmp r2,#240
	movhi r2,#240

	sub r1,r2,r1
	cmp r1,#3		;if(scanline-lastline<3)
	movmi pc,lr		;	return
ubg2_			;now setup BG for last request: (chrfinish,mirror* jumps here)
	;r1 = scanline
	stmfd sp!,{r2-r7,addy,lr}
	bl chr_req_
	ldmfd sp!,{r2-r6}
	
	;r2 = scanline end
	ldrb r0,bg_recent
	ldr r1,BGmirror
	orr r0,r0,r1
	adrl r7,chrline
	swp r1,r2,[r7]
	;r2 = scanline end
	;r1 = scanline start

	;sl == 0 >> exit
	;sl < prev  >> prev = 0
	;sl == prev >> exit
	cmp r2,#0
	beq ubg2_exit
	subs r2,r2,r1
	beq ubg2_exit
	addlt r2,r2,r1  ;could this happen?
	movlt r1,#0
	
	ldr r7,bg0cntbuff
	;fill forwards
	add r1,r7,r1,lsl#1
;;
	mov addy,r2
	bl memset16
;;
;ubg1
;	strh r0,[r1],#2	;fill forwards from lastline to scanline-1
;	subs r2,r2,#1
;	bgt ubg1

ubg2_exit
	ldmfd sp!,{r7,addy,pc}

;chrold	DCD 0 ;last write
;chrline	DCD 0 ;when?

;----------------------------------------------------------------------------
chrfinish	;end of frame...  finish up BGxCNTBUFF
;----------------------------------------------------------------------------
	mov addy,lr

	ldr r0,chrold
	mov r2,#240
	bl ubg2_
;	mov r0,#0
;	str r0,chrline

 [ DEBUG
 ldr r0,agb_bg_map
	mov r1,#0
	bl debug_
 ldr r0,agb_bg_map+4
	mov r1,#1
	bl debug_
 ldr r0,agb_bg_map+8
	mov r1,#2
	bl debug_
 ldr r0,agb_bg_map+12
	mov r1,#3
	bl debug_
 ldr r0,bg_recent
	mov r1,#4
	bl debug_

 ldr r0,nes_chr_map
	mov r1,#5
	bl debug_
 ldr r0,nes_chr_map+4
	mov r1,#6
	bl debug_
 ]

	bx addy
	[ SAVESTATES
;----------------------------------------------------------------------------
resetBGCHR
;----------------------------------------------------------------------------
	mov r0,#0
	str r0,chrline
	str r0,bankbuffer_line
	

	ldrb r2,ppuctrl0
	tst r2,#0x10
	ldreq r0,nes_chr_map
	ldrne r0,nes_chr_map+4
	str r0,chrold
	
	ldrb r0,bankable_vrom
	movs r0,r0
	bxeq lr

	ldr r0,=0x0004080c
	str r0,bg_recent

	mov r0,#-1			;reset all CHR
	adrl r1,agb_bg_map
	mov r2,#6			;agb_bg_map,agb_obj_map
	b_long filler_
	]
;;----------------------------------------------------------------------------
;updateOBJCHR	;sprite CHR update (r3-r7 killed)
;;----------------------------------------------------------------------------
;	ldrb r2,ppuctrl0frame
;	tst r2,#0x20	;8x16?
;	beq uc3
;	mov addy,lr
;	bl uc1
;	bl uc2
;	mov pc,addy
;uc3
;	tst r2,#0x08
;	bne uc2
;uc1
;	ldr r0,new_chr_map ;use old copy (OAM lags behind 2 frames)
;	ldr r1,old_chr_map ;use old copy (OAM lags behind a frame)
;	str r1,new_chr_map
;	ldr r1,agb_obj_map
;	eors r1,r1,r0
;	moveq pc,lr
;	str r0,agb_obj_map
;	ldr r5,=AGB_VRAM+0x10000
;	adrl r6,agb_obj_map
;	b im_lazy
;uc2
;	ldr r0,new_chr_map+4
;	ldr r1,old_chr_map+4
;	str r1,new_chr_map+4
;	ldr r1,agb_obj_map+4
;	eors r1,r1,r0
;	moveq pc,lr
;	str r0,agb_obj_map+4
;	ldr r5,=AGB_VRAM+0x12000
;	adrl r6,agb_obj_map+4
;	b im_lazy

;----------------------------------------------------------------------------
chr_req_		;request BG CHR group in r0
;		r0=chr group (4 1k CHR pages)
;----------------------------------------------------------------------------
	adrl r6,agb_bg_map

	mov r2,r6
	ldr r1,[r2]
	cmp r0,r1		;check for existing group
	ldrne r1,[r2,#4]!
	cmpne r0,r1
	ldrne r1,[r2,#4]!
	cmpne r0,r1
	ldrne r1,[r2,#4]!
	cmpne r0,r1
	beq cached	;(r2-agb_bg_map)=matching group#

	ldr r2,bg_recent		;move oldest group to front of the list
	mov r7,r2,lsr#24		;r7=oldest group#*4
	ldr r1,[r6,r7]			;r1=old group
	str r0,[r6,r7]!			;save new group, r6=new chr map ptr
	mov r2,r2,ror#24
	str r2,bg_recent
	bx lr
	
	
;	eor r1,r1,r0
;
decodeptr	RN r2 ;mem_chr_decode
tilecount	RN r3
nesptr		RN r4 ;chr src
agbptr		RN r5 ;chr dst
bankptr		RN r6 ;vrom bank lookup ptr

;	mov agbptr,#AGB_VRAM
;	add agbptr,agbptr,r7,lsl#12	;0000/4000/8000/C000
im_lazy		;----------r1=old^new
	ldr decodeptr,=CHR_DECODE
bg0	 tst r1,#0xff
	 ldrb r0,[bankptr],#1
	 mov r1,r1,lsr#8
	 addeq agbptr,agbptr,#0x800
	 beq bg2
	 mov tilecount,#64
	 
	;r0 in
	;r4 out
	ldr nesptr,instant_chr_banks
	ldr nesptr,[nesptr,r0,lsl#2]

 [ DEBUG
	ldr r0,misscount
	add r0,r0,#4
	str r0,misscount
 ]
bg1	  ldrb r0,[nesptr],#1
	  ldrb r7,[nesptr,#7]
	  ldr r0,[decodeptr,r0,lsl#2]
	  ldr r7,[decodeptr,r7,lsl#2]
	  orr r0,r0,r7,lsl#1
	  str r0,[agbptr],#4
	  tst agbptr,#0x1f
	  bne bg1
	 subs tilecount,tilecount,#1
	 add nesptr,nesptr,#8
	 bne bg1
bg2	tst bankptr,#3
	bne bg0
 [ DEBUG
	ldr r0,misscount
	mov r1,#18
	b debug_
misscount DCD 0
 |
	mov pc,lr
 ]
cached;--------------move to the top of the list:
	adrl r4,bg_recent
	sub r7,r2,r6	;r7=group#*4
	mov r2,r7	;r2=new xx_recent
	ldrb r0,[r4]
	cmp r7,r0
	orrne r2,r0,r2,ror#8
	ldrb r0,[r4,#1]
	cmp r7,r0
	orrne r2,r0,r2,ror#8
	ldrb r0,[r4,#2]
	cmp r7,r0
	orrne r2,r0,r2,ror#8
	ldrb r0,[r4,#3]
	cmp r7,r0
	orrne r2,r0,r2,ror#8
	mov r2,r2,ror#8
	str r2,[r4]
	mov pc,lr

;----------------------------------------------------------------------------
; [ BUILD = "DEBUG"
; AREA zzzzz, DATA, READWRITE ;MUST be last area
;
;	DCB "0123456789abcdef0123456789abcde",0
;	DCD 16400 ;romsize
;	DCD 0 ;flags
;	DCD 0 ;follow
;	DCD 0 ;saveslot
;	DCB "NES",0x1a
;
;	INCBIN ..\gbabin\roms\sndtest.nes
;
; ]
;----------------------------------------------------------------------------

	[ RESET_ALL

 AREA rom_code_, CODE, READONLY

erase_r1_to_r2
	mov r0,#0
	sub addy,r2,r1
	b memset32_
reset_all
	stmfd sp!,{r4-r12,lr}
	
	bl reset_buffers
	
	ldr globalptr,=GLOBAL_PTR_BASE	;need ptr regs init'd
	
	adrl r1,cpuregs
	adrl r2,_dontstop
	bl erase_r1_to_r2
	
	adrl r1,vramaddr
	adrl r2,vram_page_base+2 ;=recent_tiles
	bl erase_r1_to_r2

	[ USE_BG_CACHE
	adrl r1,bg_cache_cursor
	adrl r2,twitch
	bl erase_r1_to_r2
	]
	
	mov r3,#1
	strb r3,vramaddrinc
	
	adrl r1,mapperdata
	adrl r2,apu_4017
	bl erase_r1_to_r2

	adrl r1,apu_4017
	adrl r2,sending
	bl erase_r1_to_r2
	
	adrl r1,nesoamdirty
	adrl r2,vram_write_tbl+8*4
	bl erase_r1_to_r2
	
	adrl r1,vram_map
	adrl r2,nes_nt0
	bl erase_r1_to_r2
	
	adrl r1,agb_pal
	adrl r2,scrollbuff
	bl erase_r1_to_r2

	mov r0,#0
	str r0,bankbuffer_last
	str r0,bankbuffer_last+4
	str r0,bankbuffer_line
	str r0,ctrl1line
	ldr r1,=0x0440
	str r1,ctrl1old
	
	
	
	
	
	
	ldmfd sp!,{r4-r12,lr}
	bx lr

reset_buffers
	stmfd sp!,{lr}

	ldr r0,=0x04400440
	;clear dispcnt buffers
	ldr r1,=DISPCNTBUFF1
	mov r2,#240/2
	bl filler_
	ldr r1,=DISPCNTBUFF2
	mov r2,#240/2
	bl filler_
	mov r0,#0
	ldr r1,=BG0CNTBUFF1
	mov r2,#240/2
	bl filler_
	mov r0,#0
	ldr r1,=BG0CNTBUFF2
	mov r2,#240/2
	bl filler_
	
	
	ldmfd sp!,{pc}
	]


 AREA wram_globals2, CODE, READWRITE

mapperstate
	% 32	;mapperdata
	% 3     ;padding
g_bank6
	% 1	;nes_prg_map
g_bank8
	% 1
g_bankA
	% 1
g_bankC
	% 1
g_bankE
	% 1



g_Cbank0
g_nes_chr_map
	% 8	;nes_chr_map	vrom paging map for NES VRAM $0000-1FFF
; 16 bytes removed
	DCD 0,0,0,0	;agb_bg_map	vrom paging map for AGB BG CHR
	DCD 0,0,0,0	;agb_real_bg_map	what's actually sitting in VRAM
; 8 bytes removed
	DCB 0,0,0,0	;bg_recent	AGB BG CHR group#s ordered by most recently used
romstart
g_rombase
	DCD 0 ;rombase
romnum
	DCD 0 ;romnumber
rominfo                 ;keep emuflags/BGmirror together for savestate/loadstate
g_emuflags	DCB 0 ;emuflags        (label this so UI.C can take a peek) see equates.h for bitfields
g_scaling	DCB SCALED_SPRITES ;(display type)
	% 2   ;(sprite follow val)
g_BGmirror	DCD 0 ;BGmirror		(BG size for BG0CNT)

g_rommask
	DCD 0 ;rommask
g_vrombase
	DCD 0 ;vrombase
g_vrommask
	DCD 0 ;vrommask
g_instant_prg_banks
	DCD 0 ;instant_prg_banks
g_instant_chr_banks
	DCD 0 ;instant_chr_banks
g_cartflags
	DCB 0 ;cartflags
g_hackflags
	DCB 0 ;hackflags
g_hackflags2
	DCB 0 ;hackflags2
g_mapper_number
	DCB 0 ;mapper_number
g_rompages
	DCB 0 ;rompages
g_vrompages
	DCB 0 ;vrompages
	
g_fourscreen	DCB 0 ;fourscreen
	DCB 0

	DCD 0 ;chrold
	DCD 0 ;chrline

;----------------------------------------------------------------------------
	END
