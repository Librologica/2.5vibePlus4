; TED raster counter: visible 25-row area lines 4..203, PAL and NTSC.
; Text rows 0..2, bitmap rows 3..22, bottom margins from low bitmap only.
; IRQ never uses the renderer's ZP, stack only; no KERNAL/CIA/VIC accesses.
irq:
 pha
 txa
 pha
 tya
 pha
 lda #2
 sta $ff09
 lda irq_phase
 beq irq_top
 cmp #1
 beq irq_body
 ; With Y scroll 3, line 187 is a TED badline. Its register read stalls
 ; until after the active columns. A is prepared BEFORE polling so the
 ; first instruction after the branch can update FF12 before row 23 fetch.
 ; Additional horizontal-register polling here misses that narrow window.
 lda #$18
 ldx #187
irq_wait_bottom:
 cpx $ff1d
 bne irq_wait_bottom
bottom_pointer_store:
 sta $ff12
 lda #0
 sta irq_phase
 lda #252
 sta $ff0b
 jmp irq_exit
irq_body:
 ; UI ends line 27. IRQ 28 executes in the two black margin rows.
 ; Do not poll a low raster byte after a badline: it may already be past.
 lda display_buf
 beq body_a
 lda #$20
body_a:
 ora #$18
 sta $ff12
 lda #$98
 ora ted_standard_bit
 sta $ff07
 lda #$3b
body_mode_store:
 sta $ff06
 lda #2
 sta irq_phase
 lda #184
 sta $ff0b
 jmp irq_exit
irq_top:
 lda #$1b
 sta $ff06
 lda #$88
 ora ted_standard_bit
 sta $ff07
 lda ready
 beq irq_no_swap
 lda drawbuf
 sta display_buf
 eor #1
 sta drawbuf
 lda #0
 sta ready
 inc frame_count
 bne fps_frame_done
 inc frame_count+1
fps_frame_done:
 inc fps_count
irq_no_swap:
 inc pending_ticks
 bne irq_tick_ok
 dec pending_ticks
 lda #1
 sta tick_overflow
irq_tick_ok:
 inc fps_refresh
 lda fps_refresh
 cmp video_hz
 bcc irq_no_second
 lda #0
 sta fps_refresh
 lda fps_count
 sta fps_value
 ldx #0
fps_decimal:
 cmp #10
 bcc fps_decimal_done
 sec
 sbc #10
 inx
 bne fps_decimal
fps_decimal_done:
 ora #$30
 sta $dc2d
 txa
 ora #$30
 sta $dc2c
 lda #0
 sta fps_count
irq_no_second:
 lda #1
 sta irq_phase
 lda #28
 sta $ff0b
irq_exit:
 pla
 tay
 pla
 tax
 pla
 rti
nmi:
 rti
