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
    
    ; Update score and cookies blasted
    ld      de, hCookiesBlasted.end - 1
    ld      hl, COOKIES_BLASTED_ADDR
    ld      c, hCookiesBlasted.end - hCookiesBlasted
    call    .drawBCD
    ASSERT hScore.end == hCookiesBlasted
    ld      hl, SCORE_ADDR
    ld      c, hScore.end - hScore
    call    .drawBCD
    
    pop     hl
    pop     de
    pop     bc
    pop     af
    reti

.drawBCD
    ASSERT NUMBER_TILES_START == 1
    ld      a, [de]
    dec     e
    ld      b, a
    ; High nibble
    swap    a
    and     a, $0F
    inc     a       ; add a, NUMBER_TILES_START
    ld      [hli], a
    ld      a, b
    ; Low nibble
    and     a, $0F
    inc     a       ; add a, NUMBER_TILES_START
    ld      [hli], a
    dec     c
    jr      nz, .drawBCD
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
