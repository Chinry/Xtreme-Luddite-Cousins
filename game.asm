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
tmp: .db 0
tmp2: .db 0
tmp3: .db 0
tmp4: .db 0
tmp5: .db 0
tmp6: .db 0
tmp7: .db 0

jump_pointer: .db 0,0

collision_lookup_pointer: .db 0,0


object_rom_address_low: .db 0 ; indirect addressing for drawing update every (screen)
object_rom_address_high: .db 0 ; indirect addressing for drawing update every (screen)
                               ; index address to get the object

renderqueue: .db 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0, 0,0
             .db 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0, 0,0,0,0, 0,0

attribqueue: .db 0,0,0,0,0,0,0,0





;****RAM********************************
  .org $0200 
sprite_topl: .db 0,0,0,0
sprite_topr: .db 0,0,0,0
sprite_botl: .db 0,0,0,0
sprite_botr: .db 0,0,0,0

;48
jimbosprites: .db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

;40
robosprites: .db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0





  .org $0300 
playerx: .db 0
playery: .db 0
velocity: .db 0
vel_neg: .db 0
vel_y: .db 0
vel_y_high: .db 0
jumping: .db 0 ;bool






ppu_scroll: .db 0 ;location of the ppu scroll
current_position_high: .db 0 ;current nametable
current_position_low: .db 0  ;position in the name table
curr_nt_pos: .db 0  ;current name table of the updater ;bool
character_nt: .db 0 ;current name table of the scroll ;bool
hit_end: .db 0 ;if the updater is up to the player
do_an_update: .db 0 ;update attribute table
selected_attr_table_high: .db 0 ;tmp
scroll_counter: .db 0 ;counts up until a complete 16 scroll

ticks: .db 0
velhigh: .db 0
nmis: .db 0
curr_keys: .db 0
last_keys: .db 0
count: .db 0


;loading level
next_level: .db 0 ;bool
current_level: .db 0
first_screen: .db 0
is_next_screen_object: .db 0


;object_drawing

;screen is 1 name table wide


nothing: .db 0 ;bool
object_coord_queue: .db 0,0,0,0,0,0,0,0,0,0,0 ;checks the x for current draw
object_id_queue: .db 0,0,0,0,0,0,0,0,0,0,0 ;lookup the object to draw
num_objects: .db 0



;collision

collision_table: .db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    
;                          type,location
collision_side_top:       .db 0,0
collision_side_bottom:    .db 0,0 
collision_vertical_left:  .db 0,0
collision_vertical_right: .db 0,0

playerxtmp: .db 0
playerytmp: .db 0

location_nt: .db 0



;music
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

;sound effects
sound_effect_note: .db 0




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




  lda #0
  ldx #8
clear_attribqueue_loop:
  dex
  sta attribqueue,x
  bne clear_attribqueue_loop


  ldx #60
clear_renderqueue_loop:
  dex
  sta renderqueue,x
  bne clear_renderqueue_loop

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

  

  jsr init_nt0_collision



  ;clear and fill the name table
  jsr clear_nt
  lda #$23
  sta $2006
  lda #$20
  sta $2006
  jsr fill_nt
  lda #$27
  sta $2006
  lda #$20
  sta $2006
  jsr fill_nt



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
  lda #%10001000
  sta $2000
  lda #1
  sta nothing
  jsr nothing_write  
  jsr nothing_write  

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
  sta velocity
  sta vel_neg
  sta velhigh
  sta jumping
  sta count
  sta vel_y
  sta location_nt
  sta num_objects 
  sta ppu_scroll
  sta current_position_low
  sta scroll_counter
  sta current_level
  sta hit_end
  lda #$24
  sta current_position_high
  lda #1
  sta first_screen
  sta next_level
  sta nothing
  sta curr_nt_pos
  sta next_note
  sta next_notet
  lda #$AF
  sta playery
  lda #2
  sta do_an_update
  lda #20 
  sta playerx




  lda #%10001100 
  sta $2000 
  
;init sprites for enemies
  
  ldx #48
  stx <tmp
load_jimbo_sprites_loop:
  dec <tmp
  ldy <tmp
  
  bne load_jimbo_sprites_loop




  ldx #40
  stx <tmp
load_robo_sprites_loop  
  dec <tmp
  lda <tmp
  bne load_robo_sprites_loop



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
  lda #%10001100
  stx $2005
  stx $2005
  sta $2000
  lda #%00011110
  sta $2001
  



  



;attribute table update or edge update
 



  ;lda count
  ;clc
  ;adc #1
  ;sta count
  ;bne do_not_update_edge
  lda hit_end
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
  lda #%10001101
  sta $2000 
  jmp end_nm_select
nm_select_0:
  lda #%10001100 
  sta $2000 
end_nm_select:
  lda ppu_scroll
  sta $2005
  lda #0
  sta $2005

;**************************************
  lda next_level
  beq skip_level_load 
  jsr load_next_level
skip_level_load:





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
  lda last_keys
  and #%10000000
  bne skip_set_jumping
  inc jumping
  lda #20
  sta vel_y
skip_set_jumping:




;increment velocity
  lda curr_keys
  ror a
  bcc skip_move_right
  lda velocity
  bne init_velocity
  adc #10
init_velocity:
  clc
  adc #3
  bvs skip_move_right
  sta velocity
  jmp skip_move_left
skip_move_right:
  ror a
  bcc skip_move_left
  lda velocity
  bne init_velocity2
  sbc #10
init_velocity2:
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
  bpl positive_velocity
  eor #$FF
  clc
  adc #1
  lsr a
  lsr a
  lsr a
  lsr a
  sta velhigh
  jmp end_velocity_start
positive_velocity:
  lsr a
  lsr a
  lsr a
  lsr a
  sta velhigh
end_velocity_start:








;handle y velocity
  lda jumping
  beq skip_reset_jump
  jsr airtime
  lda jumping
  
skip_reset_jump:


  jsr check_collision_points_with_bg

  lda jumping
  beq handle_no_jump
  lda vel_y
  bpl move_up
skip_check_positive:
  lda collision_vertical_right
  ora collision_vertical_left 
  beq skip_reset_move_down
  lda playery 
  clc
  and #$F0
  adc #$10
  sta playery
  lda #0
  sta vel_y
  sta jumping
  jmp end_vertical_move
skip_reset_move_down:
  lda playery
  clc 
  adc vel_y_high
  sta playery
  jmp end_vertical_move
move_up:
  lda collision_vertical_right
  ora collision_vertical_left 
  beq skip_reset_move_up
  lda playery
  and #$F0
  sbc #$01
  sta playery
  lda #0
  sta vel_y
  jmp end_vertical_move
skip_reset_move_up:
  lda playery
  clc 
  sbc vel_y_high
  sta playery
  jmp end_vertical_move
handle_no_jump:
  lda collision_vertical_right
  ora collision_vertical_left 
  bne end_vertical_move
  lda #1
  sta jumping 
  lda #0
  sta vel_y
end_vertical_move:





;horizontal movement





  lda velocity
  bpl movement_positive

 ; lda collision_side_top
 ; ora collision_side_bottom
 ; bne skip_dec_x
  lda playerx
  clc
  sbc velhigh
  cmp #245
  bcc skip_stop_at_left
  lda #2
  sta playerx
  lda #0
  sta velocity
  jmp finish_velocity
skip_stop_at_left:
  sta playerx
  jmp finish_velocity
skip_dec_x:
  lda playerx
  sbc velhigh
  and #$F0
  adc #$11
  sta playerx
  lda #0
  sta velocity
  jmp finish_velocity
  
  movement_positive:
 ; lda collision_side_top
 ; ora collision_side_bottom
 ; bne skip_move_to_right
  ldx playerx
  cpx #128
  bcc inc_playerx_location
  clc
  lda velhigh
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
  lda velhigh
  adc playerx
  sta playerx
  jmp finish_velocity
skip_move_to_right: 


finish_velocity:








;game logic

  lda do_an_update
  beq skip_edge_write
  lda hit_end
  bne skip_edge_write
  jsr check_object_list 
skip_edge_write:
  









  





;reset nothing
  lda #1
  sta nothing





  





;update the updater
  ;lda count
  ;bne skipo
  lda hit_end
  bne skipo
  lda do_an_update
  beq skipo
  jsr checks
skipo:






  lda character_nt
  cmp curr_nt_pos
  bne skip_set_hit_end
  ldx ppu_scroll
  stx <tmp
  lda current_position_low
  asl a
  asl a
  asl a
  adc #16
  cmp <tmp
  bcc skip_set_hit_end
  lda #1
  sta hit_end
  lda ppu_scroll
  sta scroll_counter
skip_set_hit_end:

;reset hit_end
  lda scroll_counter
  clc
  sbc ppu_scroll
  bpl positive_scroll_difference
  eor #$FF 
  adc #1
positive_scroll_difference:
  cmp #17
  bcc skip_hit_reset
  lda #0
  sta hit_end
skip_hit_reset:

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
;*********Sub*Routines*********************
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
  lda #%10001100 
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
  stx <tmp
  txa
  adc #4
  tax
  lda attribqueue,x
  sta $2007 
  tya
  adc #8
  tay
  ldx <tmp
  inx
  cpx #8
  bcc attr_column_loop
  lda #2
  sta do_an_update
  rts


update_edge:
  lda #%10001100 
  sta $2000 
  lda current_position_high
  sta $2006
  lda current_position_low
  sta $2006
  ldx #15
  ldy #$00

 
  jsr update_edge_loop

  lda current_position_high
  sta $2006
  lda current_position_low
  clc
  adc #1
  sta current_position_low
  sta $2006
  ldy #$02
  ldx #15
  jsr update_edge_loop

  dec do_an_update
  rts


update_edge_loop:
  lda renderqueue,y
  sta $2007
  iny
  lda renderqueue,y
  sta $2007
  iny
  iny
  iny
  dex
  bne update_edge_loop

  rts




checks:
;update the updater 
  lda current_position_low
  clc
  adc #1
  sta current_position_low
  cmp #32
  bcc skip_update_high_position
  jsr read_next_screen_objects
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



;x is tile number
;y is memory offset in the buffer writing to
draw_metatile:
  sty <tmp4
  lda #0
  sta <tmp


;value = (bottomright << 6) | (bottomleft << 4) | (topright << 2) | (topleft << 0)
  tya
  lsr a
  lsr a
  tay
  and #$01
  beq skip_inc_to_bot
  lda #2
  sta <tmp
skip_inc_to_bot:
  lda #2    
  and current_position_low
  beq skip_inc_to_right
  inc <tmp 
skip_inc_to_right:
  tya
  lsr a
  tay
  lda tmp
  beq skip_shift_loop
  lda metaattributes,x
shift_by_counter_loop:
  asl a 
  asl a 
  dec <tmp
  bne shift_by_counter_loop
  jmp skip_load 
skip_shift_loop:
  lda metaattributes,x
skip_load:
  clc
  ora attribqueue,y
  sta attribqueue,y
 




  






  ldy <tmp4
  tya
  ;divide by 4 then multiply by 16
  asl a
  asl a
  sta <tmp3
  lda current_position_low
  lsr a
  clc
  adc <tmp3
  tay
  lda collision_tiles,x
  sta <tmp
  lda curr_nt_pos
  bne skip_nt_0
  lda #$F0
  jmp skip_other_bit_mask
skip_nt_0:
  asl <tmp
  asl <tmp
  asl <tmp
  asl <tmp
  lda #$0F
skip_other_bit_mask:
  and collision_table,y
  ora <tmp
  sta collision_table,y









  stx <tmp3
  txa
  asl a
  asl a
  tax
  lda #4
  sta <tmp
  ldy <tmp4
fill_render_queue_loop:
  lda metatiles,x
  sta renderqueue,y
  iny
  inx
  dec <tmp
  bne fill_render_queue_loop
  ldx <tmp3
  rts
 

  load_next_level:
;load the lookups
  lda current_level 
  asl current_level
  tax
  lda level_lookup_table,x
  sta object_rom_address_low
  inx
  lda level_lookup_table,x
  sta object_rom_address_high
  inc current_level
  dec next_level
;reset_variables 

  jsr read_next_screen_objects
  rts
  

read_next_screen_objects:
  ldy #0
  sty num_objects
  load_objects_loop:
  ldy #1
  sty is_next_screen_object
  lda [object_rom_address_low],y
  ldy num_objects
  sta object_coord_queue,y
  ldy #0
  lda [object_rom_address_low],y
  tax
  and #%01111111
  ldy num_objects
  sta object_id_queue,y
  clc
  lda object_rom_address_low
  adc #2
  sta object_rom_address_low
  lda object_rom_address_high
  adc #0
  sta object_rom_address_high
  inc num_objects
  txa
  and #%10000000
  beq load_objects_loop
  rts



check_object_list:
  ldx num_objects   
  bne skip_jump_hop
  jmp skip_draw_nothing
skip_jump_hop:
  dex
object_check_loop:
  lda object_coord_queue,x
  and #%11110000
  lsr a
  lsr a
  lsr a
  lsr a
  sta <tmp6
  lda current_position_low
  lsr a
  cmp <tmp6
  bne skip_draw_object_in_queue
  lda object_coord_queue,x
  and #$0F
  asl a
  asl a
  sta <tmp6
  lda object_id_queue,x
  asl a
  tay
  lda drawing_procedure_lookup,y
  sta jump_pointer
  iny
  lda drawing_procedure_lookup,y
  sta jump_pointer + 1
  stx <tmp5
  ldy <tmp6
  jmp [jump_pointer]
return_from_draw:
  ldx <tmp5
skip_draw_object_in_queue:
  
  dex
  bpl object_check_loop
  lda nothing
  beq skip_draw_nothing
  jsr nothing_write
skip_draw_nothing:
  rts



draw_pit:
  ldy #0
  ldx #0
  lda #15
  sta <tmp2
draw_pit_loop:
  jsr draw_metatile
  dec <tmp2
  bne draw_pit_loop
  lda #0
  sta nothing
  jmp return_from_draw


draw_block:
  tya
  pha
  jsr nothing_write
  pla
  tay
  ldx #2
  jsr draw_metatile
  lda #0
  sta nothing
  jmp return_from_draw


draw_jimbo:
  inc num_jimbos





;default screen
nothing_write:
  lda nothing
  beq skip_default_draw
  lda #11
  sta <tmp2
  ldx #0
  ldy #0
write_blank_loop:
  jsr draw_metatile 
  dec <tmp2
  bne write_blank_loop
  ldx #1
  jsr draw_metatile
  ldx #2
  jsr draw_metatile
  jsr draw_metatile
  jsr draw_metatile
skip_default_draw:
  rts






init_nt0_collision:
  ldx #192
  lda #0
load_pass_collision_loop:
  dex
  sta collision_table,x
  bne load_pass_collision_loop
  lda #1
  ldy #48
  ldx #191
load_solid_collision_loop:
  inx
  sta collision_table,x
  dey 
  bne load_solid_collision_loop
  rts



airtime:
  lda vel_y
  bpl skip_neg_y_vel
  eor #$FF 
  clc
  adc #1
  lsr a
  sta vel_y_high
  rts
skip_neg_y_vel:
  lsr a
  sta vel_y_high
  rts

check_collision_points_with_bg:
;check below or above
  jsr find_location_nt
  lda jumping
  beq handle_zero
  lda vel_y
  bpl handle_above
  jsr handle_below_routine
  jmp end_vertical_collision
handle_zero:
  jsr handle_zero_routine
  jmp end_vertical_collision
handle_above:
  jsr handle_above_routine
end_vertical_collision:

;check left and right
  
  lda velocity
  beq end_horizontal_collision
  bpl handle_right
  jsr handle_left_routine
  jmp end_horizontal_collision
handle_right:
  jsr handle_right_routine
end_horizontal_collision:


  rts

handle_right_routine:
  lda playery
  sta playerytmp
  lda playerx
  adc #13
  adc ppu_scroll
  adc velhigh
  sta playerxtmp
  jsr create_collision_lookup
  sta collision_side_top + 1
  tax
  lda collision_table,x
  jsr perform_nt_change
  sta collision_side_top
  lda playerytmp
  adc #$08
  sta playerytmp
  jsr create_collision_lookup
  sta collision_side_bottom + 1
  tax
  lda collision_table,x
  jsr perform_nt_change
  sta collision_side_bottom
  rts

handle_left_routine:
  lda playery
  sta playerytmp
  lda playerx
  adc #3
  sbc #$10
  adc ppu_scroll
  sbc velhigh
  sta playerxtmp
  jsr create_collision_lookup
  sta collision_side_top + 1
  tax
  lda collision_table,x
  jsr perform_nt_change
  sta collision_side_top
  lda playerytmp
  adc #$08
  sta playerytmp
  jsr create_collision_lookup
  sta collision_side_bottom + 1
  tax
  lda collision_table,x
  jsr perform_nt_change
  sta collision_side_bottom
  rts




handle_below_routine:
  lda playery
  adc vel_y_high
  adc #16
  sta playerytmp
  lda playerx
  adc #3
  sbc #$10
  sta playerxtmp
  jsr create_collision_lookup
  sta collision_vertical_left + 1
  tax
  lda collision_table,x
  jsr perform_nt_change
  sta collision_vertical_left
  lda playerxtmp
  adc #10
  sta playerxtmp
  jsr create_collision_lookup
  sta collision_vertical_right + 1
  tax
  lda collision_table,x
  jsr perform_nt_change
  sta collision_vertical_right
  rts



handle_above_routine:
  lda playery
  sbc vel_y_high
  sta playerytmp
  lda playerx
  adc #3
  sbc #$10
  sta playerxtmp
  jsr create_collision_lookup
  sta collision_vertical_left + 1
  tax
  lda collision_table,x
  jsr perform_nt_change
  sta collision_vertical_left
  lda playerxtmp
  adc #10
  sta playerxtmp
  jsr create_collision_lookup
  sta collision_vertical_right + 1
  tax
  lda collision_table,x
  jsr perform_nt_change
  sta collision_vertical_right
  rts


handle_zero_routine:
  lda playery
  adc #18
  sta playerytmp
  lda playerx
  adc #3
  sbc #$10
  sta playerxtmp
  jsr create_collision_lookup
  sta collision_vertical_left + 1
  tax
  lda collision_table,x
  jsr perform_nt_change
  sta collision_vertical_left
  lda playerxtmp
  adc #10
  sta playerxtmp
  jsr create_collision_lookup
  sta collision_vertical_right + 1
  tax
  lda collision_table,x
  jsr perform_nt_change
  sta collision_vertical_right
  rts







create_collision_lookup:
  lda playerytmp
  clc
  and #$F0
  sta <tmp2
  lda playerxtmp
  clc
  adc ppu_scroll
  clc
  adc #3
  lsr a
  lsr a
  lsr a
  lsr a
  clc
  ora <tmp2
  sta <tmp2
  clc
  rts

perform_nt_change:
  ldy location_nt
  bne nt_1_op
  and #$0F
  jmp skip_nt_1_op
nt_1_op:
  lsr a
  lsr a
  lsr a
  lsr a
  clc
skip_nt_1_op:
  rts

 
 
find_location_nt:
  clc
  lda ppu_scroll
  ldy velocity
  bpl positive_addition
  sbc velhigh
  adc playerx
  bcs Eyore
  jmp finish_add_velocity
positive_addition:
  adc velhigh
  bcs Eyore
  adc playerx
  bcs Eyore
finish_add_velocity: 
end_find_location
  lda character_nt
  sta location_nt
  rts


 
Eyore:
  lda character_nt
  eor #$01
  sta location_nt
  rts






;***Data********************************
metatiles:
;top left , bot left, top right, bot right, pallete
;                                        metatilenumber
space:    .db $00,$00,$00,$00  ;     0 
grass:    .db $00,$18,$00,$1A ;     1
block:    .db $1C,$19,$1D,$1B  ;     2


metaattributes:
spaceattr:    .db $00 ;0
groundattr:   .db $01 ;1
blockattr:    .db $01 ;2



collision_tiles:
spacecoll:  .db $00 ;0
groundcoll:     .db $00 ;1
blockcoll:      .db $01 ;2






;  nttttttt xxxxyyyy
;  |||||||| ||||++++- Y position within a screen
;  |||||||| ++++----- X position within a screen
;  |+++++++---------- Object type
;  +----------------- Next screen flag, moves to encoding the next screen if 1



;objects
;0, pit
;1, block
;2, block row
;3, block col
;127, level end


level_1:
  .db %00000001,$69
  .db %00000001,$6A
  .db %00000000,$FE
  .db %10000001,$5A
  .db %00000001,$4C
  .db %00000001,$5B
  .db %00000001,$6A
  .db %00000001,$79
  .db %00000001,$88
  .db %10000000,$FE
  .db %00000000,$FE
  .db %10000001,$6B
  .db %00000000,$FE
  .db %10000001,$6A
  .db %00000000,$FE
  .db %10000001,$6A
  .db %00000000,$FE
  .db %10000001,$6A
  .db %00000000,$FE
  .db %10000001,$6A
  .db %00000000,$FE
  .db %10000001,$69
  .db %00000000,$FE
  .db %10000001,$69
  .db %00000000,$FE
  .db %10000001,$69
  .db %00000000,$FE
  .db %10000001,$69
  .db %00000000,$FE
  .db %10000001,$69
  .db %00000000,$FE
  .db %10000001,$69
  .db %00000000,$FE
  .db %10000001,$69
  .db %00000000,$8E
  .db %00000000,$7E
  .db %00000000,$6E
  .db %00000000,$5E
  .db %00000000,$4E
  .db %00000001,$5A
  .db %10000000,$8E
  .db %00000000,$8E
  .db %00000000,$7E
  .db %00000000,$6E
  .db %00000000,$5E
  .db %00000000,$4E
  .db %00000000,$6E
  .db %10000000,$4E
  .db %10000000,$4E
  .db %10000000,$4E
  .db %10000000,$7E
 ; .db %11111111,$6E
level_2:



;level lookup table 
;at the beginning of a level load the offset for the level into the 
;object rom address variable
level_lookup_table:
  .dw level_1
  .dw level_2


drawing_procedure_lookup:
  .dw draw_pit
  .dw draw_block
  .dw draw_jimbo




  .bank 3
  .org $E000
palette: .db $0F,$17,$28,$39,  $0F,$17,$29,$39,  $0F,$17,$28,$39,  $0F,$17,$28,$39
         .db $0F,$30,$07,$36,  $0F,$17,$29,$39,  $0F,$17,$28,$39,  $0F,$17,$28,$39

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




  .inesmir 1 ;mirroring
  .inesmap 0 ;mapper number (no mapper)
  .ineschr 1 ;number of 8kb banks
  .inesprg 2 ;number of 16kb banks

  .bank 3
  .org $FFFA ;stores location interupts (vector table)

  .dw NMI ;Non Maskable interupt
          ;Can be masked at address $2000 bit 7 is clear
