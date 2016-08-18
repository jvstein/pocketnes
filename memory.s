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
	[ CARTSAVE
	EXPORT sram_W2
	]
	EXPORT rom_R60
	EXPORT rom_R80
	EXPORT rom_RA0
	EXPORT rom_RC0
	EXPORT rom_RE0
	EXPORT filler_
	EXPORT memset16
	EXPORT memset32
	EXPORT memcpy32
	EXPORT memset16_
	EXPORT memset32_
	EXPORT memcpy32_
;----------------------------------------------------------------------------
empty_R		;read bad address (error)
;----------------------------------------------------------------------------
	[ DEBUG
		mov r0,addy
		mov r1,#0
		b debug_
	]

	mov r0,addy,lsr#8
void ;- - - - - - - - -empty function
;	mov r0,#0	;VS excitebike liked this, read from $3DDE ($2006).
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
	ldrb r0,[cpu_zpage,addy]
	mov pc,lr
;----------------------------------------------------------------------------
ram_W	;ram write ($0000-$1FFF)
;----------------------------------------------------------------------------
	bic addy,addy,#0x1f800		;only 0x07FF is RAM
	strb r0,[cpu_zpage,addy]
	mov pc,lr
;----------------------------------------------------------------------------
sram_R	;sram read ($6000-$7FFF)
;----------------------------------------------------------------------------
	sub r1,addy,#0x5800
	ldrb r0,[cpu_zpage,r1]
	mov pc,lr
;----------------------------------------------------------------------------
sram_W	;sram write ($6000-$7FFF)
;----------------------------------------------------------------------------
	sub addy,addy,#0x5800
	strb r0,[cpu_zpage,addy]
	mov pc,lr
	[ CARTSAVE
;----------------------------------------------------------------------------
sram_W2	;write to real sram ($6000-$7FFF)
;----------------------------------------------------------------------------
	sub r1,addy,#0x5800
	strb r0,[cpu_zpage,r1]
		orr r1,addy,#0xe000000	;r1=e006000+
 [ SAVE32
 |
		add r1,r1,#0x8000		;r1=e00e000+
 ]
		strb r0,[r1]
	mov pc,lr
	]
;----------------------------------------------------------------------------
rom_R60	;rom read ($6000-$7FFF)
;----------------------------------------------------------------------------
	ldr r1,memmap_tbl+12
	ldrb r0,[r1,addy]
	mov pc,lr
;----------------------------------------------------------------------------
rom_R80	;rom read ($8000-$9FFF)
;----------------------------------------------------------------------------
	ldr r1,memmap_tbl+16
	ldrb r0,[r1,addy]
	mov pc,lr
;----------------------------------------------------------------------------
rom_RA0	;rom read ($A000-$BFFF)
;----------------------------------------------------------------------------
	ldr r1,memmap_tbl+20
	ldrb r0,[r1,addy]
	mov pc,lr
;----------------------------------------------------------------------------
rom_RC0	;rom read ($C000-$DFFF)
;----------------------------------------------------------------------------
	ldr r1,memmap_tbl+24
	ldrb r0,[r1,addy]
	mov pc,lr
;----------------------------------------------------------------------------
rom_RE0	;rom read ($E000-$FFFF)
;----------------------------------------------------------------------------
	ldr r1,memmap_tbl+28
	ldrb r0,[r1,addy]
	mov pc,lr
;----------------------------------------------------------------------------
;rom_R	;rom read ($8000-$FFFF) (actually $6000-$FFFF now)
;----------------------------------------------------------------------------
;	adr r2,memmap_tbl
;	ldr r1,[r2,r1,lsr#11] ;r1=addy & 0xe000
;	ldrb r0,[r1,addy]
;	mov pc,lr
;----------------------------------------------------------------------------

filler__
	stmfd sp!,{addy,lr}
	mov addy,r2,lsl#2
	bl memset32
	ldmfd sp!,{addy,pc}

memset32
	;r1 = dest
	;r0 = word to fill
	;addy = number of BYTES to write
	mov addy,addy,lsr#1
	b %f0
memset16
	;r1 = dest
	;r0 = halfword to fill
	;addy = number of halfwords to write
	;can destroy r2
	orr r0,r0,r0,lsl#16
	;get aligned
0	tst r1,#2
	strneh r0,[r1],#2
	subne addy,addy,#1
	;pre-subtract, jump ahead if not enough remaining
	subs addy,addy,#12
	bmi %f2
	stmfd sp!,{r3-r5,lr}
	mov r2,r0
	mov r3,r0
	mov r4,r0
	mov r5,r0
	mov lr,r0
1
	stmia r1!,{r0,r2-r5,lr} ;24 bytes
	subs addy,addy,#12
	bmi %f3
	stmia r1!,{r0,r2-r5,lr}
	subs addy,addy,#12
	bpl %b1
3
	adds addy,addy,#12
	ldmeqfd sp!,{r3-r5,pc}
	subs addy,addy,#4
	bmi %f3
1
	stmia r1!,{r0,r2}
	subs addy,addy,#4
	bmi %f3
	stmia r1!,{r0,r2}
	subs addy,addy,#4
	bpl %b1
3
	sub addy,addy,#8
	ldmfd sp!,{r3,r4,r5,lr}
2
	adds addy,addy,#12
	bxle lr
1	
	strh r0,[r1],#2
	subs addy,addy,#1
	bgt %b1
	bx lr

memcpy32
;word aligned only
;r0=dest, r1=src, r2=byte count
	subs r2,r2,#32
	blt %f2
	stmfd sp!,{r3-r10}
0
	ldmia r1!,{r3-r10}
	stmia r0!,{r3-r10}
	subs r2,r2,#32
	blt %f1
	ldmia r1!,{r3-r10}
	stmia r0!,{r3-r10}
	subs r2,r2,#32
	blt %f1
	ldmia r1!,{r3-r10}
	stmia r0!,{r3-r10}
	subs r2,r2,#32
	blt %f1
	ldmia r1!,{r3-r10}
	stmia r0!,{r3-r10}
	subs r2,r2,#32
	bge %b0
1
	ldmfd sp!,{r3-r10}
2
	adds r2,r2,#32
	bxeq lr
0
	ldr r12,[r1],#4
	str r12,[r0],#4
	subs r2,r2,#4
	bne %b0
	bx lr


 AREA rom_code, CODE, READONLY
filler_ ;r0=data r1=dest r2=word count
	b_long filler__

memset32_
	b_long memset32
memset16_
	b_long memset16
memcpy32_
	b_long memcpy32

;
;;	exit with r0 unchanged
;;----------------------------------------------------------------------------
;	subs r2,r2,#1
;	str r0,[r1,r2,lsl#2]
;	bne filler_
;	mov pc,lr
;;----------------------------------------------------------------------------
	
	END
