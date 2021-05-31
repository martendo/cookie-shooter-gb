INCLUDE "defines.inc"

SECTION "Paused Game Code", ROM0

Paused::
    ; Wait for VBlank
    halt
    ldh     a, [hVBlankFlag]
    and     a, a
    jr      z, Paused
    xor     a, a
    ldh     [hVBlankFlag], a
    
    ldh     a, [hNewKeys]
    bit     PADB_START, a
    jr      z, Paused
    
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
    jp      InGame

.quitGame
    ; Return to game mode select screen
    ld      b, SFX_QUIT
    call    SFX_Play
    
    ld      a, GAME_STATE_MODE_SELECT
    jp      Fade
