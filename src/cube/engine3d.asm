; ==============================
; Small 3D Engine
; ==============================

;***************************************************************************
; DEFINE SECTION
;***************************************************************************
ENGINE3D_VERTEX_SIZE EQU        3               ; X, Y, Z bytes per vertex
ENGINE3D_ANGLE_MASK EQU         $7F             ; 128 indexed rotation angles

ENGINE3D_YAW_ANGLE EQU          $C910           ; user RAM: horizontal angle index
ENGINE3D_PITCH_ANGLE EQU        $C911           ; user RAM: vertical angle index
ENGINE3D_SRC_PTR EQU            $C912           ; user RAM: source vertex table word
ENGINE3D_DST_PTR EQU            $C914           ; user RAM: projected output word
ENGINE3D_VERTEX_COUNT_RAM EQU   $C916           ; user RAM: remaining vertices
ENGINE3D_PROJ_Y EQU             $C917           ; user RAM: projected vertex Y
ENGINE3D_PROJ_X EQU             $C918           ; user RAM: projected vertex X
ENGINE3D_ORIG_X EQU             $C919           ; user RAM: source vertex X
ENGINE3D_ORIG_Y EQU             $C91A           ; user RAM: source vertex Y
ENGINE3D_ORIG_Z EQU             $C91B           ; user RAM: source vertex Z
ENGINE3D_ROT_X EQU              $C91C           ; user RAM: rotated vertex X
ENGINE3D_ROT_Y EQU              $C91D           ; user RAM: rotated vertex Y
ENGINE3D_ROT_Z EQU              $C91E           ; user RAM: rotated vertex Z
ENGINE3D_TEMP_Z EQU             $C91F           ; user RAM: projection scratch Z
ENGINE3D_YAW_COS EQU            $C920           ; user RAM: yaw cosine, Q6
ENGINE3D_YAW_SIN EQU            $C921           ; user RAM: yaw sine, Q6
ENGINE3D_PITCH_COS EQU          $C922           ; user RAM: pitch cosine, Q6
ENGINE3D_PITCH_SIN EQU          $C923           ; user RAM: pitch sine, Q6
ENGINE3D_ACC EQU                $C924           ; user RAM: signed 16-bit accumulator
ENGINE3D_TERM EQU               $C926           ; user RAM: signed 16-bit term
ENGINE3D_MUL_A EQU              $C928           ; user RAM: signed multiply scratch
ENGINE3D_MUL_B EQU              $C929           ; user RAM: signed multiply scratch
ENGINE3D_MUL_NEG EQU            $C92A           ; user RAM: signed multiply sign flag

;***************************************************************************
; CODE SECTION
;***************************************************************************
; ---------------------------------------------------------------------------
; Engine3D_ProjectVertices
; Input:
;   X = source table of signed XYZ vertices
;   U = destination table for projected Y,X pairs
;   A = vertex count
; Uses current ENGINE3D_YAW_ANGLE and ENGINE3D_PITCH_ANGLE. Source vertices
; stay immutable, so rotations never accumulate deformation.
; ---------------------------------------------------------------------------
Engine3D_ProjectVertices:
                STX     ENGINE3D_SRC_PTR
                STU     ENGINE3D_DST_PTR
                STA     ENGINE3D_VERTEX_COUNT_RAM
                JSR     Engine3D_LoadTrig       ; Load Q6 cos/sin from tables

Engine3D_ProjectVerticesLoop:
                LDA     ENGINE3D_VERTEX_COUNT_RAM
                BEQ     Engine3D_ProjectVerticesDone
                LDX     ENGINE3D_SRC_PTR
                LDA     ,X+
                STA     ENGINE3D_ORIG_X
                LDA     ,X+
                STA     ENGINE3D_ORIG_Y
                LDA     ,X+
                STA     ENGINE3D_ORIG_Z
                STX     ENGINE3D_SRC_PTR

                JSR     Engine3D_ProjectCurrentVertex
                LDU     ENGINE3D_DST_PTR
                LDA     ENGINE3D_PROJ_Y
                STA     ,U+
                LDA     ENGINE3D_PROJ_X
                STA     ,U+
                STU     ENGINE3D_DST_PTR
                DEC     ENGINE3D_VERTEX_COUNT_RAM
                BRA     Engine3D_ProjectVerticesLoop

Engine3D_ProjectVerticesDone:
                RTS

; ---------------------------------------------------------------------------
; Engine3D_LoadTrig
; Loads cosine and sine values from separate Q6 lookup tables. Separate tables
; avoid the index shift needed by interleaved cos/sin pairs.
; ---------------------------------------------------------------------------
Engine3D_LoadTrig:
                LDB     ENGINE3D_YAW_ANGLE
                LDX     #Engine3D_CosTable
                ABX
                LDA     ,X
                STA     ENGINE3D_YAW_COS
                LDX     #Engine3D_SinTable
                ABX
                LDA     ,X
                STA     ENGINE3D_YAW_SIN

                LDB     ENGINE3D_PITCH_ANGLE
                LDX     #Engine3D_CosTable
                ABX
                LDA     ,X
                STA     ENGINE3D_PITCH_COS
                LDX     #Engine3D_SinTable
                ABX
                LDA     ,X
                STA     ENGINE3D_PITCH_SIN
                RTS

; ---------------------------------------------------------------------------
; Engine3D_ProjectCurrentVertex
; Rotates ENGINE3D_ORIG_X/Y/Z around origin, then projects to 2D:
;   yaw:   x1 = x*cos + z*sin, z1 = z*cos - x*sin
;   pitch: y2 = y*cos + z1*sin, z2 = z1*cos - y*sin
;   screen X = x2 + z2/2, screen Y = y2 + z2/2
; Trig coefficients are signed Q6 values.
; ---------------------------------------------------------------------------
Engine3D_ProjectCurrentVertex:
                LDA     ENGINE3D_ORIG_X         ; x*cos(yaw)
                LDB     ENGINE3D_YAW_COS
                JSR     Engine3D_SignedMul8
                STD     ENGINE3D_ACC
                LDA     ENGINE3D_ORIG_Z         ; + z*sin(yaw)
                LDB     ENGINE3D_YAW_SIN
                JSR     Engine3D_SignedMul8
                ADDD    ENGINE3D_ACC
                JSR     Engine3D_SignedDToByteDiv64
                STA     ENGINE3D_ROT_X

                LDA     ENGINE3D_ORIG_Z         ; z*cos(yaw)
                LDB     ENGINE3D_YAW_COS
                JSR     Engine3D_SignedMul8
                STD     ENGINE3D_ACC
                LDA     ENGINE3D_ORIG_X         ; - x*sin(yaw)
                LDB     ENGINE3D_YAW_SIN
                JSR     Engine3D_SignedMul8
                STD     ENGINE3D_TERM
                LDD     ENGINE3D_ACC
                SUBD    ENGINE3D_TERM
                JSR     Engine3D_SignedDToByteDiv64
                STA     ENGINE3D_ROT_Z

                LDA     ENGINE3D_ORIG_Y
                STA     ENGINE3D_ROT_Y

                LDA     ENGINE3D_ROT_Y          ; y*cos(pitch)
                LDB     ENGINE3D_PITCH_COS
                JSR     Engine3D_SignedMul8
                STD     ENGINE3D_ACC
                LDA     ENGINE3D_ROT_Z          ; + z1*sin(pitch)
                LDB     ENGINE3D_PITCH_SIN
                JSR     Engine3D_SignedMul8
                ADDD    ENGINE3D_ACC
                JSR     Engine3D_SignedDToByteDiv64
                STA     ENGINE3D_PROJ_Y         ; keep y2 until projection

                LDA     ENGINE3D_ROT_Z          ; z1*cos(pitch)
                LDB     ENGINE3D_PITCH_COS
                JSR     Engine3D_SignedMul8
                STD     ENGINE3D_ACC
                LDA     ENGINE3D_ROT_Y          ; - y*sin(pitch)
                LDB     ENGINE3D_PITCH_SIN
                JSR     Engine3D_SignedMul8
                STD     ENGINE3D_TERM
                LDD     ENGINE3D_ACC
                SUBD    ENGINE3D_TERM
                JSR     Engine3D_SignedDToByteDiv64
                STA     ENGINE3D_ROT_Z

                LDA     ENGINE3D_ROT_Z          ; Orthographic depth offset
                ASRA                            ; z/2, signed
                STA     ENGINE3D_TEMP_Z
                LDA     ENGINE3D_ROT_X          ; screen X = x2 + z2/2
                ADDA    ENGINE3D_TEMP_Z
                STA     ENGINE3D_PROJ_X
                LDA     ENGINE3D_PROJ_Y         ; screen Y = y2 + z2/2
                ADDA    ENGINE3D_TEMP_Z
                STA     ENGINE3D_PROJ_Y
                RTS

; ---------------------------------------------------------------------------
; Engine3D_SignedMul8
; Signed 8-bit by signed 8-bit multiply. Input A,B. Output signed 16-bit D.
; ---------------------------------------------------------------------------
Engine3D_SignedMul8:
                STA     ENGINE3D_MUL_A
                STB     ENGINE3D_MUL_B
                CLR     ENGINE3D_MUL_NEG

                LDA     ENGINE3D_MUL_A
                BPL     Engine3D_MulAPositive
                NEGA
                STA     ENGINE3D_MUL_A
                LDA     #1
                STA     ENGINE3D_MUL_NEG

Engine3D_MulAPositive:
                LDB     ENGINE3D_MUL_B
                BPL     Engine3D_MulBPositive
                NEGB
                STB     ENGINE3D_MUL_B
                LDA     ENGINE3D_MUL_NEG
                EORA    #1
                STA     ENGINE3D_MUL_NEG

Engine3D_MulBPositive:
                LDA     ENGINE3D_MUL_A
                LDB     ENGINE3D_MUL_B
                MUL
                TST     ENGINE3D_MUL_NEG
                BEQ     Engine3D_MulDone
                COMA
                COMB
                ADDD    #1

Engine3D_MulDone:
                RTS

; ---------------------------------------------------------------------------
; Engine3D_SignedDToByteDiv64
; Arithmetic divide signed D by 64. Output signed byte in A.
; ---------------------------------------------------------------------------
Engine3D_SignedDToByteDiv64:
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
Engine3D_CosTable:
                FCB     64,64,64,63,63,62,61,60,59,58,56,55,53,51,49,47
                FCB     45,43,41,38,36,33,30,27,24,22,19,16,12,9,6,3
                FCB     0,-3,-6,-9,-12,-16,-19,-22,-24,-27,-30,-33,-36,-38,-41,-43
                FCB     -45,-47,-49,-51,-53,-55,-56,-58,-59,-60,-61,-62,-63,-63,-64,-64
                FCB     -64,-64,-64,-63,-63,-62,-61,-60,-59,-58,-56,-55,-53,-51,-49,-47
                FCB     -45,-43,-41,-38,-36,-33,-30,-27,-24,-22,-19,-16,-12,-9,-6,-3
                FCB     0,3,6,9,12,16,19,22,24,27,30,33,36,38,41,43
                FCB     45,47,49,51,53,55,56,58,59,60,61,62,63,63,64,64

Engine3D_SinTable:
                FCB     0,3,6,9,12,16,19,22,24,27,30,33,36,38,41,43
                FCB     45,47,49,51,53,55,56,58,59,60,61,62,63,63,64,64
                FCB     64,64,64,63,63,62,61,60,59,58,56,55,53,51,49,47
                FCB     45,43,41,38,36,33,30,27,24,22,19,16,12,9,6,3
                FCB     0,-3,-6,-9,-12,-16,-19,-22,-24,-27,-30,-33,-36,-38,-41,-43
                FCB     -45,-47,-49,-51,-53,-55,-56,-58,-59,-60,-61,-62,-63,-63,-64,-64
                FCB     -64,-64,-64,-63,-63,-62,-61,-60,-59,-58,-56,-55,-53,-51,-49,-47
                FCB     -45,-43,-41,-38,-36,-33,-30,-27,-24,-22,-19,-16,-12,-9,-6,-3
