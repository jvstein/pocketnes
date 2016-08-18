	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h

	EXPORT mapper1init

reg0 EQU mapperdata+0
reg1 EQU mapperdata+1
reg2 EQU mapperdata+2
reg3 EQU mapperdata+3
latch EQU mapperdata+4
latchbit EQU mapperdata+5
;----------------------------------------------------------------------------
mapper1init
;----------------------------------------------------------------------------
	DCD write0,write1,write2,write3

	mov r0,#0x0c	;init MMC1 regs
	strb r0,reg0
	mov r0,#0x10
	strb r0,reg1
	strb r0,reg2
;	mov r0,#0x00
;	strb r0,reg3
reset
	mov r0,#0
	strb r0,latch
	strb r0,latchbit

	ldrb r0,reg0
	orr r0,r0,#0x0c
	strb r0,reg0

	b promswitch
;----------------------------------------------------------------------------
	AREA wram_code3, CODE, READWRITE
;----------------------------------------------------------------------------
write0		;($8000-$9FFF)
;----------------------------------------------------------------------------
	adr addy,w0
writelatch ;-----
	tst r0,#0x80
	bne reset

	ldrb r2,latchbit
	ldrb r1,latch
	and r0,r0,#1
	orr r0,r1,r0,lsl r2

	cmp r2,#4
	mov r1,#0
	moveq pc,addy

	add r2,r2,#1
	strb r2,latchbit
	strb r0,latch
	mov pc,lr
w0;----
	strb r1,latch
	strb r1,latchbit
	strb r0,reg0

	mov addy,lr
	tst r0,#0x02
	bne w01

	tst r0,#0x01
	bl mirror1_
	mov lr,addy
	b vromswitch
w01
	tst r0,#0x01
	bl mirror2V_
	mov lr,addy
	b vromswitch
;----------------------------------------------------------------------------
write1		;($A000-$BFFF)
;----------------------------------------------------------------------------
	adr addy,w1
	b writelatch
w1	strb r1,latch
	strb r1,latchbit
	strb r0,reg1
    ;----
	b vromswitch
;----------------------------------------------------------------------------
write2		;($C000-$DFFF)
;----------------------------------------------------------------------------
	adr addy,w2
	b writelatch
w2	strb r1,latch
	strb r1,latchbit
	strb r0,reg2
    ;----
;----------------------------------------------------------------------------
vromswitch;
;----------------------------------------------------------------------------
	ldr r1,vrommask
	tst r1,#0x80000000
	bne promswitch

	ldrb r0,reg1
	mov addy,lr
	ldrb r1,reg0
	tst r1,#0x10
	bne w11

	mov r0,r0,lsr#1
	bl chr01234567_
	mov lr,addy
	b promswitch
w11
	bl chr0123_
	ldrb r0,reg2
	bl chr4567_
	mov lr,addy
	b promswitch
;----------------------------------------------------------------------------
write3		;($E000-$FFFF)
;----------------------------------------------------------------------------
	adr addy,w3
	b writelatch
w3	and r0,r0,#0x0f
	strb r1,latch
	strb r1,latchbit
	strb r0,reg3
;----------------------------------------------------------------------------
promswitch;
;----------------------------------------------------------------------------
	ldrb r0,reg1
	ldrb r1,reg3
	and r0,r0,#0x10
	orr r0,r0,r1

	ldrb r1,reg0
	tst r1,#0x08
	beq rs1
				;switch 16k:
	str lr,[sp,#-4]!
	mov addy,r0
	tst r1,#0x04
	beq rs0

	bl map89AB_	;map low bank
	orr r0,addy,#0x0f
	ldr lr,[sp],#4
	b mapCDEF_	;hardwired high bank
rs0
	bl mapCDEF_	;map high bank
	and r0,addy,#0x10
	ldr lr,[sp],#4
	b map89AB_	;hardwired low bank
rs1				;switch 32k:
	mov r0,r0,lsr#1
	b map89ABCDEF_
;----------------------------------------------------------------------------
	END
