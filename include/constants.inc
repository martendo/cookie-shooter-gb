; Hardware-related
ASSERT LCDCF_OBJON & (1 << 1) != 0
DEF LCDCB_OBJ EQU 1

DEF STAT_MODE_MASK EQU %00000011

DEF DMA_LOOP_CYCLES EQU 1 + 3

DEF STACK_SIZE EQU 24 * 2

DEF seconds EQUS "* 60"

INCLUDE "constants/game.inc"
INCLUDE "constants/power-ups.inc"
INCLUDE "constants/actors.inc"
INCLUDE "constants/player.inc"
INCLUDE "constants/lasers.inc"
INCLUDE "constants/cookies.inc"
INCLUDE "SoundSystemNotes.inc"
INCLUDE "constants/sfx.inc"
INCLUDE "constants/fade.inc"
INCLUDE "constants/mode-select.inc"
INCLUDE "constants/top-scores.inc"
INCLUDE "constants/save.inc"
