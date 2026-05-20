; ==============================
; Demo: Cube
; ==============================

;***************************************************************************
; DEFINE SECTION
;***************************************************************************
CUBE_EDGE_COUNT EQU     12                      ; 12 edges in a wireframe cube
CUBE_VERTEX_COUNT EQU   8                       ; 8 vertices in a cube
CUBE_ROT_DELAY EQU      2                       ; Joystick-held rotation divider

CUBE_ROT_COUNTER EQU    $C930                   ; user RAM: rotation speed divider
CUBE_PROJECTED_RAM EQU  $C931                   ; user RAM: 8 projected Y,X pairs
CUBE_START_Y EQU        $C941                   ; user RAM: projected edge start Y
CUBE_START_X EQU        $C942                   ; user RAM: projected edge start X
CUBE_DELTA_Y EQU        $C943                   ; user RAM: projected edge delta Y
CUBE_DELTA_X EQU        $C944                   ; user RAM: projected edge delta X
CUBE_FETCH_Y EQU        $C945                   ; user RAM: fetched projected vertex Y
CUBE_FETCH_X EQU        $C946                   ; user RAM: fetched projected vertex X

                INCLUDE "engine3d.asm"

;***************************************************************************
; CODE SECTION
;***************************************************************************
; ---------------------------------------------------------------------------
; InitCubeDemo
; Resets rotation angles. Cube vertices stay immutable in ROM, so the shape
; cannot drift or deform after repeated joystick rotations.
; ---------------------------------------------------------------------------
InitCubeDemo:
                CLRA
                STA     ENGINE3D_YAW_ANGLE
                STA     ENGINE3D_PITCH_ANGLE
                LDA     #CUBE_ROT_DELAY
                STA     CUBE_ROT_COUNTER
                LDA     #1
                STA     Vec_Joy_Mux_1_X         ; BIOS Joy_Digital reads stick 1 X
                LDA     #3
                STA     Vec_Joy_Mux_1_Y         ; BIOS Joy_Digital reads stick 1 Y
                RTS

cube_loop:
                JSR     Wait_Recal              ; Vectrex BIOS recalibration
                JSR     Read_Btns               ; BIOS updates button state RAM
                JSR     Joy_Digital             ; BIOS updates joystick direction RAM
                LDA     Vec_Button_1_2          ; Button 2 returns to main menu
                LBNE    return_to_menu
                JSR     UpdateCubeRotation      ; Joystick changes yaw/pitch angles
                JSR     Intensity_5F            ; BIOS beam intensity for cube
                JSR     DrawCube                ; Draw projected 3D wire cube
                BRA     cube_loop

; ---------------------------------------------------------------------------
; UpdateCubeRotation
; Left/right changes yaw around the origin Y axis. Up/down changes pitch around
; the origin X axis. Only angle indices change; source vertices remain intact.
; ---------------------------------------------------------------------------
UpdateCubeRotation:
                LDA     Vec_Joy_1_X             ; Signed digital X from BIOS RAM
                BNE     CubeRotationInput
                LDA     Vec_Joy_1_Y             ; Signed digital Y from BIOS RAM
                BNE     CubeRotationInput
                LDA     #CUBE_ROT_DELAY         ; Neutral stick: hold current angle
                STA     CUBE_ROT_COUNTER
                RTS

CubeRotationInput:
                DEC     CUBE_ROT_COUNTER
                BNE     CubeRotationDone
                LDA     #CUBE_ROT_DELAY
                STA     CUBE_ROT_COUNTER

                LDA     Vec_Joy_1_X
                BEQ     CheckCubePitch
                BMI     DecrementCubeYaw
                LDA     ENGINE3D_YAW_ANGLE
                INCA
                ANDA    #ENGINE3D_ANGLE_MASK
                STA     ENGINE3D_YAW_ANGLE
                BRA     CheckCubePitch

DecrementCubeYaw:
                LDA     ENGINE3D_YAW_ANGLE
                DECA
                ANDA    #ENGINE3D_ANGLE_MASK
                STA     ENGINE3D_YAW_ANGLE

CheckCubePitch:
                LDA     Vec_Joy_1_Y
                BEQ     CubeRotationDone
                BMI     DecrementCubePitch      ; Negative Y pitches downward
                LDA     ENGINE3D_PITCH_ANGLE
                INCA
                ANDA    #ENGINE3D_ANGLE_MASK
                STA     ENGINE3D_PITCH_ANGLE
                RTS

DecrementCubePitch:
                LDA     ENGINE3D_PITCH_ANGLE
                DECA
                ANDA    #ENGINE3D_ANGLE_MASK
                STA     ENGINE3D_PITCH_ANGLE

CubeRotationDone:
                RTS

; ---------------------------------------------------------------------------
; DrawCube
; Projects the immutable 3D cube through current yaw/pitch angles, then draws
; each edge with BIOS vector routines.
; ---------------------------------------------------------------------------
DrawCube:
                JSR     DP_to_D0                ; Restore DP for VIA/BIOS draw
                LDX     #CubeVertexTable        ; Source XYZ vertices centered on 0
                LDU     #CUBE_PROJECTED_RAM     ; Destination projected Y,X pairs
                LDA     #CUBE_VERTEX_COUNT
                JSR     Engine3D_ProjectVertices ; 3D rotation and 2D projection
                LDX     #CubeEdgeTable          ; Edge endpoint indices
                LDA     #CUBE_EDGE_COUNT        ; Edge loop counter

DrawCubeEdge:
                PSHS    A                       ; Preserve remaining edge count
                PSHS    X                       ; Preserve edge table pointer
                JSR     Reset0Ref               ; Draw each edge from true origin
                PULS    X

                LDA     ,X+                     ; Start vertex index
                JSR     FetchCubeProjectedVertex
                LDA     CUBE_FETCH_Y
                STA     CUBE_START_Y
                LDA     CUBE_FETCH_X
                STA     CUBE_START_X

                LDA     ,X+                     ; End vertex index
                JSR     FetchCubeProjectedVertex
                LDA     CUBE_FETCH_Y
                SUBA    CUBE_START_Y
                STA     CUBE_DELTA_Y
                LDA     CUBE_FETCH_X
                SUBA    CUBE_START_X
                STA     CUBE_DELTA_X

                LDA     CUBE_START_Y
                LDB     CUBE_START_X
                PSHS    X
                JSR     Moveto_d_7F             ; BIOS move to edge start
                LDA     CUBE_DELTA_Y
                LDB     CUBE_DELTA_X
                JSR     Draw_Line_d             ; BIOS draw projected edge
                PULS    X
                PULS    A
                DECA
                BNE     DrawCubeEdge
                RTS

; ---------------------------------------------------------------------------
; FetchCubeProjectedVertex
; Input: A = vertex index. Output: CUBE_FETCH_Y / CUBE_FETCH_X.
; ---------------------------------------------------------------------------
FetchCubeProjectedVertex:
                ASLA                            ; Two bytes per projected vertex
                LDU     #CUBE_PROJECTED_RAM
                LEAU    A,U
                LDA     ,U
                STA     CUBE_FETCH_Y
                LDA     1,U
                STA     CUBE_FETCH_X
                RTS

;***************************************************************************
; DATA SECTION
;***************************************************************************
CubeVertexTable:
                FCB     -32,32,-32              ; vertex 0: left, top, front
                FCB     32,32,-32               ; vertex 1: right, top, front
                FCB     32,-32,-32              ; vertex 2: right, bottom, front
                FCB     -32,-32,-32             ; vertex 3: left, bottom, front
                FCB     -32,32,32               ; vertex 4: left, top, back
                FCB     32,32,32                ; vertex 5: right, top, back
                FCB     32,-32,32               ; vertex 6: right, bottom, back
                FCB     -32,-32,32              ; vertex 7: left, bottom, back

CubeEdgeTable:
                FCB     0,1                     ; front top edge
                FCB     1,2                     ; front right edge
                FCB     2,3                     ; front bottom edge
                FCB     3,0                     ; front left edge
                FCB     4,5                     ; back top edge
                FCB     5,6                     ; back right edge
                FCB     6,7                     ; back bottom edge
                FCB     7,4                     ; back left edge
                FCB     0,4                     ; top-left depth edge
                FCB     1,5                     ; top-right depth edge
                FCB     2,6                     ; bottom-right depth edge
                FCB     3,7                     ; bottom-left depth edge
