; ==============================
; Demo: Cube
; ==============================

;***************************************************************************
; DEFINE SECTION
;***************************************************************************
CUBE_EDGE_COUNT EQU     12                      ; 12 edges in a wireframe cube
CUBE_VERTEX_COUNT EQU   8                       ; 8 vertices in a cube
CUBE_VERTEX_SIZE EQU    3                       ; X, Y, Z bytes per vertex
CUBE_ANGLE_MASK EQU     $7F                     ; 128 indexed rotation angles
CUBE_ROT_DELAY EQU      2                       ; Joystick-held rotation divider

CUBE_YAW_ANGLE EQU      $C910                   ; user RAM: horizontal angle index
CUBE_PITCH_ANGLE EQU    $C911                   ; user RAM: vertical angle index
CUBE_ROT_COUNTER EQU    $C912                   ; user RAM: rotation speed divider
CUBE_PROJECTED_RAM EQU  $C913                   ; user RAM: 8 projected Y,X pairs
CUBE_START_Y EQU        $C923                   ; user RAM: projected edge start Y
CUBE_START_X EQU        $C924                   ; user RAM: projected edge start X
CUBE_DELTA_Y EQU        $C925                   ; user RAM: projected edge delta Y
CUBE_DELTA_X EQU        $C926                   ; user RAM: projected edge delta X
CUBE_PROJ_Y EQU         $C927                   ; user RAM: projected vertex Y
CUBE_PROJ_X EQU         $C928                   ; user RAM: projected vertex X
CUBE_ORIG_X EQU         $C929                   ; user RAM: source vertex X
CUBE_ORIG_Y EQU         $C92A                   ; user RAM: source vertex Y
CUBE_ORIG_Z EQU         $C92B                   ; user RAM: source vertex Z
CUBE_ROT_X EQU          $C92C                   ; user RAM: rotated vertex X
CUBE_ROT_Y EQU          $C92D                   ; user RAM: rotated vertex Y
CUBE_ROT_Z EQU          $C92E                   ; user RAM: rotated vertex Z
CUBE_TEMP_Z EQU         $C92F                   ; user RAM: projection scratch Z
CUBE_YAW_COS EQU        $C930                   ; user RAM: yaw cosine, Q6
CUBE_YAW_SIN EQU        $C931                   ; user RAM: yaw sine, Q6
CUBE_PITCH_COS EQU      $C932                   ; user RAM: pitch cosine, Q6
CUBE_PITCH_SIN EQU      $C933                   ; user RAM: pitch sine, Q6
CUBE_ACC EQU            $C934                   ; user RAM: signed 16-bit accumulator
CUBE_TERM EQU           $C936                   ; user RAM: signed 16-bit term
CUBE_MUL_A EQU          $C938                   ; user RAM: signed multiply scratch
CUBE_MUL_B EQU          $C939                   ; user RAM: signed multiply scratch
CUBE_MUL_NEG EQU        $C93A                   ; user RAM: signed multiply sign flag
CUBE_VERTEX_INDEX EQU   $C93B                   ; user RAM: projection loop index

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
                STA     CUBE_YAW_ANGLE
                STA     CUBE_PITCH_ANGLE
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
                LDA     CUBE_YAW_ANGLE
                INCA
                ANDA    #CUBE_ANGLE_MASK
                STA     CUBE_YAW_ANGLE
                BRA     CheckCubePitch

DecrementCubeYaw:
                LDA     CUBE_YAW_ANGLE
                DECA
                ANDA    #CUBE_ANGLE_MASK
                STA     CUBE_YAW_ANGLE

CheckCubePitch:
                LDA     Vec_Joy_1_Y
                BEQ     CubeRotationDone
                BMI     DecrementCubePitch      ; Negative Y pitches downward
                LDA     CUBE_PITCH_ANGLE
                INCA
                ANDA    #CUBE_ANGLE_MASK
                STA     CUBE_PITCH_ANGLE
                RTS

DecrementCubePitch:
                LDA     CUBE_PITCH_ANGLE
                DECA
                ANDA    #CUBE_ANGLE_MASK
                STA     CUBE_PITCH_ANGLE

CubeRotationDone:
                RTS

; ---------------------------------------------------------------------------
; DrawCube
; Projects the immutable 3D cube through current yaw/pitch angles, then draws
; each edge with BIOS vector routines.
; ---------------------------------------------------------------------------
DrawCube:
                JSR     DP_to_D0                ; Restore DP for VIA/BIOS draw
                JSR     ProjectCubeVertices     ; Rebuild 2D points from 3D origin
                LDX     #CubeEdgeTable          ; Edge endpoint indices
                LDA     #CUBE_EDGE_COUNT        ; Edge loop counter

DrawCubeEdge:
                PSHS    A                       ; Preserve remaining edge count
                PSHS    X                       ; Preserve edge table pointer
                JSR     Reset0Ref               ; Draw each edge from true origin
                PULS    X

                LDA     ,X+                     ; Start vertex index
                JSR     FetchProjectedVertex
                LDA     CUBE_PROJ_Y
                STA     CUBE_START_Y
                LDA     CUBE_PROJ_X
                STA     CUBE_START_X

                LDA     ,X+                     ; End vertex index
                JSR     FetchProjectedVertex
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
; ProjectCubeVertices
; Builds 8 projected Y,X pairs in RAM from the ROM XYZ coordinates and the
; current yaw/pitch angle indices.
; ---------------------------------------------------------------------------
ProjectCubeVertices:
                JSR     LoadCubeTrig
                CLRA
                STA     CUBE_VERTEX_INDEX

ProjectCubeVerticesLoop:
                LDA     CUBE_VERTEX_INDEX
                JSR     ProjectCubeVertex
                LDA     CUBE_VERTEX_INDEX
                ASLA                            ; Two bytes per projected vertex
                LDU     #CUBE_PROJECTED_RAM
                LEAU    A,U
                LDA     CUBE_PROJ_Y
                STA     ,U
                LDA     CUBE_PROJ_X
                STA     1,U
                LDA     CUBE_VERTEX_INDEX
                INCA
                STA     CUBE_VERTEX_INDEX
                CMPA    #CUBE_VERTEX_COUNT
                BLO     ProjectCubeVerticesLoop
                RTS

; ---------------------------------------------------------------------------
; LoadCubeTrig
; Loads cosine/sine pairs for yaw and pitch from the Q6 lookup table.
; ---------------------------------------------------------------------------
LoadCubeTrig:
                LDB     CUBE_YAW_ANGLE
                ASLB                            ; Two bytes per angle
                LDX     #CubeTrigTable
                ABX
                LDA     ,X
                STA     CUBE_YAW_COS
                LDA     1,X
                STA     CUBE_YAW_SIN

                LDB     CUBE_PITCH_ANGLE
                ASLB                            ; Two bytes per angle
                LDX     #CubeTrigTable
                ABX
                LDA     ,X
                STA     CUBE_PITCH_COS
                LDA     1,X
                STA     CUBE_PITCH_SIN
                RTS

; ---------------------------------------------------------------------------
; ProjectCubeVertex
; Input: A = vertex index. Output: CUBE_PROJ_Y / CUBE_PROJ_X.
; Rotation is recomputed from original XYZ every frame:
;   yaw:   x1 = x*cos + z*sin, z1 = z*cos - x*sin
;   pitch: y2 = y*cos + z1*sin, z2 = z1*cos - y*sin
; All coefficients are signed Q6 values, divided by 64 after each sum.
; ---------------------------------------------------------------------------
ProjectCubeVertex:
                LDB     #CUBE_VERTEX_SIZE
                MUL                             ; D = vertex index * 3
                LDX     #CubeVertexTemplate
                ABX                             ; X points to selected XYZ vertex
                LDA     ,X
                STA     CUBE_ORIG_X
                LDA     1,X
                STA     CUBE_ORIG_Y
                LDA     2,X
                STA     CUBE_ORIG_Z

                LDA     CUBE_ORIG_X             ; x*cos(yaw)
                LDB     CUBE_YAW_COS
                JSR     SignedMul8
                STD     CUBE_ACC
                LDA     CUBE_ORIG_Z             ; + z*sin(yaw)
                LDB     CUBE_YAW_SIN
                JSR     SignedMul8
                ADDD    CUBE_ACC
                JSR     SignedDToByteDiv64
                STA     CUBE_ROT_X

                LDA     CUBE_ORIG_Z             ; z*cos(yaw)
                LDB     CUBE_YAW_COS
                JSR     SignedMul8
                STD     CUBE_ACC
                LDA     CUBE_ORIG_X             ; - x*sin(yaw)
                LDB     CUBE_YAW_SIN
                JSR     SignedMul8
                STD     CUBE_TERM
                LDD     CUBE_ACC
                SUBD    CUBE_TERM
                JSR     SignedDToByteDiv64
                STA     CUBE_ROT_Z

                LDA     CUBE_ORIG_Y
                STA     CUBE_ROT_Y

                LDA     CUBE_ROT_Y              ; y*cos(pitch)
                LDB     CUBE_PITCH_COS
                JSR     SignedMul8
                STD     CUBE_ACC
                LDA     CUBE_ROT_Z              ; + z1*sin(pitch)
                LDB     CUBE_PITCH_SIN
                JSR     SignedMul8
                ADDD    CUBE_ACC
                JSR     SignedDToByteDiv64
                STA     CUBE_PROJ_Y             ; keep y2 until projection

                LDA     CUBE_ROT_Z              ; z1*cos(pitch)
                LDB     CUBE_PITCH_COS
                JSR     SignedMul8
                STD     CUBE_ACC
                LDA     CUBE_ROT_Y              ; - y*sin(pitch)
                LDB     CUBE_PITCH_SIN
                JSR     SignedMul8
                STD     CUBE_TERM
                LDD     CUBE_ACC
                SUBD    CUBE_TERM
                JSR     SignedDToByteDiv64
                STA     CUBE_ROT_Z

                LDA     CUBE_ROT_Z              ; Simple orthographic depth offset
                ASRA                            ; z/2, signed
                STA     CUBE_TEMP_Z
                LDA     CUBE_ROT_X              ; screen X = x2 + z2/2
                ADDA    CUBE_TEMP_Z
                STA     CUBE_PROJ_X
                LDA     CUBE_PROJ_Y             ; screen Y = y2 + z2/2
                ADDA    CUBE_TEMP_Z
                STA     CUBE_PROJ_Y
                RTS

; ---------------------------------------------------------------------------
; FetchProjectedVertex
; Input: A = vertex index. Output: CUBE_PROJ_Y / CUBE_PROJ_X.
; ---------------------------------------------------------------------------
FetchProjectedVertex:
                ASLA                            ; Two bytes per projected vertex
                LDU     #CUBE_PROJECTED_RAM
                LEAU    A,U
                LDA     ,U
                STA     CUBE_PROJ_Y
                LDA     1,U
                STA     CUBE_PROJ_X
                RTS

; ---------------------------------------------------------------------------
; SignedMul8
; Signed 8-bit by signed 8-bit multiply. Input A,B. Output signed 16-bit D.
; ---------------------------------------------------------------------------
SignedMul8:
                STA     CUBE_MUL_A
                STB     CUBE_MUL_B
                CLR     CUBE_MUL_NEG

                LDA     CUBE_MUL_A
                BPL     SignedMulAPositive
                NEGA
                STA     CUBE_MUL_A
                LDA     #1
                STA     CUBE_MUL_NEG

SignedMulAPositive:
                LDB     CUBE_MUL_B
                BPL     SignedMulBPositive
                NEGB
                STB     CUBE_MUL_B
                LDA     CUBE_MUL_NEG
                EORA    #1
                STA     CUBE_MUL_NEG

SignedMulBPositive:
                LDA     CUBE_MUL_A
                LDB     CUBE_MUL_B
                MUL
                TST     CUBE_MUL_NEG
                BEQ     SignedMulDone
                COMA
                COMB
                ADDD    #1

SignedMulDone:
                RTS

; ---------------------------------------------------------------------------
; SignedDToByteDiv64
; Arithmetic divide signed D by 64. Output signed byte in A.
; ---------------------------------------------------------------------------
SignedDToByteDiv64:
                ASRA
                RORB
                ASRA
                RORB
                ASRA
                RORB
                ASRA
                RORB
                ASRA
                RORB
                ASRA
                RORB
                TFR     B,A
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

CubeTrigTable:
                FCB     64,0                    ;   0 degrees: cos, sin
                FCB     64,3                    ;   3 degrees
                FCB     64,6                    ;   6 degrees
                FCB     63,9                    ;   8 degrees
                FCB     63,12                   ;  11 degrees
                FCB     62,16                   ;  14 degrees
                FCB     61,19                   ;  17 degrees
                FCB     60,22                   ;  20 degrees
                FCB     59,24                   ;  22 degrees
                FCB     58,27                   ;  25 degrees
                FCB     56,30                   ;  28 degrees
                FCB     55,33                   ;  31 degrees
                FCB     53,36                   ;  34 degrees
                FCB     51,38                   ;  37 degrees
                FCB     49,41                   ;  39 degrees
                FCB     47,43                   ;  42 degrees
                FCB     45,45                   ;  45 degrees
                FCB     43,47                   ;  48 degrees
                FCB     41,49                   ;  51 degrees
                FCB     38,51                   ;  53 degrees
                FCB     36,53                   ;  56 degrees
                FCB     33,55                   ;  59 degrees
                FCB     30,56                   ;  62 degrees
                FCB     27,58                   ;  65 degrees
                FCB     24,59                   ;  68 degrees
                FCB     22,60                   ;  70 degrees
                FCB     19,61                   ;  73 degrees
                FCB     16,62                   ;  76 degrees
                FCB     12,63                   ;  79 degrees
                FCB     9,63                    ;  82 degrees
                FCB     6,64                    ;  84 degrees
                FCB     3,64                    ;  87 degrees
                FCB     0,64                    ;  90 degrees
                FCB     -3,64                   ;  93 degrees
                FCB     -6,64                   ;  96 degrees
                FCB     -9,63                   ;  98 degrees
                FCB     -12,63                  ; 101 degrees
                FCB     -16,62                  ; 104 degrees
                FCB     -19,61                  ; 107 degrees
                FCB     -22,60                  ; 110 degrees
                FCB     -24,59                  ; 112 degrees
                FCB     -27,58                  ; 115 degrees
                FCB     -30,56                  ; 118 degrees
                FCB     -33,55                  ; 121 degrees
                FCB     -36,53                  ; 124 degrees
                FCB     -38,51                  ; 127 degrees
                FCB     -41,49                  ; 129 degrees
                FCB     -43,47                  ; 132 degrees
                FCB     -45,45                  ; 135 degrees
                FCB     -47,43                  ; 138 degrees
                FCB     -49,41                  ; 141 degrees
                FCB     -51,38                  ; 143 degrees
                FCB     -53,36                  ; 146 degrees
                FCB     -55,33                  ; 149 degrees
                FCB     -56,30                  ; 152 degrees
                FCB     -58,27                  ; 155 degrees
                FCB     -59,24                  ; 157 degrees
                FCB     -60,22                  ; 160 degrees
                FCB     -61,19                  ; 163 degrees
                FCB     -62,16                  ; 166 degrees
                FCB     -63,12                  ; 169 degrees
                FCB     -63,9                   ; 172 degrees
                FCB     -64,6                   ; 174 degrees
                FCB     -64,3                   ; 177 degrees
                FCB     -64,0                   ; 180 degrees
                FCB     -64,-3                  ; 183 degrees
                FCB     -64,-6                  ; 186 degrees
                FCB     -63,-9                  ; 188 degrees
                FCB     -63,-12                 ; 191 degrees
                FCB     -62,-16                 ; 194 degrees
                FCB     -61,-19                 ; 197 degrees
                FCB     -60,-22                 ; 200 degrees
                FCB     -59,-24                 ; 202 degrees
                FCB     -58,-27                 ; 205 degrees
                FCB     -56,-30                 ; 208 degrees
                FCB     -55,-33                 ; 211 degrees
                FCB     -53,-36                 ; 214 degrees
                FCB     -51,-38                 ; 217 degrees
                FCB     -49,-41                 ; 219 degrees
                FCB     -47,-43                 ; 222 degrees
                FCB     -45,-45                 ; 225 degrees
                FCB     -43,-47                 ; 228 degrees
                FCB     -41,-49                 ; 231 degrees
                FCB     -38,-51                 ; 233 degrees
                FCB     -36,-53                 ; 236 degrees
                FCB     -33,-55                 ; 239 degrees
                FCB     -30,-56                 ; 242 degrees
                FCB     -27,-58                 ; 245 degrees
                FCB     -24,-59                 ; 247 degrees
                FCB     -22,-60                 ; 250 degrees
                FCB     -19,-61                 ; 253 degrees
                FCB     -16,-62                 ; 256 degrees
                FCB     -12,-63                 ; 259 degrees
                FCB     -9,-63                  ; 262 degrees
                FCB     -6,-64                  ; 264 degrees
                FCB     -3,-64                  ; 267 degrees
                FCB     0,-64                   ; 270 degrees
                FCB     3,-64                   ; 273 degrees
                FCB     6,-64                   ; 276 degrees
                FCB     9,-63                   ; 278 degrees
                FCB     12,-63                  ; 281 degrees
                FCB     16,-62                  ; 284 degrees
                FCB     19,-61                  ; 287 degrees
                FCB     22,-60                  ; 290 degrees
                FCB     24,-59                  ; 292 degrees
                FCB     27,-58                  ; 295 degrees
                FCB     30,-56                  ; 298 degrees
                FCB     33,-55                  ; 301 degrees
                FCB     36,-53                  ; 304 degrees
                FCB     38,-51                  ; 307 degrees
                FCB     41,-49                  ; 309 degrees
                FCB     43,-47                  ; 312 degrees
                FCB     45,-45                  ; 315 degrees
                FCB     47,-43                  ; 318 degrees
                FCB     49,-41                  ; 321 degrees
                FCB     51,-38                  ; 323 degrees
                FCB     53,-36                  ; 326 degrees
                FCB     55,-33                  ; 329 degrees
                FCB     56,-30                  ; 332 degrees
                FCB     58,-27                  ; 335 degrees
                FCB     59,-24                  ; 337 degrees
                FCB     60,-22                  ; 340 degrees
                FCB     61,-19                  ; 343 degrees
                FCB     62,-16                  ; 346 degrees
                FCB     63,-12                  ; 349 degrees
                FCB     63,-9                   ; 352 degrees
                FCB     64,-6                   ; 354 degrees
                FCB     64,-3                   ; 357 degrees
