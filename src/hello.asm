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
menu_choice     EQU     $C8C0                   ; user RAM: highlighted menu item
menu_joy_lock   EQU     $C8C1                   ; user RAM: joystick debounce flag
menu_launch     EQU     $C8C2                   ; user RAM: requested menu launch
text_packet_len EQU     16                      ; Y, X, 13 chars, $80
text_y_min      EQU     -$40                    ; bottom limit
text_y_max      EQU     $40                     ; top limit
text_step       EQU     1                       ; vertical speed
rot_step        EQU     2                       ; 128 frames per full turn
rot_vectors     EQU     4                       ; vector count minus 1
vector_scale    EQU     $30                     ; VIA T1 draw scale
menu_first      EQU     0                       ; menu index: Hello World demo
menu_second     EQU     1                       ; menu index: placeholder demo
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
                BRA     draw_demo2_item

draw_hello_plain:
                JSR     Intensity_3F            ; Dim unselected menu item
                LDU     #menu_hello_plain
                JSR     Print_Str_yx

draw_demo2_item:
                LDA     menu_choice
                CMPA    #menu_second
                BNE     draw_demo2_plain
                JSR     Intensity_7F            ; Highlight selected menu item
                LDU     #menu_demo2_selected
                JSR     Print_Str_yx
                JSR     DrawMenuHelp
                RTS

draw_demo2_plain:
                JSR     Intensity_3F            ; Dim unselected menu item
                LDU     #menu_demo2_plain
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

; ---------------------------------------------------------------------------
; InitHelloWorld
; Copies the string packet to RAM because the demo animates its Y coordinate.
; ---------------------------------------------------------------------------
InitHelloWorld:
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
                RTS

; ---------------------------------------------------------------------------
; InitMusicDemo
; Starts a BIOS built-in tune. The loop restarts it when Vec_Music_Flag reaches
; zero, so the melody repeats until button 2 returns to the menu.
; ---------------------------------------------------------------------------
InitMusicDemo:
                LDA     #1                      ; 1 means "start music"
                STA     Vec_Music_Flag          ; BIOS music state flag in RAM
                RTS

hello_loop:
                JSR     Wait_Recal              ; Vectrex BIOS recalibration
                JSR     Read_Btns               ; BIOS updates button state RAM
                LDA     Vec_Button_1_2          ; Button 2 returns to main menu
                LBNE    return_to_menu
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
                BRA     hello_loop
check_bottom:
                CMPA    #text_y_min
                BGT     hello_loop
                LDA     #text_y_min
                STA     text_y
                LDA     #text_step
                STA     text_dy
                BRA     hello_loop              ; and repeat forever

music_demo_loop:
                LDA     Vec_Music_Flag          ; Restart tune when BIOS ends it
                BNE     update_music
                LDA     #1                      ; 1 means "start music"
                STA     Vec_Music_Flag          ; BIOS music state flag in RAM

update_music:
                JSR     DP_to_C8                ; Init_Music_chk requires DP=$C8
                LDU     #music1                 ; Small BIOS melody
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
menu_title_packet:
                FCB     $50,-$30                ; menu title Y, X position
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
menu_demo2_selected:
                FCB     -$10,-$50               ; second menu entry position
                FCC     "> MUSIC"
                FCB     $80                     ; $80 is end of string
menu_demo2_plain:
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
music_demo_packet:
                FCB     $10,-$20                ; music demo title position
                FCC     "MUSIC"
                FCB     $80                     ; $80 is end of string
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
