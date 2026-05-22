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
menu_top        EQU     $C8C3                   ; user RAM: first visible menu item
menu_hello_ram  EQU     $C8C8                   ; user RAM: Hello menu text packet
menu_music_ram  EQU     $C8DA                   ; user RAM: Music menu text packet
menu_cube_ram   EQU     $C8E4                   ; user RAM: Cube menu text packet
menu_demo4_ram  EQU     $C8ED                   ; user RAM: Demo 4 menu text packet
menu_demo5_ram  EQU     $C8F8                   ; user RAM: Demo 5 menu text packet
menu_first      EQU     0                       ; menu index: Hello World demo
menu_second     EQU     1                       ; menu index: Music demo
menu_third      EQU     2                       ; menu index: Cube demo
menu_fourth     EQU     3                       ; menu index: placeholder demo 4
menu_fifth      EQU     4                       ; menu index: placeholder demo 5
menu_last       EQU     menu_fifth              ; last selectable menu index
menu_visible    EQU     3                       ; visible menu lines at once
menu_max_top    EQU     menu_last-menu_visible+1 ; last scrolling window start
menu_no_launch  EQU     $FF                     ; no menu entry requested
menu_text_first EQU     2                       ; text starts after Y, X bytes
menu_cursor     EQU     $3E                     ; '>' cursor character
menu_space      EQU     $20                     ; space character
menu_hello_len  EQU     18                      ; Y, X, 15 chars, $80
menu_music_len  EQU     10                      ; Y, X, 7 chars, $80
menu_cube_len   EQU     9                       ; Y, X, 6 chars, $80
menu_demo_len   EQU     11                      ; Y, X, 8 chars, $80

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
                CMPA    #menu_third
                BEQ     launch_cube_demo
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

launch_hello_world:
                JSR     InitHelloWorld
                LBRA    hello_loop

launch_music_demo:
                JSR     InitMusicDemo
                LBRA    music_demo_loop

launch_cube_demo:
                JSR     InitCubeDemo
                LBRA    cube_loop

; ---------------------------------------------------------------------------
; InitMenu
; Resets menu state when the cartridge starts or when a demo exits.
; ---------------------------------------------------------------------------
InitMenu:
                CLRA                            ; Menu starts on first entry
                STA     menu_choice
                STA     menu_joy_lock
                STA     menu_top
                LDA     #menu_no_launch
                STA     menu_launch
                LDA     #3
                STA     Vec_Joy_Mux_1_Y         ; BIOS reads controller 1 Y axis
                JSR     CopyMenuTextPackets     ; Copy mutable menu strings to RAM
                RTS

; ---------------------------------------------------------------------------
; CopyMenuTextPackets
; Copies menu text packets to RAM so DrawMenu can patch visible Y coordinates
; and cursor characters without attempting to modify cartridge ROM.
; ---------------------------------------------------------------------------
CopyMenuTextPackets:
                LDX     #menu_hello_template    ; ROM source: Y, X, string
                LDU     #menu_hello_ram         ; RAM packet for Print_Str_yx
                LDB     #menu_hello_len         ; Copy count, including $80
copy_menu_hello:
                LDA     ,X+
                STA     ,U+
                DECB
                BNE     copy_menu_hello

                LDX     #menu_music_template    ; ROM source: Y, X, string
                LDU     #menu_music_ram         ; RAM packet for Print_Str_yx
                LDB     #menu_music_len         ; Copy count, including $80
copy_menu_music:
                LDA     ,X+
                STA     ,U+
                DECB
                BNE     copy_menu_music

                LDX     #menu_cube_template     ; ROM source: Y, X, string
                LDU     #menu_cube_ram          ; RAM packet for Print_Str_yx
                LDB     #menu_cube_len          ; Copy count, including $80
copy_menu_cube:
                LDA     ,X+
                STA     ,U+
                DECB
                BNE     copy_menu_cube

                LDX     #menu_demo4_template    ; ROM source: Y, X, string
                LDU     #menu_demo4_ram         ; RAM packet for Print_Str_yx
                LDB     #menu_demo_len          ; Copy count, including $80
copy_menu_demo4:
                LDA     ,X+
                STA     ,U+
                DECB
                BNE     copy_menu_demo4

                LDX     #menu_demo5_template    ; ROM source: Y, X, string
                LDU     #menu_demo5_ram         ; RAM packet for Print_Str_yx
                LDB     #menu_demo_len          ; Copy count, including $80
copy_menu_demo5:
                LDA     ,X+
                STA     ,U+
                DECB
                BNE     copy_menu_demo5
                RTS

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
                CMPA    #menu_last
                BEQ     select_first
                INCA
                STA     menu_choice
                JSR     UpdateMenuScroll        ; Keep selection inside window
                RTS

select_first:
                LDA     #menu_first
                STA     menu_choice
                STA     menu_top
                RTS

select_previous:
                LDA     menu_choice
                CMPA    #menu_first
                BEQ     select_last
                DECA
                STA     menu_choice
                JSR     UpdateMenuScroll        ; Keep selection inside window
                RTS

select_last:
                LDA     #menu_last
                STA     menu_choice
                LDA     #menu_max_top
                STA     menu_top
update_menu_done:
                RTS

; ---------------------------------------------------------------------------
; UpdateMenuScroll
; Scrolls the menu window only when the selected item leaves the visible
; three-line area. This avoids extra redraw work and keeps movement readable.
; ---------------------------------------------------------------------------
UpdateMenuScroll:
                LDA     menu_choice
                CMPA    menu_top
                BHS     check_scroll_bottom
                STA     menu_top
                RTS

check_scroll_bottom:
                SUBA    menu_top                ; A = selected offset in window
                CMPA    #menu_visible
                BLO     update_scroll_done
                LDA     menu_choice
                SUBA    #menu_visible-1         ; Top follows selected item down
                STA     menu_top
update_scroll_done:
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

                LDA     #menu_space             ; Clear menu cursors in RAM
                STA     menu_hello_ram+menu_text_first
                STA     menu_music_ram+menu_text_first
                STA     menu_cube_ram+menu_text_first
                STA     menu_demo4_ram+menu_text_first
                STA     menu_demo5_ram+menu_text_first
                LDA     menu_choice
                CMPA    #menu_second
                BEQ     mark_music_cursor
                CMPA    #menu_third
                BEQ     mark_cube_cursor
                CMPA    #menu_fourth
                BEQ     mark_demo4_cursor
                CMPA    #menu_fifth
                BEQ     mark_demo5_cursor
                LDA     #menu_cursor
                STA     menu_hello_ram+menu_text_first
                BRA     draw_visible_menu

mark_music_cursor:
                LDA     #menu_cursor
                STA     menu_music_ram+menu_text_first
                BRA     draw_visible_menu

mark_cube_cursor:
                LDA     #menu_cursor
                STA     menu_cube_ram+menu_text_first
                BRA     draw_visible_menu

mark_demo4_cursor:
                LDA     #menu_cursor
                STA     menu_demo4_ram+menu_text_first
                BRA     draw_visible_menu

mark_demo5_cursor:
                LDA     #menu_cursor
                STA     menu_demo5_ram+menu_text_first

draw_visible_menu:
                LDA     menu_top
                CMPA    #menu_second
                BEQ     draw_menu_top_music
                CMPA    #menu_third
                BEQ     draw_menu_top_cube

draw_menu_top_hello:
                LDA     #$10                    ; Top visible menu Y coordinate
                STA     menu_hello_ram
                LDA     #-$10                   ; Middle visible menu Y coordinate
                STA     menu_music_ram
                LDA     #-$30                   ; Bottom visible menu Y coordinate
                STA     menu_cube_ram
                JSR     DrawHelloMenuEntry
                JSR     DrawMusicMenuEntry
                JSR     DrawCubeMenuEntry
                JSR     DrawMenuHelp
                RTS

draw_menu_top_music:
                LDA     #$10                    ; Top visible menu Y coordinate
                STA     menu_music_ram
                LDA     #-$10                   ; Middle visible menu Y coordinate
                STA     menu_cube_ram
                LDA     #-$30                   ; Bottom visible menu Y coordinate
                STA     menu_demo4_ram
                JSR     DrawMusicMenuEntry
                JSR     DrawCubeMenuEntry
                JSR     DrawDemo4MenuEntry
                JSR     DrawMenuHelp
                RTS

draw_menu_top_cube:
                LDA     #$10                    ; Top visible menu Y coordinate
                STA     menu_cube_ram
                LDA     #-$10                   ; Middle visible menu Y coordinate
                STA     menu_demo4_ram
                LDA     #-$30                   ; Bottom visible menu Y coordinate
                STA     menu_demo5_ram
                JSR     DrawCubeMenuEntry
                JSR     DrawDemo4MenuEntry
                JSR     DrawDemo5MenuEntry
                JSR     DrawMenuHelp
                RTS

DrawHelloMenuEntry:
                LDA     menu_hello_ram+menu_text_first
                CMPA    #menu_cursor
                BNE     draw_hello_plain
                JSR     Intensity_7F            ; Highlight selected menu item
                LDU     #menu_hello_ram
                JSR     Print_Str_yx
                RTS

draw_hello_plain:
                JSR     Intensity_3F            ; Dim unselected menu item
                LDU     #menu_hello_ram
                JSR     Print_Str_yx
                RTS

DrawMusicMenuEntry:
                LDA     menu_music_ram+menu_text_first
                CMPA    #menu_cursor
                BNE     draw_music_plain
                JSR     Intensity_7F            ; Highlight selected menu item
                LDU     #menu_music_ram
                JSR     Print_Str_yx
                RTS

draw_music_plain:
                JSR     Intensity_3F            ; Dim unselected menu item
                LDU     #menu_music_ram
                JSR     Print_Str_yx
                RTS

DrawCubeMenuEntry:
                LDA     menu_cube_ram+menu_text_first
                CMPA    #menu_cursor
                BNE     draw_cube_plain
                JSR     Intensity_7F            ; Highlight selected menu item
                LDU     #menu_cube_ram
                JSR     Print_Str_yx
                RTS

draw_cube_plain:
                JSR     Intensity_3F            ; Dim unselected menu item
                LDU     #menu_cube_ram
                JSR     Print_Str_yx
                RTS

DrawDemo4MenuEntry:
                LDA     menu_demo4_ram+menu_text_first
                CMPA    #menu_cursor
                BNE     draw_demo4_plain
                JSR     Intensity_7F            ; Highlight selected menu item
                LDU     #menu_demo4_ram
                JSR     Print_Str_yx
                RTS

draw_demo4_plain:
                JSR     Intensity_3F            ; Dim unselected menu item
                LDU     #menu_demo4_ram
                JSR     Print_Str_yx
                RTS

DrawDemo5MenuEntry:
                LDA     menu_demo5_ram+menu_text_first
                CMPA    #menu_cursor
                BNE     draw_demo5_plain
                JSR     Intensity_7F            ; Highlight selected menu item
                LDU     #menu_demo5_ram
                JSR     Print_Str_yx
                RTS

draw_demo5_plain:
                JSR     Intensity_3F            ; Dim unselected menu item
                LDU     #menu_demo5_ram
                JSR     Print_Str_yx
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
menu_hello_template:
                FCB     0,-$50                  ; Y patched by scrolling menu
                FCC     "  HELLO WORLD !"
                FCB     $80                     ; $80 is end of string
menu_hello_template_end:
menu_music_template:
                FCB     0,-$50                  ; Y patched by scrolling menu
                FCC     "  MUSIC"
                FCB     $80                     ; $80 is end of string
menu_music_template_end:
menu_cube_template:
                FCB     0,-$50                  ; Y patched by scrolling menu
                FCC     "  CUBE"
                FCB     $80                     ; $80 is end of string
menu_cube_template_end:
menu_demo4_template:
                FCB     0,-$50                  ; Y patched by scrolling menu
                FCC     "  DEMO 4"
                FCB     $80                     ; $80 is end of string
menu_demo4_template_end:
menu_demo5_template:
                FCB     0,-$50                  ; Y patched by scrolling menu
                FCC     "  DEMO 5"
                FCB     $80                     ; $80 is end of string
menu_demo5_template_end:
menu_help_run_packet:
                FCB     -$50,-$78               ; help text below menu entries
                FCC     "BUTTON 1 TO RUN"
                FCB     $80                     ; $80 is end of string
menu_help_exit_packet:
                FCB     -$68,-$78               ; help text below menu entries
                FCC     "BUTTON 2 TO EXIT"
                FCB     $80                     ; $80 is end of string

                INCLUDE "hello/hello.asm"
                INCLUDE "music/music.asm"
                INCLUDE "cube/cube.asm"

;***************************************************************************
                END     main
;***************************************************************************
