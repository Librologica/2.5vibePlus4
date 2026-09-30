; Native Plus/4 BASIC 3.5 loader. RAM-only after takeover, no KERNAL calls.
*=$1001
 .word basic_end,10
 .byte $9e
 .text "4109"
 .byte 0
basic_end:
 .word 0
boot:
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
 ldx #0
copy_loader:
 lda loader_bytes,x
 sta $0200,x
 inx
 cpx #loader_end-loader_bytes
 bne copy_loader
 jmp $0200
loader_bytes:
 .logical $0200
 lda #0
 sta $fb
 lda #$20
 sta $fc
 lda #$01
 sta $fd
 lda #$08
 sta $fe
 ldx #(50687 / 256)
 ldy #0
relocate_page:
 lda ($fb),y
 sta ($fd),y
 iny
 bne relocate_page
 inc $fc
 inc $fe
 dex
 bne relocate_page
relocate_tail:
 cpy #(50687 & 255)
 beq relocated
 lda ($fb),y
 sta ($fd),y
 iny
 bne relocate_tail
relocated:
 jmp $080d
 .here
loader_end:
 .cerror loader_end-loader_bytes>256,"loader page"
 .cerror boot!=$100d,"BASIC SYS target"
*=$2000
 .binary "payload.bin"
 .cerror *>=$fd00,"payload collides with permanent TED I/O"
