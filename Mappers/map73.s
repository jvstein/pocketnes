	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h
	INCLUDE 6502.h
	INCLUDE 6502mac.h

	EXPORT mapper73init

counter EQU mapperdata
irqen EQU mapperdata+4
;----------------------------------------------------------------------------
mapper73init	;Konami Salamander (J)...
;----------------------------------------------------------------------------
	DCD write8000,writeA000,writeC000,writeE000

	adr r0,hook
	str r0,scanlinehook

	mov pc,lr
;-------------------------------------------------------
write8000
;-------------------------------------------------------
	ldr r2,counter
	and r0,r0,#0xF
	tst addy,#0x1000
	bne write9000
	bic r2,r2,#0xF0000
	orr r0,r2,r0,lsl#16
	str r0,counter
	mov pc,lr
write9000
	bic r2,r2,#0xF00000
	orr r0,r2,r0,lsl#20
	str r0,counter
	mov pc,lr

;-------------------------------------------------------
writeA000
;-------------------------------------------------------
	ldr r2,counter
	and r0,r0,#0xF
	tst addy,#0x1000
	bne writeB000
	bic r2,r2,#0xF000000
	orr r0,r2,r0,lsl#24
	str r0,counter
	mov pc,lr
writeB000
	bic r2,r2,#0xF0000000
	orr r0,r2,r0,lsl#28
	str r0,counter
	mov pc,lr

;-------------------------------------------------------
writeC000
;-------------------------------------------------------
	tst addy,#0x1000
	andeq r0,r0,#2
	streqb r0,irqen
	mov pc,lr

;-------------------------------------------------------
writeE000
;-------------------------------------------------------
	tst addy,#0x1000
	bne map89AB_
	mov pc,lr
;-------------------------------------------------------
hook
;------------------------------------------------------
	ldrb r0,irqen
	cmp r0,#0	;timer active?
	beq h1

	ldr r0,counter
;	adds r0,r0,#0x71aaab		;113.66667
	adds r0,r0,#0x720000
	bcc h0
	mov r0,#0
	strb r0,irqen
	sub r0,r0,#0x10000
	str r0,counter
	b irq6502
h0
	str r0,counter
h1
	fetch 0
;-------------------------------------------------------
	END
