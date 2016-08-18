	INCLUDE equates.h

 AREA rom_code5, CODE, READONLY
cheat_test
	b_long cheat_test_core

 AREA wram_code5, CODE, READWRITE

 IMPORT compare_value
 IMPORT cheatfinderstate
 EXPORT cheat_test

results RN r0
bits RN r5
values RN r7
ram RN r2
mask RN r3
word RN r4
index RN r6
changeok RN r1
temp RN r8
prev RN r10
compare RN r9

;0 ==
;4 != 
;8 >
;12 <
;16 >=
;20 <=
;24 true

cheat_test_core
	stmfd sp!,{r1-r10,lr}
;init self modify code
	;more init code, need to modify this code
	ldr temp,=cheatfinderstate
	ldr temp,[temp]
	cmp temp,#1
	ldreq temp,mod1table
	ldrne temp,mod1table+4
	str temp,ct_modify1
	ldr temp,=mod2table
	ldr temp,[temp,r0]
	str temp,ct_modify2

	mov results,#0

	mov mask,#0x00000001
	ldr ram,=NES_RAM
	ldr values,=CHEATFINDER_VALUES
	ldr bits,=CHEATFINDER_BITS-4
	mov index,#0
	ldr compare,=compare_value
	ldrb compare,[compare]
	
ctloop
	movs mask,mask,ror #1
	ldrcs word,[bits,#4]!
	tst word,mask
	beq aftermark

	ldrb temp,[ram,index]
	ldrb prev,[values,index]
ct_modify1
	cmp temp,prev
ct_modify2
	beq dontmark
	cmp changeok,#0
	bicne word,word,mask
	strne word,[bits]
	b aftermark
dontmark
	add results,results,#1
aftermark
	add index,index,#1
	cmp index,#10240
	bne ctloop
	ldmfd sp!,{r1-r10,lr}
	bx lr
	
mod1table
	cmp temp,prev
	cmp temp,compare
mod2table
;eq -> ne
;ne -> eq
;gt -> le
;lt -> ge
;ge -> lt
;le -> gt

	DCD 0x0A000003	;beq 3
	DCD 0x1A000003	;bne 3
	DCD 0xCA000003	;bgt 3
	DCD 0xBA000003	;blt 3
	DCD 0xAA000003	;bge 3
	DCD 0xDA000003	;ble 3
	DCD 0xEA000003  ;b   3

 END