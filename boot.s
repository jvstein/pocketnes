	AREA rom_code, CODE, READONLY
	ENTRY

	INCLUDE equates.h

	IMPORT |Image$$RO$$Base|
	IMPORT |Image$$RO$$Limit|
	IMPORT |Image$$RW$$Base|
	IMPORT |Image$$RW$$Limit|
	IMPORT |Image$$ZI$$Base|
	IMPORT |Image$$ZI$$Limit|
 [ BUILD = "ARMDEBUG"
	IMPORT |zzzzz$$Base|
 ]

	IMPORT C_entry	;from main.c
	IMPORT textstart

	EXPORT font
	EXPORT fontpal
;------------------------------------------------------------
 	b __main

	% 156			;logo
	DCB "PocketNES   "	;title
	DCB "PNES"		;gamecode
	DCW 0			;maker
	DCB 0x96		;?
	DCB 0			;unit code
	DCB 0			;device type
	DCB 0,0,0,0,0,0,0	;unused
	DCB 0			;version
	DCB 0			;complement check
	DCW 0			;checksum
	% 32			;multiboot header
;----------------------------------------------------------
__main
;----------------------------------------------------------
	[ BUILD = "ARMDEBUG"
		mov r0, #0x10	;usr mode
		msr cpsr_f, r0
	]

	ldr	sp,=0x3007f00
	LDR	r5,=|Image$$RO$$Limit| ;r5=pointer to IWRAM code

	ldr r4,=textstart		;textstart=ptr to NES rom info
	ldr r0,=|Image$$RO$$Limit|
 [ BUILD = "ARMDEBUG"
	ldr r1,=|zzzzz$$Base|
 |
	ldr r1,=|Image$$RW$$Limit|
 ]
	add r1,r1,r0
	sub r6,r1,#0x3000000		;r6=textstart

	adr lr,_3
	tst lr,#0x8000000
	beq _3				;running from cart?
		add r6,r6,#0x6000000		;textstart=8xxxxxx
		add r5,r5,#0x6000000		;RW code ptr=8xxxxxx

		ldr r1,=|Image$$RO$$Base|	;copy rom code to exram
		add r0,r1,#0x6000000
		ldr r3,=|Image$$RO$$Limit|
_2		cmp r1,r3
		ldrcc r2, [r0], #4
		strcc r2, [r1], #4
		bcc _2
		sub pc,lr,#0x6000000	;jump to exram copy
_3
	LDR	r1, =|Image$$RW$$Base|
	LDR	r3, =|Image$$ZI$$Base| ; Zero init base => top of initialized data
_0	CMP	r1, r3
	LDRCC	r2, [r5], #4		;copy RW code to IWRAM
	STRCC	r2, [r1], #4
	BCC	_0
	LDR	r1, =|Image$$ZI$$Limit| ; Top of zero init segment
	MOV	r2, #0
_1	CMP	r3, r1 ; Zero init
	STRCC	r2, [r3], #4
	BCC	_1

 [ DEBUG
	ldr r0,=NES_RAM
	cmp r1,r0
iwramcodeistoobigsodonteventry bhi iwramcodeistoobigsodonteventry
 ]
	str r6,[r4]		;textstart

	b C_entry
;----------------------------------------------------------
font
	INCBIN font.bin
fontpal
	INCBIN fontpal.bin
	END
