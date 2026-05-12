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
                JSR     Wait_Recal              ; Vectrex BIOS recalibration
                JSR     Intensity_5F            ; Sets the intensity of the
                                                ; vector beam to $5f
                LDU     #hello_world_string     ; address of string
                LDA     #$10                    ; Text position relative Y
                LDB     #-$50                   ; Text position relative X
                JSR     Print_Str_d             ; Vectrex BIOS print routine
                BRA     main                    ; and repeat forever
;***************************************************************************
; DATA SECTION
;***************************************************************************
hello_world_string:
                FCC   	"HELLO WORLD !"         ; only capital letters
                FCB   	$80                     ; $80 is end of string
;***************************************************************************
                END  	main
;***************************************************************************
