	INCLUDE equates.h

	[ APACK

;APlib ARM7 decompressor by Dan Weiss, based on the original C version
;Takes in raw apacked data, NOT data created by the 'safe' compressor.

 AREA rom_codeX, CODE, READONLY

src RN r0
dest RN r1
byte RN r2
mask RN r3
gamma RN r4
lwm RN r6
recentoff RN r7
temp RN r8

 EXPORT depack

;r0 = src
;r1 = dest
;r2 = byte
;r3 = rotating bit mask
;r4 = increasing gamma
;r6 = lwm
;r7 = recentoff
;r8 = lr copy/scratch

	MACRO ;3 instructions
	GETBIT
	movs mask,mask,ror #1
	ldrcsb byte,[src],#1
	tst byte,mask
	MEND

	MACRO ;5 instructions
	GETBITGAMMA
	mov gamma,gamma,lsl #1
	GETBIT
	addne gamma,gamma,#1
	MEND

depack
	stmfd sp!,{r4-r10,lr}
	ldrb temp,[src],#1
	strb temp,[dest],#1
	ldr mask,=0x01010101
	b_long aploop_nolwm


 AREA wram_code5, CODE, READWRITE

;;ap_getbit
;;	movs mask, mask, ror #1
;;;	bcc getbit_continue
;;	ldrbcs byte,[src],#1
;;;getbit_continue
;;	tst byte,byte,mask
;;	bx lr

;;ap_getbitgamma
;;	movs gamma,gamma,lsl #1
;;	movs mask,mask,ror #1
;;	bcc getbit_continue2
;;	ldrb byte,[src],#1
;;getbit_continue2
;;	tst byte,byte,mask
;;	addne gamma,gamma,#1
;;	bx lr

	;depack enters here
aploop_nolwm
	mov lwm,#0
aploop
	GETBIT
	bne apbranch1
	ldrb temp,[src],#1
	strb temp,[dest],#1
	b aploop_nolwm
apbranch1
	GETBIT
	beq apbranch2
	GETBIT
	beq apbranch3
	;get an offset
	mov gamma,#0
	GETBIT
	addne gamma,gamma,#1
	GETBITGAMMA
	GETBITGAMMA
	GETBITGAMMA
	cmp gamma,#0
	ldrneb gamma,[dest,-gamma]
	strb gamma,[dest],#1
	b aploop_nolwm
apbranch3
	;use 7 bit offset, length = 2 or 3
	;if a zero is encountered here, it's EOF
	ldrb gamma,[src],#1
	movs recentoff,gamma,lsr #1
	beq done
	ldrcsb temp,[dest,-recentoff]
	strcsb temp,[dest],#1
	ldrb temp,[dest,-recentoff]
	strb temp,[dest],#1
	ldrb temp,[dest,-recentoff]
	strb temp,[dest],#1
	mov lwm,#1
	b aploop
apbranch2
	;use a gamma code * 256 for offset, another gamma code for length

	bl ap_getgamma
	sub gamma,gamma,#2
	cmp lwm,#0
	bne ap_is_lwm
	mov lwm,#1
	cmp gamma,#0
	bne ap_not_zero_gamma

	;if gamma code is 2, use old recent offset, and a new gamma code for length
	bl ap_getgamma
copyloop1
	ldrb temp,[dest,-recentoff]
	strb temp,[dest],#1
	subs gamma,gamma,#1
	bne copyloop1
	b aploop
	
ap_not_zero_gamma
	sub gamma,gamma,#1
ap_is_lwm
	ldrb temp,[src],#1
	add recentoff,temp,gamma,lsl #8
	bl ap_getgamma
	;gamma=length
	cmp recentoff,#32000
	addge gamma,gamma,#1
	cmp recentoff,#1280
	addge gamma,gamma,#1
	cmp recentoff,#128
	addlt gamma,gamma,#2
copyloop2
	ldrb temp,[dest,-recentoff]
	strb temp,[dest],#1
	subs gamma,gamma,#1
	bne copyloop2
	b aploop

ap_getgamma
	mov gamma,#1
ap_getgammaloop
	GETBITGAMMA
	GETBIT
	bne ap_getgammaloop
	bx lr

done
	ldmfd sp!,{r4-r10,lr}
	bx lr

	]
 END
