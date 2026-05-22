; this file is part of Release, written by Malban in 2017
;
;***************************************************************************
_DP_TO_C8           MACRO                       ; pretty for optimizing to use a makro :-)
                    LDA     #$C8
                    TFR     A,DP
                    direct  $C8
                    ENDM

;***************************************************************************
_DP_TO_D0           MACRO                       ; pretty for optimizing to use a makro :-)
                    LDA     #$D0
                    TFR     A,DP
                    direct  $D0
                    ENDM

NEG_D               MACRO
                    COMA
                    COMB
                    ADDD    #1
                    ENDM

;***************************************************************************
RESET_VECTOR_BEAM   MACRO
                    LDA     #$CC
                    STA     <VIA_cntl           ;/BLANK low and /ZERO low
                    lda     #$83                ; a = $18, b = $83 disable RAMP, muxsel=false, channel 1 (integrators offsets)
                    clr     <VIA_port_a         ; Clear D/A output
                    sta     <VIA_port_b         ; set mux to channel 1, leave mux disabled
                    dec     <VIA_port_b         ; enable mux, reset integrator offset values
                                                ;nop 4
                    LDA     #$CE
                    STA     <VIA_cntl           ;/BLANK high and /ZERO low
                    inc     <VIA_port_b         ; Disable mux
                    ENDM
;***************************************************************************
_SCALE              macro    value
        LDA     #\1                             ; scale for placing first point
        _SCALE_A
        endm
;***************************************************************************
_SCALE_A            macro
        STA     VIA_t1_cnt_lo                   ; move to time 1 lo, this means scaling
        endm
;***************************************************************************
MY_WAIT_RECAL       macro
        direct  $d0
        LDA     #$20
        ldx     Vec_Loop_Count                  ; recal counter, about 21 Minutes befor roll over
        leax    1,x
        stx     Vec_Loop_Count
        ldb     <VIA_t2_hi
        stb     t2_rest
LF19E\?
        BITA    <VIA_int_flags                  ;Wait for timer t2
        BEQ     LF19E\?
        LDD     #$3075                          ;Store refresh value
        STD     <VIA_t2_lo                      ;into timer t2
        LDD     #$CC
        STB     <VIA_cntl                       ;blank low and zero low
        STA     <VIA_shift_reg                  ;clear shift register
        sta     <VIA_port_a                     ;clear D/A register
        LDD     #$0302
        STA     <VIA_port_b                     ;mux=1, disable mux
        STB     <VIA_port_b                     ;mux=1, enable mux
        LDB     #$01
        STB     <VIA_port_b                     ;disable mux
        endm
MY_WAIT_RECAL2      macro
        direct  $d0
        LDA     #$20
        ldx     Vec_Loop_Count                  ; recal counter, about 21 Minutes befor roll over
        leax    1,x
        stx     Vec_Loop_Count
LF19E\?
        BITA    <VIA_int_flags                  ;Wait for timer t2
        BEQ     LF19E\?
        LDD     #$3075                          ;Store refresh value
        STD     <VIA_t2_lo                      ;into timer t2
        LDD     #$CC
        STB     <VIA_cntl                       ;blank low and zero low
        STA     <VIA_shift_reg                  ;clear shift register
        sta     <VIA_port_a                     ;clear D/A register
        LDD     #$0302
        STA     <VIA_port_b                     ;mux=1, disable mux
        STB     <VIA_port_b                     ;mux=1, enable mux
        LDB     #$01
        STB     <VIA_port_b                     ;disable mux
        endm
;***************************************************************************
_ZERO_VECTOR_BEAM   macro
        LDB     #$CC
        STB     VIA_cntl                        ;/BLANK low and /ZERO low
        endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; macro D = D *2
MY_LSL_D            macro
        ASLB
        ROLA
        endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; macro D = D /2
MY_LSR_D            macro
        ASRA
        RORB
        endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; "random" Galois LFSR
RANDOM_A            macro
        lda     random_seed
        lsra
        bcc     @noEOR
        eora    #$d4
@noEOR
        sta     random_seed
        endm
RANDOM_B            macro
        ldb     random_seed
        lsrb
        bcc     @noEOR
        eorb    #$d4
@noEOR
        stb     random_seed
        endm
RANDOM_A2           macro
        lda     random_seed2
        lsra
        bcc     @noEOR
        eora    #$d4
@noEOR
        sta     random_seed2
        endm
RANDOM_A2_f         macro
        lda     random_seed2
        asla
        eora    random_seed2
        asla
        eora    random_seed2
        asla
        asla
        eora    random_seed2
        asla
        rol     random_seed2
; hey dissi "pri nt a = #a"
        endm
RANDOM_A_f          macro
        lda     random_seed
        asla
        eora    random_seed
        asla
        eora    random_seed
        asla
        asla
        eora    random_seed
        asla
        rol     random_seed
; hey dissi "pri nt a = #a"
        endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;***************************************************************************
;***************************************************************************
; expect DP = d0
; playes one piece of music, that is given as param
INIT_MUSIC          macro    musicPiece
        ldu     musicPiece                      ; this piece of music
        jSR     PLY_INIT                        ; NOW
        endm

;***************************************************************************
MY_MOVE_TO_D_START_NT macro
        STA     <VIA_port_a
        LDA     #$CE                            ;Blank low, zero high?
        STA     <VIA_cntl                       ;
        CLRA
        STA     <VIA_port_b                     ;Enable mux
        STA     <VIA_shift_reg                  ;Clear shift regigster
        INC     <VIA_port_b                     ;Disable mux
        STB     <VIA_port_a                     ;Store X in D/A register
        STA     <VIA_t1_cnt_hi                  ;enable timer
        endm
MY_MOVE_TO_D_START  macro
        STA     <VIA_port_a                     ;Store Y in D/A register
        LDA     #$CE                            ;Blank low, zero high?
        STA     <VIA_cntl                       ;
        CLRA
        STA     <VIA_port_b                     ;Enable mux ; hey dis si "break integratorzero 440"
;                    STA      <VIA_shift_reg               ;Clear shift regigster
        INC     <VIA_port_b                     ;Disable mux
        STB     <VIA_port_a                     ;Store X in D/A register
        STA     <VIA_t1_cnt_hi                  ;enable timer
        endm
MY_MOVE_TO_A_END    macro
        LDA     #$40                            ;
@LF33D
        BITA    <VIA_int_flags                  ;
        BEQ     @LF33D                          ;
        endm
MY_MOVE_TO_B_END    macro
        LDB     #$40                            ;
@LF33D
        BITB    <VIA_int_flags                  ;
        BEQ     @LF33D                          ;
        endm
MY_MOVE_TO_D_END    macro
        LDB     #$40                            ;
@LF33D
        BITB    <VIA_int_flags                  ;
        BEQ     @LF33D                          ;
        endm
MY_MOVE_TO_D        macro
; optimzed, tweaked not perfect... 'MOVE TO D' makro
        MY_MOVE_TO_D_START
        MY_MOVE_TO_B_END
        endm
MY_MOVE_TO_D_NT     macro
; optimzed, tweaked not perfect... 'MOVE TO D' makro
        MY_MOVE_TO_D_START_NT
        MY_MOVE_TO_B_END
        endm
;***************************************************************************
_INTENSITY_A_8      macro
        STA     <VIA_port_a                     ;Store intensity in D/A
        LDD     #$8584                          ;mux disabled channel 2
        STA     <VIA_port_b                     ;
        STB     <VIA_port_b                     ;mux enabled channel 2
        STA     <VIA_port_b                     ;turn off mux
        endm
_INTENSITY_A        macro
        STA     <VIA_port_a                     ;Store intensity in D/A
        LDD     #$0504                          ;mux disabled channel 2
        STA     <VIA_port_b                     ;
        STB     <VIA_port_b                     ;mux enabled channel 2
        STA     <VIA_port_b                     ;turn off mux
        endm
_INTENSITY_A_ONLY   macro
        STA     <VIA_port_a                     ;Store intensity in D/A
        LDa     #$05                            ;mux disabled channel 2
        STA     <VIA_port_b                     ;
        deca
        STa     <VIA_port_b                     ;mux enabled channel 2
        inca
        STA     <VIA_port_b                     ;turn off mux
        endm
_INTENSITY_B        macro
        STB     <VIA_port_a                     ;Store intensity in D/A
        LDD     #$0504                          ;mux disabled channel 2
        STA     <VIA_port_b                     ;
        STB     <VIA_port_b                     ;mux enabled channel 2
        STA     <VIA_port_b                     ;turn off mux
        endm
; uses x and d
; prints the numbers in a and b at a location given
; prints in hex
; need 6 bytes RAM starting with tmp_debug
PRINT_NUMBERS_D_AT  macro    _yloc, _xloc
        pshs    d                               ; save the numbers
        lda     #_yloc
        ldb     #_xloc
        jsr     Moveto_d
        lda     ,s
        lsra
        lsra
        lsra
        lsra
        adda    # '0'
        cmpa    # '9'
        ble     ok1\?
        adda    #( 'A'-'0'-10)
ok1\?
        sta     tmp_debug
        lda     ,s
        anda    #$f
        adda    # '0'
        cmpa    # '9'
        ble     ok2\?
        adda    #( 'A'-'0'-10)
ok2\?
        sta     tmp_debug+1
        lda     # ','
        sta     tmp_debug+2
        lda     1,s
        lsra
        lsra
        lsra
        lsra
        adda    # '0'
        cmpa    # '9'
        ble     ok3\?
        adda    #( 'A'-'0'-10)
ok3\?
        sta     tmp_debug+3
        lda     1,s
        anda    #$f
        adda    # '0'
        cmpa    # '9'
        ble     ok4\?
        adda    #( 'A'-'0'-10)
ok4\?
        sta     tmp_debug+4
        lda     #$80
        sta     tmp_debug+5
        ldu     #tmp_debug
        jsr     Print_Str
        _ZERO_VECTOR_BEAM
        puls    d
        endm
;***************************************************************************
QUERY_JOYSTICK_HORIZINTAL macro
queryHW\?
; joytick pot readings are also switched by the (de)muliplexer (analog section)
; with joystick pots the switching is not done in regard of the output (in opposite to "input" switching of integrator logic)
; but with regard to input
; thus, the SEL part of the mux now selects which joystick pot is selected and send to the compare logic.
; mux sel:
;    xxxx x00x: port 0 horizontal
;    xxxx x01x: port 0 vertical
;    xxxx x10x: port 1 horizontal
;    xxxx x11x: port 1 vertical
;
; the result of the pot reading is compared to the
; value present in the dac and according to the comparisson the compare flag of VIA (bit 5 of port b) is set.
; (compare bit is set if contents of dac was "smaller" (signed) than the "pot" read)
DIGITAL_JOYTICK_LOOP_MIN  EQU  $08
; now the same for horizontal
        ldd     #$0100                          ; mux disabled, mux sel = 00 (horizontal pot port 0)
        std     <VIA_port_b
        dec     <VIA_port_b                     ; mux enabled, mux sel = 01
        ldb     #DIGITAL_JOYTICK_LOOP_MIN       ; a wait loop 32 times a loop (waiting for the pots to "read" values, and feed to compare logic)
waitLoopH\?:
        decb                                    ; ...
        bne     waitLoopH\?                     ; wait...
        inc     <VIA_port_b                     ; disable mux
        ldd     #$4020                          ; load a with test value (positive x)
        sta     <VIA_port_a                     ; test value to DAC
        lda     #$01                            ; default result value x was pushed right
        bitb    <VIA_port_b                     ; test comparator
        bne     xReadDone\?                     ; if comparator cleared - joystick was moved right
        neg     <VIA_port_a                     ; "load" with negative value
        nega                                    ; also switch the possible result in A
        bitb    <VIA_port_b                     ; test comparator again
        beq     xReadDone\?                     ; if cleared the joystick was moved left
        clra                                    ; if still not cleared, we clear a as the final vertical test result (no move at all)
xReadDone\?:
        sta     >Vec_Joy_1_X                    ; remember the result in "our" joystick data
        beq     noxmove\?
noxmove\?
        endm
;***************************************************************************
QUERY_JOYSTICK_VERTICAL macro
queryHW\?
; joytick pot readings are also switched by the (de)muliplexer (analog section)
; with joystick pots the switching is not done in regard of the output (in opposite to "input" switching of integrator logic)
; but with regard to input
; thus, the SEL part of the mux now selects which joystick pot is selected and send to the compare logic.
; mux sel:
;    xxxx x00x: port 0 horizontal
;    xxxx x01x: port 0 vertical
;    xxxx x10x: port 1 horizontal
;    xxxx x11x: port 1 vertical
;
; the result of the pot reading is compared to the
; value present in the dac and according to the comparisson the compare flag of VIA (bit 5 of port b) is set.
; (compare bit is set if contents of dac was "smaller" (signed) than the "pot" read)
DIGITAL_JOYTICK_LOOP_MIN  EQU  $08
; now the same for horizontal
        ldd     #$0300                          ; mux disabled, mux sel = 00 (horizontal pot port 0)
        std     <VIA_port_b
        dec     <VIA_port_b                     ; mux enabled, mux sel = 01
        ldb     #DIGITAL_JOYTICK_LOOP_MIN       ; a wait loop 32 times a loop (waiting for the pots to "read" values, and feed to compare logic)
waitLoopH\?:
        decb                                    ; ...
        bne     waitLoopH\?                     ; wait...
        inc     <VIA_port_b                     ; disable mux
        ldd     #$4020                          ; load a with test value (positive x)
        sta     <VIA_port_a                     ; test value to DAC
        lda     #$01                            ; default result value x was pushed right
        bitb    <VIA_port_b                     ; test comparator
        bne     xReadDone\?                     ; if comparator cleared - joystick was moved right
        neg     <VIA_port_a                     ; "load" with negative value
        nega                                    ; also switch the possible result in A
        bitb    <VIA_port_b                     ; test comparator again
        beq     xReadDone\?                     ; if cleared the joystick was moved left
        clra                                    ; if still not cleared, we clear a as the final vertical test result (no move at all)
xReadDone\?:
        sta     >Vec_Joy_1_Y                    ; remember the result in "our" joystick data
        beq     noxmove\?
noxmove\?
        endm
;***************************************************************************
QUERY_JOYSTICK      macro
queryHW\?
; joytick pot readings are also switched by the (de)muliplexer (analog section)
; with joystick pots the switching is not done in regard of the output (in opposite to "input" switching of integrator logic)
; but with regard to input
; thus, the SEL part of the mux now selects which joystick pot is selected and send to the compare logic.
; mux sel:
;    xxxx x00x: port 0 horizontal
;    xxxx x01x: port 0 vertical
;    xxxx x10x: port 1 horizontal
;    xxxx x11x: port 1 vertical
;
; the result of the pot reading is compared to the
; value present in the dac and according to the comparisson the compare flag of VIA (bit 5 of port b) is set.
; (compare bit is set if contents of dac was "smaller" (signed) than the "pot" read)
DIGITAL_JOYTICK_LOOP_MIN  EQU  $08
        ldd     #$0300                          ; mux disabled, mux sel = 01 (vertical pot port 0)
        std     <VIA_port_b
        dec     <VIA_port_b                     ; mux enabled, mux sel = 01
        ldb     #DIGITAL_JOYTICK_LOOP_MIN       ; a wait loop 32 times a loop (waiting for the pots to "read" values, and feed to compare logic)
waitLoopV\?:
        decb                                    ; ...
        bne     waitLoopV\?                     ; wait...
        inc     <VIA_port_b                     ; disable mux
        ldd     #$4020                          ; load a with test value (positive y)
        sta     <VIA_port_a                     ; test value to DAC
        lda     #$01                            ; default result value y was pushed UP
        bitb    <VIA_port_b                     ; test comparator
        bne     yReadDone\?                     ; if comparator cleared - joystick was moved up
        neg     <VIA_port_a                     ; "load" with negative value
        nega                                    ; also switch the possible result in A
        bitb    <VIA_port_b                     ; test comparator again
        beq     yReadDone\?                     ; if cleared the joystick was moved down
        clra                                    ; if still not cleared, we clear a as the final vertical test result (no move at all)
yReadDone\?:
        sta     >Vec_Joy_1_Y                    ; remember the result in "our" joystick data
        beq     noymove\?
        bra     noxmove\?                       ; if y moved I assume no X move

noymove\?
; now the same for horizontal
        ldd     #$0100                          ; mux disabled, mux sel = 00 (horizontal pot port 0)
        std     <VIA_port_b
        dec     <VIA_port_b                     ; mux enabled, mux sel = 01
        ldb     #DIGITAL_JOYTICK_LOOP_MIN       ; a wait loop 32 times a loop (waiting for the pots to "read" values, and feed to compare logic)
waitLoopH\?:
        decb                                    ; ...
        bne     waitLoopH\?                     ; wait...
        inc     <VIA_port_b                     ; disable mux
        ldd     #$4020                          ; load a with test value (positive x)
        sta     <VIA_port_a                     ; test value to DAC
        lda     #$01                            ; default result value x was pushed right
        bitb    <VIA_port_b                     ; test comparator
        bne     xReadDone\?                     ; if comparator cleared - joystick was moved right
        neg     <VIA_port_a                     ; "load" with negative value
        nega                                    ; also switch the possible result in A
        bitb    <VIA_port_b                     ; test comparator again
        beq     xReadDone\?                     ; if cleared the joystick was moved left
        clra                                    ; if still not cleared, we clear a as the final vertical test result (no move at all)
xReadDone\?:
        sta     >Vec_Joy_1_X                    ; remember the result in "our" joystick data
        beq     noxmove\?
noxmove\?
        endm
;***************************************************************************
CALIBRATION_ZERO    macro
        ldb     #$CC
        stb     <VIA_cntl
        ldd     #$8100
        std     <VIA_port_b
        dec     <VIA_port_b
        ldb     >calibrationValue
        lda     #$82
        std     <VIA_port_b
        ldd     #$83FF
        stb     <VIA_port_a
        sta     <VIA_port_b
        endm
;***************************************************************************
PLAYER_MOVEMENT_MOVE_BLOCK_old macro
;;;;;;
;;;;;;
; THIS BLOCK CAN BE HANDLED IN SOME MOVE
;;;;;;
; this whole block does the player movement according to current joystick data
; the testing whether the end of the screen is reached seems dumb - can I do that better?
        ldb     Vec_Joy_1_X
        beq     noPlayerMovement\?
        bmi     leftPlayerMovement\?
rightPlayerMovement\?
        ldd     playerXpos                      ; half a pixel per "move"
        bpl     rightWasPositive\?
        addd    playerSpeed
        std     playerXpos
        bra     playerMovementDone\?

rightWasPositive\?
        addd    playerSpeed
        bmi     playerMovementDone\?
        std     playerXpos
        bra     noPlayerMovement\?

leftPlayerMovement\?
        ldd     playerXpos                      ; half a pixel per "move"
        bmi     leftWasNegative\?
        subd    playerSpeed
        std     playerXpos
        bra     playerMovementDone\?

leftWasNegative\?
        subd    playerSpeed
        bpl     playerMovementDone\?
        std     playerXpos
playerMovementDone\?
noPlayerMovement\?
        endm
;***************************************************************************
PLAYER_MOVEMENT_MOVE_BLOCK macro
;;;;;;
;;;;;;
; THIS BLOCK CAN BE HANDLED IN SOME MOVE
;;;;;;
; this whole block does the player movement according to current joystick data
; the testing whether the end of the screen is reached seems dumb - can I do that better?
        ldb     Vec_Joy_1_X
        beq     noPlayerMovement\?
        bmi     leftPlayerMovement\?
rightPlayerMovement\?
        ldd     playerXpos                      ; half a pixel per "move"
        addd    playerSpeed
        cmpd    #$68ff
        bgt     playerMovementDone\?
        std     playerXpos
        bra     playerMovementDone\?

leftPlayerMovement\?
        ldd     playerXpos                      ; half a pixel per "move"
        subd    playerSpeed
        cmpd    #$9a00
        blt     playerMovementDone\?
        std     playerXpos
playerMovementDone\?
noPlayerMovement\?
        endm
;***************************************************************************
WAITING_WOBBLE_CHANGES_MOVE_BLOCK macro
;;;;;;
;;;;;;
; THIS BLOCK CAN BE HANDLED IN SOME MOVE
;;;;;;
; do the "wobbling" of enemies in waiting position
        if      NO_WOBBLE = 1
        else
        lda     Vec_Loop_Count+1
        anda    #1
        beq     noWobbleChange\?
        tst     globalPatternWobbleDirection
        bpl     wobbleAdd\?
wobbleDec\?
        dec     globalPatternWobble
        lda     globalPatternWobble
        cmpa    #-16
        bgt     noWobbleChange\?
        inc     globalPatternWobbleDirection
        bra     noWobbleChange\?

wobbleAdd\?
        inc     globalPatternWobble
        lda     globalPatternWobble
        cmpa    #16
        blt     noWobbleChange\?
        dec     globalPatternWobbleDirection
noWobbleChange\?
        endif
        endm
;***************************************************************************
; reg u can be used!
ADD_POINTS_ENEMY_DESTROY macro
        ldy     #player_score
        ldb     #100
        ldu     #back\?
        jmp     addScore_b

back\?
        endm
;***************************************************************************
ADD_POINTS_BONUS_COMPLETE macro
        ldy     #player_score
        ldb     #200
        ldu     #back\?
        jmp     addScore_b

back\?
        endm
;***************************************************************************
ADD_POINTS_DOUBLE_LETTER macro
        ldy     #player_score
        ldb     #250
        ldu     #back\?
        jmp     addScore_b

back\?
        endm
;***************************************************************************
ADD_CASH            macro    amount
        ldd     playerCashW
        addd    #amount
        std     playerCashW
back\?
        endm
;***************************************************************************
ADD_SHOT            macro
        ldd     playerShotCountW
        addd    #1
        std     playerShotCountW
        endm
;***************************************************************************
ADD_HIT             macro
        ldd     playerHitCountW
        addd    #1
        std     playerHitCountW
        endm
;***************************************************************************
CHECK_MINY_LOAD_A   macro
        lda     Y_POS+u_offset1,s
        cmpa    enemyMINY
        bge     noNewMin\?
        sta     enemyMINY
noNewMin\?
        endm
;***************************************************************************
CHECK_MINY_A        macro
        cmpa    enemyMINY
        bge     noNewMin\?
        sta     enemyMINY
noNewMin\?
        endm
;***************************************************************************
INIT_SHOT_TEST      macro    testBase
        if      SHOW_COORDINATES = 1
        else
        cmpu    #OBJECT_LIST_COMPARE_ADDRESS
        bhi     godShotHere\?
        ldd     #0
        std     testBase
        bra     endm\?

godShotHere\?
; ldd ,u
; cmpd #lazerPlayerShotBehaviour
; bne normalShot\?
; ldd #-1
; std testBase
; bra      endm\?
;normalShot\?
        stu     testBase+SHOT_ORG
        ldd     Y_POS,u
        sta     testBase+T_YPOS
        lda     SHOT_RADIUS ,u
        bne     shotIsAlive1\?
        lda     #SHOT_RADIUS1
shotIsAlive1\?
        cmpa    #SHOT_RADIUS1
        bne     not1Shot\?
        adda    #2
        bra     shotdone\?

not1Shot\?
        cmpa    #SHOT_RADIUS2
        bne     not2Shot\?
        suba    #2
        bra     shotdone\?

not2Shot\?
        cmpa    #SHOT_RADIUS3
        bne     not3Shot\?
        if      USE_NEW_SHOTS = 1
        suba    #2
        else
        suba    #4
        endif
        bra     shotdone\?

not3Shot\?
        cmpa    #SHOT_RADIUS5
        bne     not5Shot\?
        adda    #2                              ; same a 1
        bra     shotdone\?

not5Shot\?
        cmpa    #SHOT_RADIUS4
        bne     not4Shot\?
        if      USE_NEW_SHOTS = 1
        suba    #2
        else
        suba    #9
        endif
        bra     shotdone\?

not4Shot\?
        cmpa    #SHOT_RADIUS6
        bne     not6Shot\?
        adda    #2
; bra shotdone\?
not6Shot\?
shotdone\?
        sta     tmp3_tmp                        ; tmp 1 is current 1 radius for scoopy check
        addb    #$80                            ; make x 0 based 0 - 255
        stb     tmp2_tmp                        ; tmp2_tmp is zero based shot x position
        subb    tmp3_tmp
        subb    tmp3_tmp
        subb    tmp3_tmp
; in b now 3 radii to the left of zero based shot position
; might be OOB
; therefor check if result is lower than starting position, if no, we are oob
; and take as lowest position "0"
        cmpb    tmp2_tmp
        blo     ok1\?
        ldb     #0
ok1\?
        stb     testBase+T_XPOS0_MINUS_3_RADIUS
        ldb     tmp2_tmp                        ; reload zero based shot x position
        addb    tmp3_tmp
        addb    tmp3_tmp
        addb    tmp3_tmp
; in b now 3 radii to the right of zero based shot position
; might be OOB
; therefor check if result is higher than starting position, if no, we are oob
; and take as highest position "255"
        cmpb    tmp2_tmp
        bhi     ok2\?
        ldb     #255
ok2\?
        stb     testBase+T_XPOS0_PLUS_3_RADIUS
; test for center radii are done
; with scoopy unmodified x radius
; correct it!
; radii must be chose, so that
; no overflow/underflow can occur!
        ldb     tmp2_tmp                        ; reload zero based shot x position
        subb    SHOT_RADIUS ,u
        stb     testBase+T_XPOS0_MINUS_1_RADIUS
        ldb     tmp2_tmp                        ; reload zero based shot x position
        addb    SHOT_RADIUS ,u
        stb     testBase+T_XPOS0_PLUS_1_RADIUS
        endif
endm\?
        endm
;***************************************************************************
INITIALZE_SHOT_TEST_MOVE_BLOCK_1 macro
        ldu     testShot
        cmpu    #OBJECT_LIST_COMPARE_ADDRESS
        bls     startFresh\?
                                                          ; if last time something was hit and
                                                          ; the bullet is still active
                                                          ; do not switch - we probably will hit again!
        tst     explosionSound
        bne     nextShotTestLoaded\?
enemyOutOfBounds\?
        ldu     NEXT_SHOT_OBJECT,u
        cmpu    #OBJECT_LIST_COMPARE_ADDRESS
        blo     startFresh\?
        lda     enemyMINY
        cmpa    Y_POS,u
        bgt     enemyOutOfBounds\?
        bra     nextShotTestLoaded\?

startFresh\?
        ldu     playershotlist_objects_head
nextShotTestLoaded\?
        INIT_SHOT_TEST testShot
        endm
;***************************************************************************
INITIALZE_SHOT_TEST_MOVE_BLOCK_2 macro
        if      NO_2SHOT_TEST = 1
        else
;....
; allways use testShot + 5 for testShot 2
        lda     #5
        clr     tmp3_tmp
        ldu     testShot
loadNextShot2\?
        cmpu    #OBJECT_LIST_COMPARE_ADDRESS
        bls     startFresh2\?
loadNextShot3\?
        ldu     NEXT_SHOT_OBJECT,u
        cmpu    #OBJECT_LIST_COMPARE_ADDRESS
        bhi     nextShotTestLoaded2\?
startFresh2\?
        tst     tmp3_tmp
        bne     nextShotTestLoadedreally\?
        inc     tmp3_tmp
        ldu     playershotlist_objects_head
nextShotTestLoaded2\?
        deca
        bne     loadNextShot2\?
        lda     enemyMINY
        cmpa    Y_POS,u
        blt     nextShotTestLoadedreally\?
        tst     tmp3_tmp
        bne     loadNextShot3\?
nextShotTestLoadedreally\?
        INIT_SHOT_TEST test2Shot
;....
        endif
        lda     #$7f
        sta     enemyMINY
        endm

















;***************************************************************************
SCOOP_INTERVALL_ADD  =       6                  ;7
CORRECTION          =        10
DRAW_SCOOP_HERE     macro
        lda     #3                              ; loop count
        sta     tmp2_tmp
        clra
        suba    Vec_Loop_Count+1
        anda    #$f
        sta     <VIA_t1_cnt_lo
        sta     tmp1_tmp                        ; scale width
anotherScoopLoop\?
        ldd     #$0070                          ; go ++ to next step
; move
        STd     <VIA_port_b                     ;Store Y in D/A register
                                                          ;Enable mux ; hey dis si "break integratorzero 440"
        INC     <VIA_port_b                     ;Disable mux
        ldb     #$38 -CORRECTION                ; intervall add right is only half intervall add up
        STb     <VIA_port_a                     ;Store Y in D/A register
        STA     <VIA_t1_cnt_hi                  ;enable timer
        lda     tmp1_tmp
        sta     <VIA_t1_cnt_lo
        adda    #SCOOP_INTERVALL_ADD
        sta     tmp1_tmp
        MY_MOVE_TO_B_END
        ldd     #$0090                          ; draw go left
; draw
        STa     <VIA_port_a                     ;Store Y in D/A register
        STa     <VIA_port_b                     ;switch to y int, enable mux
        INC     <VIA_port_b                     ;Disable mux
        STb     <VIA_port_a                     ;Store X in D/A register
        ldb     #$FF
        stb     <VIA_shift_reg
        sta     <VIA_t1_cnt_hi
        lda     #SCOOP_INTERVALL_ADD
        sta     <VIA_t1_cnt_lo
        clra
        MY_MOVE_TO_B_END
        sta     <VIA_shift_reg
        ldd     #$0070                          ; go +- to next step
; move
        STd     <VIA_port_b                     ;Store Y in D/A register
                                                          ;Enable mux ; hey dis si "break integratorzero 440"
        INC     <VIA_port_b                     ;Disable mux
        ldb     #-$38+CORRECTION                ; intervall add right is only half intervall add up
        STb     <VIA_port_a                     ;Store Y in D/A register
        STA     <VIA_t1_cnt_hi                  ;enable timer
        lda     tmp1_tmp
        sta     <VIA_t1_cnt_lo
        adda    #SCOOP_INTERVALL_ADD
        sta     tmp1_tmp
        MY_MOVE_TO_B_END
        ldd     #$0070                          ; draw go right
; draw
        STa     <VIA_port_a                     ;Store Y in D/A register
        STa     <VIA_port_b                     ;switch to y int, enable mux
        INC     <VIA_port_b                     ;Disable mux
        STb     <VIA_port_a                     ;Store X in D/A register
        ldb     #$FF
        stb     <VIA_shift_reg
        sta     <VIA_t1_cnt_hi
        lda     #SCOOP_INTERVALL_ADD
        sta     <VIA_t1_cnt_lo
        clra
        MY_MOVE_TO_B_END
        sta     <VIA_shift_reg
        dec     tmp2_tmp
        bne     anotherScoopLoop\?
        endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; draws the fighter (anim) and all that goes with it (armor, shield or scoop)
; only one addition at any given time at once
DRAW_FIGHTER_PREP   macro
        lda     #OBJECT_SCALE
        sta     VIA_t1_cnt_lo
        ldu     #SM_Fighter
        dec     playAnimDelayCounter
        bpl     animCounterFighterOk\?
        lda     #ANIMATION_DELAY
        sta     playAnimDelayCounter
        inc     playerAnim
        lda     playerAnim
        asla
        ldx     a,u
        beq     resetAnim\?
        tfr     x,u
        bra     drawFighter\?

resetAnim\?
        clr     playerAnim
animCounterFighterOk\?
        lda     playerAnim
        asla
        ldu     a,u
drawFighter\?
        MY_MOVE_TO_B_END
        jsr     drawSmart                       ; twice the speed ofdraw synced AND calibrated!
        lda     playerBonusActive
        beq     drawFighterDone\?
        bita    #BITFIELD_ARMOR
        beq     testNext1\?
        ldu     #SM_Armor
        bra     continueDrawFighter\?

testNext1\?
        bita    #BITFIELD_SHIELD
        beq     testNext2\?
        ldu     #SM_Shield
        ldx     playerBonusCounter
        leax    -1,x
        stx     playerBonusCounter              ;
        beq     endBonusShield\?
        cmpx    #100
        bhi     noFlickerShield\?
        lda     Vec_Loop_Count+1
        anda    #1
        beq     drawFighterDone\?
noFlickerShield\?
        bra     continueDrawFighter\?

endBonusShield\?
        clr     playerBonusActive
        bra     continueDrawFighter\?

testNext2\?
        bita    #BITFIELD_SCOOP
        beq     drawFighterDone\?
        ldx     playerBonusCounter
        leax    -1,x
        stx     playerBonusCounter              ; dec playerBonusCounter
        beq     endBonusScoop\?
        cmpx    #100
        bhi     noFlickerScoop\?
        lda     Vec_Loop_Count+1
        anda    #1
        beq     drawFighterDone\?
noFlickerScoop\?
        jsr     draw_scooping
        bra     drawFighterDone\?

endBonusScoop\?
        clr     playerBonusActive
        bra     drawFighterDone\?

continueDrawFighter\?
        lda     playerAnim
        asla
        ldu     a,u
        jsr     drawSmart                       ; twice the speed ofdraw synced AND calibrated!
drawFighterDone\?
; draw cleanup
        LDA     #$CC
        ldb     gameScale
        STA     VIA_cntl                        ;/BLANK low and /ZERO low
        stB     VIA_t1_cnt_lo
        ldd     #0
        std     <VIA_port_b
        endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INIT_PLAYER_EXPLOSION macro
        ldu     #playerExplosionSpace
        lda     #1
        sta     EX_START_SIZE,u                 ; position
        lda     #25
        sta     EX_MAX_SIZE,u                   ; position
        clr     EX_STEP,u                       ; start at 0
        endm
DRAW_VLP            macro
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Draw_VLp\?
        LDD     1,X                             ;Get next coordinate pair
        STA     <VIA_port_a                     ;Send Y to A/D
        CLR     <VIA_port_b                     ;Enable mux
        LDA     ,X                              ;Get pattern byte?
        LEAX    3,X                             ;Advance to next point in list
        INC     <VIA_port_b                     ;Disable mux
        STB     <VIA_port_a                     ;Send X to A/D
        clrb
        STA     <VIA_shift_reg                  ;Store pattern in shift register
        stb     <VIA_t1_cnt_hi                  ;Clear T1H
        tfr     a,a
        tfr     a,a
; brn 0 ; max ten scale
;                NOP                     ;Wait a moment more
        STb     <VIA_shift_reg                  ;Clear shift register (blank output)
        LDA     ,X                              ;Get next pattern byte
        BLE     Draw_VLp\?                      ;Go back if high bit of pattern is set
        endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DO_PLAYER_EXPLOSION macro
; position to explosion
        ldu     #playerExplosionSpace
        ldb     EX_START_SIZE,u                 ; * If the scale factor for the explosion
        cmpb    EX_MAX_SIZE,u                   ; * has not surpassed the max value, then
        lbhs    dyingDone
        addb    #SPEED_ADD                      ;
        stb     EX_START_SIZE,u                 ;
        clra
        sta     <VIA_shift_reg
        ldb     #63 / ANGLE_ADD
        stb     tmp8Count
        ldb     #ANGLE_ROT_ADD                  ;
        if      DO_PLAYER_EXPLOSION_ROTATE = 1
        addb    EX_STEP,u                       ;
        endif
        andb    #%00111111                      ; max 63
        stb     EX_STEP,u                       ;
        stb     tmp8
next_exangle_rot_ob_scale\?
        jsr     getCircleCoordinate
        std     tmp16_pos
        nega
        negb
        std     tmp16_neg
        ldb     playerXpos,u                    ;
        lda     tmp8Count
        mul
        andb    #%00001111
        addb    EX_START_SIZE,u                 ;
        STb     <VIA_t1_cnt_lo
        MY_MOVE_TO_A_END
; get position of dot and move there
        ldd     tmp16_pos
        MY_MOVE_TO_D_START
        adda    playerXpos,u                    ;
        adda    tmp8Count
        anda    #7
        adda    #3
        sta     <VIA_t1_cnt_lo
        lda     playerXpos,u                    ;
        adda    tmp8Count
        anda    #$7
        asla
        ldx     #AnimList
        ldx     a,x
        MY_MOVE_TO_A_END
        DRAW_VLP
; ldb EX_START_SIZE+u_offset1,u    ;
        ldb     playerXpos,u                    ;
        lda     tmp8Count
        mul
        andb    #%00001111
        addb    EX_START_SIZE,u                 ;
        stb     <VIA_t1_cnt_lo
        ldd     tmp16_neg
; return to center of explosion
        MY_MOVE_TO_D_START
        ldb     #ANGLE_ADD
        addb    tmp8
        andb    #%00111111                      ; max 63
        stb     tmp8
        dec     tmp8Count
        lbpl    next_exangle_rot_ob_scale\?
; complete explosion done
        ldb     gameScale
        stB     VIA_t1_cnt_lo
        LDa     #$CC
        STA     VIA_cntl                        ;/BLANK low and /ZERO low
        ldd     #0
        std     <VIA_port_b
        MY_MOVE_TO_A_END

        endm

RESET_LASER         macro
        lda     #$7f
        sta     laserLowestY
        sta     laserLowestYRight
        sta     laserLowestYLeft
        ldd     #0
        std     laserEnemyPointer
        std     laserEnemyPointerRight
        std     laserEnemyPointerLeft
        sta     tmp2_tmp_unique
        sta     laserTag                        ; ensure in enemy display this is 0 (for laser shot inhibitaion)
        endm
RESET_LASER_SMALL   macro
        lda     #$7f
        sta     laserLowestY
        ldd     #0
        std     laserEnemyPointer
        sta     tmp2_tmp_unique
        sta     laserTag                        ; ensure in enemy display this is 0 (for laser shot inhibitaion)
        endm

; .......................................................................................................
;
Draw_VLpMe_split_dot macro

        lda     ,x+
        beq     doMove\?
doDraw\?
        LDD     ,X                              ;Get next coordinate pair
        STA     <VIA_port_a                     ;Send Y to A/D
        clra
        sta     <VIA_port_b                     ;Enable mux
        INC     <VIA_port_b                     ;Disable mux
        STB     <VIA_port_a                     ;Send X to A/D
        DEC     <VIA_shift_reg                  ;Store pattern in shift register
        sta     <VIA_t1_cnt_hi                  ;Clear T1H
        LEAX    2,X                             ;Advance to next point in list
        LDb     #$40                            ;B-reg = T1 interrupt bit
        lda     ,x+
        beq     willMove\?
        bpl     willEnd\?
willDrawAgain\?
LF425_1\?
        BITB    <VIA_int_flags                  ;Wait for T1 to time out
        beq     LF425_1\?


        LDD     ,X                              ;Get next coordinate pair
        STA     <VIA_port_a                     ;Send Y to A/D
        clra
        sta     <VIA_port_b                     ;Enable mux
        INC     <VIA_port_b                     ;Disable mux
        STB     <VIA_port_a                     ;Send X to A/D
        sta     <VIA_t1_cnt_hi                  ;Clear T1H
        LEAX    2,X                             ;Advance to next point in list
        LDb     #$40                            ;B-reg = T1 interrupt bit
        lda     ,x+
        bmi     willDrawAgain\?
        beq     willMove\?
        bpl     willEnd\?

willMove\?
        clra
LF425_2\?
        BITB    <VIA_int_flags                  ;Wait for T1 to time out
        BEQ     LF425_2\?
        sta     <VIA_shift_reg                  ;Clear shift register (blank output)
doMove\?
        LDD     ,X                              ;Get next coordinate pair
        STA     <VIA_port_a                     ;Send Y to A/D
        clra
        sta     <VIA_port_b                     ;Enable mux
        INC     <VIA_port_b                     ;Disable mux
        STB     <VIA_port_a                     ;Send X to A/D
        STA     <VIA_t1_cnt_hi                  ;Clear T1H
        LEAX    2,X                             ;Advance to next point in list
        LDb     #$40                            ;B-reg = T1 interrupt bit
        lda     ,x+
        beq     willMove2\?
        bpl     willEnd\?
willDraw2\?
LF425_3\?
        BITB    <VIA_int_flags                  ;Wait for T1 to time out
        beq     LF425_3\?
        bra     doDraw\?

willMove2\?
LF425_4\?
        BITB    <VIA_int_flags                  ;Wait for T1 to time out
        beq     LF425_4\?
        bra     doMove\?

willEnd\?
LF425_5\?
        BITB    <VIA_int_flags                  ;Wait for T1 to time out
        BEQ     LF425_5\?
        clra
        sta     <VIA_shift_reg                  ;Clear shift register (blank output)
        endm
;
; .......................................................................................................
;
Draw_VLpMe_split    MACRO

        lda     ,x+
        beq     doMove\?
doDraw\?
        LDD     ,X                              ;Get next coordinate pair
        STA     <VIA_port_a                     ;Send Y to A/D
        clra
        sta     <VIA_port_b                     ;Enable mux
        INC     <VIA_port_b                     ;Disable mux
        STB     <VIA_port_a                     ;Send X to A/D
        DEC     <VIA_shift_reg                  ;Store pattern in shift register
        sta     <VIA_t1_cnt_hi                  ;Clear T1H
        LEAX    2,X                             ;Advance to next point in list
        LDb     #$40                            ;B-reg = T1 interrupt bit
        lda     ,x+
        beq     willMove\?
        bpl     willEnd\?
willDrawAgain\?
LF425_1\?
        BITB    <VIA_int_flags                  ;Wait for T1 to time out
        beq     LF425_1\?
        inc     <VIA_shift_reg                  ;Store pattern in shift register


        LDD     ,X                              ;Get next coordinate pair
        STA     <VIA_port_a                     ;Send Y to A/D
        clra
        sta     <VIA_port_b                     ;Enable mux
        INC     <VIA_port_b                     ;Disable mux
        STB     <VIA_port_a                     ;Send X to A/D
        DEC     <VIA_shift_reg                  ;Store pattern in shift register
        sta     <VIA_t1_cnt_hi                  ;Clear T1H
        LEAX    2,X                             ;Advance to next point in list
        LDb     #$40                            ;B-reg = T1 interrupt bit
        lda     ,x+
        bmi     willDrawAgain\?
        beq     willMove\?
        bpl     willEnd\?

willMove\?

LF425_2\?
        BITB    <VIA_int_flags                  ;Wait for T1 to time out
        BEQ     LF425_2\?

doMove\?
        LDD     ,X                              ;Get next coordinate pair
        clr     <VIA_shift_reg                  ;Clear shift register (blank output)
        STA     <VIA_port_a                     ;Send Y to A/D
        clra
        sta     <VIA_port_b                     ;Enable mux
        INC     <VIA_port_b                     ;Disable mux
        STB     <VIA_port_a                     ;Send X to A/D
        STA     <VIA_t1_cnt_hi                  ;Clear T1H
        LEAX    2,X                             ;Advance to next point in list
        LDb     #$40                            ;B-reg = T1 interrupt bit
        lda     ,x+
        beq     willMove2\?
        bpl     willEnd\?
willDraw2\?
LF425_3\?
        BITB    <VIA_int_flags                  ;Wait for T1 to time out
        beq     LF425_3\?
        bra     doDraw\?

willMove2\?
LF425_4\?
        BITB    <VIA_int_flags                  ;Wait for T1 to time out
        beq     LF425_4\?
        bra     doMove\?

willEnd\?
LF425_5\?
        BITB    <VIA_int_flags                  ;Wait for T1 to time out
        BEQ     LF425_5\?

        clra
        sta     <VIA_shift_reg                  ;Clear shift register (blank output)

                ENDM
;
