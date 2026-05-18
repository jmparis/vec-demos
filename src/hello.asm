; ============================
; Vectrex Program: Hello World
; ============================

;***************************************************************************
; DEFINE SECTION
;***************************************************************************
                INCLUDE "../include/vectrex.i"

text_packet     EQU     $C880                   ; user RAM: Y, X, string, $80
text_y          EQU     text_packet             ; user RAM: text Y position
text_dy         EQU     $C890                   ; user RAM: text direction
rot_angle       EQU     $C891                   ; user RAM: rotation angle
rot_buffer      EQU     $C8A0                   ; user RAM: rotated vectors
text_packet_len EQU     text_packet_end - text_packet_template
text_y_min      EQU     -$40                    ; bottom limit
text_y_max      EQU     $40                     ; top limit
text_step       EQU     1                       ; vertical speed
rot_step        EQU     2                       ; 128 frames per full turn
rot_vectors     EQU     4                       ; vector count minus 1
vector_scale    EQU     $30                     ; VIA T1 draw scale
; start of vectrex memory with cartridge name...
                ORG     $0
;***************************************************************************
; HEADER SECTION
;***************************************************************************
                FCC     "g GCE 1998"            ; 'g' is copyright sign
                FCB     $80                     ; reserved
                FDB     music1                  ; music from the rom
                FCB     $F8,$50,$20,$AA         ; height, width, rel y, rel x
                                                ; (from 0,0)
                FCC     "PROG 1"                ; some game information,
                FCB     $80                     ; ending with $80
                FCB     0                       ; end of game header
;***************************************************************************
; CODE SECTION
;***************************************************************************
; here the cartridge program starts off
main:
                LDX     #text_packet_template   ; ROM template: Y, X, string
                LDU     #text_packet            ; RAM packet for Print_Str_yx
                LDB     #text_packet_len        ; Copy count, including $80
copy_text_packet:
                LDA     ,X+
                STA     ,U+
                DECB
                BNE     copy_text_packet

                LDA     #$10                    ; Initial text position Y
                STA     text_y
                LDA     #text_step              ; Start by moving up
                STA     text_dy
                CLRA                            ; Start rotation at 0 degrees
                STA     rot_angle
main_loop:
                JSR     Wait_Recal              ; Vectrex BIOS recalibration
                JSR     Intensity_5F            ; Sets the intensity of the
                                                ; vector beam to $5f
                LDU     #text_packet            ; address of Y, X, string
                JSR     Print_Str_yx            ; Vectrex BIOS print routine

                LDA     rot_angle               ; BIOS rotation angle, 0..255
                LDB     #rot_vectors            ; number of vectors minus one
                LDX     #diamond_vectors        ; source vector list, no count
                LDU     #rot_buffer             ; RAM destination for rotation
                JSR     Rot_VL_ab               ; rotate vectors into buffer

                JSR     DP_to_D0                ; Restore DP for VIA/BIOS draw
                JSR     Reset0Ref               ; Re-center before object draw
                LDA     text_y                  ; Object follows text Y motion
                LDB     #$40                    ; Object relative X position
                JSR     Moveto_d_7F             ; BIOS move before vector draw
                LDX     #rot_buffer             ; rotated vector list
                LDA     #rot_vectors            ; number of vectors to draw
                LDB     #vector_scale           ; BIOS draw scale factor
                JSR     Mov_Draw_VL_ab          ; Draw rotated vector object

                LDA     rot_angle               ; Advance rotation every frame
                ADDA    #rot_step
                STA     rot_angle

                LDA     text_y                  ; Move text up/down
                ADDA    text_dy
                STA     text_y
                CMPA    #text_y_max
                BLT     check_bottom
                LDA     #text_y_max
                STA     text_y
                LDA     #-text_step
                STA     text_dy
                BRA     main_loop
check_bottom:
                CMPA    #text_y_min
                BGT     main_loop
                LDA     #text_y_min
                STA     text_y
                LDA     #text_step
                STA     text_dy
                BRA     main_loop               ; and repeat forever
;***************************************************************************
; DATA SECTION
;***************************************************************************
text_packet_template:
                FCB     $10,-$50                ; relative Y, X position
                FCC   	"HELLO WORLD !"         ; only capital letters
                FCB   	$80                     ; $80 is end of string
text_packet_end:
diamond_vectors:
                FCB     $20,$00                 ; vector math: top point
                FCB     -$20,$20                ; vector math: right point
                FCB     -$20,-$20               ; vector math: bottom point
                FCB     $20,-$20                ; vector math: left point
                FCB     $20,$20                 ; vector math: close shape
;***************************************************************************
                END  	main
;***************************************************************************
