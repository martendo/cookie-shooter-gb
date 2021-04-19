INCLUDE "defines.inc"

SECTION "Paused Game Code", ROM0

PauseGame::
    ld      a, GAME_STATE_PAUSED
    ldh     [hGameState], a
    
    ld      de, PausedStripMap
    ld      hl, vPausedStrip
    ld      bc, SCRN_X_B
    jr      LCDMemcopy

Paused::
    ldh     a, [hNewKeys]
    bit     PADB_START, a
    jr      z, :+
    
    ; Don't immediately resume the game
    res     PADB_START, a
    ldh     [hNewKeys], a
    
    ld      a, GAME_STATE_IN_GAME
    ldh     [hGameState], a
    
    ld      hl, vPausedStrip
    lb      bc, IN_GAME_BACKGROUND_TILE, SCRN_X_B
    call    LCDMemsetSmall
    jp      Main
    
:
    call    HaltVBlank
    jp      Main
