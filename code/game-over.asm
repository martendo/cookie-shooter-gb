INCLUDE "defines.inc"

SECTION "Game Over Screen", ROM0

LoadGameOverScreen::
    ld      hl, _SCRN0 + (STATUS_BAR_TILE_HEIGHT * SCRN_VX_B)
    ld      de, GameOverMap
    ld      c, SCRN_Y_B - STATUS_BAR_TILE_HEIGHT
    call    LCDMemcopyMap
    
    jp      HideAllObjects

GameOver::
    ; TODO: Make game over screen
    jp      Main
