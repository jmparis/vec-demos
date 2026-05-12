; ============================
; Vectrex Program: Hello World
; ============================

;***************************************************************************
; DEFINE SECTION
;***************************************************************************
Intensity_5F    EQU     $F2A5                   ; BIOS Intensity routine
Print_Str_d     EQU     $F37A                   ; BIOS print routine
Wait_Recal      EQU     $F192                   ; BIOS recalibration
music1          EQU     $FD0D                   ; address of a (BIOS ROM)
                                                ; music
text_y          EQU     $C880                   ; user RAM: text Y position
text_dy         EQU     $C881                   ; user RAM: text direction
text_y_min      EQU     -$40                    ; bottom limit
text_y_max      EQU     $40                     ; top limit
text_step       EQU     1                       ; vertical speed
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
                LDA     #$10                    ; Initial text position Y
                STA     text_y
                LDA     #text_step              ; Start by moving up
                STA     text_dy
main_loop:
                JSR     Wait_Recal              ; Vectrex BIOS recalibration
                JSR     Intensity_5F            ; Sets the intensity of the
                                                ; vector beam to $5f
                LDU     #hello_world_string     ; address of string
                LDA     text_y                  ; Text position relative Y
                LDB     #-$50                   ; Text position relative X
                JSR     Print_Str_d             ; Vectrex BIOS print routine

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
hello_world_string:
                FCC   	"HELLO WORLD !"         ; only capital letters
                FCB   	$80                     ; $80 is end of string
;***************************************************************************
                END  	main
;***************************************************************************
