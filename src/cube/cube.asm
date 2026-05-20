; ==============================
; Demo: Cube
; ==============================

;***************************************************************************
; DEFINE SECTION
;***************************************************************************
cube_edge_count EQU     12                      ; 12 edges in a wireframe cube

;***************************************************************************
; CODE SECTION
;***************************************************************************
; ---------------------------------------------------------------------------
; InitCubeDemo
; Placeholder for future cube animation state.
; ---------------------------------------------------------------------------
InitCubeDemo:
                RTS

cube_loop:
                JSR     Wait_Recal              ; Vectrex BIOS recalibration
                JSR     Read_Btns               ; BIOS updates button state RAM
                LDA     Vec_Button_1_2          ; Button 2 returns to main menu
                LBNE    return_to_menu
                JSR     Intensity_5F            ; BIOS beam intensity for cube
                JSR     DrawCube                ; Draw projected 3D wire cube
                BRA     cube_loop

; ---------------------------------------------------------------------------
; DrawCube
; Draws a static isometric wireframe cube. Each edge stores a start point and
; a line delta in projected 2D coordinates: start Y, start X, delta Y, delta X.
; ---------------------------------------------------------------------------
DrawCube:
                JSR     DP_to_D0                ; Restore DP for VIA/BIOS draw
                LDX     #cube_edge_table        ; 3D cube projected as 2D edges
                LDA     #cube_edge_count        ; Edge loop counter

draw_cube_edge:
                PSHS    A                       ; Preserve remaining edge count
                PSHS    X                       ; Preserve edge table pointer
                JSR     Reset0Ref               ; Draw each edge from true origin
                PULS    X
                LDA     ,X+                     ; Edge start Y
                LDB     ,X+                     ; Edge start X
                PSHS    X                       ; Preserve pointer to edge delta
                JSR     Moveto_d_7F             ; BIOS move to edge start
                PULS    X
                LDA     ,X+                     ; Edge delta Y
                LDB     ,X+                     ; Edge delta X
                PSHS    X                       ; Preserve pointer to next edge
                JSR     Draw_Line_d             ; BIOS draw edge from start point
                PULS    X
                PULS    A
                DECA
                BNE     draw_cube_edge
                RTS

;***************************************************************************
; DATA SECTION
;***************************************************************************
cube_edge_table:
                FCB     $20,-$30,$00,$40        ; front top edge
                FCB     $20,$10,-$40,$00        ; front right edge
                FCB     -$20,$10,$00,-$40       ; front bottom edge
                FCB     -$20,-$30,$40,$00       ; front left edge

                FCB     $38,-$18,$00,$40        ; back top edge
                FCB     $38,$28,-$40,$00        ; back right edge
                FCB     -$08,$28,$00,-$40       ; back bottom edge
                FCB     -$08,-$18,$40,$00       ; back left edge

                FCB     $20,-$30,$18,$18        ; top-left depth edge
                FCB     $20,$10,$18,$18         ; top-right depth edge
                FCB     -$20,$10,$18,$18        ; bottom-right depth edge
                FCB     -$20,-$30,$18,$18       ; bottom-left depth edge
