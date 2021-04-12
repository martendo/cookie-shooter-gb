INCLUDE "constants/missiles.asm"

SECTION "Shadow OAM", WRAM0, ALIGN[8]

wOAM::
    DS      OAM_COUNT * sizeof_OAM_ATTRS

SECTION "Missile RAM", WRAM0

wMissiles::
    DS      MAX_MISSILE_COUNT * MISSILE_SIZE
