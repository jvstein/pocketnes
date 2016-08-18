	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE sound.h
	INCLUDE cart.h
	INCLUDE 6502.h
	INCLUDE link.h

	EXPORT IO_reset
	EXPORT IO_R
	EXPORT IO_W
	EXPORT joypad_write_ptr
	EXPORT joy0_W
	EXPORT _joycfg
	EXPORT spriteinit
	EXPORT suspend
	EXPORT refreshNESjoypads
	EXPORT thumbcall_r1
	[ RTCSUPPORT
	EXPORT gettime
	]
	EXPORT vbaprint
	EXPORT waitframe
	EXPORT LZ77UnCompVram
	EXPORT CheckGBAVersion
	EXPORT empty_io_w_hook
	EXPORT breakpoint

 AREA rom_code, CODE, READONLY ;-- - - - - - - - - - - - - - - - - - - - - -

breakpoint
	mov r11,r11
	bx lr


vbaprint
	swi 0xFF0000		;!!!!!!! Doesn't work on hardware !!!!!!!
	bx lr
LZ77UnCompVram
	swi 0x120000
	bx lr
waitframe
VblWait
	mov r0,#0				;don't wait if not necessary
	mov r1,#1				;VBL wait
	swi 0x040000			; Turn of CPU until VBLIRQ if not too late allready.
	bx lr
CheckGBAVersion
	ldr r0,=0x5AB07A6E		;Fool proofing
	mov r12,#0
	swi 0x0D0000			;GetBIOSChecksum
	ldr r1,=0xABBE687E		;Proto GBA
	cmp r0,r1
	moveq r12,#1
	ldr r1,=0xBAAE187F		;Normal GBA
	cmp r0,r1
	moveq r12,#2
	ldr r1,=0xBAAE1880		;Nintendo DS
	cmp r0,r1
	moveq r12,#4
	mov r0,r12
	bx lr

scaleparms;	   NH     FH     NV     FV
	DCD 0x0000,0x0100,0xff00,0x0150,0xfeb6,AGB_OAM+6,AGB_OAM+518
;----------------------------------------------------------------------------
IO_reset
;----------------------------------------------------------------------------
	adr r6,scaleparms		;set sprite scaling params
	ldmia r6,{r0-r6}

;	mov r7,#3
scaleloop
	strh r1,[r5],#8				;buffer1, buffer2, buffer3
	strh r0,[r5],#8
	strh r0,[r5],#8
	strh r3,[r5],#232
		strh r2,[r5],#8
		strh r0,[r5],#8
		strh r0,[r5],#8
		strh r3,[r5],#232
;	subs r7,r7,#1
	bne scaleloop

	strh r1,[r6],#8				;7000200
	strh r0,[r6],#8
	strh r0,[r6],#8
	strh r4,[r6],#232
		strh r2,[r6],#8
		strh r0,[r6],#8
		strh r0,[r6],#8
		strh r4,[r6]

        ldrb r0,emuflags+1
	;..to spriteinit
;----------------------------------------------------------------------------
spriteinit	;build yscale_lookup tbl (called by ui.c) r0=scaletype
;called by ui.c:  void spriteinit(char scaletype) (pass scaletype in r0 because globals ptr isn't set up to read it)
;----------------------------------------------------------------------------
	ldr r3,=YSCALE_LOOKUP
	cmp r0,#SCALED
	bhs si1

	sub r3,r3,#80
	mov r0,#-79
si3	strb r0,[r3],#1
	add r0,r0,#1
	cmp r0,#256
	bne si3
	bx lr
si1
	mov   r0,#0x00c00000		;0.75
	mov   r1,#0xf3000000		;-16*0.75
	movhi r1,#0xef000000		;-16*0.75 was 0xf5000000
;	ldrhi r1,=0xeec00000		;-16*0.75 was 0xf5000000  ;FIXME: find good value for this
si4	mov r2,r1,lsr#24
	strb r2,[r3],#1
	add r1,r1,r0
	cmp r2,#0xb4
	bne si4
	bx lr
;----------------------------------------------------------------------------
suspend	;called from ui.c and 6502.s
;-------------------------------------------------
	mov r3,#REG_BASE

	ldr r1,=REG_P1CNT
	ldr r0,=0xc00c			;interrupt on start+sel
	strh r0,[r3,r1]

	ldrh r1,[r3,#REG_SGCNT_L]
	strh r3,[r3,#REG_SGCNT_L]	;sound off

	ldrh r0,[r3,#REG_DISPCNT]
	orr r0,r0,#0x80
	strh r0,[r3,#REG_DISPCNT]	;LCD off

	swi 0x030000

	ldrh r0,[r3,#REG_DISPCNT]
	bic r0,r0,#0x80
	strh r0,[r3,#REG_DISPCNT]	;LCD on

	strh r1,[r3,#REG_SGCNT_L]	;sound on

	bx lr
	[ RTCSUPPORT
;----------------------------------------------------------------------------
gettime	;called from ui.c
;----------------------------------------------------------------------------
	ldr r3,=0x080000c4		;base address for RTC
	mov r1,#1
	strh r1,[r3,#4]			;enable RTC
	mov r1,#7
	strh r1,[r3,#2]			;enable write

	mov r1,#1
	strh r1,[r3]
	mov r1,#5
	strh r1,[r3]			;State=Command

	mov r2,#0x65			;r2=Command, YY:MM:DD 00 hh:mm:ss
	mov addy,#8
RTCLoop1
	mov r1,#2
	and r1,r1,r2,lsr#6
	orr r1,r1,#4
	strh r1,[r3]
	mov r1,r2,lsr#6
	orr r1,r1,#5
	strh r1,[r3]
	mov r2,r2,lsl#1
	subs addy,addy,#1
	bne RTCLoop1

	mov r1,#5
	strh r1,[r3,#2]			;enable read
	mov r2,#0
	mov addy,#32
RTCLoop2
	mov r1,#4
	strh r1,[r3]
	mov r1,#5
	strh r1,[r3]
	ldrh r1,[r3]
	and r1,r1,#2
	mov r2,r2,lsr#1
	orr r2,r2,r1,lsl#30
	subs addy,addy,#1
	bne RTCLoop2

	mov r0,#0
	mov addy,#24
RTCLoop3
	mov r1,#4
	strh r1,[r3]
	mov r1,#5
	strh r1,[r3]
	ldrh r1,[r3]
	and r1,r1,#2
	mov r0,r0,lsr#1
	orr r0,r0,r1,lsl#22
	subs addy,addy,#1
	bne RTCLoop3

	bx lr
	]
;--------------------------------------------------

	[ VISOLY
	INCLUDE visoly.s
	|
	EXPORT doReset
doReset
	mov r1,#REG_BASE
	mov r0,#0
	strh r0,[r1,#REG_DM0CNT_H]	;stop all DMA
	strh r0,[r1,#REG_DM1CNT_H]
	strh r0,[r1,#REG_DM2CNT_H]
	strh r0,[r1,#REG_DM3CNT_H]
	add r1,r1,#0x200
	str r0,[r1,#8]		;interrupts off
	mov		r0, #0
	ldr		r1,=0x3007ffa	;must be 0 before swi 0x00 is run, otherwise it tries to start from 0x02000000.
	strh		r0,[r1]
	mov		r0, #8		;VRAM clear
	swi		0x010000
	swi		0x000000
	]
	
	
 AREA wram_code1, CODE, READWRITE ;-- - - - - - - - - - - - - - - - - - - - - -

thumbcall_r1 bx r1
;----------------------------------------------------------------------------
IO_R		;I/O read
;----------------------------------------------------------------------------
	sub r2,addy,#0x4000
	subs r2,r2,#0x15
	bmi empty_R
	cmp r2,#3
	ldrmi pc,[pc,r2,lsl#2]
	b empty_R
io_read_tbl
	DCD _4015r	;4015 (sound)
	DCD joy0_R	;4016: controller 1
	DCD joy1_R	;4017: controller 2
;----------------------------------------------------------------------------
IO_W		;I/O write
;----------------------------------------------------------------------------
	sub r2,addy,#0x4000
	cmp r2,#0x18
	ldrmi pc,[pc,r2,lsl#2]
	ldr pc,[pc,#0x5C]
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
	DCD _4017w	;$4017: frame irq
empty_io_w_hook
	DCD empty_W


dulr2rldu DCB 0x00,0x80,0x40,0xc0, 0x10,0x90,0x50,0xd0, 0x20,0xa0,0x60,0xe0, 0x30,0xb0,0x70,0xf0
ssba2ssab DCB 0x00,0x02,0x01,0x03, 0x04,0x06,0x05,0x07, 0x08,0x0a,0x09,0x0b, 0x0c,0xe0,0xd0,0x0f

;----------------------------------------------------------------------------
refreshNESjoypads	;call every frame
;exits with Z flag clear if update incomplete (waiting for other player)
;is my multiplayer code butt-ugly?  yes, I thought so.
;i'm not trying to win any contests here.
;----------------------------------------------------------------------------
	mov r6,lr		;return with this..

;	ldr r0,received0
;	mov r1,#4
;	bl debug_
;	ldr r0,received1
;	mov r1,#5
;	bl debug_
;	ldr r0,received2
;	mov r1,#7
;	bl debug_
;	ldr r0,received3
;	mov r1,#8
;	bl debug_
;	ldr r0,sending
;	mov r1,#10
;	bl debug_
;	ldr r0,lastsent
;	mov r1,#11
;	bl debug_

		ldr r4,frame
		movs r0,r4,lsr#2 ;C=frame&2 (autofire alternates every other frame)
	ldr r1,NESjoypad
	and r0,r1,#0xf0
		ldr r2,joycfg
		andcs r1,r1,r2
		movcss addy,r1,lsr#9	;R?
		andcs r1,r1,r2,lsr#16
	adr addy,dulr2rldu
	ldrb r0,[addy,r0,lsr#4]	;downupleftright
	and r1,r1,#0x0f			;startselectBA
	tst r2,#0x400			;Swap A/B?
	adrne addy,ssba2ssab
	ldrneb r1,[addy,r1]	;startselectBA
	orr r0,r1,r0		;r0=joypad state

	tst r2,#0x80000000
	[ LINK
	bne_long link_multi
	]

;	tst r2,#0x40000000	; P3/P4
;	beq no4scr
;	tst r2,#0x20000000	; P3/P4
;	streqb r0,joy2state
;	strneb r0,joy3state
;	ands r0,r0,#0		;Z=1
;	mov pc,r6
	
no4scr
	tst r2,#0x20000000
	strneb r0,joy0state
	tst r2,#0x40000000
	strneb r0,joy1state
	ands r0,r0,#0		;Z=1
	mov pc,r6

;----------------------------------------------------------------------------
joy0_W		;4016
;----------------------------------------------------------------------------
	tst r0,#1
	movne pc,lr
	ldr r2,nrplayers
	cmp r2,#3
	mov r2,#-1

	ldrb r0,joy0state
	ldrb r1,joy2state
	orr r0,r0,r1,lsl#8
	orrmi r0,r0,r2,lsl#8	;for normal joypads.
	orrpl r0,r0,#0x00080000	;4player adapter
	str r0,joy0serial

	ldrb r0,joy1state
	ldrb r1,joy3state
	orr r0,r0,r1,lsl#8
	orrmi r0,r0,r2,lsl#8	;for normal joypads.
	orrpl r0,r0,#0x00040000	;4player adapter
	str r0,joy1serial
	mov pc,lr
;----------------------------------------------------------------------------
joy0_R		;4016
;----------------------------------------------------------------------------
	ldr r0,joy0serial
	mov r1,r0,asr#1
	and r0,r0,#1
	str r1,joy0serial

	ldrb r1,cartflags
	tst r1,#VS
	orreq r0,r0,#0x40
	moveq pc,lr

	ldrb r1,joy0state
	tst r1,#8		;start=coin (VS)
	orrne r0,r0,#0x40

	mov pc,lr
;----------------------------------------------------------------------------
joy1_R		;4017
;----------------------------------------------------------------------------
	ldr r0,joy1serial
	mov r1,r0,asr#1
	and r0,r0,#1
	str r1,joy1serial

	ldrb r1,cartflags
	tst r1,#VS
	orrne r0,r0,#0xf8	;VS dip switches
	mov pc,lr
;----------------------------


	AREA wram_globals4, CODE, READWRITE

_sending DCD 0
_lastsent DCD 0
_received0 DCD 0
_received1 DCD 0
_received2 DCD 0
_received3 DCD 0

_joycfg DCD 0x20ff01ff ;byte0=auto mask, byte1=(saves R)bit2=SwapAB, byte2=R auto mask
;bit 31=single/multi, 30,29=1P/2P, 27=(multi) link active, 24=reset signal received
_joy0state DCB 0
_joy1state DCB 0
_joy2state DCB 0
_joy3state DCB 0
_joy0serial DCD 0
_joy1serial DCD 0
_nrplayers DCD 0		;Number of players in multilink.


	END
