	INCLUDE equates.h
	INCLUDE ppu.h

	EXPORT timer1interrupt
	EXPORT Sound_reset
	EXPORT updatesound
	EXPORT make_freq_table
	EXPORT _4000w
	EXPORT _4001w
	EXPORT _4002w
	EXPORT _4003w
	EXPORT _4004w
	EXPORT _4005w
	EXPORT _4006w
	EXPORT _4007w
	EXPORT _4008w
	EXPORT _400aw
	EXPORT _400bw
	EXPORT _400cw
	EXPORT _400ew
	EXPORT _400fw
	EXPORT _4010w
	EXPORT _4011w
	EXPORT _4012w
	EXPORT _4013w
	EXPORT _4015w
	EXPORT _4015r
	EXPORT pcmctrl

pcmirqbakup EQU mapperdata+24
pcmirqcount EQU mapperdata+28

 AREA wram_code0, CODE, READWRITE
;----------------------------------------------------------------------------
pcm_mix
;----------------------------------------------------------------------------
	movs r2,r2,lsr#1
	addcs r0,r0,#PCMSTEP
	subcc r0,r0,#PCMSTEP
	cmp r0,#PCMLIMIT			;range check volume level
	movgt r0,#PCMLIMIT
	cmp r0,#-PCMLIMIT
	movlt r0,#-PCMLIMIT
	mov r5,r0

	movs r2,r2,lsr#1
	addcs r0,r0,#PCMSTEP
	subcc r0,r0,#PCMSTEP
	cmp r0,#PCMLIMIT			;range check volume level
	movgt r0,#PCMLIMIT
	cmp r0,#-PCMLIMIT
	movlt r0,#-PCMLIMIT
	orr r5,r0,r5,lsr#8

	movs r2,r2,lsr#1
	addcs r0,r0,#PCMSTEP
	subcc r0,r0,#PCMSTEP
	cmp r0,#PCMLIMIT			;range check volume level
	movgt r0,#PCMLIMIT
	cmp r0,#-PCMLIMIT
	movlt r0,#-PCMLIMIT
	orr r5,r0,r5,lsr#8

	movs r2,r2,lsr#1
	addcs r0,r0,#PCMSTEP
	subcc r0,r0,#PCMSTEP
	cmp r0,#PCMLIMIT			;range check volume level
	movgt r0,#PCMLIMIT
	cmp r0,#-PCMLIMIT
	movlt r0,#-PCMLIMIT
	orr r5,r0,r5,lsr#8
	str r5,[r12],#4

	movs r2,r2,lsr#1
	addcs r0,r0,#PCMSTEP
	subcc r0,r0,#PCMSTEP
	cmp r0,#PCMLIMIT			;range check volume level
	movgt r0,#PCMLIMIT
	cmp r0,#-PCMLIMIT
	movlt r0,#-PCMLIMIT
	mov r5,r0

	movs r2,r2,lsr#1
	addcs r0,r0,#PCMSTEP
	subcc r0,r0,#PCMSTEP
	cmp r0,#PCMLIMIT			;range check volume level
	movgt r0,#PCMLIMIT
	cmp r0,#-PCMLIMIT
	movlt r0,#-PCMLIMIT
	orr r5,r0,r5,lsr#8

	movs r2,r2,lsr#1
	addcs r0,r0,#PCMSTEP
	subcc r0,r0,#PCMSTEP
	cmp r0,#PCMLIMIT			;range check volume level
	movgt r0,#PCMLIMIT
	cmp r0,#-PCMLIMIT
	movlt r0,#-PCMLIMIT
	orr r5,r0,r5,lsr#8

	movs r2,r2,lsr#1
	addcs r0,r0,#PCMSTEP
	subcc r0,r0,#PCMSTEP
	cmp r0,#PCMLIMIT			;range check volume level
	movgt r0,#PCMLIMIT
	cmp r0,#-PCMLIMIT
	movlt r0,#-PCMLIMIT
	orr r5,r0,r5,lsr#8
	str r5,[r12],#4

	b endmix
;----------------------------------------------------------------------------



 AREA rom_code, CODE, READONLY ;-- - - - - - - - - - - - - - - - - - - - - -

;----------------------------------------------------------------------------
Sound_reset
;----------------------------------------------------------------------------
	mov r1,#REG_BASE

	ldrh r0,[r1,#REG_SGBIAS]
	bic r0,r0,#0xc000			;just change bits we know about.
	orr r0,r0,#0x8000			;PWM 7-bit 131.072kHz
	strh r0,[r1,#REG_SGBIAS]

	ldr r0,=0xb00a0077			;stop all channels, output ratio=full range.  use directsound B, timer 0
	str r0,[r1,#REG_SGCNT_L]

	mov r0,#0x80
	strh r0,[r1,#REG_SGCNT_X]	;sound master enable

	mov r0,#0x08
	strh r0,[r1,#REG_SG1CNT_L]	;square0 sweep off
	str r0,sweepctrl
	ldr r0,=0x10001010
	str r0,soundctrl			;volume=0
	mov r0,#0xffffff00
	str r0,soundmask
								;triangle reset
	mov r0,#0x0040				;write to waveform bank 0
	strh r0,[r1,#REG_SG3CNT_L]
	adr r6,trianglewav			;init triangle waveform
	ldmia r6,{r2-r5}
	add r7,r1,#REG_SGWR0_L
	stmia r7,{r2-r5}
	mov r0,#0x00000080
	str r0,[r1,#REG_SG3CNT_L]	;sound3 enable, mute, write bank 1
	mov r0,#0x8000
	strh r0,[r1,#REG_SG3CNT_X]	;sound3 init

	strh r1,[r1,#REG_DM2CNT_H]	;DMA2 stop
	add r0,r1,#REG_FIFO_B_L		;DMA2 destination..
	str r0,[r1,#REG_DM2DAD]
	ldr r0,=PCMWAV
	str r0,[r1,#REG_DM2SAD]		;dmasrc=..
	ldr r0,=0xB640				;noIRQ fifo 32bit repeat incsrc fixeddst
	strh r0,[r1,#REG_DM2CNT_H]	;DMA start
								;PCM reset:
	mov r0,#-1
	str r0,pcmcount
	mov r0,#0x00001000
	str r0,pcmctrl
	
	add r1,r1,#REG_TM0D		;timer 0 controls sample rate:
	mov r0,#0
	strh r0,[r1],#4
	str r0,pcmlevel

	mov r0,#-PCMWAVSIZE		;timer 1 counts samples played:
	strh r0,[r1],#2
	mov r0,#0					;disable timer 1 before enabling it again.
	strh r0,[r1]
	mov r0,#0xc4				;enable+irq+count up
	strh r0,[r1],#2

make_freq_table
	ldr r0,emuflags
	tst r0,#PALTIMING
	ldreq r2,=2400				;0x10000000/111860 NTSC
	ldrne r2,=2583				;0x10000000/103912 PAL
	ldr r12,=FREQTBL
	mov r3,#4096
	mov r1,#2048
frqloop
	mul r0,r2,r3
	subs r0,r1,r0,lsr#12
	movmi r0,#0
	subs r3,r3,#2
	strh r0,[r12,r3]
	bhi frqloop

	bx lr

trianglewav				;Remember this is 4-bit
	DCB 0x76,0x54,0x32,0x10,0x01,0x23,0x45,0x67,0x89,0xAB,0xCD,0xEF,0xFE,0xDC,0xBA,0x98
;----------------------------------------------------------------------------
timer1interrupt
;----------------------------------------------------------------------------
PCMSTEP		EQU 3<<24
PCMLIMIT	EQU 96<<24

	mov r1,#REG_BASE
	strh r1,[r1,#REG_DM2CNT_H]	;DMA stop
	mov r0,   #0xb600
	orr r0,r0,#0x0040		;noINTR fifo 32bit repeat incsrc fixeddst
	strh r0,[r1,#REG_DM2CNT_H]	;DMA go

	;update DMA buffer for PCM

	stmfd sp!,{r4-r8,lr}
	ldr r3,pcmcount			;r3=bytes remaining
	ldr r12,=PCMWAV			;r12=dma buffer
	ldr r0,pcmlevel			;r0=volume level
	mov r0,r0,lsl#24
	add r4,r12,#PCMWAVSIZE		;r4=end of buffer

	tst r3,#0x80000000		;if pcmcount<0 (pcm finished on previous interrupt)
	movne r3,#0x80000000
	bne pcm1				;finish clearing buffer

	ldr r1,pcmcurrentaddr		;r1=pcm data ptr
pcm0
	subs r3,r3,#1			;pcmcount--
	bmi pcm2
	ldrb r2,[r1],#1			;next byte..
	b pcm_mix
endmix
	cmp r12,r4
	blo pcm0
	mov r0,r0,lsr#24
	str r0,pcmlevel
	str r1,pcmcurrentaddr
	b pcmexit
pcm2			;PCM data just ran out.  what now?
	ldrb r2,pcmctrl
	tst r2,#0x40		;looping enabled?
				;yes?
	ldrne r3,pcmlength			;reload pcmcount
	ldrne r1,pcmstart			;reload pcmcurrentaddr
	bne pcm0
pcm1				;PCM has stopped.  clear remaining sound buffer.
	mov r0,#0
clpcm 	str r0,[r12],#4
	str r0,[r12],#4
	cmp r12,r4
	blo clpcm

	cmp r3,#0x80000000		;if this was the 2nd pass (entire buffer is cleared),
	bne pcmexit
	mov r1,#REG_BASE
	add r1,r1,#REG_TM0D
	mov r0,#0
	strh r0,[r1,#2]			;stop timer 0 (to reduce interrupt frequency)
	ldrb r0,pcmctrl+1
	and r0,r0,#0xef			;only clear channel 5.
	strb r0,pcmctrl+1

pcmexit
	str r3,pcmcount
	ldmfd sp!,{r4-r8,pc}
;----------------------------------------------------------------------------
_4000w
;----------------------------------------------------------------------------
	strb r0,soundctrl

	and r2,r0,#0x0f
	adr addy,enveloperates
	ldr r1,[addy,r2,lsl#2]	;lookup envelope decay rate
	str r1,sq0enveloperate

	and r0,r0,#0xc0		;duty cycle
	mov r2,#REG_BASE
	ldrh r1,[r2,#REG_SG1CNT_H]
	bic r1,r1,#0xc0
	orr r1,r1,r0
	strh r1,[r2,#REG_SG1CNT_H]

	mov pc,lr

timeouts DCB 5,127,10,1,20,2,40,3,80,4,30,5,7,6,13,7,6,8,12,9,24,10,48,11,96,12,36,13,8,14,16,15
sweeptimes DCW 0xffff,0xfffe,0xaaaa,0x8000,0x6666,0x5554,0x4924,0x4000
enveloperates DCD 0x40000000/1,0x40000000/2,0x40000000/3,0x40000000/4
 DCD 0x40000000/5,0x40000000/6,0x40000000/7,0x40000000/8
 DCD 0x40000000/9,0x40000000/10,0x40000000/11,0x40000000/12
 DCD 0x40000000/13,0x40000000/14,0x40000000/15,0x40000000/16
;----------------------------------------------------------------------------
_4001w
;----------------------------------------------------------------------------
	strb r0,sweepctrl

	mov r1,r0,lsr#3
	adr r2,sweeptimes
	and r1,r1,#0x0e
	ldrh r0,[r2,r1]
	str r0,sq0sweepnext

	mov pc,lr
;----------------------------------------------------------------------------
_4002w
;----------------------------------------------------------------------------
	mov addy,#REG_BASE
	strb r0,sq0freq
	ldr r0,sq0freq
sq0setfreq			;updatesound jumps here
	mov r0,r0,lsl#1
	ldr r1,=FREQTBL
	ldrh r0,[r1,r0]		;freq lookup

	str r0,saveSG11
	strh r0,[addy,#REG_SG1CNT_X]	;set freq

	mov pc,lr
;----------------------------------------------------------------------------
_4003w
;----------------------------------------------------------------------------
	mov r2,#-1
	str r2,sq0envelope	;reset envelope decay

	and r1,r0,#0xf8
	adr r2,timeouts
	ldrb r1,[r2,r1,lsr#3]	;timer lookup
	str r1,sq0timeout

	and r0,r0,#7
	strb r0,sq0freq+1
	ldr r0,sq0freq
	mov r0,r0,lsl#1
	ldr r1,=FREQTBL
	ldrh r0,[r1,r0]		;freq lookup

	str r0,saveSG11

	mov r2,#REG_BASE
	strh r0,[r2,#REG_SG1CNT_X]	;set freq

	ldrh r0,[r2,#REG_SGCNT_L]
	ldr r1,soundmask
	ands r1,r1,#0x1100
	orr r0,r0,r1
	strneh r0,[r2,#REG_SGCNT_L]	;turn sound back on (may have been stopped from timer or 4015)

	mov pc,lr

sq0freq	DCD 0
saveSG11 DCD 0
sq0timeout DCD 0
sq0sweepnext DCD 0
sweepctrl DCD 0
sq0envelope DCD 0
sq0enveloperate DCD 0
;----------------------------------------------------------------------------
_4004w
;----------------------------------------------------------------------------
	strb r0,soundctrl+1

	and r2,r0,#0x0f
	adr addy,enveloperates
	ldr r1,[addy,r2,lsl#2]	;lookup envelope decay rate
	str r1,sq1enveloperate

	and r0,r0,#0xc0		;duty cycle
	mov r2,#REG_BASE
	ldrh r1,[r2,#REG_SG2CNT_L]
	bic r1,r1,#0xc0
	orr r1,r1,r0
	strh r1,[r2,#REG_SG2CNT_L]

	mov pc,lr
;----------------------------------------------------------------------------
_4005w
;----------------------------------------------------------------------------
	strb r0,sweepctrl+1

	mov r1,r0,lsr#3
	adr r2,sweeptimes
	and r1,r1,#0x0e
	ldrh r0,[r2,r1]
	str r0,sq1sweepnext

	mov pc,lr
;----------------------------------------------------------------------------
_4006w
;----------------------------------------------------------------------------
	mov addy,#REG_BASE
	strb r0,sq1freq
	ldr r0,sq1freq
sq1setfreq			;updatesound jumps here
	mov r0,r0,lsl#1
	ldr r1,=FREQTBL
	ldrh r0,[r1,r0]		;freq lookup

	str r0,saveSG21
	strh r0,[addy,#REG_SG2CNT_H]	;set freq

	mov pc,lr
;----------------------------------------------------------------------------
_4007w
;----------------------------------------------------------------------------
	mov r2,#-1
	str r2,sq1envelope	;reset envelope decay

	and r1,r0,#0xf8
	adr r2,timeouts
	ldrb r1,[r2,r1,lsr#3]	;timer lookup
	str r1,sq1timeout

	and r0,r0,#7
	strb r0,sq1freq+1
	ldr r0,sq1freq
	mov r0,r0,lsl#1
	ldr r1,=FREQTBL
	ldrh r0,[r1,r0]		;freq lookup

	str r0,saveSG21

	mov r2,#REG_BASE
	strh r0,[r2,#REG_SG2CNT_H]	;set freq

	ldrh r0,[r2,#REG_SGCNT_L]
	ldr r1,soundmask
	ands r1,r1,#0x2200
	orr r0,r0,r1
	strneh r0,[r2,#REG_SGCNT_L]	;turn sound back on (may have been stopped from timer or 4015)

	mov pc,lr

sq1freq	DCD 0
saveSG21 DCD 0
sq1timeout DCD 0
sq1sweepnext DCD 0
sq1envelope DCD 0
sq1enveloperate DCD 0
;----------------------------------------------------------
_4008w
	ldrb r1,soundctrl+2
	strb r0,soundctrl+2
	tst r1,#0x80		;if timer's already started,
	moveq pc,lr		;don't touch it
_4008w2
	and r0,r0,#0xff
	cmp r0,#0x80
	moveq r0,#0		;stop sound if count=0
	movhi r0,#0x40000000	;hold timer if MSB=1
	str r0,tritimeout2

	mov pc,lr
;----------------------------------------------------------
_400aw
	strb r0,trifreq
	ldr r0,trifreq
	mov r0,r0,lsl#1
	ldr r1,=FREQTBL
	ldrh r0,[r1,r0]		;freq lookup

	mov r2,#REG_BASE
	strh r0,[r2,#REG_SG3CNT_X]

	mov pc,lr
;----------------------------------------------------------
_400bw
	and r1,r0,#0xf8
	adr r2,timeouts
	ldrb r1,[r2,r1,lsr#3]	;timer1 lookup
	str r1,tritimeout1

	and r0,r0,#7
	strb r0,trifreq+1
	ldr r0,trifreq
	mov r0,r0,lsl#1
	ldr r1,=FREQTBL
	ldrh r0,[r1,r0]		;freq lookup

	mov r2,#REG_BASE
	strh r0,[r2,#REG_SG3CNT_X]

	ldrh r0,[r2,#REG_SGCNT_L]
	ldr r1,soundmask
	ands r1,r1,#0x4400
	orr r0,r0,r1
	strneh r0,[r2,#REG_SGCNT_L]	;turn sound back on (may have been stopped from timer or 4015)

	ldrb r0,soundctrl+2		;setup timer2
	b _4008w2

trifreq DCD 0
tritimeout1 DCD 0
tritimeout2 DCD 0
;----------------------------------------------------------
_400cw
;----------------------------------------------------------
	strb r0,soundctrl+3

	and r2,r0,#0x0f
	adr addy,enveloperates
	ldr r1,[addy,r2,lsl#2]	;lookup envelope decay rate
	str r1,noiseenveloperate

	mov pc,lr
;----------------------------------------------------------
_400ew
;----------------------------------------------------------
	and r1,r0,#0x0f
	adr addy,noisefreqs
	ldrb r2,[addy,r1]

	tst r0,#0x80
	orrne r2,r2,#8

	mov addy,#REG_BASE
	str r2,saveSG41
	strh r2,[addy,#REG_SG4CNT_H]	;set freq

	mov pc,lr

noisefreqs
 DCB 2,2,2,3
 DCB 3,20,22,36
 DCB 37,39,53,55
 DCB 69,70,87,103
;----------------------------------------------------------
_400fw
;----------------------------------------------------------
	mov r2,#-1
	str r2,noiseenvelope	;reset envelope decay

	and r1,r0,#0xf8
	adr r2,timeouts
	ldrb r1,[r2,r1,lsr#3]	;timer lookup
	str r1,noisetimeout

	mov r2,#REG_BASE
	ldrh r0,[r2,#REG_SGCNT_L]
	ldr r1,soundmask
	ands r1,r1,#0x8800
	orr r0,r0,r1
	strneh r0,[r2,#REG_SGCNT_L]	;turn sound back on (may have been stopped from timer or 4015)

	mov pc,lr

noisetimeout DCD 0
noiseenvelope DCD 0
noiseenveloperate DCD 0
saveSG41 DCD 0
;----------------------------------------------------------
_4010w
;----------------------------------------------------------
	strb r0,pcmctrl		;bit7=irq enable, bit 6=loop enable, bits 0-3=freq

	and r0,r0,#0x0f
	adr r1,pcmfreq
	add r0,r0,r0
	ldrh r2,[r1,r0]		;lookup PCM freq..
	mov r0,#REG_BASE
	mov r1,#REG_TM0D
	strh r2,[r0,r1]		;set timer0 rate

	mov pc,lr
;----------------------------------------------------------
_4011w	;Delta Counter load register
;----------------------------------------------------------
	add r0,r0,r0
	and r0,r0,#0xfe
	sub r0,r0,#0x80		;GBA has -128 -> +127
	str r0,pcmlevel		;Start level for PCM

;	orr r0,r0,r0,lsl#8
;	orr r0,r0,r0,lsl#16
;	mov r1,#REG_BASE
;	str r0,[r1,#REG_FIFO_B_L]		;Set DA value... doesn't work  :(

	mov pc,lr
;----------------------------------------------------------
_4012w	;returns pcmstart
;----------------------------------------------------------
	strb r0,pcmctrl+2	;pcm start addr

	and r1,r0,#0xff
	mov r0,#0xc000
	orr r0,r0,r1,lsl#6	;pcm start addr=$C000+x*64
	adr r2,memmap_tbl
	mov r1,r0,lsr#13
	ldr r1,[r2,r1,lsl#2]	;lookup rom ptr..
	add r0,r0,r1
	str r0,pcmstart

	mov pc,lr
;----------------------------------------------------------
_4013w	;returns pcmlength
;----------------------------------------------------------
	strb r0,pcmctrl+3

	and r0,r0,#0xff
	mov r0,r0,lsl#4
	add r0,r0,#1		;pcm length(bytes)=1+x*16
	str r0,pcmlength

	mov pc,lr

pcmctrl DCD 0		;bit7=irqen, bit6=loop.  bit 12=PCM enable (from $4015). bits 8-15=old $4015
pcmlength DCD 0		;total bytes
pcmcount DCD 0		;bytes remaining
pcmstart DCD 0		;starting addr
pcmcurrentaddr DCD 0	;current addr
pcmlevel DCD 0

;  (GBA CPU / NES CPU*8)*cycles
;-(16777216/14318180)*N
pcmfreq DCW 0xf054 ;N=3424
	DCW 0xf216 ;3040
	DCW 0xf38d ;2720
	DCW 0xf449 ;2560
	DCW 0xf588 ;2288
	DCW 0xf6b4 ;2032
	DCW 0xf7ba ;1808
	DCW 0xf82a ;1712
	DCW 0xf90b ;1520
	DCW 0xfa25 ;1280
	DCW 0xfacd ;1136
	DCW 0xfb51 ;1024
	DCW 0xfc1f ;848
	DCW 0xfce4 ;680
	DCW 0xfd5e ;576
	DCW 0xfe06 ;432

pcmcpuN	DCW 3424		;NTSC
	DCW 3040
	DCW 2720
	DCW 2560
	DCW 2288
	DCW 2032
	DCW 1808
	DCW 1712
	DCW 1520
	DCW 1280
	DCW 1136
	DCW 1024
	DCW 848
	DCW 680		;680
	DCW 576		;576
	DCW 432		;432

;pcmcpuP	DCW 3424*3		;PAL
;	DCW 3040*3
;	DCW 2720*3
;	DCW 2560*3
;	DCW 2288*3
;	DCW 2032*3
;	DCW 1808*3
;	DCW 1712*3
;	DCW 1520*3
;	DCW 1280*3
;	DCW 1136*3
;	DCW 1024*3
;	DCW 848*3
;	DCW 536*3		;680
;	DCW 302*3		;576
;	DCW 360*3		;432

;----------------------------------------------------------------------------
_4015w
;----------------------------------------------------------------------------
	stmfd sp!,{r3,lr}
	mov addy,#REG_BASE
				;channel 5 (PCM):
	ldr r3,pcmctrl
	and r0,r0,#0x1f		;only write channel 1-5
	strb r0,pcmctrl+1

	tst r0,#0x10			;PCM stop? 0x10
	moveq r1,#-1
	streq r1,pcmcount
	beq asdf
					;PCM restart? (0->1)
	tst r3,#0x1000
	bne asdf

	mov r0,r3,lsr#16
	bl _4012w
	str r0,pcmcurrentaddr

	mov r0,r3,lsr#24
	bl _4013w
	str r0,pcmcount
	cmp r0,#50			;if the sample is less then 50 bytes it's not a sound.

	addpl r1,addy,#REG_TM0D
	movpl r2,#0x80
	strplh r2,[r1,#2]		;timer 0 on

;--------------------------
; for pcm IRQ
;--------------------------
	and r0,r3,#0x0f
	adr r1,pcmcpuN
	add r0,r0,r0
	ldrh r2,[r1,r0]		;lookup PCM/CPU cycles ..
	ldr r0,pcmlength
	sub r2,r2,#6		;DMA steals 6PPU/2CPU cycle every fetch
	mul r1,r0,r2
;	sub r1,r1,#113
	str r1,pcmirqcount
	str r1,pcmirqbakup

;--------------------------

	ldrb r0,pcmctrl+1
asdf				;channels 1-4:
	ldrh r1,[addy,#REG_SGCNT_L]

	and r0,r0,#0x0f
	orr r0,r0,r0,lsl#4
	mov r0,r0,lsl#8
	str r0,soundmask

	and r1,r1,r0		;stop square1,square2,triangle,noise
	orr r1,r1,#0x77		;(max vol)
	strh r1,[addy,#REG_SGCNT_L]

	ldmfd sp!,{r3,pc}

soundmask DCD 0		;mask for SGCNT_L
;----------------------------------------------------------------------------
_4015r
;----------------------------------------------------------------------------
	mov r2,#REG_BASE
	ldrh r0,[r2,#REG_SGCNT_L]
	ldrb r1,pcmctrl+1
	and r1,r1,#0x90		;only read channel 5 and pcm IRQ
	orr r0,r1,r0,lsr#12

	mov pc,lr
;----------------------------------------------------------------------------
updatesound	;called from line 0..  r0-r9 are free to use
;----------------------------------------------------------------------------
	mov r9,lr
	mov addy,#REG_BASE

	ldr r4,soundctrl	;process all timers:
	ldrh r2,[addy,#REG_SGCNT_L]
					;square1:
	tst r4,#0x20
	bne us0
	ldr r0,sq0timeout
	subs r0,r0,#1
	str r0,sq0timeout
	bicmi r2,r2,#0x1100
us0					;square2:
	tst r4,#0x2000
	bne us11
	ldr r0,sq1timeout
	subs r0,r0,#1
	str r0,sq1timeout
	bicmi r2,r2,#0x2200
us11					;noise:
	tst r4,#0x20000000
	bne us6
	ldr r0,noisetimeout
	subs r0,r0,#1
	str r0,noisetimeout
	bicmi r2,r2,#0x8800
us6					;tri(1):
	tst r4,#0x800000
	bne us1
	ldr r0,tritimeout1
	subs r0,r0,#1
	str r0,tritimeout1
	bicmi r2,r2,#0x4400
us1
	ldr r0,tritimeout2		;tri(2):
	subs r0,r0,#4
	str r0,tritimeout2
	movmi r0,#0x0000		;Mute
	movpl r0,#0x2000		;Full
	strh r0,[addy,#REG_SG3CNT_H]

	strh r2,[addy,#REG_SGCNT_L]
				;square1 freq sweep:
	ldrb r2,sweepctrl
	tst r2,#0x80			;sweep enabled?
	beq us7

	ldr r3,sq0sweepnext
	adds r3,r3,r3,lsl#16
	str r3,sq0sweepnext
	bcc us7				;next step?

	ands r1,r2,#7			;r1=freq shift amt
	beq us7				;no sweep if shift=0
	ldr r0,sq0freq
us3	tst r2,#0x08			;0=up 1=down
	addeq r0,r0,r0,lsr r1
	subne r0,r0,r0,lsr r1
	cmp r0,#0x800
	movhs r0,#0			;freq out of range?
		movs r3,r3,lsl#31		;(now some stupid bit twiddling)
		bne us3				;if MSB=1, do 2 sweep steps (fastest sweep is twice per frame)
	str r0,sq0freq
	bl sq0setfreq
us7				;square2 freq sweep:
	ldrb r2,sweepctrl+1
	tst r2,#0x80			;sweep enabled?
	beq us2

	ldr r3,sq1sweepnext
	adds r3,r3,r3,lsl#16
	str r3,sq1sweepnext
	bcc us2				;next step?

	ands r1,r2,#7			;r1=freq shift amt
	beq us2				;no sweep if shift=0
	ldr r0,sq1freq
us8	tst r2,#0x08			;0=up 1=down
	addeq r0,r0,r0,lsr r1
	subne r0,r0,r0,lsr r1
	subne r0,r0,#1
	cmp r0,#0x800
	movhs r0,#0			;freq out of range?
		movs r3,r3,lsl#31		;(now some stupid bit twiddling)
		bne us8				;if MSB=1, do 2 sweep steps (fastest sweep is twice per frame)
	str r0,sq1freq
	bl sq1setfreq
us2				;square1 envelope:
	ldr r0,sq0envelope
	ldr r1,sq0enveloperate
	subs r0,r0,r1
	bcs us5				;looping?
	tst r4,#0x20			;loop ok?
	moveq r0,#0			;no envelope loop =(
us5
	str r0,sq0envelope
	tst r4,#0x10			;use set volume or envelope decay?
	moveq r0,r0,lsr#28
	andne r0,r4,#0x0f

	ldrh r1,[addy,#REG_SG1CNT_H]	;get old volume
	cmp r0,r1,lsr#12		;old=new?
	beq us4

	bic r1,r1,#0xf000
	orr r1,r1,r0,lsl#12
	strh r1,[addy,#REG_SG1CNT_H]	;set new volume
	ldr r0,saveSG11
	orr r0,r0,#0x8000		;init
	strh r0,[addy,#REG_SG1CNT_X]
us4				;square2 envelope:
	ldr r0,sq1envelope
	ldr r1,sq1enveloperate
	subs r0,r0,r1
	bcs us10			;looping?
	tst r4,#0x2000			;loop ok?
	moveq r0,#0			;no envelope loop =(
us10
	str r0,sq1envelope
	tst r4,#0x1000			;use set volume or envelope decay?
	moveq r0,r0,lsr#28
	andne r0,r4,#0x0f00
	movne r0,r0,lsr#8

	ldrh r1,[addy,#REG_SG2CNT_L]	;get old volume
	cmp r0,r1,lsr#12		;old=new?
	beq us9

	bic r1,r1,#0xf000
	orr r1,r1,r0,lsl#12
	strh r1,[addy,#REG_SG2CNT_L]	;set new volume
	ldr r0,saveSG21
	orr r0,r0,#0x8000		;init
	strh r0,[addy,#REG_SG2CNT_H]
us9				;noise envelope:
	ldr r0,noiseenvelope
	ldr r1,noiseenveloperate
	subs r0,r0,r1
	bcs us12			;looping?
	tst r4,#0x20000000		;loop ok?
	moveq r0,#0			;no envelope loop =(
us12
	str r0,noiseenvelope
	tst r4,#0x10000000		;use set volume or envelope decay?
	moveq r0,r0,lsr#29			;half volume.. noise tends to be loud on GBA
	andne r0,r4,#0x0f000000
	movne r0,r0,lsr#25

	ldrh r1,[addy,#REG_SG4CNT_L]	;get old volume
	cmp r0,r1,lsr#12		;old=new?
	beq us13

	bic r1,r1,#0xf000
	orr r1,r1,r0,lsl#12
	strh r1,[addy,#REG_SG4CNT_L]	;set new volume
	ldr r0,saveSG41
	orr r0,r0,#0x8000
	strh r0,[addy,#REG_SG4CNT_H]	;init
us13
	mov pc,r9

soundctrl DCD 0		;1st control reg for ch1-4
;----------------------------------------------------------------------------
	END
