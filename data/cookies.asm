INCLUDE "defines.inc"

SECTION "Cookie Data", ROM0

MACRO hitbox
    ; Y, H, X, W
    DB (COOKIE_WIDTH - \1) / 2
    DB \1
    DB (COOKIE_HEIGHT - \1) / 2
    DB \1
ENDM

CookieHitboxTable::
    hitbox 12   ; COOKIE_SIZE_16
    hitbox 10   ; COOKIE_SIZE_14
    hitbox 8    ; COOKIE_SIZE_12
    hitbox 6    ; COOKIE_SIZE_10
    hitbox 4    ; COOKIE_SIZE_8
.end::

; Points values in BCD
CookiePointsTable::
    DW $25  ; COOKIE_SIZE_16
    DW $50  ; COOKIE_SIZE_14
    DW $75  ; COOKIE_SIZE_12
    DW $100 ; COOKIE_SIZE_10
    DW $125 ; COOKIE_SIZE_8
.end::
