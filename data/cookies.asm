INCLUDE "defines.inc"

SECTION "Cookie Data", ROM0

CookieTileTable::
    DB      COOKIE_TILE         ; COOKIE_SIZE_16
    DB      COOKIE_TILE + 4     ; COOKIE_SIZE_14
    DB      COOKIE_TILE + 8     ; COOKIE_SIZE_12
    DB      COOKIE_TILE + 12    ; COOKIE_SIZE_10
    DB      COOKIE_TILE + 16    ; COOKIE_SIZE_8
.end::

CookieHitboxTable::
    ;       Y,  H, X,  W
    DB      2, 12, 2, 12    ; COOKIE_SIZE_16
    DB      3, 10, 3, 10    ; COOKIE_SIZE_14
    DB      4,  8, 4,  8    ; COOKIE_SIZE_12
    DB      5,  6, 5,  6    ; COOKIE_SIZE_10
    DB      6,  4, 6,  4    ; COOKIE_SIZE_8
.end::

; Points values in BCD
CookiePointsTable::
    DW      $25     ; COOKIE_SIZE_16
    DW      $50     ; COOKIE_SIZE_14
    DW      $75     ; COOKIE_SIZE_12
    DW      $100    ; COOKIE_SIZE_10
    DW      $125    ; COOKIE_SIZE_8
.end::
