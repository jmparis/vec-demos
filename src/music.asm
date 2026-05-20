; ==============================
; Demo: Music
; ==============================

;***************************************************************************
; DEFINE SECTION
;***************************************************************************
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

;***************************************************************************
; CODE SECTION
;***************************************************************************
; ---------------------------------------------------------------------------
; InitMusicDemo
; Starts custom cartridge music. The loop restarts it when Vec_Music_Flag reaches
; zero, so the melody repeats until button 2 returns to the menu.
; ---------------------------------------------------------------------------
InitMusicDemo:
                LDA     #1                      ; 1 means "start music"
                STA     Vec_Music_Flag          ; BIOS music state flag in RAM
                RTS

music_demo_loop:
                LDA     Vec_Music_Flag          ; Restart tune when BIOS ends it
                BNE     update_music
                LDA     #1                      ; 1 means "start music"
                STA     Vec_Music_Flag          ; BIOS music state flag in RAM

update_music:
                JSR     DP_to_C8                ; Init_Music_chk requires DP=$C8
                LDU     #NoelMelody             ; Custom cartridge music data
                JSR     Init_Music_chk          ; Update PSG shadow registers
                JSR     Wait_Recal              ; Vectrex BIOS recalibration
                JSR     Do_Sound                ; Copy PSG shadow changes to chip
                JSR     Read_Btns               ; BIOS updates button state RAM
                LDA     Vec_Button_1_2          ; Button 2 returns to main menu
                LBNE    return_to_menu
                JSR     Intensity_5F            ; BIOS beam intensity for title
                LDU     #music_demo_packet
                JSR     Print_Str_yx            ; BIOS print routine
                BRA     music_demo_loop

;***************************************************************************
; DATA SECTION
;***************************************************************************
music_demo_packet:
                FCB     $10,-$20                ; music demo title position
                FCC     "MUSIC"
                FCB     $80                     ; $80 is end of string

; ---------------------------------------------------------------------------
; Custom one-voice music data for the BIOS music sequencer.
; Format: ADSR pointer, TWANG pointer, then note/duration pairs.
; This is an original Christmas-style phrase, not a BIOS built-in tune.
; ---------------------------------------------------------------------------
NoelMelody:
                FDB     NoelAdsrTable           ; ADSR envelope for notes
                FDB     NoelTwangTable          ; no vibrato/twang
                FCB     NOTE_G4,DUR_QUARTER     ; music phrase: rising motif
                FCB     NOTE_G4,DUR_EIGHTH
                FCB     NOTE_A4,DUR_EIGHTH
                FCB     NOTE_G4,DUR_QUARTER
                FCB     NOTE_E4,DUR_QUARTER
                FCB     NOTE_F4,DUR_QUARTER
                FCB     NOTE_G4,DUR_HALF
                FCB     NOTE_C5,DUR_QUARTER
                FCB     NOTE_B4,DUR_EIGHTH
                FCB     NOTE_A4,DUR_EIGHTH
                FCB     NOTE_G4,DUR_QUARTER
                FCB     NOTE_A4,DUR_QUARTER
                FCB     NOTE_B4,DUR_HALF
                FCB     NOTE_D5,DUR_QUARTER
                FCB     NOTE_C5,DUR_EIGHTH
                FCB     NOTE_B4,DUR_EIGHTH
                FCB     NOTE_A4,DUR_QUARTER
                FCB     NOTE_G4,DUR_QUARTER
                FCB     NOTE_E5,DUR_HALF
                FCB     NOTE_D5,DUR_QUARTER
                FCB     NOTE_C5,DUR_QUARTER
                FCB     NOTE_B4,DUR_QUARTER
                FCB     NOTE_A4,DUR_QUARTER
                FCB     NOTE_G4,DUR_HALF
                FCB     NOTE_C4,DUR_END         ; end marker, loop restarts

NoelAdsrTable:
                FDB     $FFEE,$DDCC,$BBAA,$9988 ; soft falling envelope
                FDB     $7777,$6666,$5555,$4444
NoelTwangTable:
                FCB     0,0,0,0,0,0,0,0         ; stable pitch, no vibrato
