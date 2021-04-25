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
    point_rate 5000     ; POWER_UP_SLOW_COOKIES
    point_rate 15000    ; POWER_UP_FREEZE_COOKIES
    point_rate 10000    ; POWER_UP_EXTRA_LIFE

; Power-up duration (in number of frames)
PowerUpDurationTable::
    DW 15 seconds   ; POWER_UP_SLOW_COOKIES
    DW 10 seconds   ; POWER_UP_FREEZE_COOKIES
