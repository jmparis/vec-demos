; ========================================
; Vectrex Program: Hello World
; ========================================

; Entry point at address $0000 (reset vector)
        ORG     $0000

; ----------------------------------------
; Music callback pointer (unused, points to default handler)
; ----------------------------------------

music1  EQU     $FD0D

; ----------------------------------------
; Header Vectrex obligatoire (required by Vectrex BIOS)
; ----------------------------------------
; The BIOS looks for specific data at fixed offsets from the reset vector:
; - Offset $00-$1F: Cartridge name and year (16 bytes, $80 terminated)
; - Offset $20-$21: Music callback address (2 bytes)
; - Offset $22-$25: Default scale, vector brightness, etc.
; - Offset $26-$7F: Additional cartridge info

; Cartridge identifier: "g GCE 2025" + $80 terminator
; Format: 'g' (game flag) + 2 spaces + publisher + 4-digit year
        fcc     "g GCE 2026"
        fcb     $80

; Music callback address - called during vertical blank
; Points to a simple return routine (RTS) in ROM
        fdb     music1

; Default scale factor for vectors (precision for coordinate scaling)
        fcb     $F8    ; Default: $F8 = -8 (scaled down)

; Vector brightness intensity ($00-$7F, $FF = max)
        fcb     $50

; Vector timer (delay after drawing, affects refresh rate)
        fcb     $20

; Joystick sensitivity thresholds (Y, X)
        fcb     $80

; Program title displayed in BIOS menu (terminated by $80)
        fcc     "HELLO"
        fcb     $80

; ----------------------------------------
; Programme principal (main program loop)
; ----------------------------------------

main:
loop:
        ; Wait for vertical blank and recalibrate the vector display
        ; This ensures stable vector positioning and prevents drift
        jsr     $F192      ; Wait_Recal

        ; Set display intensity (brightness) for vectors
        ; A register contains intensity value (0-255)
	lda	#$5F
        jsr     $F2A5      ; Intensity

        ; Load address of message string into U register
        ; Print_Str_d ($F37A) reads 2 position bytes (Y, X) then the string
        ldu     #message
        ldx     #$0000         ; Position relative to center of screen
        jsr     $F37A          ; Print_Str_d

        ; Infinite loop - wait for next frame
        ; BIOS Wait_Recal will be called again on next interrupt
        bra     loop

; ----------------------------------------
; Texte affiché (displayed text with position)
; ----------------------------------------

message:
        ; Y coordinate offset from center (-128 to +127)
        ; $10 = 16 = moves down from center
        fcb     $10

        ; X coordinate offset from center (-128 to +127)
        ; $20 = 32 = moves right from center
        fcb     $00

        ; Null-terminated string (must end with $80 per Vectrex BIOS)
        fcc     "HELLO VECTREX!"
        fcb     $80