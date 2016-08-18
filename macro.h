
 [ VERSION_IN_ROM
	MACRO
	bl_long $label
	mov lr,pc
	ldr pc,=$label
	MEND

	MACRO
	bleq_long $label
	moveq lr,pc
	ldreq pc,=$label
	MEND

	MACRO
	bllo_long $label
	movlo lr,pc
	ldrlo pc,=$label
	MEND

	MACRO
	blhi_long $label
	movhi lr,pc
	ldrhi pc,=$label
	MEND

	MACRO
	bllt_long $label
	movlt lr,pc
	ldrlt pc,=$label
	MEND

	MACRO
	blgt_long $label
	movgt lr,pc
	ldrgt pc,=$label
	MEND

	MACRO
	blne_long $label
	movne lr,pc
	ldrne pc,=$label
	MEND

	MACRO
	blcc_long $label
	movcc lr,pc
	ldrcc pc,=$label
	MEND

	MACRO
	blpl_long $label
	movpl lr,pc
	ldrpl pc,=$label
	MEND

	MACRO
	b_long $label
	ldr pc,=$label
	MEND

	MACRO
	bcc_long $label
	ldrcc pc,=$label
	MEND

	MACRO
	bhs_long $label
	ldrhs pc,=$label
	MEND

	MACRO
	beq_long $label
	ldreq pc,=$label
	MEND

	MACRO
	bne_long $label
	ldrne pc,=$label
	MEND

	MACRO
	blo_long $label
	ldrlo pc,=$label
	MEND

	MACRO
	bhi_long $label
	ldrhi pc,=$label
	MEND

	MACRO
	bgt_long $label
	ldrgt pc,=$label
	MEND

	MACRO
	blt_long $label
	ldrlt pc,=$label
	MEND

	MACRO
	bcs_long $label
	ldrcs pc,=$label
	MEND

	MACRO
	bmi_long $label
	ldrmi pc,=$label
	MEND

	MACRO
	bpl_long $label
	ldrpl pc,=$label
	MEND

	|

	MACRO
	bl_long $label
	bl $label
	MEND

	MACRO
	bleq_long $label
	bleq $label
	MEND

	MACRO
	bllo_long $label
	bllo $label
	MEND

	MACRO
	blhi_long $label
	blhi $label
	MEND

	MACRO
	bllt_long $label
	bllt $label
	MEND

	MACRO
	blgt_long $label
	blgt $label
	MEND

	MACRO
	blne_long $label
	blne $label
	MEND

	MACRO
	blcc_long $label
	blcc $label
	MEND

	MACRO
	blpl_long $label
	blpl $label
	MEND

	MACRO
	b_long $label
	b $label
	MEND

	MACRO
	bcc_long $label
	bcc $label
	MEND

	MACRO
	bhs_long $label
	bhs $label
	MEND

	MACRO
	beq_long $label
	beq $label
	MEND

	MACRO
	bne_long $label
	bne $label
	MEND

	MACRO
	blo_long $label
	blo $label
	MEND

	MACRO
	bhi_long $label
	bhi $label
	MEND

	MACRO
	bgt_long $label
	bgt $label
	MEND

	MACRO
	blt_long $label
	blt $label
	MEND

	MACRO
	bcs_long $label
	bcs $label
	MEND

	MACRO
	bmi_long $label
	bmi $label
	MEND

	MACRO
	bpl_long $label
	bpl $label
	MEND
 ]
	END
