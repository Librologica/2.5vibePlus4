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
 ldx #63
 lda #0
ted_clear_safe_tail:
 sta $fcc0,x
 dex
 bpl ted_clear_safe_tail
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

nx_ceiling:
 lda drawbuf
 bne nx_ceiling_b
 lda col
 asl
 asl
 asl
 tax
 ldy band_count
 jmp nx_ceiling_a_0
nx_ceiling_b:
 lda col
 asl
 asl
 asl
 tax
 ldy band_count
 jmp nx_ceiling_b_0
nx_ceiling_a_0:
 lda #$44
 sta $6660,x
 sta $6662,x
 sta $6664,x
 sta $6666,x
 lda #$11
 sta $6661,x
 sta $6663,x
 sta $6665,x
 sta $6667,x
 dey
 bne nx_ceiling_a_1
 jmp nx_ceiling_done
nx_ceiling_a_1:
 lda #$44
 sta $67a0,x
 sta $67a2,x
 sta $67a4,x
 sta $67a6,x
 lda #$11
 sta $67a1,x
 sta $67a3,x
 sta $67a5,x
 sta $67a7,x
 dey
 bne nx_ceiling_a_2
 jmp nx_ceiling_done
nx_ceiling_a_2:
 lda #$44
 sta $68e0,x
 sta $68e2,x
 sta $68e4,x
 sta $68e6,x
 lda #$11
 sta $68e1,x
 sta $68e3,x
 sta $68e5,x
 sta $68e7,x
 dey
 bne nx_ceiling_a_3
 jmp nx_ceiling_done
nx_ceiling_a_3:
 lda #$44
 sta $6a20,x
 sta $6a22,x
 sta $6a24,x
 sta $6a26,x
 lda #$11
 sta $6a21,x
 sta $6a23,x
 sta $6a25,x
 sta $6a27,x
 dey
 bne nx_ceiling_a_4
 jmp nx_ceiling_done
nx_ceiling_a_4:
 lda #$44
 sta $6b60,x
 sta $6b62,x
 sta $6b64,x
 sta $6b66,x
 lda #$11
 sta $6b61,x
 sta $6b63,x
 sta $6b65,x
 sta $6b67,x
 dey
 bne nx_ceiling_a_5
 jmp nx_ceiling_done
nx_ceiling_a_5:
 lda #$44
 sta $6ca0,x
 sta $6ca2,x
 sta $6ca4,x
 sta $6ca6,x
 lda #$11
 sta $6ca1,x
 sta $6ca3,x
 sta $6ca5,x
 sta $6ca7,x
 dey
 bne nx_ceiling_a_6
 jmp nx_ceiling_done
nx_ceiling_a_6:
 lda #$44
 sta $6de0,x
 sta $6de2,x
 sta $6de4,x
 sta $6de6,x
 lda #$11
 sta $6de1,x
 sta $6de3,x
 sta $6de5,x
 sta $6de7,x
 dey
 bne nx_ceiling_a_7
 jmp nx_ceiling_done
nx_ceiling_a_7:
 lda #$44
 sta $6f20,x
 sta $6f22,x
 sta $6f24,x
 sta $6f26,x
 lda #$11
 sta $6f21,x
 sta $6f23,x
 sta $6f25,x
 sta $6f27,x
 dey
 bne nx_ceiling_a_8
 jmp nx_ceiling_done
nx_ceiling_a_8:
 lda #$44
 sta $7060,x
 sta $7062,x
 sta $7064,x
 sta $7066,x
 lda #$11
 sta $7061,x
 sta $7063,x
 sta $7065,x
 sta $7067,x
 dey
 bne nx_ceiling_a_9
 jmp nx_ceiling_done
nx_ceiling_a_9:
 lda #$44
 sta $71a0,x
 sta $71a2,x
 sta $71a4,x
 sta $71a6,x
 lda #$11
 sta $71a1,x
 sta $71a3,x
 sta $71a5,x
 sta $71a7,x
 dey
 bne nx_ceiling_a_10
 jmp nx_ceiling_done
nx_ceiling_a_10:
 lda #$44
 sta $72e0,x
 sta $72e2,x
 sta $72e4,x
 sta $72e6,x
 lda #$11
 sta $72e1,x
 sta $72e3,x
 sta $72e5,x
 sta $72e7,x
 dey
 bne nx_ceiling_a_11
 jmp nx_ceiling_done
nx_ceiling_a_11:
 lda #$44
 sta $7420,x
 sta $7422,x
 sta $7424,x
 sta $7426,x
 lda #$11
 sta $7421,x
 sta $7423,x
 sta $7425,x
 sta $7427,x
 dey
 bne nx_ceiling_a_12
 jmp nx_ceiling_done
nx_ceiling_a_12:
 lda #$44
 sta $7560,x
 sta $7562,x
 sta $7564,x
 sta $7566,x
 lda #$11
 sta $7561,x
 sta $7563,x
 sta $7565,x
 sta $7567,x
 dey
 bne nx_ceiling_a_13
 jmp nx_ceiling_done
nx_ceiling_a_13:
 lda #$44
 sta $76a0,x
 sta $76a2,x
 sta $76a4,x
 sta $76a6,x
 lda #$11
 sta $76a1,x
 sta $76a3,x
 sta $76a5,x
 sta $76a7,x
 dey
 bne nx_ceiling_a_14
 jmp nx_ceiling_done
nx_ceiling_a_14:
 lda #$44
 sta $77e0,x
 sta $77e2,x
 sta $77e4,x
 sta $77e6,x
 lda #$11
 sta $77e1,x
 sta $77e3,x
 sta $77e5,x
 sta $77e7,x
 dey
 bne nx_ceiling_a_15
 jmp nx_ceiling_done
nx_ceiling_a_15:
 lda #$44
 sta $7920,x
 sta $7922,x
 sta $7924,x
 sta $7926,x
 lda #$11
 sta $7921,x
 sta $7923,x
 sta $7925,x
 sta $7927,x
 dey
 bne nx_ceiling_a_16
 jmp nx_ceiling_done
nx_ceiling_a_16:
 lda #$44
 sta $7a60,x
 sta $7a62,x
 sta $7a64,x
 sta $7a66,x
 lda #$11
 sta $7a61,x
 sta $7a63,x
 sta $7a65,x
 sta $7a67,x
 dey
 bne nx_ceiling_a_17
 jmp nx_ceiling_done
nx_ceiling_a_17:
 lda #$44
 sta $7ba0,x
 sta $7ba2,x
 sta $7ba4,x
 sta $7ba6,x
 lda #$11
 sta $7ba1,x
 sta $7ba3,x
 sta $7ba5,x
 sta $7ba7,x
 dey
 bne nx_ceiling_a_18
 jmp nx_ceiling_done
nx_ceiling_a_18:
nx_ceiling_b_0:
 lda #$44
 sta $e660,x
 sta $e662,x
 sta $e664,x
 sta $e666,x
 lda #$11
 sta $e661,x
 sta $e663,x
 sta $e665,x
 sta $e667,x
 dey
 bne nx_ceiling_b_1
 jmp nx_ceiling_done
nx_ceiling_b_1:
 lda #$44
 sta $e7a0,x
 sta $e7a2,x
 sta $e7a4,x
 sta $e7a6,x
 lda #$11
 sta $e7a1,x
 sta $e7a3,x
 sta $e7a5,x
 sta $e7a7,x
 dey
 bne nx_ceiling_b_2
 jmp nx_ceiling_done
nx_ceiling_b_2:
 lda #$44
 sta $e8e0,x
 sta $e8e2,x
 sta $e8e4,x
 sta $e8e6,x
 lda #$11
 sta $e8e1,x
 sta $e8e3,x
 sta $e8e5,x
 sta $e8e7,x
 dey
 bne nx_ceiling_b_3
 jmp nx_ceiling_done
nx_ceiling_b_3:
 lda #$44
 sta $ea20,x
 sta $ea22,x
 sta $ea24,x
 sta $ea26,x
 lda #$11
 sta $ea21,x
 sta $ea23,x
 sta $ea25,x
 sta $ea27,x
 dey
 bne nx_ceiling_b_4
 jmp nx_ceiling_done
nx_ceiling_b_4:
 lda #$44
 sta $eb60,x
 sta $eb62,x
 sta $eb64,x
 sta $eb66,x
 lda #$11
 sta $eb61,x
 sta $eb63,x
 sta $eb65,x
 sta $eb67,x
 dey
 bne nx_ceiling_b_5
 jmp nx_ceiling_done
nx_ceiling_b_5:
 lda #$44
 sta $eca0,x
 sta $eca2,x
 sta $eca4,x
 sta $eca6,x
 lda #$11
 sta $eca1,x
 sta $eca3,x
 sta $eca5,x
 sta $eca7,x
 dey
 bne nx_ceiling_b_6
 jmp nx_ceiling_done
nx_ceiling_b_6:
 lda #$44
 sta $ede0,x
 sta $ede2,x
 sta $ede4,x
 sta $ede6,x
 lda #$11
 sta $ede1,x
 sta $ede3,x
 sta $ede5,x
 sta $ede7,x
 dey
 bne nx_ceiling_b_7
 jmp nx_ceiling_done
nx_ceiling_b_7:
 lda #$44
 sta $ef20,x
 sta $ef22,x
 sta $ef24,x
 sta $ef26,x
 lda #$11
 sta $ef21,x
 sta $ef23,x
 sta $ef25,x
 sta $ef27,x
 dey
 bne nx_ceiling_b_8
 jmp nx_ceiling_done
nx_ceiling_b_8:
 lda #$44
 sta $f060,x
 sta $f062,x
 sta $f064,x
 sta $f066,x
 lda #$11
 sta $f061,x
 sta $f063,x
 sta $f065,x
 sta $f067,x
 dey
 bne nx_ceiling_b_9
 jmp nx_ceiling_done
nx_ceiling_b_9:
 lda #$44
 sta $f1a0,x
 sta $f1a2,x
 sta $f1a4,x
 sta $f1a6,x
 lda #$11
 sta $f1a1,x
 sta $f1a3,x
 sta $f1a5,x
 sta $f1a7,x
 dey
 bne nx_ceiling_b_10
 jmp nx_ceiling_done
nx_ceiling_b_10:
 lda #$44
 sta $f2e0,x
 sta $f2e2,x
 sta $f2e4,x
 sta $f2e6,x
 lda #$11
 sta $f2e1,x
 sta $f2e3,x
 sta $f2e5,x
 sta $f2e7,x
 dey
 bne nx_ceiling_b_11
 jmp nx_ceiling_done
nx_ceiling_b_11:
 lda #$44
 sta $f420,x
 sta $f422,x
 sta $f424,x
 sta $f426,x
 lda #$11
 sta $f421,x
 sta $f423,x
 sta $f425,x
 sta $f427,x
 dey
 bne nx_ceiling_b_12
 jmp nx_ceiling_done
nx_ceiling_b_12:
 lda #$44
 sta $f560,x
 sta $f562,x
 sta $f564,x
 sta $f566,x
 lda #$11
 sta $f561,x
 sta $f563,x
 sta $f565,x
 sta $f567,x
 dey
 bne nx_ceiling_b_13
 jmp nx_ceiling_done
nx_ceiling_b_13:
 lda #$44
 sta $f6a0,x
 sta $f6a2,x
 sta $f6a4,x
 sta $f6a6,x
 lda #$11
 sta $f6a1,x
 sta $f6a3,x
 sta $f6a5,x
 sta $f6a7,x
 dey
 bne nx_ceiling_b_14
 jmp nx_ceiling_done
nx_ceiling_b_14:
 lda #$44
 sta $f7e0,x
 sta $f7e2,x
 sta $f7e4,x
 sta $f7e6,x
 lda #$11
 sta $f7e1,x
 sta $f7e3,x
 sta $f7e5,x
 sta $f7e7,x
 dey
 bne nx_ceiling_b_15
 jmp nx_ceiling_done
nx_ceiling_b_15:
 lda #$44
 sta $f920,x
 sta $f922,x
 sta $f924,x
 sta $f926,x
 lda #$11
 sta $f921,x
 sta $f923,x
 sta $f925,x
 sta $f927,x
 dey
 bne nx_ceiling_b_16
 jmp nx_ceiling_done
nx_ceiling_b_16:
 lda #$44
 sta $fa60,x
 sta $fa62,x
 sta $fa64,x
 sta $fa66,x
 lda #$11
 sta $fa61,x
 sta $fa63,x
 sta $fa65,x
 sta $fa67,x
 dey
 bne nx_ceiling_b_17
 jmp nx_ceiling_done
nx_ceiling_b_17:
 lda #$44
 sta $fba0,x
 sta $fba2,x
 sta $fba4,x
 sta $fba6,x
 lda #$11
 sta $fba1,x
 sta $fba3,x
 sta $fba5,x
 sta $fba7,x
 dey
 bne nx_ceiling_b_18
 jmp nx_ceiling_done
nx_ceiling_b_18:
nx_ceiling_done:
 lda #0
 sta band_count
 rts
