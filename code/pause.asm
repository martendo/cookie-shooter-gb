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
    
    ; Some hearts may have been drawn over
    ASSERT PAUSED_STRIP_TILE_Y < STATUS_BAR_TILE_HEIGHT + HEARTS_TILE_OFFSET_Y + (HEART_TILE_HEIGHT * PLAYER_MAX_LIVES)
    call    DrawHearts
    
    ldh     a, [hGameMode]
    ASSERT GAME_MODE_CLASSIC == 0
    and     a, a
    jp      z, Main
    
    ASSERT GAME_MODE_COUNT - 1 == 1
    ; Last power-up has been drawn over
    ASSERT PAUSED_STRIP_TILE_Y < STATUS_BAR_TILE_HEIGHT + POWER_UP_TILE_OFFSET_Y + (POWER_UP_TILE_HEIGHT * MAX_POWER_UP_COUNT)
    ASSERT PAUSED_STRIP_TILE_Y >= STATUS_BAR_TILE_HEIGHT + POWER_UP_TILE_OFFSET_Y + (POWER_UP_TILE_HEIGHT * 2)
    ld      hl, vPowerUps + (2 * SCRN_VX_B * POWER_UP_TILE_HEIGHT)
    ld      de, SCRN_VX_B
    ldh     a, [hPowerUps.2]
    ld      b, 2
    call    DrawPowerUp
    
    jp      Main

.quitGame
    ; Return to game mode select screen
    ld      b, SFX_QUIT
    call    SFX_Play
    
    ld      a, GAME_STATE_MODE_SELECT
    call    StartFade
    jp      Main
