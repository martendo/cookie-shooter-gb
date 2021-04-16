INCLUDE "defines.inc"

SECTION "VBlank Interrupt", ROM0[$0040]

    jp      VBlankHandler

SECTION "VBlank Handler", ROM0

VBlankHandler:
    push    af
    push    bc
    push    hl
    
    ld      a, HIGH(wOAM)
    lb      bc, 41, LOW(rDMA)
    call    hOAMDMA
    ; Disable objects for status bar
    ld      hl, rLCDC
    res     1, [hl]
    ld      l, LOW(hVBlankFlag)
    ld      [hl], h ; Non-zero
    
    pop     hl
    pop     bc
    pop     af
    reti

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
