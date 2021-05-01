INCLUDE "defines.inc"

SECTION "Power-Up Data", ROM0

MACRO point_rate
    ; Get value in thousands
    REDEF RATE = \1 / 1000
    ; Points values in BCD
    REDEF BCD_RATE EQUS "${u:RATE}"
    
    DB BCD_RATE
ENDM

; Point rate - every X points, give the player a certain power-up
PowerUpPointRateTable::
    point_rate 4000     ; POWER_UP_FAST_LASERS
    point_rate 7000     ; POWER_UP_SLOW_COOKIES
    point_rate 9000     ; POWER_UP_DOUBLE_LASERS
    
    point_rate 10000    ; POWER_UP_EXTRA_LIFE
    point_rate 5000     ; POWER_UP_BOMB
.end::

; Power-up duration (in number of frames)
PowerUpDurationTable::
    DW 15 seconds   ; POWER_UP_FAST_LASERS
    DW 15 seconds   ; POWER_UP_SLOW_COOKIES
    DW 20 seconds   ; POWER_UP_DOUBLE_LASERS
.end::
