	AREA wram_code2, CODE, READWRITE

	INCLUDE equates.h
	INCLUDE 6502.h
	INCLUDE ppu.h

	EXPORT void
	EXPORT empty_R
	EXPORT empty_W
	EXPORT ram_R
	EXPORT ram_W
	EXPORT sram_R
	EXPORT sram_W
	EXPORT sram_W2
	EXPORT rom_R60
	EXPORT rom_R80
	EXPORT rom_RA0
	EXPORT rom_RC0
	EXPORT rom_RE0
	EXPORT filler_
;----------------------------------------------------------------------------
empty_R		;read bad address (error)
;----------------------------------------------------------------------------
	[ DEBUG
		mov r0,addy
		mov r1,#0
		b debug_
	]

	mov nes_nz,addy,lsr#8
void ;- - - - - - - - -empty function
;	mov nes_nz,#0	;VS excitebike liked this, read from $3DDE ($2006).
	mov pc,lr
;----------------------------------------------------------------------------
empty_W		;write bad address (error)
;----------------------------------------------------------------------------
	[ DEBUG
		mov r0,addy
		mov r1,#0
		b debug_
	|
		mov pc,lr
	]
;----------------------------------------------------------------------------
ram_R	;ram read ($0000-$1FFF)
;----------------------------------------------------------------------------
	bic addy,addy,#0x1f800		;only 0x07FF is RAM
	ldrsb nes_nz,[nes_zpage,addy]
	mov pc,lr
;----------------------------------------------------------------------------
ram_W	;ram write ($0000-$1FFF)
;----------------------------------------------------------------------------
	bic addy,addy,#0x1f800		;only 0x07FF is RAM
	strb r0,[nes_zpage,addy]
	mov pc,lr
;----------------------------------------------------------------------------
sram_R	;sram read ($6000-$7FFF)
;----------------------------------------------------------------------------
	sub r1,addy,#0x5800
	ldrsb nes_nz,[nes_zpage,r1]
	mov pc,lr
;----------------------------------------------------------------------------
sram_W	;sram write ($6000-$7FFF)
;----------------------------------------------------------------------------
	sub addy,addy,#0x5800
	strb r0,[nes_zpage,addy]
	mov pc,lr
;----------------------------------------------------------------------------
sram_W2	;write to real sram ($6000-$7FFF)
;----------------------------------------------------------------------------
	sub r1,addy,#0x5800
	strb r0,[nes_zpage,r1]
		orr r1,addy,#0xe000000	;r1=e006000+
		add r1,r1,#0x8000		;r1=e00e000+
		strb r0,[r1]
	mov pc,lr
;----------------------------------------------------------------------------
rom_R60	;rom read ($6000-$7FFF)
;----------------------------------------------------------------------------
	ldr r1,memmap_tbl+12
	ldrsb nes_nz,[r1,addy]
	mov pc,lr
;----------------------------------------------------------------------------
rom_R80	;rom read ($8000-$9FFF)
;----------------------------------------------------------------------------
	ldr r1,memmap_tbl+16
	ldrsb nes_nz,[r1,addy]
	mov pc,lr
;----------------------------------------------------------------------------
rom_RA0	;rom read ($A000-$BFFF)
;----------------------------------------------------------------------------
	ldr r1,memmap_tbl+20
	ldrsb nes_nz,[r1,addy]
	mov pc,lr
;----------------------------------------------------------------------------
rom_RC0	;rom read ($C000-$DFFF)
;----------------------------------------------------------------------------
	ldr r1,memmap_tbl+24
	ldrsb nes_nz,[r1,addy]
	mov pc,lr
;----------------------------------------------------------------------------
rom_RE0	;rom read ($E000-$FFFF)
;----------------------------------------------------------------------------
	ldr r1,memmap_tbl+28
	ldrsb nes_nz,[r1,addy]
	mov pc,lr
;----------------------------------------------------------------------------
;rom_R	;rom read ($8000-$FFFF) (actually $6000-$FFFF now)
;----------------------------------------------------------------------------
;	adr r2,memmap_tbl
;	ldr r1,[r2,r1,lsr#11] ;r1=addy & 0xe000
;	ldrsb nes_nz,[r1,addy]
;	mov pc,lr
;----------------------------------------------------------------------------
 AREA rom_code, CODE, READONLY
filler_ ;r0=data r1=dest r2=word count
;	exit with r0 unchanged
;----------------------------------------------------------------------------
	subs r2,r2,#1
	str r0,[r1,r2,lsl#2]
	bne filler_
	mov pc,lr
;----------------------------------------------------------------------------
	END
