INCLUDE "defines.inc"

SECTION "Game Over Screen", ROM0

LoadGameOverScreen::
    ld      hl, _SCRN0 + (STATUS_BAR_TILE_HEIGHT * SCRN_VX_B)
    ld      de, GameOverMap
    ld      c, SCRN_Y_B - STATUS_BAR_TILE_HEIGHT
    call    LCDMemcopyMap
    
    jp      HideAllObjects

GameOver::
    ldh     a, [hNewKeys]
    and     a, PADF_A | PADF_START
    jr      z, :+
    
    ld      a, GAME_STATE_FADE_IN_GAME
    ldh     [hGameState], a
    ld      hl, SetUpGame
    call    StartFade
    jp      Main
    
:
    call    HaltVBlank
    jp      Main
