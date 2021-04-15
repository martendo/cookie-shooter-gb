INCLUDE "defines.inc"

SECTION "VBlank Interrupt", ROM0[$0040]

VBlankHandler:
    ld      a, HIGH(wOAM)
    lb      bc, 41, LOW(rDMA)
    call    hOAMDMA
    reti
