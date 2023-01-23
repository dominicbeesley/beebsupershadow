; Shadow data transfers
; 
; Used by file loading and saving, etc
;
; Set the address first, then either read or write bytes by calling other routines one at a time.  They
; mustn't be mixed.

&shadow_data_setaddr_impl:
.(
	; If it's 2 or greater, we want to disable the routines
	cmp #2 : bcc ok

	; Clamp it to 2, which will be a jmp instruction, and set X and Y so it's a "jmp normal_rts"
	lda #2
	ldx #<normal_rts
	ldy #>normal_rts

ok:
	stx shadow_data_byte_impl+1
	sty shadow_data_byte_impl+2

	tax
	lda instrs,x
	sta shadow_data_byte_impl

	jmp normal_rts

instrs:
	.byte $ad ; lda absolute
	.byte $8d ; sta absolute
	.byte $4c ; jmp absolute
.)


; The first instruction gets rewritten by shadow_data_setaddr_impl, so it's sometimes a load or the routine
; is skipped
&shadow_data_byte_impl:
.(
	sta $1234
	inc shadow_data_byte_impl+1
	bne do_rts
	inc shadow_data_byte_impl+2
do_rts:
	jmp normal_rts
.)

