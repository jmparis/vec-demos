; ==============================
; Demo: Cube
; ==============================

;***************************************************************************
; DEFINE SECTION
;***************************************************************************
CUBE_EDGE_COUNT EQU     12                      ; 12 edges in a wireframe cube
CUBE_VERTEX_COUNT EQU   8                       ; 8 vertices in a cube
CUBE_VERTEX_SIZE EQU    3                       ; X, Y, Z bytes per vertex
CUBE_VERTEX_BYTES EQU   CUBE_VERTEX_COUNT*CUBE_VERTEX_SIZE
CUBE_ROT_DELAY EQU      1                       ; Joystick-held rotation divider
CUBE_VERTEX_RAM EQU     $C910                   ; user RAM: 8 signed XYZ vertices
CUBE_ROT_COUNTER EQU    $C928                   ; user RAM: rotation speed divider
CUBE_START_Y EQU        $C929                   ; user RAM: projected edge start Y
CUBE_START_X EQU        $C92A                   ; user RAM: projected edge start X
CUBE_DELTA_Y EQU        $C92B                   ; user RAM: projected edge delta Y
CUBE_DELTA_X EQU        $C92C                   ; user RAM: projected edge delta X
CUBE_PROJ_Y EQU         $C92D                   ; user RAM: projected vertex Y
CUBE_PROJ_X EQU         $C92E                   ; user RAM: projected vertex X
CUBE_TEMP_X EQU         $C92F                   ; user RAM: rotation scratch X
CUBE_TEMP_Y EQU         $C930                   ; user RAM: rotation scratch Y
CUBE_TEMP_Z EQU         $C931                   ; user RAM: rotation scratch Z
CUBE_TEMP_STEP EQU      $C932                   ; user RAM: signed small-angle term

;***************************************************************************
; CODE SECTION
;***************************************************************************
; ---------------------------------------------------------------------------
; InitCubeDemo
; Copies the cube vertices to RAM. The cube is centered on origin (0,0,0), so
; every rotation below is naturally around its center.
; ---------------------------------------------------------------------------
InitCubeDemo:
                LDX     #CubeVertexTemplate     ; ROM source: signed X,Y,Z
                LDU     #CUBE_VERTEX_RAM        ; RAM copy mutated by rotations
                LDB     #CUBE_VERTEX_BYTES

CopyCubeVertex:
                LDA     ,X+
                STA     ,U+
                DECB
                BNE     CopyCubeVertex

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
                JSR     UpdateCubeRotation      ; Joystick rotates 3D vertices
                JSR     Intensity_5F            ; BIOS beam intensity for cube
                JSR     DrawCube                ; Draw projected 3D wire cube
                BRA     cube_loop

; ---------------------------------------------------------------------------
; UpdateCubeRotation
; Left/right rotates around the Y axis. Up/down rotates around the X axis.
; The cube coordinates are signed bytes centered on (0,0,0), and each update
; applies a tiny shift-based rotation approximation to all vertices.
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
                BMI     RotateCubeLeft
                JSR     RotateCubeRight
                BRA     CheckCubePitch

RotateCubeLeft:
                JSR     RotateCubeLeftStep

CheckCubePitch:
                LDA     Vec_Joy_1_Y
                BEQ     CubeRotationDone
                BMI     RotateCubeDown          ; Negative Y pitches downward
                JSR     RotateCubeUp
                RTS

RotateCubeDown:
                JSR     RotateCubeDownStep

CubeRotationDone:
                RTS

; ---------------------------------------------------------------------------
; RotateCubeRight / RotateCubeLeftStep
; Horizontal yaw around the origin Y axis:
;   right: x' = x + z/8, z' = z - x'/8
;   left:  x' = x - z/8, z' = z + x'/8
; The second step uses the newly updated X value. That keeps the incremental
; rotation bounded instead of adding a small scale factor on every joystick step.
; ---------------------------------------------------------------------------
RotateCubeRight:
                LDX     #CUBE_VERTEX_RAM
                LDB     #CUBE_VERTEX_COUNT

RotateCubeRightLoop:
                LDA     ,X                      ; Current vertex X
                STA     CUBE_TEMP_X
                LDA     2,X                     ; Current vertex Z
                STA     CUBE_TEMP_Z
                JSR     SignedDiv8
                ADDA    CUBE_TEMP_X
                STA     ,X                      ; Store rotated X
                JSR     SignedDiv8              ; Use new X for stable rotation
                STA     CUBE_TEMP_STEP
                LDA     CUBE_TEMP_Z
                SUBA    CUBE_TEMP_STEP
                STA     2,X                     ; Store rotated Z
                LEAX    CUBE_VERTEX_SIZE,X
                DECB
                BNE     RotateCubeRightLoop
                RTS

RotateCubeLeftStep:
                LDX     #CUBE_VERTEX_RAM
                LDB     #CUBE_VERTEX_COUNT

RotateCubeLeftLoop:
                LDA     ,X                      ; Current vertex X
                STA     CUBE_TEMP_X
                LDA     2,X                     ; Current vertex Z
                STA     CUBE_TEMP_Z
                JSR     SignedDiv8
                STA     CUBE_TEMP_STEP
                LDA     CUBE_TEMP_X
                SUBA    CUBE_TEMP_STEP
                STA     ,X                      ; Store rotated X
                JSR     SignedDiv8              ; Use new X for stable rotation
                ADDA    CUBE_TEMP_Z
                STA     2,X                     ; Store rotated Z
                LEAX    CUBE_VERTEX_SIZE,X
                DECB
                BNE     RotateCubeLeftLoop
                RTS

; ---------------------------------------------------------------------------
; RotateCubeUp / RotateCubeDownStep
; Vertical pitch around the origin X axis:
;   up:   y' = y + z/8, z' = z - y'/8
;   down: y' = y - z/8, z' = z + y'/8
; ---------------------------------------------------------------------------
RotateCubeUp:
                LDX     #CUBE_VERTEX_RAM
                LDB     #CUBE_VERTEX_COUNT

RotateCubeUpLoop:
                LDA     1,X                     ; Current vertex Y
                STA     CUBE_TEMP_Y
                LDA     2,X                     ; Current vertex Z
                STA     CUBE_TEMP_Z
                JSR     SignedDiv8
                ADDA    CUBE_TEMP_Y
                STA     1,X                     ; Store rotated Y
                JSR     SignedDiv8              ; Use new Y for stable rotation
                STA     CUBE_TEMP_STEP
                LDA     CUBE_TEMP_Z
                SUBA    CUBE_TEMP_STEP
                STA     2,X                     ; Store rotated Z
                LEAX    CUBE_VERTEX_SIZE,X
                DECB
                BNE     RotateCubeUpLoop
                RTS

RotateCubeDownStep:
                LDX     #CUBE_VERTEX_RAM
                LDB     #CUBE_VERTEX_COUNT

RotateCubeDownLoop:
                LDA     1,X                     ; Current vertex Y
                STA     CUBE_TEMP_Y
                LDA     2,X                     ; Current vertex Z
                STA     CUBE_TEMP_Z
                JSR     SignedDiv8
                STA     CUBE_TEMP_STEP
                LDA     CUBE_TEMP_Y
                SUBA    CUBE_TEMP_STEP
                STA     1,X                     ; Store rotated Y
                JSR     SignedDiv8              ; Use new Y for stable rotation
                ADDA    CUBE_TEMP_Z
                STA     2,X                     ; Store rotated Z
                LEAX    CUBE_VERTEX_SIZE,X
                DECB
                BNE     RotateCubeDownLoop
                RTS

; ---------------------------------------------------------------------------
; SignedDiv8
; Divides signed A by 8 using arithmetic shifts. This is the small-angle term
; used by the rotation approximation above.
; ---------------------------------------------------------------------------
SignedDiv8:
                ASRA
                ASRA
                ASRA
                RTS

; ---------------------------------------------------------------------------
; DrawCube
; Projects each 3D edge endpoint to 2D and draws the resulting vector. The
; projection is intentionally simple for Vectrex hardware:
;   screen X = x + z/2
;   screen Y = y + z/2
; ---------------------------------------------------------------------------
DrawCube:
                JSR     DP_to_D0                ; Restore DP for VIA/BIOS draw
                LDX     #CubeEdgeTable          ; Edge endpoint indices
                LDA     #CUBE_EDGE_COUNT        ; Edge loop counter

DrawCubeEdge:
                PSHS    A                       ; Preserve remaining edge count
                PSHS    X                       ; Preserve edge table pointer
                JSR     Reset0Ref               ; Draw each edge from true origin
                PULS    X

                LDA     ,X+                     ; Start vertex index
                PSHS    X
                JSR     ProjectCubeVertex       ; Convert signed XYZ to Y/X
                PULS    X
                LDA     CUBE_PROJ_Y
                STA     CUBE_START_Y
                LDA     CUBE_PROJ_X
                STA     CUBE_START_X

                LDA     ,X+                     ; End vertex index
                PSHS    X
                JSR     ProjectCubeVertex       ; Convert signed XYZ to Y/X
                PULS    X
                LDA     CUBE_PROJ_Y
                SUBA    CUBE_START_Y
                STA     CUBE_DELTA_Y
                LDA     CUBE_PROJ_X
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
; ProjectCubeVertex
; Input: A = vertex index. Output: CUBE_PROJ_Y / CUBE_PROJ_X.
; ---------------------------------------------------------------------------
ProjectCubeVertex:
                LDB     #CUBE_VERTEX_SIZE
                MUL                             ; D = vertex index * 3
                LDX     #CUBE_VERTEX_RAM
                ABX                             ; X points to selected XYZ vertex

                LDA     2,X                     ; Z contributes perspective depth
                ASRA                            ; z/2, signed
                STA     CUBE_TEMP_Z
                LDA     ,X                      ; Projected X = x + z/2
                ADDA    CUBE_TEMP_Z
                STA     CUBE_PROJ_X
                LDA     1,X                     ; Projected Y = y + z/2
                ADDA    CUBE_TEMP_Z
                STA     CUBE_PROJ_Y
                RTS

;***************************************************************************
; DATA SECTION
;***************************************************************************
CubeVertexTemplate:
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
