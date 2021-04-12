INCLUDE "hardware.inc/hardware.inc"

MACRO lb
    IF LOW(\2) != \2
        WARN "lb: Value \2 is not 8-bit!"
    ENDC
    IF LOW(\3) != \3
        WARN "lb: Value \3 is not 8-bit!"
    ENDC
    ld      \1, (LOW(\2) << 8) + LOW(\3)
ENDM
