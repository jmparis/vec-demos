;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Music note and duration constants for Vectrex BIOS music data             ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        IFNDEF MUSIC_NOTES_I

MUSIC_NOTES_I   EQU     1

NOTE_C4         EQU     $11                     ; BIOS music note: C4
NOTE_D4         EQU     $13                     ; BIOS music note: D4
NOTE_E4         EQU     $15                     ; BIOS music note: E4
NOTE_F4         EQU     $16                     ; BIOS music note: F4
NOTE_G4         EQU     $18                     ; BIOS music note: G4
NOTE_A4         EQU     $1A                     ; BIOS music note: A4
NOTE_B4         EQU     $1C                     ; BIOS music note: B4
NOTE_C5         EQU     $1D                     ; BIOS music note: C5
NOTE_D5         EQU     $1F                     ; BIOS music note: D5
NOTE_E5         EQU     $21                     ; BIOS music note: E5

DUR_EIGHTH      EQU     $08                     ; BIOS music duration value
DUR_QUARTER     EQU     $10                     ; BIOS music duration value
DUR_HALF        EQU     $20                     ; BIOS music duration value
DUR_END         EQU     $80                     ; BIOS music end marker in duration

        ENDC
