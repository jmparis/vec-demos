        ORG     $0000

music1  EQU     $FD0D

; ----------------------------------------
; Header Vectrex obligatoire
; ----------------------------------------

        fcc     "g GCE 2025"
        fcb     $80

        fdb     music1

        fcb     $F8
        fcb     $50
        fcb     $20
        fcb     $80

        fcc     "HELLO"
        fcb     $80

; ----------------------------------------
; Programme principal
; ----------------------------------------

main:
        jsr     $F192      ; Wait_Recal
        jsr     $F2A5      ; Intensity

        ldu     #message
        ldx     #$0000
        jsr     $F37A      ; Print_Str_d

loop:
        bra     loop

; ----------------------------------------
; Texte affiché
; ----------------------------------------

message:
        fcb     $10
        fcb     $20

        fcc     "HELLO VECTREX"
        fcb     $80