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
    
    ; Check if this score is a new high score
    ld      a, CART_SRAM_ENABLE
    ld      [rRAMG], a
    
    ; Get corresponding high score to check based on game mode
    ld      de, sClassicHighScore.end - 1
    ldh     a, [hGameMode]
    ASSERT GAME_MODE_CLASSIC == 0
    and     a, a
    jr      z, :+
    ASSERT HIGH(sClassicHighScore.end - 1) == HIGH(sSuperHighScore.end - 1)
    ld      e, LOW(sSuperHighScore.end - 1)
:
    push    de      ; Save to draw it onscreen later
    ld      hl, hScore.end - 1
    ld      b, SCORE_BYTE_COUNT
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
    pop     de
    push    de
    ld      l, LOW(hScore.end - 1)  ; h unchanged
    ld      a, [hld]
    ld      [de], a
    dec     e
    ld      a, [hld]
    ld      [de], a
    dec     e
    ld      a, [hl]
    ld      [de], a
    
    ; Show "NEW" sprite
    ld      hl, wShadowOAM
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
    ld      [hl], a     ; a = 0
    
.oldHighScore
    ; Draw high score
    pop     de
    ld      hl, vGameOverHighScore
    lb      bc, GAME_OVER_NUMBER_TILES_START, SCORE_BYTE_COUNT
    call    LCDDrawBCDWithOffset
    
    ASSERT CART_SRAM_DISABLE == 0
    xor     a, a
    ld      [rRAMG], a
    
    ret

GameOver::
    ldh     a, [hNewKeys]
    and     a, PADF_A | PADF_START
    jr      z, :+
    
    ; Reset game
    ld      a, GAME_STATE_IN_GAME
    ld      hl, SetUpGame
    call    StartFade
    jp      Main
    
:
    call    HaltVBlank
    jp      Main
