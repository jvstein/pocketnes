PSR_N EQU 0x80000000	;ARM flags
PSR_Z EQU 0x40000000
PSR_C EQU 0x20000000
PSR_V EQU 0x10000000

C EQU 2_00000001	;6502 flags
Z EQU 2_00000010
I EQU 2_00000100
D EQU 2_00001000
B EQU 2_00010000
R EQU 2_00100000	;(locked at 1)
V EQU 2_01000000
N EQU 2_10000000


	MACRO		;Change CPU mode from System to FIQ
	modeFIQ
	mrs r0,cpsr
	bic r0,r0,#0x0e
	msr cpsr_cf,r0
	MEND

	MACRO		;Change CPU mode from FIQ to System
	modeSystem
	mrs r0,cpsr
	orr r0,r0,#0x0e
	msr cpsr_cf,r0
	MEND

	MACRO		;translate nes_pc from 6502 PC to rom offset
	encodePC
	mov r1,nes_pc,lsr#13
	adr r2,memmap_tbl
	ldr r0,[r2,r1,lsl#2]
	str r0,lastbank
	add nes_pc,nes_pc,r0
	MEND

	MACRO		;pack 6502 flags into r0
	encodeP $extra
	and r1,nes_nz,#0x80000000
	ldr r0,nes_di			;DI
	orr r0,r0,r1,lsr#24		;N
	tst nes_nz,#0xff
	orreq r0,r0,#Z			;Z
	tst nes_c,#PSR_C
	orrne r0,r0,#C			;C
	ldr r1,nes_v
	tst r1,#PSR_V		;V
	orrne r0,r0,#V
	orr r0,r0,#$extra		;..
	MEND

	MACRO		;unpack 6502 flags from r0
	decodeP
	and r1,r0,#D+I
	str r1,nes_di			;DI
	mov r1,r0,lsl#22
	str r1,nes_v			;V
	mov nes_c,r0,lsl#29		;C
	mov nes_nz,r0,lsl#24		;N
	tst r0,#Z
	orreq nes_nz,nes_nz,#1		;Z
	MEND

	MACRO
	fetch $count
	subs cycles,cycles,#$count*3*CYCLE
	ldrplb r0,[nes_pc],#1
	ldrpl pc,[nes_optbl,r0,lsl#2]
	ldr pc,nexttimeout
	MEND

	MACRO
	readmemabs
	and r1,addy,#0xE000
	adr r2,readmem_tbl
	adr lr,%F0
	ldr pc,[r2,r1,lsr#11]	;in: addy,r1=addy&0xE000 (for rom_R)
0				;out: nes_nz=val (bits 8-31=sign (watch ROL,DEC)), addy preserved for RMW instructions
	MEND

	MACRO
	readmemzp
	ldrsb nes_nz,[nes_zpage,addy]
	MEND

	MACRO
	readmemimm
	ldrsb nes_nz,[nes_pc],#1
	MEND

	MACRO
	readmem
	[ _type = _ABS
		readmemabs
	]
	[ _type = _ZP
		readmemzp
	]
	[ _type = _IMM
		readmemimm
	]
	MEND

	MACRO
	writemem
	and r1,addy,#0xE000
	adr r2,writemem_tbl
	adr lr,%F0
	ldr pc,[r2,r1,lsr#11]	;in: addy,r0=val(bits 8-31=?)
0				;out: r0,r1,r2,addy=?
	MEND

	MACRO
	writememzp
	strb r0,[pce_zpage,addy]
	MEND

;----------------------------------------------------------------------------

	MACRO
	push16		;push r0
	mov r1,r0,lsr#8
	ldr r2,nes_s
	strb r1,[r2],#-1
	orr r2,r2,#0x100
	strb r0,[r2],#-1
	strb r2,nes_s
	MEND		;r1,r2=?

	MACRO
	push8 $x
	ldr r2,nes_s
	strb $x,[r2],#-1
	strb r2,nes_s
	MEND		;r2=?

	MACRO
	pop16		;pop nes_pc
	ldrb r2,nes_s
	add r2,r2,#1
	orr r2,r2,#0x100
	ldrb nes_pc,[nes_zpage,r2]
	add r2,r2,#1
	strb r2,nes_s
	ldr r2,nes_s
	ldrb r0,[r2]
	orr nes_pc,nes_pc,r0,lsl#8
	MEND		;r0,r1=?

	MACRO
	pop8 $x
	ldrb r2,nes_s
	add r2,r2,#1
	strb r2,nes_s
	orr r2,r2,#0x100 ;..
	ldrsb $x,[r2,nes_zpage]		;signed for PLA
	MEND	;r2=?

;----------------------------------------------------------------------------
;doXXX: load addy, increment nes_pc

	GBLA _type

_IMM	EQU     1                       ;immediate
_ZP	EQU     2                       ;zero page
_ABS	EQU     3                       ;absolute

	MACRO
	doABS                           ;absolute               $nnnn
_type	SETA      _ABS
	ldrb addy,[nes_pc],#1
	ldrb r0,[nes_pc],#1
	orr addy,addy,r0,lsl#8
	MEND

	MACRO
	doAIX                           ;absolute indexed X     $nnnn,X
_type	SETA      _ABS
	ldrb addy,[nes_pc],#1
	ldrb r0,[nes_pc],#1
	orr addy,addy,r0,lsl#8
	add addy,addy,nes_x,lsr#24
	bic addy,addy,#0xff0000 ;Base Wars needs this
	MEND

	MACRO
	doAIY                           ;absolute indexed Y     $nnnn,Y
_type	SETA      _ABS
	ldrb addy,[nes_pc],#1
	ldrb r0,[nes_pc],#1
	orr addy,addy,r0,lsl#8
	add addy,addy,nes_y,lsr#24
	bic addy,addy,#0xff0000 ;Tecmo Bowl needs this
	MEND

	MACRO
	doIMM                           ;immediate              #$nn
_type	SETA      _IMM
	MEND

	MACRO
	doIIX                           ;indexed indirect X     ($nn,X)
_type	SETA      _ABS
	ldrb r0,[nes_pc],#1
	add r0,nes_x,r0,lsl#24
	ldrb addy,[nes_zpage,r0,lsr#24]
	add r0,r0,#0x01000000
	ldrb r1,[nes_zpage,r0,lsr#24]
	orr addy,addy,r1,lsl#8
	MEND

	MACRO
	doIIY                           ;indirect indexed Y     ($nn),Y
_type	SETA      _ABS
	ldrb r0,[nes_pc],#1
	ldrb addy,[r0,nes_zpage]!
	ldrb r1,[r0,#1]
	orr addy,addy,r1,lsl#8
	add addy,addy,nes_y,lsr#24
	bic addy,addy,#0xff0000 ;Zelda2 needs this
	MEND

	MACRO
	doZ                             ;zero page              $nn
_type	SETA      _ZP
	ldrb addy,[nes_pc],#1
	MEND

	MACRO
	doZIX                           ;zero page indexed X    $nn,X
_type	SETA      _ZP
	ldrb addy,[nes_pc],#1
	add addy,addy,nes_x,lsr#24
	and addy,addy,#0xff ;Rygar needs this
	MEND

	MACRO
	doZIY                           ;zero page indexed Y    $nn,Y
_type	SETA      _ZP
	ldrb addy,[nes_pc],#1
	add addy,addy,nes_y,lsr#24
	and addy,addy,#0xff
	MEND

;----------------------------------------------------------------------------

	MACRO
	opADC
	readmem
	eor nes_nz,nes_nz,#0xff
	msr cpsr_f,nes_c        ;get C
	sbcs nes_a,nes_a,nes_nz,lsl#24
	mov nes_nz,nes_a,asr#24 ;NZ
	mrs nes_c,cpsr          ;C
	str nes_c,nes_v         ;V
	and nes_a,nes_a,#0xff000000
	MEND

	MACRO
	opAND
	readmem
	and nes_a,nes_a,nes_nz,lsl#24
	mov nes_nz,nes_a,asr#24
	MEND

	MACRO
	opASL
	[ _type=_ABS
		readmemabs
		 mov nes_c,nes_nz,lsl#22	;C	;Do this first so we get rid of the signextend.
		 mov r0,nes_c,lsr#21
		 orr nes_nz,r0,r0,lsl#24	;NZ
		writemem
	|
		ldrb r0,[nes_zpage,addy]
		 add r0,r0,r0
		 orrs nes_nz,r0,r0,lsl#24	;NZ
		 mrs nes_c,cpsr			;C
		strb r0,[nes_zpage,addy]
	]
	MEND

	MACRO
	opBIT
	readmem
	and r0,nes_nz,nes_a,lsr#24	;Z
	mov r1,nes_nz,lsl#22
	str r1,nes_v			;V
	orr nes_nz,r0,nes_nz,lsl#24	;N
	MEND

	MACRO
	opCOMP $x			;A,X & Y
	readmem
	subs nes_nz,$x,nes_nz,lsl#24
	mov nes_nz,nes_nz,asr#24	;NZ
	mrs nes_c,cpsr			;C
	MEND

	MACRO
	opDEC
	[ _type=_ABS
		readmemabs
		and r0,nes_nz,#0xff
		sub r0,r0,#1
		orr nes_nz,r0,r0,lsl#24	;NZ
		writemem
	|
		ldrb r0,[nes_zpage,addy]
		sub r0,r0,#1
		orr nes_nz,r0,r0,lsl#24	;NZ
		strb r0,[nes_zpage,addy]
	]
	MEND

	MACRO
	opEOR
	readmem
	eor nes_a,nes_a,nes_nz,lsl#24
	mov nes_nz,nes_a,asr#24		;NZ
	MEND

	MACRO
	opINC
	[ _type=_ABS
		readmemabs
		add r0,nes_nz,#1
		orr nes_nz,r0,r0,lsl#24	;NZ
		writemem
	|
		ldrb r0,[nes_zpage,addy]
		add r0,r0,#1
		orr nes_nz,r0,r0,lsl#24	;NZ
		strb r0,[nes_zpage,addy]
	]
	MEND

	MACRO
	opLOAD $x
	readmem
	mov $x,nes_nz,lsl#24
	MEND

	MACRO
	opLSR
	[ _type=_ABS
		readmemabs
		mov nes_c,nes_nz,lsl#29
		and nes_nz,nes_nz,#0xfe	;(N=0)
		mov r0,nes_nz,lsr#1
		writemem
	|
		ldrb nes_nz,[nes_zpage,addy]
		movs nes_nz,nes_nz,lsr#1	;NZ
		mrs nes_c,cpsr			;C
		strb nes_nz,[nes_zpage,addy]
	]
	MEND

	MACRO
	opORA
	readmem
	orr nes_a,nes_a,nes_nz,lsl#24
	mov nes_nz,nes_a,asr#24
	MEND

	MACRO
	opROL
	[ _type=_ABS
		readmemabs
		 msr cpsr_f,nes_c	;get C
		 adc r0,nes_nz,nes_nz
		 orrs nes_nz,r0,r0,lsl#24 ;NZ
		 mrs nes_c,cpsr		;C
		writemem
	|
		ldrb r0,[nes_zpage,addy]
		 msr cpsr_f,nes_c	;get C
		 adc r0,r0,r0
		 orrs nes_nz,r0,r0,lsl#24 ;NZ
		 mrs nes_c,cpsr		;C
		strb r0,[nes_zpage,addy]
	]
	MEND

	MACRO
	opROR
	[ _type=_ABS
		readmemabs
		 mov r0,nes_nz,lsl#24
		 orr r0,r0,nes_c,lsr#29
		 movs r0,r0,ror#25
		 mrs nes_c,cpsr
		 orr nes_nz,r0,r0,lsl#24
		writemem
	|
		ldrb r0,[nes_zpage,addy]
		 tst nes_c,#PSR_C
		 orrne r0,r0,#0x100
		 movs r0,r0,lsr#1
		 mrs nes_c,cpsr
		 orr nes_nz,r0,r0,lsl#24
		strb r0,[nes_zpage,addy]
	]
	MEND

	MACRO
	opSBC
	readmem
	msr cpsr_f,nes_c        ;get C
	sbcs nes_a,nes_a,nes_nz,lsl#24
	mov nes_nz,nes_a,asr#24 ;NZ
	mrs nes_c,cpsr          ;C
	str nes_c,nes_v         ;V
	and nes_a,nes_a,#0xff000000
	MEND

	MACRO
	opSTORE $x
	mov r0,$x,lsr#24
	[ _type=_ABS
		writemem
	|
		strb r0,[nes_zpage,addy]
	]
	MEND
;----------------------------------------------------
	END
