STAR_OR_DEFINED = 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; new list object to U
; leaves with flags set to result
; (positive = not successfull) ROM
; negative = successfull RAM
; destroys d, u 
newStarObject                                             ;#isfunction  
                    ldu      starlist_empty_head 
                    cmpu     #OBJECT_LIST_COMPARE_ADDRESS 
                    bls      cs_done_star 
                                                          ; set the new empty head 
                    ldd      NEXT_STAR_OBJECT,u           ; the next in out empty list will be the new 
                    std      starlist_empty_head          ; head of our empty list 
                                                          ; load last of current object list 
; the old head is always our next
                    ldd      starlist_objects_head 
                    std      NEXT_STAR_OBJECT,u 
; newobject is always head
                    stu      starlist_objects_head 
                    inc      starCount                    ; and remember that we created a new object 
cs_done_star 
                    rts      

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
spawnStar                                                 ;#isfunction  
                    bsr      newStarObject                ; "create" (or rather get) new object 
                    leax     ,u                           ; pointer to new object now in X also 
                    cmpu     #OBJECT_LIST_COMPARE_ADDRESS 
                    lbls      spawnStar_end 
                                                          ; bpl spawnBonus_end ; if positve - there is no object left, jump out 
; copy and initialze new enemy
                    ldd      #simpleStarBehaviour2 
                    std      BEHAVIOUR,x 
                    RANDOM_A  
                    sta      Y1_POS,x 
                    RANDOM_A  
                    sta      Y2_POS,x 
                    RANDOM_A  
                    sta      Y3_POS,x 
                    RANDOM_A  
                    sta      Y4_POS,x 
                    RANDOM_A  
                    sta      X1_POS,x 
                    anda     #TWINKLE_AND 
 if STAR_OR_DEFINED = 1
                    ora     #TWINKLE_OR 
 endif
 lda #$7f
 RANDOM_A  
 anda #%01111111
 ora #8
                    sta      TWINKLE , x 
                    RANDOM_A  
                    sta      X2_POS,x 
                    RANDOM_A  
                    sta      X3_POS,x 
                    RANDOM_A  
                    sta      X4_POS,x 
spawnStar_end 
                    rts      

;STAR_SHIFT          =        %11100000; $e0 
STAR_SHIFT          =        %01100000; $e0 
STAR_SHIFT          =        %00011110; $e0 
TWINKLE_AND         =        %00111111 
TWINKLE_OR          =        %00001111                    ; lowest twinkle brightness 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_ZERO_VECTOR_BEAM2   macro    
                    sta      <VIA_shift_reg 
                    LDB      #$CC 
                    STB      VIA_cntl                     ;/BLANK low and /ZERO low 
                    endm     

simpleStarBehaviour                                       ;#isfunction  
; 1 ;;;
                    MY_MOVE_TO_D_START  
                    dec      Y1_POS+u_offset1,s 
                    bvc      notBottom1 
                    RANDOM_A  
                    sta      X1_POS+u_offset1,s 
                    anda     #TWINKLE_AND 
 if STAR_OR_DEFINED = 1
                    ora     #TWINKLE_OR 
 endif
                    sta      TWINKLE +u_offset1,s 
notBottom1 
                    lda      TWINKLE+u_offset1,s 
                    MY_MOVE_TO_B_END  

                    _INTENSITY_A  
                    lda      #STAR_SHIFT 
                    _ZERO_VECTOR_BEAM2  
                    ldd      #0 
                    std      <VIA_port_b 
; 2 ;;;
                    ldd      Y2_POS+u_offset1,s 
                    MY_MOVE_TO_D_START  
                    dec      Y2_POS+u_offset1,s 
                    bvc      notBottom2 
                    RANDOM_A  
                    sta      X2_POS+u_offset1,s 
                    anda     #TWINKLE_AND 
 if STAR_OR_DEFINED = 1
                    ora     #TWINKLE_OR 
 endif
                    sta      TWINKLE +u_offset1,s 
notBottom2 
                    lda      #STAR_SHIFT 
                    MY_MOVE_TO_B_END  
                    _ZERO_VECTOR_BEAM2  
                    ldd      #0 
                    std      <VIA_port_b 
; 3 ;;;
                    ldd      Y3_POS+u_offset1,s 
                    MY_MOVE_TO_D_START  
                    dec      Y3_POS+u_offset1,s 
                    bvc      notBottom3 
                    RANDOM_A  
                    sta      X3_POS+u_offset1,s 
                    anda     #TWINKLE_AND 
 if STAR_OR_DEFINED = 1
                    ora     #TWINKLE_OR 
 endif




                    sta      TWINKLE +u_offset1,s 
notBottom3 
                    lda      #STAR_SHIFT 
                    MY_MOVE_TO_B_END  
                    _ZERO_VECTOR_BEAM2  
                    ldd      #0 
                    std      <VIA_port_b 
; 4 ;;;
                    ldd      Y4_POS+u_offset1,s 
                    MY_MOVE_TO_D_START  
                    dec      Y4_POS+u_offset1,s 
                    bvc      notBottom4 
                    RANDOM_A  
                    sta      X4_POS+u_offset1,s 
                    anda     #TWINKLE_AND 
 if STAR_OR_DEFINED = 1
                    ora     #TWINKLE_OR 
 endif
                    sta      TWINKLE +u_offset1,s 
notBottom4 
                    lda      #STAR_SHIFT 
                    MY_MOVE_TO_B_END  
                    _ZERO_VECTOR_BEAM2  
; end 
                    lds      NEXT_STAR_OBJECT+u_offset1,s ; preload next user stack 
; clean up
                    LDa      #$CC 
                    STA      VIA_cntl                     ;/BLANK low and /ZERO low 
                    ldd      #0 
                    std      <VIA_port_b 
                    puls     d,pc                         ; (D = y,x, pc = next object) 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
removeOneStar:                                            ;#isfunction  
                    ldx      starlist_objects_head        ; is it the first? 
was_first_star 
                    ldu      NEXT_STAR_OBJECT,x           ; s pointer to next objext 
                    stu      starlist_objects_head        ; the next object will be the first 
 bra starCleanupDone
was_not_first_star                                        ;        find previous, go thru all objects from first and look where "I" am the next... 
                    ldy      starlist_objects_head        ; start at list head 
try_next_star 
                    cmpx     NEXT_STAR_OBJECT,y           ; am I the next object of the current investigated list element 
                    beq      found_next_switch_star       ; jup -> jump 
                    ldy      NEXT_STAR_OBJECT,y           ; otherwise load the next as new current 
                    bra      try_next_star                ; and search further 

found_next_switch_star 
                    ldu      NEXT_STAR_OBJECT,x           ; we load "our" next object to s 
                    stu      NEXT_STAR_OBJECT,y           ; and store our next in the place of our previous next and thus eleminate ourselfs 
starCleanupDone
                    dec      starCount 
                    ldy      starlist_empty_head          ; set u free, as new free head 
                    sty      NEXT_STAR_OBJECT,x           ; load to u the next linked list element 
                    stx      starlist_empty_head 
                    rts                                   ; (D = y,x) 



; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
simpleStarBehaviour2                                       ;#isfunction  
; 1 ;;;
 lda TWINKLE +u_offset1,s 
 sta <VIA_t1_cnt_lo
 lda Y1_POS+u_offset1,s 
                    MY_MOVE_TO_D_START  
;                    inc      TWINKLE +u_offset1,s 
 lda      TWINKLE +u_offset1,s 
 lsra
 lsra
 lsra
; lsra
 lsra
 bne addyeah
 lda #1
addyeah
 adda TWINKLE +u_offset1,s 
 sta TWINKLE +u_offset1,s 
; lda      TWINKLE +u_offset1,s 
 cmpa #$7f
 blo constar2
 lda #8
 sta TWINKLE +u_offset1,s 
; bne constar2
; lda #$7f
; sta TWINKLE +u_offset1,s 







                    RANDOM_A  
                    sta      Y1_POS+u_offset1,s 
                    RANDOM_A  
                    sta      Y2_POS+u_offset1,s 
                    RANDOM_A  
                    sta      Y3_POS+u_offset1,s 
                    RANDOM_A  
                    sta      Y4_POS+u_offset1,s 
                    RANDOM_A  
                    sta      X1_POS+u_offset1,s 
                    RANDOM_A  
                    sta      X2_POS+u_offset1,s 
                    RANDOM_A  
                    sta      X3_POS+u_offset1,s 
                    RANDOM_A  
                    sta      X4_POS+u_offset1,s 





constar2
                    MY_MOVE_TO_B_END  
 lda #$7f
 suba TWINKLE +u_offset1,s 
 lda TWINKLE +u_offset1,s 
                    _INTENSITY_A  
                    lda      #STAR_SHIFT 
                    _ZERO_VECTOR_BEAM2  
                    ldd      #0 
                    std      <VIA_port_b 
; 2 ;;;
                    ldd      Y2_POS+u_offset1,s 
                    MY_MOVE_TO_D_START  

                    lda      #STAR_SHIFT 
                    MY_MOVE_TO_B_END  
                    _ZERO_VECTOR_BEAM2  
                    ldd      #0 
                    std      <VIA_port_b 
; 3 ;;;
                    ldd      Y3_POS+u_offset1,s 
                    MY_MOVE_TO_D_START  

                    lda      #STAR_SHIFT 
                    MY_MOVE_TO_B_END  
                    _ZERO_VECTOR_BEAM2  
                    ldd      #0 
                    std      <VIA_port_b 
; 4 ;;;
                    ldd      Y4_POS+u_offset1,s 
                    MY_MOVE_TO_D_START  

                    lda      #STAR_SHIFT 
                    MY_MOVE_TO_B_END  
                    _ZERO_VECTOR_BEAM2  
; end 
                    lds      NEXT_STAR_OBJECT+u_offset1,s ; preload next user stack 
; clean up
                    LDa      #$CC 
                    STA      VIA_cntl                     ;/BLANK low and /ZERO low 
                    ldd      #0 
                    std      <VIA_port_b 
                    puls     d,pc                         ; (D = y,x, pc = next object) 

; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
