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

    jsr bootup

	; If carry is set, bootup failed
	bcs skip_init

    ; Check for soft-boot
	lda #$fd : ldx #$00 : ldy #$ff
	jsr osbyte
	cpx #0
	beq skip_init

    ; If it's not a soft boot, we want to perform first-time initialisation
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
	.byte 13, "SuperShadow service ROM", 13
	.byte "        V2 hardware ", 0

	jsr detect_hardware
	bcc detected

	jsr nprintimm
	.byte "not ", 0

detected:
	jsr nprintimm
	.byte "present", 13

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

star_sson:
.(
	; Unlock shadow mode
	sei
	sta $e000 : sta $d000 : sta $e000 : sta $c000
	; Leave interrupts disabled for now

	; Boot up and initialise shadow OS
	jsr bootup

    ;jsr printimm
    ;.byte "Initialising shadow OS", 13, 13, 0

	jsr $ffe7

	; Send the initialisation command
	lda #SCMD_INIT
	jsr shadow_command

	; Chain to the post-Break handler to do the things that normally happen during reset -
	; hooking vectors with routines to pass them to Shadow mode, etc
	sec ; it only acts when the carry is set
	jsr normal_breakhandler

	; Issue a *DISC command so that DNFS reinitialises with its Tube support enabled
	ldx #<cmd_disc : ldy #>cmd_disc
	jsr do_oscli

	; Read currently-active language ROM number into X
	lda #$fc : ldx #0 : ldy #$ff : jsr osbyte

	; Reactivate the language ROM specified by X, causing it to get copied to shadow
	; RAM and executed there
	lda #$8e : jsr osbyte
	
    ; If it returns somehow, we can't really carry on as we've corrupted BASIC's 
	; zero page and set weird vectors, so reboot.
	jmp ($fffc)
	
cmd_disc:
	.byte "DISC", 13
.)

star_ssoff:
.(
	sei

	; Disable shadow mode
	sta $e000

	; Restore OS vectors
	lda $ffb8
	sta $f9
	lda $ffb7
	sta $f8
	ldy $ffb6
loop:
	dey
	lda ($f8),y : sta $0200,y
	cpy #0 : bne loop

	; Disable fake Tube
	lda #$ea : ldx #0 : ldy #0 : jsr $fff4

	; Disable BREAK intercept
	lda #247 : ldx #0 : ldy #0 : jsr $fff4

	cli

	jsr nprintimm
	.byte 13, "SuperShadow disabled", 13, 13, 0

	; Reactivate filing system
	ldx #<cmd_disc : ldy #>cmd_disc
	jsr do_oscli

	; Enter BASIC
	ldx #<cmd_basic : ldy #>cmd_basic
	jmp do_oscli

cmd_disc:
	.byte "DISC", 13

cmd_basic:
	.byte "B.", 13
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

