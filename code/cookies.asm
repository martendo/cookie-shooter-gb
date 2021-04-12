INCLUDE "hardware.inc/hardware.inc"
INCLUDE "constants/cookies.asm"

SECTION "Cookie Code", ROM0

ClearAllCookies::
    ld      hl, wOAM + COOKIES_OFFSET
    ld      bc, sizeof_OAM_ATTRS
    ld      d, OAM_COUNT - (COOKIES_OFFSET / sizeof_OAM_ATTRS)
    xor     a, a
.loop
    ld      [hl], a
    add     hl, bc
    dec     d
    jr      nz, .loop
    ret
