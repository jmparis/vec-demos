; ==============================
; Engine3D 6809 Harness
; ==============================

                ORG     $8000

TEST_STATUS     EQU     $C980                   ; $AA on success, error code otherwise
TEST_PROJECTED  EQU     $C981                   ; 2 bytes: projected Y, X

TestStart:
                CLRA
                STA     TEST_STATUS

                JSR     TestSignedMul8
                JSR     TestSignedDToByteDiv64
                JSR     TestLoadTrig
                JSR     TestProjectVertices

                LDA     #$AA
                STA     TEST_STATUS
                SWI

Fail:
                STA     TEST_STATUS
                SWI

; ---------------------------------------------------------------------------
; TestSignedMul8
; Verifies signed 8-bit multiplication used by 3D rotation math.
; ---------------------------------------------------------------------------
TestSignedMul8:
                LDA     #12
                LDB     #-5
                JSR     Engine3D_SignedMul8
                CMPA    #$FF
                BNE     FailMulA
                CMPB    #$C4                    ; -60
                BNE     FailMulA

                LDA     #-7
                LDB     #-9
                JSR     Engine3D_SignedMul8
                CMPA    #$00
                BNE     FailMulB
                CMPB    #63
                BNE     FailMulB
                RTS

FailMulA:
                LDA     #$11
                JMP     Fail

FailMulB:
                LDA     #$12
                JMP     Fail

; ---------------------------------------------------------------------------
; TestSignedDToByteDiv64
; Verifies signed D / 64 conversion used after Q6 multiplications.
; ---------------------------------------------------------------------------
TestSignedDToByteDiv64:
                LDD     #$0800                  ; 2048 / 64 = 32
                JSR     Engine3D_SignedDToByteDiv64
                CMPA    #32
                BNE     FailDivA

                LDD     #$F800                  ; -2048 / 64 = -32
                JSR     Engine3D_SignedDToByteDiv64
                CMPA    #$E0
                BNE     FailDivB
                RTS

FailDivA:
                LDA     #$21
                JMP     Fail

FailDivB:
                LDA     #$22
                JMP     Fail

; ---------------------------------------------------------------------------
; TestLoadTrig
; Verifies direct indexing into separate cosine/sine tables.
; ---------------------------------------------------------------------------
TestLoadTrig:
                LDA     #32                     ; 90 degrees in 128-step table
                STA     ENGINE3D_YAW_ANGLE
                LDA     #64                     ; 180 degrees in 128-step table
                STA     ENGINE3D_PITCH_ANGLE
                JSR     Engine3D_LoadTrig

                LDA     ENGINE3D_YAW_COS
                CMPA    #0
                BNE     FailTrigA
                LDA     ENGINE3D_YAW_SIN
                CMPA    #64
                BNE     FailTrigA
                LDA     ENGINE3D_PITCH_COS
                CMPA    #-64
                BNE     FailTrigB
                LDA     ENGINE3D_PITCH_SIN
                CMPA    #0
                BNE     FailTrigB
                RTS

FailTrigA:
                LDA     #$31
                JMP     Fail

FailTrigB:
                LDA     #$32
                JMP     Fail

; ---------------------------------------------------------------------------
; TestProjectVertices
; Verifies the public projection entry point with simple known rotations.
; ---------------------------------------------------------------------------
TestProjectVertices:
                CLRA                            ; yaw=0, pitch=0
                STA     ENGINE3D_YAW_ANGLE
                STA     ENGINE3D_PITCH_ANGLE
                LDX     #TestVertexA
                LDU     #TEST_PROJECTED
                LDA     #1
                JSR     Engine3D_ProjectVertices
                LDA     TEST_PROJECTED          ; Y = 16 + 8/2
                CMPA    #20
                BNE     FailProjectA
                LDA     TEST_PROJECTED+1        ; X = 32 + 8/2
                CMPA    #36
                BNE     FailProjectA

                LDA     #32                     ; yaw=90, pitch=0
                STA     ENGINE3D_YAW_ANGLE
                CLRA
                STA     ENGINE3D_PITCH_ANGLE
                LDX     #TestVertexA
                LDU     #TEST_PROJECTED
                LDA     #1
                JSR     Engine3D_ProjectVertices
                LDA     TEST_PROJECTED          ; Y = 16 + (-32)/2
                CMPA    #0
                BNE     FailProjectB
                LDA     TEST_PROJECTED+1        ; X = 8 + (-32)/2
                CMPA    #-8
                BNE     FailProjectB
                RTS

FailProjectA:
                LDA     #$41
                JMP     Fail

FailProjectB:
                LDA     #$42
                JMP     Fail

                INCLUDE "src/cube/engine3d.asm"

TestVertexA:
                FCB     32,16,8                 ; X, Y, Z
