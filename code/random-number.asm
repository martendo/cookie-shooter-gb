INCLUDE "defines.inc"

SECTION "Random Number Variables", HRAM

hRandomNumber::
    DS 1

SECTION "Random Number", ROM0

; @return   a   Random number
GenerateRandomNumber::
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
