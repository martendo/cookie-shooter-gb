INCLUDE "defines.inc"

SECTION "Paused Game Code", ROM0

Paused::
    ldh     a, [hNewKeys]
    bit     PADB_START, a
    jp      z, Main
    
    ; Resuming or quitting the game? (SELECT)
    ldh     a, [hPressedKeys]
    bit     PADB_SELECT, a
    jr      nz, .quitGame
    
    ; Resume game
    ld      a, GAME_STATE_IN_GAME
    ldh     [hGameState], a
    
    ld      b, SFX_RESUME
    call    SFX_Play
    call    Music_Resume
    
    ; Erase "paused" strip
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
