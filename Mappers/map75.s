	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h

	EXPORT mapper75init

map75ar EQU mapperdata
map75sel EQU mapperdata+2
;----------------------------------------------------------------------------
mapper75init		; Konami/Jaleco
;----------------------------------------------------------------------------
	DCD write8000,writeA000,writeC000,writeE000

	mov pc,lr
;-------------------------------------------------------
write8000
;-------------------------------------------------------
	tst addy,#0x1000
	beq map89_

write9000
	strb r0,map75sel
	mov addy,r0
	stmfd sp!,{lr}
	tst r0,#1
	bl mirror2V_
	ldrb r1,map75ar
	and r0,addy,#2
	orr r0,r1,r0,lsl#3
	bl chr0123_

	ldmfd sp!,{lr}
	ldrb r1,map75ar+1
	and r0,addy,#4
	orr r0,r1,r0,lsl#2
	b chr4567_

;-------------------------------------------------------
writeA000
;-------------------------------------------------------
	tst addy,#0x1000
	beq mapAB_

writeB000
	mov pc,lr

;-------------------------------------------------------
writeC000
;-------------------------------------------------------
	tst addy,#0x1000
	beq mapCD_

writeD000
	mov pc,lr

;-------------------------------------------------------
writeE000
;-------------------------------------------------------
	and r0,r0,#0xF
	ldrb r1,map75sel
	tst addy,#0x1000
	bne writeF000
	strb r0,map75ar
	and r1,r1,#2
	orr r0,r0,r1,lsl#3
	b chr0123_

writeF000
	strb r0,map75ar+1
	and r1,r1,#4
	orr r0,r0,r1,lsl#2
	b chr4567_

	mov pc,lr
;-------------------------------------------------------
	END
