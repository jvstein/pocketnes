	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE sound.h

	IMPORT C_entry	;from main.c

	EXPORT IO_reset_
	EXPORT IO_R
	EXPORT IO_W
	EXPORT joypad_write_ptr
	EXPORT joy0_W
	EXPORT joycfg
	EXPORT spriteinit
	EXPORT suspend

 AREA rom_code, CODE, READONLY ;-- - - - - - - - - - - - - - - - - - - - - -

scaleparms
	DCD 0x0000,0x0100,0xff01,0x0150,0xfeb6,OAM_BUFFER1+6,AGB_OAM+518
;----------------------------------------------------------------------------
IO_reset_
;----------------------------------------------------------------------------
	adr r6,scaleparms		;set sprite scaling params
	ldmia r6,{r0-r6}

	strh r1,[r5],#8				;buffer1
	strh r0,[r5],#8
	strh r0,[r5],#8
	strh r3,[r5],#232
		strh r2,[r5],#8
		strh r0,[r5],#8
		strh r0,[r5],#8
		strh r3,[r5],#232
	strh r1,[r5],#8				;buffer2
	strh r0,[r5],#8
	strh r0,[r5],#8
	strh r3,[r5],#232
		strh r2,[r5],#8
		strh r0,[r5],#8
		strh r0,[r5],#8
		strh r3,[r5],#232
	strh r1,[r5],#8				;buffer3
	strh r0,[r5],#8
	strh r0,[r5],#8
	strh r3,[r5],#232
		strh r2,[r5],#8
		strh r0,[r5],#8
		strh r0,[r5],#8
		strh r3,[r5],#232
	strh r1,[r6],#8				;7000200
	strh r0,[r6],#8
	strh r0,[r6],#8
	strh r4,[r6],#232
		strh r2,[r6],#8
		strh r0,[r6],#8
		strh r0,[r6],#8
		strh r4,[r6]

	ldrb r0,hackflags
;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
spriteinit	;build yscale_lookup tbl (called by ui.c) r0=hackflags
;----------------------------------------------------------------------------
	ldr r3,=YSCALE_LOOKUP
	tst r0,#NOSCALING
	beq si1

	sub r3,r3,#80
	mov r0,#-79
si3	strb r0,[r3],#1
	add r0,r0,#1
	cmp r0,#256
	bne si3
	mov pc,lr
si1
	ldr r0,=0x00c00000		;0.75
	ldr r1,=0xf5000000		;-14*0.75
si4	mov r2,r1,lsr#24
	strb r2,[r3],#1
	add r1,r1,r0
	cmp r2,#0xb4
	bne si4
	mov pc,lr

 AREA wram_code1, CODE, READWRITE ;-- - - - - - - - - - - - - - - - - - - - - -
;----------------------------------------------------------------------------
IO_R		;I/O read
;----------------------------------------------------------------------------
	sub r2,addy,#0x4000
	subs r2,r2,#0x15
	bmi empty_R
	cmp r2,#2
	bhi empty_R
	adr r1,io_read_tbl
	ldr pc,[r1,r2,lsl#2]

io_read_tbl
	DCD _4015r	;4015 (sound)
	DCD joy0_R	;4016: controller 1
	DCD joy1_R	;4017: controller 2
;----------------------------------------------------------------------------
IO_W		;I/O write
;----------------------------------------------------------------------------
	sub r2,addy,#0x4000
	cmp r2,#0x17
	bhi empty_W
	adr r1,io_write_tbl
	ldr pc,[r1,r2,lsl#2]
io_write_tbl
	DCD _4000w
	DCD _4001w
	DCD _4002w
	DCD _4003w
	DCD _4004w
	DCD _4005w
	DCD _4006w
	DCD _4007w
	DCD _4008w
	DCD void
	DCD _400aw
	DCD _400bw
	DCD _400cw
	DCD void
	DCD _400ew
	DCD _400fw
	DCD _4010w
	DCD _4011w
	DCD _4012w
	DCD _4013w
	DCD dma_W	;$4014: Sprite DMA transfer
	DCD _4015w
joypad_write_ptr
	DCD joy0_W	;$4016: Joypad 0 write
	DCD void	;$4017: ?
;----------------------------------------------------------------------------
dma_W	;(4014)		sprite DMA transfer
;----------------------------------------------------------------------------
PRIORITY EQU 0x800	;AGB OBJ priority (2/3)

	ldr r1,=3*514*CYCLE
	sub cycles,cycles,r1
	[ DEBUG
		tst r0,#0x80		;DMA from rom?
		adrne r0,dma_W
		movne r1,#0
		bne debug_
	]
	stmfd sp!,{r3-r6,lr}

	and r0,r0,#0xff
	add addy,nes_zpage,r0,lsl#8 ;addy=DMA source

	ldr r2,oambuffer+4	;r2=dest
	ldr r1,oambuffer+8
	ldr r0,oambuffer
	str r2,oambuffer
	str r1,oambuffer+4
	str r0,oambuffer+8

	ldr r1,hackflags
	tst r1,#SCALESPRITES
	movne r6,#0x100		;r6=rot/scale flag
	moveq r6,#0

	tst r1,#NOSCALING
	beq dm0
	tst r1,#SPRITEFOLLOW+MEMFOLLOW
	beq dm0				;do autoscroll
	ldr r3,AGBjoypad
	tst r3,#0x100
	tsteq r3,#0x200
	bne dm0				;stop if L/R pressed (manual scroll)
	mov r3,r1,lsr#8
	bic r3,r3,#0xff0000
	tst r1,#SPRITEFOLLOW
	ldrneb r0,[addy,r3,lsl#2]
	ldreqb r0,[nes_zpage,r3]
	cmp r0,#239
	bhi dm0
	add r0,r0,r0,lsl#2
	mov r0,r0,lsr#4
	str r0,windowtop
dm0
	ldr r0,windowtop+4
	adrl r5,yscale_lookup
	sub r5,r5,r0

	ldrb r0,ppuctrl0frame	;8x16?
	tst r0,#0x20
	bne dm4
				;get sprite0 hit pos:
	tst r0,#0x08			;CHR base? (0000/1000)
	moveq r4,#0+PRIORITY		;r4=CHR set+AGB priority
	movne r4,#0x100+PRIORITY
	ldrb r0,[addy,#1]		;sprite tile#
	mov r1,#AGB_VRAM
	addeq r1,r1,#0x10000
	addne r1,r1,#0x12000
	add r0,r1,r0,lsl#5		;r0=VRAM base+tile*32
	ldr r1,[r0]			;I don't really give a shit about Y flipping at the moment
	cmp r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	and r0,r0,#31
	ldrb r1,[addy]			;r1=sprite0 Y
	add r1,r1,r0,lsr#2
	moveq r1,#512			;blank tile=no hit
	cmp r1,#239
	movhi r1,#512			;no hit if Y>239
	str r1,sprite0y
dm11
	ldr r3,[addy],#4
	and r0,r3,#0xff
	cmp r0,#239
	bhi dm10		;skip if sprite Y>239
	ldrb r0,[r5,r0]		;y
	subs r1,r3,#0x08000000	;x-8
	and r1,r1,#0xff000000
	orr r0,r0,r1,lsr#8
	orrcc r0,r0,#0x01000000
	and r1,r3,#0x00c00000	;flip
	orr r0,r0,r1,lsl#6
	orr r0,r0,r6		;rot/scale
	str r0,[r2],#4
	and r1,r3,#0x0000ff00	;tile#
	mov r0,r1,lsr#8
	and r1,r3,#0x00030000	;color
	orr r0,r0,r1,lsr#4
	and r1,r3,#0x00200000	;priority
	orr r0,r0,r1,lsr#11
	orr r0,r0,r4		;tileset+priority
	strh r0,[r2],#4
dm9
	tst addy,#0xff
	bne dm11
	ldmfd sp!,{r3-r6,pc}
dm10
	mov r0,#0xe0
	str r0,[r2],#8
	b dm9

dm4	;- - - - - - - - - - - - -8x16
				;check sprite hit:
	ldrb r0,[addy,#1]		;sprite tile#
	movs r0,r0,lsr#1
	orrcs r0,r0,#0x80
	ldr r1,=0x6010000		;AGB VRAM
	add r0,r1,r0,lsl#6
	ldr r1,[r0]
	cmp r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	ldreq r1,[r0,#4]!
	cmpeq r1,#0
	and r0,r0,#63
	ldrb r1,[addy]			;r1=sprite0 Y
	add r1,r1,r0,lsr#2
	moveq r1,#512			;blank tile=no hit
	cmp r1,#239
	movhi r1,#512			;no hit if Y>239
	str r1,sprite0y

	mov r4,#PRIORITY
	orr r6,r6,#0x8000	;8x16 flag
dm12
	ldr r3,[addy],#4
	and r0,r3,#0xff
	cmp r0,#239
	bhi dm13		;skip if sprite Y>239
	ldrb r0,[r5,r0]		;y
	subs r1,r3,#0x08000000	;x-8
	and r1,r1,#0xff000000
	orr r0,r0,r1,lsr#8
	orrcc r0,r0,#0x01000000
	and r1,r3,#0x00c00000	;flip
	orr r0,r0,r1,lsl#6
	orr r0,r0,r6		;8x16+rot/scale
	str r0,[r2],#4
	and r1,r3,#0x0000ff00	;tile#
	movs r0,r1,lsr#9
	orrcs r0,r0,#0x80
	orr r0,r4,r0,lsl#1	;priority, tile#*2
	and r1,r3,#0x00030000	;color
	orr r0,r0,r1,lsr#4
	and r1,r3,#0x00200000	;priority
	orr r0,r0,r1,lsr#11
	strh r0,[r2],#4
dm14
	tst addy,#0xff
	bne dm12
	ldmfd sp!,{r3-r6,pc}
dm13
	mov r0,#0xe0
	str r0,[r2],#8
	b dm14
;----------------------------------------------------------------------------
joy0_W		;4016
;----------------------------------------------------------------------------
	tst r0,#1
	movne pc,lr

		ldr r2,frame
		movs r2,r2,lsr#2 ;C=frame&2 (autofire alternates every other frame)
	ldr r1,AGBjoypad
	and r0,r1,#0xf0
		ldr r2,joycfg
		andcs r1,r1,r2
		movcss addy,r1,lsr#9	;R?
		andcs r1,r1,r2,lsr#16
	adr addy,dulr2rldu
	and r1,r1,#0x0f
	ldrb r0,[addy,r0,lsr#4]
	orr r1,r1,r0

	tst r2,#0x80000000
	streq r1,joy0data
	strne r1,joy1data

	mov pc,lr

joycfg DCD 0x00ff01ff ;byte0=auto mask, byte1=(saves R), byte2=R auto mask, MSB=joy1/joy2
joy0data DCD 0
joy1data DCD 0
dulr2rldu DCB 0x00,0x80,0x40,0xc0, 0x10,0x90,0x50,0xd0, 0x20,0xa0,0x60,0xe0, 0x30,0xb0,0x70,0xf0
;----------------------------------------------------------------------------
joy0_R		;4016
;----------------------------------------------------------------------------
	ldr r0,joy0data
	mov r1,r0,lsr#1
	and r0,r0,#1
	str r1,joy0data

	ldrb r1,cartflags
	tst r1,#VS
	moveq pc,lr

	ldr r2,AGBjoypad
	tst r2,#8		;start=coin (VS)
	orrne r0,r0,#0x40

	mov pc,lr
;----------------------------------------------------------------------------
joy1_R		;4017
;----------------------------------------------------------------------------
	ldr r0,joy1data
	mov r1,r0,lsr#1
	and r0,r0,#1
	str r1,joy1data

	ldrb r1,cartflags
	tst r1,#VS
	orrne r0,r0,#0xf8		;VS switches
	mov pc,lr
;----------------------------------------------------------------------------
suspend	;called from ui.c and 6502.s
;-------------------------------------------------
	stmfd sp!,{r0,r1,lr}
	mov r3,#REG_BASE

	ldr r1,=REG_P1CNT
	ldr r0,=0xc00c			;interrupt on start+sel
	strh r0,[r3,r1]

	ldrh r1,[r3,#REG_SGCNT0_L]
	strh r3,[r3,#REG_SGCNT0_L]	;sound off

	ldrh r0,[r3,#REG_DISPCNT]
	orr r0,r0,#0x80
	strh r0,[r3,#REG_DISPCNT]	;LCD off

	swi 0x030000
	
	ldrh r0,[r3,#REG_DISPCNT]
	bic r0,r0,#0x80
	strh r0,[r3,#REG_DISPCNT]	;LCD on

	strh r1,[r3,#REG_SGCNT0_L]	;sound on

	ldmfd sp!,{r0,r1,pc}
;--------------------------------------------------
	END
