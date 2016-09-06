	AREA entry, CODE, READONLY
	ENTRY
;----------------------------------------------------------
__main
;----------------------------------------------------------
	b %F0
	nop			;multiboot header?
0
	adr r0,lz77data
	mov r1,#0x3000000
	orr sp,r1,#0x7f00
	swi 0x110000		;unpack everything into IWRAM
	mov r1,#0x3000000
	bx r1
;--------------------------
lz77data
         INCBIN gbabin\lz77.bin
	END
