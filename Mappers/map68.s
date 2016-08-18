	AREA rom_code, CODE, READONLY

	INCLUDE equates.h
	INCLUDE memory.h
	INCLUDE ppu.h
	INCLUDE cart.h

	EXPORT mapper68init
;----------------------------------------------
mapper68init	;Sunsoft, After Burner...
;----------------------------------------------
	DCD write0,write1,write2,write3

	mov pc,lr
;----------------------------------------------
write0
;----------------------------------------------
	tst addy,#0x1000
	bne chr23_
	b chr01_
;----------------------------------------------
write1
;----------------------------------------------
	tst addy,#0x1000
	bne chr67_
	b chr45_
;----------------------------------------------
write2
;----------------------------------------------
	b empty_W
;	tst addy,#0x1000
;	bne chrAB_
;	b chr89_
;----------------------------------------------
write3
;----------------------------------------------
	tst addy,#0x1000
	bne map89AB_

	tst r0,#0x10
	bne setNTmanualy
	b mirrorKonami_
setNTmanualy
	b empty_W		;fix this some day
;----------------------------------------------
	END
