; ROMs start at $8000
* = $8000

.(
    .byte 0,0,0
    jmp service_entry
    .byte $82
    .byte <(copyrightstring-1)
    .byte 1
    .byte "SuperShadow", 0
copyrightstring:
    .byte "(C)2023 gfoot", 0
.)

service_entry:
.(
	cmp #$0e : beq rfs_bget
	cmp #$04 : beq star
    cmp #$fe : beq post_tube
	cmp #$09 : beq help
	cmp #$0d : beq rfs_init
    rts

star:
	jmp starcommand

rfs_init:
	jmp do_rfs_init

rfs_bget:
	jmp do_rfs_bget

post_tube:
    pha : txa : pha : tya : pha

    ; Check for soft-boot
	lda #$fd : ldx #$00 : ldy #$ff
	jsr osbyte
	cpx #0
	beq skip_init

    ; If it's not a soft boot, we want to perform first-time initialisation

    ; Check if shadow mode has been locked - if so, don't try to use it
    jsr check_if_locked
    bcc skip_init

    ; Continue initialisation
    jsr bootup

    ; If carry is set, bootup failed
    bcs skip_init

    lda #SCMD_INIT
    jsr shadow_command
skip_init:

    pla : tay : pla : tax : pla
    rts

help:
	lda ($f2),y
	cmp #13
	bne skiphelp

	jsr nprintimm
	.byte 13, "SuperShadow service ROM 0.22 (V2/V4)", 13, 0

	jsr detect_hardware
	bcc detected
	jsr nprintimm
	.byte "  Hardware not detected", 13, 0
	jmp skiphelp

detected:
	jsr nprintimm
	.byte "  SSON", 13
	.byte "  SSOFF", 13
	.byte 0

skiphelp:
	lda #9
	rts

.)

.(
&do_rfs_init:
	pha
	tya : eor #15 : cmp $f4 : bcc passon

	lda #<rfs_data : sta $f6
	lda #>rfs_data : sta $f7
	lda $f4 : eor #15 : sta $f5
	bpl claim

&do_rfs_bget:
	pha
	lda $f5 : eor #15 : cmp $f4 : bne passon
	ldy #0 : lda ($f6),y : tay
	inc $f6 : bne claim
	inc $f7

claim:
	pla : lda #0
	rts

passon:
	pla
	rts
.)


starcommand:
.(
	; Taken from http://www.sprow.co.uk/bbc/library/sidewrom.pdf
	ldx #$ff : dey
	tya : pha

compare:
	iny : inx
	lda ($f2),y : and #$df : cmp table,x : beq compare

	lda table,x : bmi runnit

findnext:
	inx : lda table,x : bpl findnext

	inx
	pla : pha : tay
	jmp compare

table:
	.byte "SSON", >star_sson, <star_sson
	.byte "SSOFF", >star_ssoff, <star_ssoff
	.byte $ff

runnit:
	cmp #$ff : beq passon
	sta $f9
	inx : lda table,x
	sta $f8
	pla
	jmp ($f8)

passon:
	pla : tay
	lda #4
	rts


.(
&star_sson:
	jsr sson
	jmp init_fs_enter_language

&star_ssoff:
	jsr ssoff
	jmp init_fs_enter_language

#include "common/ssoff.s"
#include "common/sson.s"
#include "common/init_fs_enter_language.s"
.)

do_oscli:
.(
	stx $f8 : sty $f9
	ldy #0
loop:
	lda ($f8),y : sta $100,y
	cmp #13 : beq endloop
	iny : bne loop
endloop:
	ldx #<$100
	ldy #>$100
	jmp $fff7
.)

.)



; Returns with carry set if shadow mode is available, clear if it is locked
check_if_locked:
.(
    ; These zero-page locations are corrupted by the test
    n_rts = $3f
    s_sec = $f8

    php : sei

    ; Set up a "normal rts" stub
    lda #$60 : sta n_rts

    ; Set up a fake "shadow sec" stub that doesn't set the carry
    sta s_sec

    ; Set up the real "shadow sec" stub
	lda #>s_sec : sta $feed
    lda #<s_sec : sta $feed
    lda #$38    : sta $fee5    ; sec
    lda #$4c    : sta $fee5    ; jmp
    lda #<n_rts : sta $fee5    ; <n_rts
    lda #>n_rts : sta $fee5    ; >n_rts

    ; Call it and check the carry flag
    clc
    jsr s_sec

    ; Save the carry
    rol n_rts

    ; Restore flags for interrupt state, restore carry, and exit
    plp
    ror n_rts
    rts
.)




