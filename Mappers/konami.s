	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h
	INCLUDE 6502.h
	INCLUDE 6502mac.h

	EXPORT Konami_Init
	EXPORT Konami_IRQ_Hook
	EXPORT KoLatch
	EXPORT KoLatchLo
	EXPORT KoLatchHi
	EXPORT KoCounter
	EXPORT KoIRQen

latch EQU mapperdata+0
irqen EQU mapperdata+1
k4irq EQU mapperdata+2
counter EQU mapperdata+3


;-------------------------------------------------------
Konami_Init
	ldr r0,=Konami_IRQ_Hook
	str r0,scanlinehook
	mov pc,lr
;-------------------------------------------------------
KoLatch ;- - - - - - - - - - - - - - -
	strb r0,latch
	mov pc,lr
KoLatchLo ;- - - - - - - - - - - - - - -
	and r2,r2,#0xf0
	and r0,r0,#0x0f
	orr r0,r0,r2
	strb r0,latch
	mov pc,lr
KoLatchHi ;- - - - - - - - - - - - - - -
	and r2,r2,#0x0f
	orr r0,r2,r0,lsl#4
	strb r0,latch
	mov pc,lr
KoCounter ;- - - - - - - - - - - - - - -
	ands r1,r0,#2
	and r0,r0,#1
	strb r0,k4irq
	strb r1,irqen
	ldrneb r0,latch
	strneb r0,counter
	mov pc,lr
KoIRQen ;- - - - - - - - - - - - - - -
	ldrb r0,k4irq
	orr r0,r0,r0,lsl#1
	strb r0,irqen
	mov pc,lr
;-------------------------------------------------------
	AREA wram_code3, CODE, READWRITE
Konami_IRQ_Hook
;------------------------------------------------------
	ldr r0,latch
	tst r0,#0x200	;timer active?
	beq h1

	adds r0,r0,#0x01000000	;counter++
	bcc h0

	strb r0,counter	;copy latch to counter
	b irq6502
h0
	str r0,latch
h1
	fetch 0
;-------------------------------------------------------
	END
