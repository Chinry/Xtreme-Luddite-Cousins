  .inesmir 1 ;mirroring
  .inesmap 0 ;mapper number (no mapper)
  .ineschr 1 ;number of 8kb banks
  .inesprg 2 ;number of 16kb banks

  .bank 3
  .org $FFFA ;stores location interupts (vector table)

  .dw NMI ;Non Maskable interupt
          ;Can be masked at address $2000 bit 7 is clear

  .dw start ;where to start the game aka reset interrupt
  .dw 0 ;regular interupt not important

  .bank 0
;****Zero-Page*************************
  .org $0000
gameactive: .db 0
vidlow: .db 0
vidhigh: .db 0
tmp: .db 0
renderqueue: .db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
             .db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 

attribqueue: .db 0,0,0,0,0,0,0,0


;****RAM********************************
  .org $0200 
sprite_topl: .db 0,0,0,0
sprite_topr: .db 0,0,0,0
sprite_botl: .db 0,0,0,0
sprite_botr: .db 0,0,0,0

  .org $0300 
playerx: .db 0
playery: .db 0
velocity: .db 0
vel_neg: .db 0
vel_y: .db 0
jumping: .db 0 ;bool






ppu_scroll: .db 0 ;location of the ppu scroll
current_position_high: .db 0 ;current nametable
current_position_low: .db 0  ;position in the name table
curr_nt_pos: .db 0  ;current name table of the updater ;bool
character_nt: .db 0 ;current name table of the scroll ;bool

do_an_update: .db 0 ;update attribute table
selected_attr_table_high: .db 0 ;tmp



ticks: .db 0
velhigh: .db 0
nmis: .db 0
curr_keys: .db 0
last_keys: .db 0
count: .db 0



note:.db 0
pattern_offset:.db 0
note_playing:.db 0
resting:.db 0
rest_count:.db 0
rest_timer:  .db 0
next_note: .db 0 ;bool

next_notet: .db 0 ;bool
notet_length: .db 0
notet_counter .db 0
pattern_offsett .db 0
notet .db 0

;****GAME******************************  
  .org $8000

;**********VBLANK-NMI*******************

NMI:
  inc nmis
  rti

;**********Start/RESET******************
start: cld ;clear decimal mode
  sei ;disable irq maskable interupt
  sec ;set carry
  lda #$00 ;load a with 0 to zero out memory
  tax ;make x register 0 as well
  sta $2000 ;disables nmi
  sta $2001 ;disables rendering
  dex
  txs ;init the stack pointer $01FF
  bit $2002 ;acknowledge PPU STATUS
  bit $4015 ;acknowledge DMC
 

  ;init apu
  lda #%01000000 ;disable apu frame IRQ
  sta $4017
  lda #%00001111 ;disable DMC playback and init other channels
  sta $4015
  
  ldy #$13
init_apu_loop:
  lda regs, y
  sta 4000, y
  dey
  bpl init_apu_loop
  

vblank_wait1:
  bit $2002 ;wait on ppu status register
  bpl vblank_wait1

;clear ppu oam
  ldx #0
  lda #$FF
clear_oam_loop:
  sta $2003,x
  inx
  inx
  inx
  inx
  bne clear_oam_loop





vblank_wait2:
  bit $2002
  bpl vblank_wait2



;set palettes
  lda $2002 ;reset high low latch of bit 7 vblank bit
  lda #$3F ;set ppu address to start at $3F00
  sta $2006
  lda #$00
  sta $2006


  ldx #$00
palette_loop:
  lda palette, x
  sta $2007
  inx
  cpx #32
  bcc palette_loop

  





  ;clear and fill the name table
  jsr clear_nt
  jsr fill_nt
  
  ldx #8 
  lda #%01010101
attrib_queue_fill:
  dex
  sta attribqueue,x
  bne attrib_queue_fill

  




;sprites
  lda #$AF ;put sprite on ground
  sta sprite_topl
  sta sprite_topr
  adc #8
  sta sprite_botl
  sta sprite_botr
  lda #$00 ;put sprite to the left
  sta sprite_topl + 3
  sta sprite_botl + 3
  adc #8
  sta sprite_topr + 3
  sta sprite_botr + 3
  
  ldx #$01 ;load tile number
  stx sprite_topl + 1
  inx
  stx sprite_topr + 1
  inx
  stx sprite_botl + 1
  inx 
  stx sprite_botr + 1
  lda #$00 ;load color palette
  sta sprite_topl + 2
  sta sprite_topr + 2
  sta sprite_botl + 2
  sta sprite_botr + 2

;enable nmi and use pattern table 0
  lda #%10000000
  sta $2000

;init ticks
  lda #$00
  sta ticks
  sta nmis
  sta note
  sta pattern_offset
  sta note_playing
  sta resting
  sta rest_count
  sta rest_timer
  sta notet_length
  sta notet_counter
  sta playerx
  sta velocity
  sta vel_neg
  sta velhigh
  sta jumping
  sta count
  sta vel_y
  sta ppu_scroll
  sta current_position_low
  lda #$24
  sta current_position_high
  lda #1
  sta curr_nt_pos
  sta next_note
  sta next_notet
  lda #$B8
  sta playery
  lda #2
  sta do_an_update
  




  lda #%10000100 
  sta $2000 



end_loop:
  lda nmis
;********VBLANK*****AKA**GET*SH*T*DONE***********
vblank_wait3:
  cmp nmis
  beq vblank_wait3



;sprite dma
  lda #$00
  sta $2003
  lda #$02
  sta $4014
  
  ldx #0
  lda #%10000000
  stx $2005
  stx $2005
  sta $2000
  lda #%00011110
  sta $2001
  



  



;attribute table update or edge update
 



  lda count
  clc
  adc #16
  sta count
  bne do_not_update_edge

  lda do_an_update
  beq update_attrib_table
  jsr update_edge 
  jmp do_not_update_edge
update_attrib_table:
  jsr update_attrib_col
do_not_update_edge:



;ppuscroll
  lda character_nt
  beq nm_select_0
  lda #%10000101
  sta $2000 
  jmp end_nm_select
nm_select_0:
  lda #%10000100 
  sta $2000 
end_nm_select:
  lda ppu_scroll
  sta $2005
  lda #0
  sta $2005

;**************************************



;sprite animation frame handling  
  lda velocity
  bne skip_static_frame
  jsr set_static_frame
  jmp skip_frame_change
skip_static_frame
  lda velhigh
  eor #%00001111
  lsr a
  sta velhigh
  inc ticks
  lda ticks
  cmp velhigh
  beq skip_reset_ticks
  bcs reset_ticks
  bne skip_frame_change
  jmp skip_reset_ticks
reset_ticks:
  lda #0
  sta ticks
  jmp skip_frame_change
skip_reset_ticks:
  lda #0
  sta ticks
  inc sprite_botl + 1
  inc sprite_botl + 1
  inc sprite_botr + 1
  inc sprite_botr + 1
  lda sprite_botr + 1
  cmp #$0C
  bcc skip_frame_change
  jsr set_static_frame


skip_frame_change:


;move player to location
  lda playerx
  sta sprite_topl + 3
  sta sprite_botl + 3
  adc #7
  sta sprite_topr + 3
  sta sprite_botr + 3

  lda playery
  sta sprite_topl
  sta sprite_topr
  adc #8
  sta sprite_botl
  sta sprite_botr

  

  

;handling input
;7  6  5       4      3   2     1     0
;A  B  SELECT  START  UP  DOWN  LEFT  RIGHT
;Player 1 $4016
;Player 2 $4017
;move current to last
  lda curr_keys
  sta last_keys
;send the 1 then 0 latch signal tells the controllers
;to send data to a shift register
  lda #$00
  sta curr_keys
  lda #$01
  sta curr_keys ;store bit to set the carry later
  sta $4016
  lsr a
  sta $4016
pad_read_loop:
  lda $4016
  and #%00000001 ;only bit 0 matters
  cmp #1 ;if value of a is = to or greater
         ;than 1 set carry
  rol curr_keys 
  bcc pad_read_loop ;branch when leftmost bit sets
                    ;carry
  
  

;handle jumping
  bit curr_keys
  bpl skip_set_jumping 
  lda jumping
  bne skip_set_jumping
  inc jumping
  lda #10
  sta vel_y
skip_set_jumping:

;increment velocity
  lda curr_keys
  ror a
  bcc skip_move_right
  lda velocity
  clc
  adc #3
  bvs skip_move_right
  sta velocity
  jmp skip_move_left
skip_move_right:
  ror a
  bcc skip_move_left
  lda velocity
  clc
  sbc #3
  bvs skip_move_left
  sta velocity
skip_move_left:


;decrement y velocity
  lda jumping
  beq skip_jumping 
  dec vel_y
skip_jumping:
  








;friction
  lda velocity
  beq skip_friction
  cmp #128 
  bcs do_left_friction
  cmp #3
  bcc dec_vel_once
  dec velocity
dec_vel_once:
  dec velocity
  jmp skip_friction
do_left_friction:
  cmp #$FE
  bcs inc_vel_once
  inc velocity
inc_vel_once:
  inc velocity
skip_friction:


;handle velocity
  lda velocity
  cmp #128
  bcs negative_velocity
  lsr a
  lsr a
  lsr a
  lsr a
  sta velhigh
  ldx playerx
  cpx #128
  bcc inc_playerx_location
  clc
  adc ppu_scroll 
  sta ppu_scroll
  bcc skip_change_nt_on_scroll_end
  lda character_nt
  eor #1
  sta character_nt
skip_change_nt_on_scroll_end:
  jmp finish_velocity
inc_playerx_location:
  clc
  adc playerx
  sta playerx
  jmp finish_velocity
negative_velocity:
  eor #$FF
  clc
  adc #1
  lsr a
  lsr a
  lsr a
  lsr a
  sta vel_neg
  sta velhigh
  lda playerx
  clc
  sbc vel_neg
  cmp #250
  bcc skip_stop_at_left
  lda #2
  sta playerx
skip_stop_at_left:
  sta playerx
finish_velocity:

;handle y velocity
  lda jumping
  beq skip_reset_jump
  lda vel_y
  bpl skip_neg_y_vel
  eor #$FF 
  clc
  adc #1
  adc playery
  sta playery
  jmp end_vel_y
skip_neg_y_vel:
  lda playery
  sbc vel_y
  sta playery
end_vel_y:
  lda playery
  cmp #$AF
  bcc skip_reset_jump
  dec jumping
  lda #$B8
  sta playery
  lda #0
  sta vel_y
skip_reset_jump:

 

  lda count
  bne skipo
  lda do_an_update
  beq skipo
  jsr checks
skipo:






;***********MUSIC*************



  ;square
  lda next_note
  beq skip_next_note
  ldy pattern_offset
  cpy #16
  bcc skip_reset_pattern
  ldy #0
  sty pattern_offset
skip_reset_pattern:
  ldx music_square1_pattern1,y
  stx note
  iny
  ldx music_square1_pattern1,y
  iny
  sty pattern_offset
  stx rest_count
  lda #5
  sta note_playing
  dec next_note
skip_next_note:

  lda note_playing 
  beq skip_play_note
  ldx note
  lda periodTableHi,x
  sta $4003
  lda periodTableLo,x
  sta $4002
  lda #%10111111
  sta $4000
  dec note_playing
  bne skip_play_note
  inc resting
  lda #5
  sta rest_timer
skip_play_note:  
  
  lda resting
  beq skip_rest
  lda #%10110000
  sta $4000
  dec rest_timer
  bne skip_rest
  lda #5
  sta rest_timer
  dec rest_count
  bne skip_rest
  sta rest_count
  dec resting
  inc next_note
skip_rest:




  lda next_notet
  beq skip_next_notet
  ldy pattern_offsett
  cpy #26
  bcc skip_reset_patternt
  ldy #0
  sty pattern_offsett
skip_reset_patternt:
  ldx music_triangle_pattern1,y
  stx notet
  iny
  ldx music_triangle_pattern1,y
  iny
  sty pattern_offsett
  stx notet_length
  lda #5
  sta notet_counter
  ldx notet
  lda periodTableHi,x
  sta $400B
  lda periodTableLo,x
  sta $400A
  lda #%11000000
  sta $4008
  sta $4017 
  dec next_notet
skip_next_notet:

  dec notet_counter
  bne next_t
  lda #5
  sta notet_counter
  dec notet_length
  bne next_t
  inc next_notet
next_t:

  jmp end_loop



  .bank 2
  .org $C000
;*********Functions*********************
set_static_frame:
  lda #4
  sta sprite_botr + 1
  lda #3
  sta sprite_botl + 1
  rts

clear_nt:

;ppu clear
  ldx #$20
  lda #$00
  ldy #$AA
 
  stx $2006
  ldx #$00
  stx $2006
  ldx #240
ppu_clear_nametable:
  sta $2007
  sta $2007
  sta $2007
  sta $2007
  dex
  bne ppu_clear_nametable

  ldx #64

ppu_clear_attr_table0:
  sty $2007
  dex
  bne ppu_clear_attr_table0

  lda #$27
  sta $2006
  lda #$C0
  sta $2006


  ldx #64
ppu_clear_attr_table1:
  sty $2007
  dex
  bne ppu_clear_attr_table1

  rts

fill_nt:
  
;draw something
  lda #$23
  sta $2006
  lda #$20
  sta $2006
  ldx #32
  lda #18
draw_loop:
  sta $2007
  dex
  bne draw_loop
  ldx #96
  lda #19
draw_rest_loop:
  sta $2007
  dex
  bne draw_rest_loop
  rts



update_attrib_col:
  lda #%10000100 
  sta $2000 
  lda curr_nt_pos
  beq handle_AT_0_update
  lda #$27
  sta selected_attr_table_high
  jmp finish_attr_high
handle_AT_0_update:
  lda #$23
  sta selected_attr_table_high
finish_attr_high:
  ldx #0
  lda current_position_low
  lsr a
  lsr a
  clc
  adc #$C0
  tay
attr_column_loop:
  lda selected_attr_table_high
  sta $2006
  sty $2006
  lda attribqueue,x
  sta $2007
  stx tmp
  txa
  adc #4
  tax
  lda attribqueue,x
  sta $2007 
  tya
  adc #8
  tay
  ldx tmp
  inx
  cpx #9
  bcc attr_column_loop
  lda #2
  sta do_an_update
  rts


update_edge:
  lda #%10000100 
  sta $2000 
  lda current_position_high
  sta $2006
  lda current_position_low
  sta $2006
  ldx #30
  lda #$10
update_edge_loop:
  sta $2007
  dex
  bne update_edge_loop
  
  lda current_position_high
  sta $2006
  lda current_position_low
  clc
  adc #1
  sta current_position_low
  sta $2006
  lda #$10
  ldx #30

update_edge_loop2:
  sta $2007
  dex
  bne update_edge_loop2
  

  dec do_an_update
  rts




checks:
;update scroll position

  lda current_position_low
  clc
  adc #1
  sta current_position_low
  cmp #32
  bcc skip_update_high_position
  lda #$00
  sta current_position_low
  lda curr_nt_pos
  beq handle_0
  dec curr_nt_pos
  lda #$20 
  sta current_position_high
  jmp skip_update_high_position
handle_0:
  lda #$24
  sta current_position_high
  inc curr_nt_pos
skip_update_high_position:




  rts




;***Data********************************
;metatiles
space:    .db $00,$00,$00,$00
block:    .db $13,$13,$13,$13

;objects
;0, pit
;
;
;
;


level_1:
  .db %00000000,$AE
  .db %10000000,$BE

level_2:

  .bank 3
  .org $E000
palette: .db $0F,$17,$28,$39,  $0F,$30,$07,$36,  $0F,$17,$28,$39,  $0F,$17,$28,$39
         .db $0F,$30,$07,$36,  $0F,$17,$28,$39,  $0F,$17,$28,$39,  $0F,$17,$28,$39

regs:
        .db $30,$08,$00,$00
        .db $30,$08,$00,$00
        .db $80,$00,$00,$00
        .db $30,$00,$00,$00
        .db $00,$00,$00,$00

periodTableLo:
  .db $f1,$7f,$13,$ad,$4d,$f3,$9d,$4c,$00,$b8,$74,$34
  .db $f8,$bf,$89,$56,$26,$f9,$ce,$a6,$80,$5c,$3a,$1a
  .db $fb,$df,$c4,$ab,$93,$7c,$67,$52,$3f,$2d,$1c,$0c
  .db $fd,$ef,$e1,$d5,$c9,$bd,$b3,$a9,$9f,$96,$8e,$86
  .db $7e,$77,$70,$6a,$64,$5e,$59,$54,$4f,$4b,$46,$42
  .db $3f,$3b,$38,$34,$31,$2f,$2c,$29,$27,$25,$23,$21
  .db $1f,$1d,$1b,$1a,$18,$17,$15,$14

periodTableHi:
  .db $07,$07,$07,$06,$06,$05,$05,$05,$05,$04,$04,$04
  .db $03,$03,$03,$03,$03,$02,$02,$02,$02,$02,$02,$02
  .db $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
  .db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .db $00,$00,$00,$00,$00,$00,$00,$00


;music pattern tables
square1:
  .dw music_square1_pattern1
  .dw music_square1_pattern1

;pitch,length
music_square1_pattern1:
  .db 31, 4
  .db 31, 4
  .db 34, 2
  .db 35, 2

  .db 31, 4
  .db 31, 4
  .db 29, 2
  .db 30, 2

music_triangle_pattern1:
  .db 31,10
  .db 29,6
  .db 31,10
  .db 34,6
  .db 31,10
  .db 29,6
  .db 31,1
  .db 32,1
  .db 34,3
  .db 31,1
  .db 32,1
  .db 34,3
  .db 32,6

;**********CHR**************************
  .bank 4
  .org $0000
  .incbin "game.chr"




