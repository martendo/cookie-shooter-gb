INCLUDE "hardware.inc/hardware.inc"

SECTION "Random Number", ROM0

; @return a Random number
GetRandomNumber::
    push    hl
    ld      hl, hRandomNumber
    add     a, [hl]
    ld      l, LOW(rLY)
    add     a, [hl]
    rrca
    ld      l, LOW(rDIV)
    add     a, [hl]
    ldh     [hRandomNumber], a
    pop     hl
    ret
