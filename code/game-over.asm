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
    
    ld      a, CART_SRAM_ENABLE
    ld      [rRAMG], a
    
    ld      de, sHighScore.end - 1
    ld      hl, hScore.end - 1
    ld      b, sHighScore.end - sHighScore
.checkHighScoreLoop
    ld      a, [de]
    cp      a, [hl]
    jr      c, .newHighScore    ; High score < Score
    jr      nz, .oldHighScore   ; High score > Score
    dec     b
    jr      z, .oldHighScore
    dec     e
    dec     l
    jr      .checkHighScoreLoop
    
.newHighScore
    ; New high score
    
    ; Overwrite high score
    ; h and d unchanged
    ld      e, LOW(sHighScore)
    ld      l, LOW(hScore)
    ld      a, [hli]
    ld      [de], a
    inc     e
    ld      a, [hli]
    ld      [de], a
    inc     e
    ld      a, [hl]
    ld      [de], a
    
    ; Show "NEW" sprite
    ld      hl, wOAM
    ; Object 1
    ld      [hl], NEW_HIGH_SCORE_Y
    inc     l
    ld      [hl], NEW_HIGH_SCORE_X
    inc     l
    ld      [hl], NEW_HIGH_SCORE_TILE
    inc     l
    xor     a, a
    ld      [hli], a
    ; Object 2
    ld      [hl], NEW_HIGH_SCORE_Y
    inc     l
    ld      [hl], NEW_HIGH_SCORE_X + 8
    inc     l
    ld      [hl], NEW_HIGH_SCORE_TILE + 2
    inc     l
    ; a = 0
    ld      [hl], a
    ld      de, hScore.end - 1
    jr      .drawHighScore
    
.oldHighScore
    ; d unchanged
    ld      e, LOW(sHighScore.end - 1)
.drawHighScore
    ld      hl, vHighScore
    ld      c, sHighScore.end - sHighScore
.drawHighScoreLoop
    ldh     a, [rSTAT]
    and     a, STATF_BUSY
    jr      nz, .drawHighScoreLoop
    
    ld      a, [de]
    dec     e
    ld      b, a
    ; High nibble
    swap    a
    and     a, $0F
    add     a, GAME_OVER_NUMBER_TILES_START
    ld      [hli], a
    
:
    ldh     a, [rSTAT]
    and     a, STATF_BUSY
    jr      nz, :-
    
    ld      a, b
    ; Low nibble
    and     a, $0F
    add     a, GAME_OVER_NUMBER_TILES_START
    ld      [hli], a
    dec     c
    jr      nz, .drawHighScoreLoop
    
    xor     a, a    ; CART_SRAM_DISABLE
    ld      [rRAMG], a
    
    ret

GameOver::
    ldh     a, [hNewKeys]
    and     a, PADF_A | PADF_START
    jr      z, :+
    
    ; Reset game, as if coming from the title screen
    ld      a, GAME_STATE_TITLE_SCREEN
    ldh     [hGameState], a
    
    ld      hl, SetUpGame.skipTiles
    call    StartFade
    jp      Main
    
:
    call    HaltVBlank
    jp      Main
