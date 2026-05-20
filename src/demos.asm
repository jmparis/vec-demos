; ==========================
; Vectrex Program: Demos Menu
; ==========================

;***************************************************************************
; DEFINE SECTION
;***************************************************************************
                INCLUDE "../include/vectrex.i"

menu_choice     EQU     $C8C0                   ; user RAM: highlighted menu item
menu_joy_lock   EQU     $C8C1                   ; user RAM: joystick debounce flag
menu_launch     EQU     $C8C2                   ; user RAM: requested menu launch
menu_first      EQU     0                       ; menu index: Hello World demo
menu_second     EQU     1                       ; menu index: Music demo
menu_no_launch  EQU     $FF                     ; no menu entry requested

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
                FCC     "DEMOS"                 ; some game information,
                FCB     $80                     ; ending with $80
                FCB     0                       ; end of game header

;***************************************************************************
; CODE SECTION
;***************************************************************************
; here the cartridge program starts off
main:
                JSR     InitMenu

menu_loop:
                JSR     Wait_Recal              ; Vectrex BIOS recalibration
                JSR     Read_Btns               ; BIOS updates button state RAM
                JSR     Joy_Digital             ; BIOS updates joystick RAM
                JSR     UpdateMenuInput         ; Move cursor or launch a demo
                LDA     menu_launch
                CMPA    #menu_first
                BEQ     launch_hello_world
                CMPA    #menu_second
                BEQ     launch_music_demo
                LDA     #menu_no_launch         ; Unknown entry: keep menu open
                STA     menu_launch
                JSR     DrawMenu                ; Draw menu every frame
                BRA     menu_loop

return_to_menu:
                CLRA
                STA     Vec_Music_Flag          ; Stop BIOS music sequencer
                JSR     DP_to_D0                ; Clear_Sound writes PSG hardware
                JSR     Clear_Sound             ; Silence PSG when leaving a demo
                JSR     InitMenu
                BRA     menu_loop

; ---------------------------------------------------------------------------
; InitMenu
; Resets menu state when the cartridge starts or when a demo exits.
; ---------------------------------------------------------------------------
InitMenu:
                CLRA                            ; Menu starts on first entry
                STA     menu_choice
                STA     menu_joy_lock
                LDA     #menu_no_launch
                STA     menu_launch
                LDA     #3
                STA     Vec_Joy_Mux_1_Y         ; BIOS reads controller 1 Y axis
                RTS

launch_hello_world:
                JSR     InitHelloWorld
                LBRA    hello_loop

launch_music_demo:
                JSR     InitMusicDemo
                LBRA    music_demo_loop

; ---------------------------------------------------------------------------
; UpdateMenuInput
; Reads controller 1 through BIOS-maintained RAM. The joystick lock makes each
; up/down press move one menu entry instead of repeating every frame.
; ---------------------------------------------------------------------------
UpdateMenuInput:
                LDA     Vec_Button_1_1          ; Button 1 edge from Read_Btns
                BEQ     update_joystick
                LDA     menu_choice
                STA     menu_launch             ; Main loop launches the entry
                RTS

update_joystick:
                LDA     Vec_Joy_1_Y             ; Digital Y axis from BIOS
                BNE     check_joy_lock
                STA     menu_joy_lock           ; Neutral: release debounce lock
                RTS

check_joy_lock:
                LDB     menu_joy_lock
                BNE     update_menu_done        ; Wait until joystick is neutral
                LDB     #1
                STB     menu_joy_lock
                TSTA                            ; Positive Y moves upward
                BPL     select_previous

select_next:
                LDA     menu_choice
                CMPA    #menu_second
                BEQ     select_first
                INCA
                STA     menu_choice
                RTS

select_first:
                LDA     #menu_first
                STA     menu_choice
                RTS

select_previous:
                LDA     menu_choice
                CMPA    #menu_first
                BEQ     select_second
                DECA
                STA     menu_choice
                RTS

select_second:
                LDA     #menu_second
                STA     menu_choice
update_menu_done:
                RTS

; ---------------------------------------------------------------------------
; DrawMenu
; Uses BIOS text routines. The selected entry is brighter and uses a leading
; cursor character so the choice remains visible on real vector hardware.
; ---------------------------------------------------------------------------
DrawMenu:
                JSR     Intensity_5F            ; BIOS beam intensity for title
                LDU     #menu_title_packet
                JSR     Print_Str_yx            ; BIOS print routine

                LDA     menu_choice
                CMPA    #menu_first
                BNE     draw_hello_plain
                JSR     Intensity_7F            ; Highlight selected menu item
                LDU     #menu_hello_selected
                JSR     Print_Str_yx
                BRA     draw_music_item

draw_hello_plain:
                JSR     Intensity_3F            ; Dim unselected menu item
                LDU     #menu_hello_plain
                JSR     Print_Str_yx

draw_music_item:
                LDA     menu_choice
                CMPA    #menu_second
                BNE     draw_music_plain
                JSR     Intensity_7F            ; Highlight selected menu item
                LDU     #menu_music_selected
                JSR     Print_Str_yx
                JSR     DrawMenuHelp
                RTS

draw_music_plain:
                JSR     Intensity_3F            ; Dim unselected menu item
                LDU     #menu_music_plain
                JSR     Print_Str_yx
                JSR     DrawMenuHelp
                RTS

; ---------------------------------------------------------------------------
; DrawMenuHelp
; Draws low-intensity controller hints below the main menu entries.
; ---------------------------------------------------------------------------
DrawMenuHelp:
                JSR     Intensity_1F            ; Low intensity for help text
                LDU     #menu_help_run_packet
                JSR     Print_Str_yx            ; BIOS print routine
                LDU     #menu_help_exit_packet
                JSR     Print_Str_yx            ; BIOS print routine
                RTS

;***************************************************************************
; DATA SECTION
;***************************************************************************
menu_title_packet:
                FCB     $50,-$38                ; menu title Y, X position
                FCC     "VECTREX DEMOS"
                FCB     $80                     ; $80 is end of string
menu_hello_selected:
                FCB     $10,-$50                ; first menu entry position
                FCC     "> HELLO WORLD !"
                FCB     $80                     ; $80 is end of string
menu_hello_plain:
                FCB     $10,-$50                ; first menu entry position
                FCC     "  HELLO WORLD !"
                FCB     $80                     ; $80 is end of string
menu_music_selected:
                FCB     -$10,-$50               ; second menu entry position
                FCC     "> MUSIC"
                FCB     $80                     ; $80 is end of string
menu_music_plain:
                FCB     -$10,-$50               ; second menu entry position
                FCC     "  MUSIC"
                FCB     $80                     ; $80 is end of string
menu_help_run_packet:
                FCB     -$50,-$78               ; help text below menu entries
                FCC     "BUTTON 1 TO RUN"
                FCB     $80                     ; $80 is end of string
menu_help_exit_packet:
                FCB     -$68,-$78               ; help text below menu entries
                FCC     "BUTTON 2 TO EXIT"
                FCB     $80                     ; $80 is end of string

                INCLUDE "hello.asm"
                INCLUDE "music.asm"

;***************************************************************************
                END     main
;***************************************************************************
