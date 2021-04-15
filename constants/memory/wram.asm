INCLUDE "constants/constants.asm"

SECTION "Shadow OAM", WRAM0, ALIGN[8]

wOAM::
    DS      OAM_COUNT * sizeof_OAM_ATTRS

SECTION "Actor RAM", WRAM0

wMissileTable::
    DS      MAX_MISSILE_COUNT * ACTOR_SIZE

wCookieTable::
    DS      MAX_COOKIE_COUNT * ACTOR_SIZE
wCookieSpeedTable::
    DS      MAX_COOKIE_COUNT * ACTOR_SIZE
