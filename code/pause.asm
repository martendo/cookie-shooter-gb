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
    
    call    Music_Resume
    ld      b, SFX_RESUME
    call    SFX_Play
    jp      Main

.quitGame
    ; Return to game mode select screen
    ld      b, SFX_QUIT
    call    SFX_Play
    
    ld      a, GAME_STATE_MODE_SELECT
    call    StartFade
    jp      Main
