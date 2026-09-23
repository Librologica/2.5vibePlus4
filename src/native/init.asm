native_init:
 sei
 cld
 ldx #$ff
 txs
 lda #0
 sta $ff0a
 sta $ff06
 sta $ff11
 sta $ff19
 sta $ff3f
 lda #<nmi
 sta $fffa
 lda #>nmi
 sta $fffb
 lda #<irq
 sta $fffe
 lda #>irq
 sta $ffff
 jsr layout_copy_tables
 lda #0
 ldx #$1a
clear_state:
 sta $02,x
 dex
 bpl clear_state
 jsr init_video_standard
 ; Hires UI 256 ASCII-indexed glyphs at 5800; fast-clock bit 1 CLEAR.
 lda #$58
 sta $ff13
 lda #$18
 sta $ff12
 lda #$d8
 sta $ff14
 lda #0
 sta $ff15
 lda #$67
 sta $ff16
 lda #$88
 ora ted_standard_bit
 sta $ff07
 ; Shared color matrices. 01=brown 29, 10=orange 48, 11=yellow 67.
 ; No per-frame matrix updates except the UI FPS digits.
 ldx #0
 lda #$42
init_attr:
 sta $d800,x
 sta $d900,x
 sta $da00,x
 sta $db00,x
 lda #$98
 sta $dc00,x
 sta $dd00,x
 sta $de00,x
 sta $df00,x
 lda #$42
 inx
 bne init_attr
 ldx #119
init_ui:
 lda ui_text,x
 sta $dc00,x
 lda #$71
 sta $d800,x
 dex
 bpl init_ui
 ldx #23
init_guards:
 lda #$a5
 sta $dbe8,x
 sta $dfe8,x
 dex
 bpl init_guards
 jsr init_camera
 jsr init_simulation
 jsr latch_pose
 jsr raycast_layers
 jsr select_strips
 jsr vp_clear_frame
 lda #0
 sta drawbuf
 jsr compose_screen
 lda #1
 sta drawbuf
 jsr compose_screen
 lda #$1b
 sta $ff06
 lda #252
 sta $ff0b
 lda #$5e
 sta $ff09
 lda #2
 sta $ff0a
 cli
main_loop:
 jsr consume_video_ticks
render_frame_begin:
 lda sim_ticks
 sta frame_pose_tick
 lda sim_ticks+1
 sta frame_pose_tick+1
 jsr latch_pose
 jsr raycast_layers
 jsr select_strips
 jsr compose_screen
render_frame_end:
 lda #1
 sta ready
wait_present:
 jsr consume_video_ticks
 lda ready
 bne wait_present
presentation_done:
 jmp main_loop
frame_pose_tick:
 .word 0
ted_standard_bit:
 .byte 0

; Runtime input. TED latch FF08 selects joystick and keyboard input lines;
; FD30 is the keyboard row output, not C64 CIA DDR/port state.
ted_read_controls:
 lda #$ff
 sta $fd30
 lda #$fd
 sta $ff08
 lda $ff08
 eor #$ff
 and #15
 sta keys
 ; Plus/4 matrix row 1: W bit 1, A bit 2, S bit 5. Row 2: D bit 2.
 lda #$fd
 sta $fd30
 lda #$ff
 sta $ff08
 lda $ff08
 sta key_row
 and #2
 bne ted_not_w
 lda keys
 ora #1
 sta keys
ted_not_w:
 lda key_row
 and #$20
 bne ted_not_s
 lda keys
 ora #2
 sta keys
ted_not_s:
 lda key_row
 and #4
 bne ted_not_a
 lda keys
 ora #4
 sta keys
ted_not_a:
 lda #$fb
 sta $fd30
 lda #$ff
 sta $ff08
 lda $ff08
 and #4
 bne ted_not_d
 lda keys
 ora #8
 sta keys
ted_not_d:
 lda #$ff
 sta $fd30
 rts
