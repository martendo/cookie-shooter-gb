INCLUDE "constants/constants.asm"

SECTION "Shadow OAM", WRAM0, ALIGN[8]

wOAM::
    DS      OAM_COUNT * sizeof_OAM_ATTRS

SECTION "Actor RAM", WRAM0

wMissiles::
    DS      MAX_MISSILE_COUNT * ACTOR_SIZE

wCookies::
    DS      MAX_COOKIE_COUNT * ACTOR_SIZE
wCookieSpeeds::
    DS      MAX_COOKIE_COUNT * ACTOR_SIZE
