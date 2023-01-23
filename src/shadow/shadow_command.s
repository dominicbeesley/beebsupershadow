; Main command entry point
;
; A = command code
; X,Y = parameters
&shadow_command_impl:
.(
    cmp #SCMD_INIT : beq do_init
	cmp #SCMD_CALL : beq do_call
	cmp #SCMD_ENTERLANG : beq do_enterlang
	cmp #SCMD_REBOOT : beq do_reboot
	cmp #SCMD_REENTERLANG : beq do_reenterlang
	cmp #SCMD_SETESCAPEFLAG : beq do_setescapeflag

    brk
    .db $fa, "Unknown command", 0

do_init:
    jmp shadow_init

do_enterlang:
	; Update memtop, so that HIMEM is below the language ROM image
	stx memtop
	sty memtop+1

	; Print the language name
	clc
	lda memtop : adc #9 : sta print_ptr
	lda memtop+1 : adc #0 : sta print_ptr+1
	jsr print
	jsr osnewl
	jsr osnewl
	
	; Set FD/FE to point to whatever is next
	lda print_ptr : sta brkptr
	lda print_ptr+1 : sta brkptr+1

do_reenterlang:
	ldx memtop
	ldy memtop+1

	; Enter the language with reason code 1
	lda #1
do_call:
.(
	stx jsrinst+1
	sty jsrinst+2
jsrinst:
	jsr $1234
	jmp normal_rts
.)

do_reboot:
.(
	jsr printimm
	.byte "SuperShadow 64K", 13, 13, 0

	jmp normal_rts
.)

do_setescapeflag:
.(
	stx $ff
	jmp normal_rts
.)

.)


