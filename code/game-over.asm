INCLUDE "defines.inc"

SECTION "Game Over Screen", ROM0

LoadGameOverScreen::
    ld      hl, _SCRN0 + (STATUS_BAR_TILE_HEIGHT * SCRN_VX_B)
    ld      de, GameOverMap
    ld      c, SCRN_Y_B - STATUS_BAR_TILE_HEIGHT
.mapLoop
    ld      b, SCRN_X_B
.rowLoop
    ldh     a, [rSTAT]
    and     a, STATF_BUSY
    jr      nz, .rowLoop
    
    ld      a, [de]
    ld      [hli], a
    inc     de
    dec     b
    jr      nz, .rowLoop
    
    push    de
    ld      de, SCRN_VX_B - SCRN_X_B
    add     hl, de
    pop     de
    dec     c
    jr      nz, .mapLoop
    
    jp      HideAllObjects

GameOver::
    ; TODO: Make game over screen
    jp      Main
