; ==============================
; Demo: Cube
; ==============================

;***************************************************************************
; DEFINE SECTION
;***************************************************************************
CUBE_EDGE_COUNT EQU     12                      ; 12 edges in a wireframe cube
CUBE_FRAME_COUNT EQU    16                      ; Precomputed rotation steps
CUBE_FRAME_DELAY EQU    6                       ; Frames between rotation steps
CUBE_ANIM_COUNTER EQU   $C910                   ; user RAM: animation divider
CUBE_FRAME_INDEX EQU    $C911                   ; user RAM: current cube angle

;***************************************************************************
; CODE SECTION
;***************************************************************************
; ---------------------------------------------------------------------------
; InitCubeDemo
; Resets the frame divider and starts the cube rotation from the first angle.
; ---------------------------------------------------------------------------
InitCubeDemo:
                LDA     #CUBE_FRAME_DELAY
                STA     CUBE_ANIM_COUNTER
                CLRA
                STA     CUBE_FRAME_INDEX
                RTS

cube_loop:
                JSR     Wait_Recal              ; Vectrex BIOS recalibration
                JSR     Read_Btns               ; BIOS updates button state RAM
                LDA     Vec_Button_1_2          ; Button 2 returns to main menu
                LBNE    return_to_menu
                JSR     UpdateCubeAnimation     ; Advance the projected cube angle
                JSR     Intensity_5F            ; BIOS beam intensity for cube
                JSR     DrawCube                ; Draw projected 3D wire cube
                BRA     cube_loop

; ---------------------------------------------------------------------------
; UpdateCubeAnimation
; Uses a small RAM divider so the cube rotates at a readable speed. The draw
; routine then selects a precomputed projection table for the current angle.
; ---------------------------------------------------------------------------
UpdateCubeAnimation:
                DEC     CUBE_ANIM_COUNTER
                BNE     UpdateCubeAnimationDone
                LDA     #CUBE_FRAME_DELAY
                STA     CUBE_ANIM_COUNTER
                LDA     CUBE_FRAME_INDEX
                INCA
                CMPA    #CUBE_FRAME_COUNT
                BLO     StoreCubeFrame
                CLRA

StoreCubeFrame:
                STA     CUBE_FRAME_INDEX

UpdateCubeAnimationDone:
                RTS

; ---------------------------------------------------------------------------
; DrawCube
; Draws the current wireframe cube frame. Each edge stores a start point and a
; line delta in projected 2D coordinates: start Y, start X, delta Y, delta X.
; ---------------------------------------------------------------------------
DrawCube:
                JSR     DP_to_D0                ; Restore DP for VIA/BIOS draw
                LDA     CUBE_FRAME_INDEX
                ASLA                            ; Word offset in frame pointer table
                LDX     #cube_frame_table
                LEAX    A,X
                LDX     ,X                      ; Projection table for angle
                LDA     #CUBE_EDGE_COUNT        ; Edge loop counter

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
cube_frame_table:
                FDB     CubeFrame0              ; 0 degrees around vertical axis
                FDB     CubeFrame1              ; 22 degrees around vertical axis
                FDB     CubeFrame2              ; 45 degrees around vertical axis
                FDB     CubeFrame3              ; 67 degrees around vertical axis
                FDB     CubeFrame4              ; 90 degrees around vertical axis
                FDB     CubeFrame5              ; 112 degrees around vertical axis
                FDB     CubeFrame6              ; 135 degrees around vertical axis
                FDB     CubeFrame7              ; 157 degrees around vertical axis
                FDB     CubeFrame8              ; 180 degrees around vertical axis
                FDB     CubeFrame9              ; 202 degrees around vertical axis
                FDB     CubeFrame10             ; 225 degrees around vertical axis
                FDB     CubeFrame11             ; 247 degrees around vertical axis
                FDB     CubeFrame12             ; 270 degrees around vertical axis
                FDB     CubeFrame13             ; 292 degrees around vertical axis
                FDB     CubeFrame14             ; 315 degrees around vertical axis
                FDB     CubeFrame15             ; 337 degrees around vertical axis

CubeFrame0:
                FCB     17,-43,0,60             ; front top edge
                FCB     17,17,-60,0             ; front right edge
                FCB     -43,17,0,-60            ; front bottom edge
                FCB     -43,-43,60,0            ; front left edge
                FCB     43,-17,0,60             ; back top edge
                FCB     43,43,-60,0             ; back right edge
                FCB     -17,43,0,-60            ; back bottom edge
                FCB     -17,-17,60,0            ; back left edge
                FCB     17,-43,26,26            ; top-left depth edge
                FCB     17,17,26,26             ; top-right depth edge
                FCB     -43,17,26,26            ; bottom-right depth edge
                FCB     -43,-43,26,26           ; bottom-left depth edge

CubeFrame1:
                FCB     23,-46,-10,45           ; front top edge
                FCB     13,-1,-60,0             ; front right edge
                FCB     -47,-1,10,-45           ; front bottom edge
                FCB     -37,-46,60,0            ; front left edge
                FCB     47,1,-10,45             ; back top edge
                FCB     37,46,-60,0             ; back right edge
                FCB     -23,46,10,-45           ; back bottom edge
                FCB     -13,1,60,0              ; back left edge
                FCB     23,-46,24,47            ; top-left depth edge
                FCB     13,-1,24,47             ; top-right depth edge
                FCB     -47,-1,24,47            ; bottom-right depth edge
                FCB     -37,-46,24,47           ; bottom-left depth edge

CubeFrame2:
                FCB     30,-42,-18,24           ; front top edge
                FCB     12,-18,-60,0            ; front right edge
                FCB     -48,-18,18,-24          ; front bottom edge
                FCB     -30,-42,60,0            ; front left edge
                FCB     48,18,-18,24            ; back top edge
                FCB     30,42,-60,0             ; back right edge
                FCB     -30,42,18,-24           ; back bottom edge
                FCB     -12,18,60,0             ; back left edge
                FCB     30,-42,18,60            ; top-left depth edge
                FCB     12,-18,18,60            ; top-right depth edge
                FCB     -48,-18,18,60           ; bottom-right depth edge
                FCB     -30,-42,18,60           ; bottom-left depth edge

CubeFrame3:
                FCB     37,-32,-24,-1           ; front top edge
                FCB     13,-33,-60,0            ; front right edge
                FCB     -47,-33,24,1            ; front bottom edge
                FCB     -23,-32,60,0            ; front left edge
                FCB     47,33,-24,-1            ; back top edge
                FCB     23,32,-60,0             ; back right edge
                FCB     -37,32,24,1             ; back bottom edge
                FCB     -13,33,60,0             ; back left edge
                FCB     37,-32,10,65            ; top-left depth edge
                FCB     13,-33,10,65            ; top-right depth edge
                FCB     -47,-33,10,65           ; bottom-right depth edge
                FCB     -23,-32,10,65           ; bottom-left depth edge

CubeFrame4:
                FCB     43,-17,-26,-26          ; front top edge
                FCB     17,-43,-60,0            ; front right edge
                FCB     -43,-43,26,26           ; front bottom edge
                FCB     -17,-17,60,0            ; front left edge
                FCB     43,43,-26,-26           ; back top edge
                FCB     17,17,-60,0             ; back right edge
                FCB     -43,17,26,26            ; back bottom edge
                FCB     -17,43,60,0             ; back left edge
                FCB     43,-17,0,60             ; top-left depth edge
                FCB     17,-43,0,60             ; top-right depth edge
                FCB     -43,-43,0,60            ; bottom-right depth edge
                FCB     -17,-17,0,60            ; bottom-left depth edge

CubeFrame5:
                FCB     47,1,-24,-47            ; front top edge
                FCB     23,-46,-60,0            ; front right edge
                FCB     -37,-46,24,47           ; front bottom edge
                FCB     -13,1,60,0              ; front left edge
                FCB     37,46,-24,-47           ; back top edge
                FCB     13,-1,-60,0             ; back right edge
                FCB     -47,-1,24,47            ; back bottom edge
                FCB     -23,46,60,0             ; back left edge
                FCB     47,1,-10,45             ; top-left depth edge
                FCB     23,-46,-10,45           ; top-right depth edge
                FCB     -37,-46,-10,45          ; bottom-right depth edge
                FCB     -13,1,-10,45            ; bottom-left depth edge

CubeFrame6:
                FCB     48,18,-18,-60           ; front top edge
                FCB     30,-42,-60,0            ; front right edge
                FCB     -30,-42,18,60           ; front bottom edge
                FCB     -12,18,60,0             ; front left edge
                FCB     30,42,-18,-60           ; back top edge
                FCB     12,-18,-60,0            ; back right edge
                FCB     -48,-18,18,60           ; back bottom edge
                FCB     -30,42,60,0             ; back left edge
                FCB     48,18,-18,24            ; top-left depth edge
                FCB     30,-42,-18,24           ; top-right depth edge
                FCB     -30,-42,-18,24          ; bottom-right depth edge
                FCB     -12,18,-18,24           ; bottom-left depth edge

CubeFrame7:
                FCB     47,33,-10,-65           ; front top edge
                FCB     37,-32,-60,0            ; front right edge
                FCB     -23,-32,10,65           ; front bottom edge
                FCB     -13,33,60,0             ; front left edge
                FCB     23,32,-10,-65           ; back top edge
                FCB     13,-33,-60,0            ; back right edge
                FCB     -47,-33,10,65           ; back bottom edge
                FCB     -37,32,60,0             ; back left edge
                FCB     47,33,-24,-1            ; top-left depth edge
                FCB     37,-32,-24,-1           ; top-right depth edge
                FCB     -23,-32,-24,-1          ; bottom-right depth edge
                FCB     -13,33,-24,-1           ; bottom-left depth edge

CubeFrame8:
                FCB     43,43,0,-60             ; front top edge
                FCB     43,-17,-60,0            ; front right edge
                FCB     -17,-17,0,60            ; front bottom edge
                FCB     -17,43,60,0             ; front left edge
                FCB     17,17,0,-60             ; back top edge
                FCB     17,-43,-60,0            ; back right edge
                FCB     -43,-43,0,60            ; back bottom edge
                FCB     -43,17,60,0             ; back left edge
                FCB     43,43,-26,-26           ; top-left depth edge
                FCB     43,-17,-26,-26          ; top-right depth edge
                FCB     -17,-17,-26,-26         ; bottom-right depth edge
                FCB     -17,43,-26,-26          ; bottom-left depth edge

CubeFrame9:
                FCB     37,46,10,-45            ; front top edge
                FCB     47,1,-60,0              ; front right edge
                FCB     -13,1,-10,45            ; front bottom edge
                FCB     -23,46,60,0             ; front left edge
                FCB     13,-1,10,-45            ; back top edge
                FCB     23,-46,-60,0            ; back right edge
                FCB     -37,-46,-10,45          ; back bottom edge
                FCB     -47,-1,60,0             ; back left edge
                FCB     37,46,-24,-47           ; top-left depth edge
                FCB     47,1,-24,-47            ; top-right depth edge
                FCB     -13,1,-24,-47           ; bottom-right depth edge
                FCB     -23,46,-24,-47          ; bottom-left depth edge

CubeFrame10:
                FCB     30,42,18,-24            ; front top edge
                FCB     48,18,-60,0             ; front right edge
                FCB     -12,18,-18,24           ; front bottom edge
                FCB     -30,42,60,0             ; front left edge
                FCB     12,-18,18,-24           ; back top edge
                FCB     30,-42,-60,0            ; back right edge
                FCB     -30,-42,-18,24          ; back bottom edge
                FCB     -48,-18,60,0            ; back left edge
                FCB     30,42,-18,-60           ; top-left depth edge
                FCB     48,18,-18,-60           ; top-right depth edge
                FCB     -12,18,-18,-60          ; bottom-right depth edge
                FCB     -30,42,-18,-60          ; bottom-left depth edge

CubeFrame11:
                FCB     23,32,24,1              ; front top edge
                FCB     47,33,-60,0             ; front right edge
                FCB     -13,33,-24,-1           ; front bottom edge
                FCB     -37,32,60,0             ; front left edge
                FCB     13,-33,24,1             ; back top edge
                FCB     37,-32,-60,0            ; back right edge
                FCB     -23,-32,-24,-1          ; back bottom edge
                FCB     -47,-33,60,0            ; back left edge
                FCB     23,32,-10,-65           ; top-left depth edge
                FCB     47,33,-10,-65           ; top-right depth edge
                FCB     -13,33,-10,-65          ; bottom-right depth edge
                FCB     -37,32,-10,-65          ; bottom-left depth edge

CubeFrame12:
                FCB     17,17,26,26             ; front top edge
                FCB     43,43,-60,0             ; front right edge
                FCB     -17,43,-26,-26          ; front bottom edge
                FCB     -43,17,60,0             ; front left edge
                FCB     17,-43,26,26            ; back top edge
                FCB     43,-17,-60,0            ; back right edge
                FCB     -17,-17,-26,-26         ; back bottom edge
                FCB     -43,-43,60,0            ; back left edge
                FCB     17,17,0,-60             ; top-left depth edge
                FCB     43,43,0,-60             ; top-right depth edge
                FCB     -17,43,0,-60            ; bottom-right depth edge
                FCB     -43,17,0,-60            ; bottom-left depth edge

CubeFrame13:
                FCB     13,-1,24,47             ; front top edge
                FCB     37,46,-60,0             ; front right edge
                FCB     -23,46,-24,-47          ; front bottom edge
                FCB     -47,-1,60,0             ; front left edge
                FCB     23,-46,24,47            ; back top edge
                FCB     47,1,-60,0              ; back right edge
                FCB     -13,1,-24,-47           ; back bottom edge
                FCB     -37,-46,60,0            ; back left edge
                FCB     13,-1,10,-45            ; top-left depth edge
                FCB     37,46,10,-45            ; top-right depth edge
                FCB     -23,46,10,-45           ; bottom-right depth edge
                FCB     -47,-1,10,-45           ; bottom-left depth edge

CubeFrame14:
                FCB     12,-18,18,60            ; front top edge
                FCB     30,42,-60,0             ; front right edge
                FCB     -30,42,-18,-60          ; front bottom edge
                FCB     -48,-18,60,0            ; front left edge
                FCB     30,-42,18,60            ; back top edge
                FCB     48,18,-60,0             ; back right edge
                FCB     -12,18,-18,-60          ; back bottom edge
                FCB     -30,-42,60,0            ; back left edge
                FCB     12,-18,18,-24           ; top-left depth edge
                FCB     30,42,18,-24            ; top-right depth edge
                FCB     -30,42,18,-24           ; bottom-right depth edge
                FCB     -48,-18,18,-24          ; bottom-left depth edge

CubeFrame15:
                FCB     13,-33,10,65            ; front top edge
                FCB     23,32,-60,0             ; front right edge
                FCB     -37,32,-10,-65          ; front bottom edge
                FCB     -47,-33,60,0            ; front left edge
                FCB     37,-32,10,65            ; back top edge
                FCB     47,33,-60,0             ; back right edge
                FCB     -13,33,-10,-65          ; back bottom edge
                FCB     -23,-32,60,0            ; back left edge
                FCB     13,-33,24,1             ; top-left depth edge
                FCB     23,32,24,1              ; top-right depth edge
                FCB     -37,32,24,1             ; bottom-right depth edge
                FCB     -47,-33,24,1            ; bottom-left depth edge
