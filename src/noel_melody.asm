; ==============================
; Music data: Noel melody
; ==============================

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
