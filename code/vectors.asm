INCLUDE "defines.inc"

SECTION "VBlank Interrupt", ROM0[$0040]

    jp      VBlankHandler

SECTION "VBlank Handler", ROM0

VBlankHandler:
    push    af
    push    bc
    push    de
    push    hl
    
    ld      a, HIGH(wOAM)
    lb      bc, 41, LOW(rDMA)
    call    hOAMDMA
    
    ; Disable objects for status bar
    ld      hl, rLCDC
    res     1, [hl]
    ld      l, LOW(hVBlankFlag)
    ld      [hl], h ; Non-zero
    
    ldh     a, [hGameState]
    cp      a, GAME_STATE_WAIT
    jr      c, .noStatusBar
    ; Update score and cookies blasted
    ld      de, hCookiesBlasted.end - 1
    ld      hl, COOKIES_BLASTED_ADDR
    ld      c, hCookiesBlasted.end - hCookiesBlasted
    call    DrawBCD
    ASSERT hScore.end == hCookiesBlasted
    ld      hl, SCORE_ADDR
    ld      c, hScore.end - hScore
    call    DrawBCD
.noStatusBar
    
    call    UpdateFade
    
    ; Read joypad
    ld      a, P1F_GET_DPAD
    call    .readPadNibble
    swap    a           ; Move directions to high nibble
    ld      b, a
    
    ld      a, P1F_GET_BTN
    call    .readPadNibble
    xor     a, b        ; Combine buttons and directions + complement
    ld      b, a
    
    ld      a, [hPressedKeys]
    xor     a, b        ; a = keys that changed state
    and     a, b        ; a = keys that changed to pressed
    ld      [hNewKeys], a
    ld      a, b
    ld      [hPressedKeys], a
    
    ld      a, P1F_GET_NONE
    ldh     [rP1], a
    
    pop     hl
    pop     de
    pop     bc
    pop     af
    reti

; @param a  Byte to write to rP1
; @return a  Reading from rP1, ignoring non-input bits
.readPadNibble
    ldh     [rP1], a
    ; Burn 16 cycles between write and read
    call    .ret        ; 10 cycles
    ldh     a, [rP1]    ; 3 cycles
    ldh     a, [rP1]    ; 3 cycles
    ldh     a, [rP1]    ; Read
    or      a, $F0      ; Ignore non-input bits
.ret
    ret

SECTION "STAT Interrupt", ROM0[$0048]

STATHandler:
    push    af
    push    hl
.waitHBL
    ldh     a, [rSTAT]
    and     a, %11      ; Mode 0 - HBlank
    jr      nz, .waitHBL
    ; Enable objects - end of status bar
    ld      hl, rLCDC
    set     1, [hl]
    pop     hl
    pop     af
    reti
