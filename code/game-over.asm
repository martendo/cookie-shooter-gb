INCLUDE "defines.inc"

SECTION "Game Over Screen", ROM0

LoadGameOverScreen::
    call    HideAllObjects
    
    ld      de, GameOverTiles
    ld      hl, _VRAM8800
    ld      bc, GameOverTiles.end - GameOverTiles
    call    LCDMemcopy
    ld      de, GameOverMap
    ld      hl, _SCRN0 + (STATUS_BAR_TILE_HEIGHT * SCRN_VX_B)
    ld      c, SCRN_Y_B - STATUS_BAR_TILE_HEIGHT
    call    LCDMemcopyMap
    
    ; Remove current power-up
    ldh     a, [hGameMode]
    ASSERT GAME_MODE_COUNT - 1 == 1 && GAME_MODE_CLASSIC == 0
    and     a, a
    jr      z, .noPowerUps
    
    ld      hl, vCurrentPowerUp
:
    ldh     a, [rSTAT]
    and     a, STATF_BUSY
    jr      nz, :-
    ; 2 cycles
    ld      a, NO_POWER_UP + POWER_UP_CURRENT_TILES_START
    ld      [hli], a    ; 2 cycles
    inc     a           ; 1 cycle
    ld      [hl], a     ; 2 cycles
    ASSERT HIGH(vCurrentPowerUp + 1) == HIGH(vCurrentPowerUp + SCRN_VX_B)
    ; 2 cycles
    ld      l, LOW(vCurrentPowerUp + SCRN_VX_B)
    inc     a           ; 1 cycle
    ld      [hli], a    ; 2 cycles
    inc     a           ; 1 cycle
    ld      [hl], a     ; 2 cycles
    ; Total 15 cycles
.noPowerUps
    jp      Music_Pause

GameOver::
    ldh     a, [hNewKeys]
    and     a, PADF_A | PADF_START
    jp      z, Main
    
    ; Move on to the top scores screen
    ld      b, SFX_OK
    call    SFX_Play
    
    ld      a, GAME_STATE_TOP_SCORES
    ld      hl, LoadTopScoresScreen
    call    StartFade
    jp      Main
