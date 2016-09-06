	AREA entrypoint, CODE, READONLY
	ENTRY

	IMPORT AGBmain
	IMPORT serialinterrupt

	EXPORT __16__rt_sdiv
	EXPORT __call_via_r6
;----------------------------------------------------------
;0x3000000 (entry point) decompressor jumps here
;----------------------------------------------------------
	adr r2,interrupt
	str r2,[sp,#0xfc]
	ldr lr,=AGBmain
	bx lr
;----------------------------------------------------------
interrupt
;----------------------------------------------------------
	mov r2,#0x4000000
	ldr r1,[r2,#0x200]!
	and r1,r1,r1,lsr#16	;r1=IE&IF
	strh r1,[r2,#2]		;IF clear

	;tst r1,#0x80
	;ldrne r2,=serialinterrupt
	;tsteq r1,#0x10
	;ldrne r2,=timer1interrupt
	;bxeq lr
	;bx r2

	ldr r2,=serialinterrupt
	bx r2
;----------------------------------------------------------
	CODE16

__call_via_r6		bx r6
__16__rt_sdiv		swi 0x07
			bx lr
;----------------------------------------------------------
	END