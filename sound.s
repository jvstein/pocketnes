	INCLUDE equates.h
	INCLUDE ppu.h

	EXPORT timer1interrupt
	EXPORT sound_reset_
	EXPORT updatesound
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
 AREA rom_code, CODE, READONLY ;-- - - - - - - - - - - - - - - - - - - - - -

freqtbl
	INCLUDE freqtbl.h
;----------------------------------------------------------------------------
sound_reset_
;----------------------------------------------------------------------------
	mov r1,#REG_BASE
	mov r0,#0x00020000		;stop all channels, output ratio=full range
	str r0,[r1,#REG_SGCNT0_L]

;	ldrh r0,[r1,#REG_SGBIAS]
;	bic r0,r0,#0xc000
;	orr r0,r0,#0x?000
;	strh r0,[r1,#REG_SGBIAS]

	mov r0,#0x80
	strh r0,[r1,#REG_SGCNT1]	;sound master enable
				;reset NES sound channels
	mov r0,#0x08
	strh r0,[r1,#REG_SG10_L]	;sweep off
	str r0,sweepctrl
	ldr r0,=0x10001010
	str r0,soundctrl		;volume=0
	mov r0,#0xffffff00
	str r0,soundmask
				;triangle reset
	mov r0,#0x0040			;waveform bank 0 select
	strh r0,[r1,#REG_SG30_L]
	adr r6,trianglewav		;init triangle waveform
	ldmia r6,{r2-r5}
	add r7,r1,#REG_SGWR0_L
	stmia r7,{r2-r5}
	ldr r0,=0x00000080
	str r0,[r1,#REG_SG30_L]		;sound3 enable, mute
	mov r0,#0x8000
	strh r0,[r1,#REG_SG31]		;sound3 init

;	strh r1,[r1,#REG_DM2CNT_H]	;DMA stop
;	add r0,r1,#REG_SGFIFOB_L	;DMA2 goes here
;	str r0,[r1,#REG_DM2DAD]
;	ldr r0,=PCMWAV
;	str r0,[r1,#REG_DM2SAD]		;dmasrc=..
;	ldr r0,=0xB640			;noIRQ fifo 32bit repeat incsrc fixeddst
;	strh r0,[r1,#REG_DM2CNT_H]	;DMA go

;	add r1,r1,#REG_TM0D
;	ldr r0,=0x0000		;timer 0 controls sample rate:
;	strh r0,[r1],#2
;	mov r0,#0x80			;enable
;	strh r0,[r1],#2
;	mov r0,#-PCMSAMPLES	;timer 1 counts samples played:
;	strh r0,[r1],#2
;	mov r0,#0xc4			;enable+irq+count up
;	strh r0,[r1],#2

	mov pc,lr

trianglewav
	DCB 0x76,0x54,0x32,0x10,0x01,0x23,0x45,0x67,0x89,0xAB,0xCD,0xEF,0xFE,0xDC,0xBA,0x98
;----------------------------------------------------------------------------
timer1interrupt
;----------------------------------------------------------------------------
	strh r0,[r2,#2]		;IF clear

;	mov r1,#REG_BASE
;	strh r1,[r1,#REG_DM2CNT_H]	;DMA stop
;	mov r0,   #0xb600
;	orr r0,r0,#0x0040			;noINTR fifo 32bit repeat incsrc fixeddst
;	strh r0,[r1,#REG_DM2CNT_H]	;DMA go

;	prep DMA buffer..

	bx lr
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
	ldrh r1,[r2,#REG_SG10_H]
	bic r1,r1,#0xc0
	orr r1,r1,r0
	strh r1,[r2,#REG_SG10_H]

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
	ldr r1,=freqtbl
	ldrh r0,[r1,r0]		;freq lookup

	str r0,saveSG11
	strh r0,[addy,#REG_SG11]	;set freq

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
	ldr r1,=freqtbl
	ldrh r0,[r1,r0]		;freq lookup

	str r0,saveSG11

	mov r2,#REG_BASE
	strh r0,[r2,#REG_SG11]	;set freq

	ldrh r0,[r2,#REG_SGCNT0_L]
	ldr r1,soundmask
	ands r1,r1,#0x1100
	orr r0,r0,r1
	strneh r0,[r2,#REG_SGCNT0_L]	;turn sound back on (may have been stopped from timer or 4015)

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
	ldrh r1,[r2,#REG_SG20]
	bic r1,r1,#0xc0
	orr r1,r1,r0
	strh r1,[r2,#REG_SG20]

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
	ldr r1,=freqtbl
	ldrh r0,[r1,r0]		;freq lookup

	str r0,saveSG21
	strh r0,[addy,#REG_SG21]	;set freq

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
	ldr r1,=freqtbl
	ldrh r0,[r1,r0]		;freq lookup

	str r0,saveSG21

	mov r2,#REG_BASE
	strh r0,[r2,#REG_SG21]	;set freq

	ldrh r0,[r2,#REG_SGCNT0_L]
	ldr r1,soundmask
	ands r1,r1,#0x2200
	orr r0,r0,r1
	strneh r0,[r2,#REG_SGCNT0_L]	;turn sound back on (may have been stopped from timer or 4015)

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
	ldr r1,=freqtbl
	ldrh r0,[r1,r0]		;freq lookup

	mov r2,#REG_BASE
	strh r0,[r2,#REG_SG31]

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
	ldr r1,=freqtbl
	ldrh r0,[r1,r0]		;freq lookup

	mov r2,#REG_BASE
	strh r0,[r2,#REG_SG31]

	ldrh r0,[r2,#REG_SGCNT0_L]
	ldr r1,soundmask
	ands r1,r1,#0x4400
	orr r0,r0,r1
	strneh r0,[r2,#REG_SGCNT0_L]	;turn sound back on (may have been stopped from timer or 4015)

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
	strh r2,[addy,#REG_SG41]	;set freq

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
	ldrh r0,[r2,#REG_SGCNT0_L]
	ldr r1,soundmask
	ands r1,r1,#0x8800
	orr r0,r0,r1
	strneh r0,[r2,#REG_SGCNT0_L]	;turn sound back on (may have been stopped from timer or 4015)

	mov pc,lr

noisetimeout DCD 0
noiseenvelope DCD 0
noiseenveloperate DCD 0
saveSG41 DCD 0
;----------------------------------------------------------
_4010w
_4011w
_4012w
_4013w
	mov pc,lr
;----------------------------------------------------------------------------
_4015w
;----------------------------------------------------------------------------
	mov addy,#REG_BASE

	ldrh r1,[addy,#REG_SGCNT0_L]

	and r0,r0,#0x0f
	orr r0,r0,r0,lsl#4
	mov r0,r0,lsl#8
	str r0,soundmask

	and r1,r1,r0		;stop square1,square2,triangle,noise
	orr r1,r1,#0x77			;(max vol)
	strh r1,[addy,#REG_SGCNT0_L]

	mov pc,lr

soundmask DCD 0		;mask for SGCNT0_L
;----------------------------------------------------------------------------
_4015r
;----------------------------------------------------------------------------
	mov r2,#REG_BASE
	ldrh r0,[r2,#REG_SGCNT0_L]
	mov r0,r0,lsr#12

	mov pc,lr
;----------------------------------------------------------------------------
updatesound	;called from line 0..  r0-r9 are free to use
;----------------------------------------------------------------------------
	mov r9,lr
	mov addy,#REG_BASE

	ldr r4,soundctrl	;process all timers:
	ldrh r2,[addy,#REG_SGCNT0_L]
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
	movmi r0,#0
	movpl r0,#0x2000
	strh r0,[addy,#REG_SG30_H]

	strh r2,[addy,#REG_SGCNT0_L]
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

	ldrh r1,[addy,#REG_SG10_H]	;get old volume
	cmp r0,r1,lsr#12		;old=new?
	beq us4

	bic r1,r1,#0xf000
	orr r1,r1,r0,lsl#12
	strh r1,[addy,#REG_SG10_H]	;set new volume
	ldr r0,saveSG11
	orr r0,r0,#0x8000		;init
	strh r0,[addy,#REG_SG11]
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

	ldrh r1,[addy,#REG_SG20]	;get old volume
	cmp r0,r1,lsr#12		;old=new?
	beq us9

	bic r1,r1,#0xf000
	orr r1,r1,r0,lsl#12
	strh r1,[addy,#REG_SG20]	;set new volume
	ldr r0,saveSG21
	orr r0,r0,#0x8000		;init
	strh r0,[addy,#REG_SG21]
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

	ldrh r1,[addy,#REG_SG40]	;get old volume
	cmp r0,r1,lsr#12		;old=new?
	beq us13

	bic r1,r1,#0xf000
	orr r1,r1,r0,lsl#12
	strh r1,[addy,#REG_SG40]	;set new volume
	ldr r0,saveSG41
	orr r0,r0,#0x8000
	strh r0,[addy,#REG_SG41]	;init
us13
	mov pc,r9

soundctrl DCD 0		;1st control reg for ch1-4
;----------------------------------------------------------------------------
	END
