INCLUDE "defines.inc"

SECTION "Paused Game Code", ROM0

PauseGame::
    ld      a, GAME_STATE_PAUSED
    ldh     [hGameState], a
    
    ld      b, SFX_PAUSE
    call    SFX_Play
    
    ; Draw "paused" strip
    ld      de, PausedStripMap
    ld      hl, vPausedStrip
    ld      c, PAUSED_STRIP_TILE_HEIGHT
    jp      LCDMemcopyMap

Paused::
    ldh     a, [hNewKeys]
    bit     PADB_START, a
    jp      z, Main
    
    ; Resuming or quitting the game? (SELECT)
    ldh     a, [hPressedKeys]
    bit     PADB_SELECT, a
    jr      nz, .quitGame
    
    ; Resume game
    ; Don't immediately pause the game again
    res     PADB_START, a
    ldh     [hNewKeys], a
    
    ld      a, GAME_STATE_IN_GAME
    ldh     [hGameState], a
    
    ; Erase "paused" strip
    ld      b, SFX_RESUME
    call    SFX_Play
    
    ld      hl, vPausedStrip
    ld      b, IN_GAME_BACKGROUND_TILE
    ld      d, PAUSED_STRIP_TILE_HEIGHT
    call    LCDMemsetMap
    jp      Main

.quitGame
    ; Return to game mode select screen
    ld      b, SFX_QUIT
    call    SFX_Play
    
    ld      a, GAME_STATE_MODE_SELECT
    ld      hl, LoadModeSelectScreen
    call    StartFade
    jp      Main
