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
    ASSERT GAME_MODE_CLASSIC == 0
    and     a, a
    jr      z, .noPowerUps
    
    ASSERT GAME_MODE_COUNT - 1 == 1
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
    
    ; Check if this score is a new high score
    ld      a, CART_SRAM_ENABLE
    ld      [rRAMG], a
    
    ; Get corresponding top scores list to check based on game mode
    ld      de, sClassicTopScores
    ldh     a, [hGameMode]
    ASSERT GAME_MODE_CLASSIC == 0
    and     a, a
    jr      z, :+
    ASSERT GAME_MODE_COUNT - 1 == 1
    ASSERT sSuperTopScores == sClassicTopScores + (1 << 8)
    inc     d
:
    ld      hl, hScore
    lb      bc, SCORE_BYTE_COUNT, 0
.checkHighScoreLoop
    ld      a, [de]
    cp      a, [hl]
    jr      c, .insertTopScore  ; Top score < Score
    jr      nz, .nextTopScore   ; Top score > Score
    dec     b
    jr      z, .insertTopScore  ; Top score == Score
    inc     e
    inc     l
    jr      .checkHighScoreLoop
    
.nextTopScore
    inc     c
    ld      a, c
    cp      a, TOP_SCORE_COUNT
    ; Not a new top score
    jr      nc, .notNewTopScore
    
    ASSERT SCORE_BYTE_COUNT == 3
    add     a, a
    add     a, c
    ld      e, a
    ld      l, LOW(hScore)
    ld      b, SCORE_BYTE_COUNT
    jr      .checkHighScoreLoop
    
.insertTopScore
    ASSERT LOW(sClassicTopScores.end - 1 - SCORE_BYTE_COUNT) == LOW(sSuperTopScores.end - 1 - SCORE_BYTE_COUNT)
    ld      e, LOW(sClassicTopScores.end - 1 - SCORE_BYTE_COUNT)
    ld      h, d
    ASSERT LOW(sClassicTopScores.end - 1) == LOW(sSuperTopScores.end - 1)
    ld      l, LOW(sClassicTopScores.end - 1)
    
    ld      a, TOP_SCORE_COUNT - 1
    sub     a, c
    jr      z, .saveScore   ; No shifting to do
    ld      b, a
.shiftTopScoresLoop
    REPT SCORE_BYTE_COUNT
    ld      a, [de]
    ld      [hld], a
    dec     e
    ENDR
    dec     b
    jr      nz, .shiftTopScoresLoop
.saveScore
    ld      a, c
    ASSERT SCORE_BYTE_COUNT == 3
    add     a, a
    add     a, c
    ld      e, a
    
    ld      hl, hScore
    REPT SCORE_BYTE_COUNT - 1
    ld      a, [hli]
    ld      [de], a
    inc     e
    ENDR
    ld      a, [hl]
    ld      [de], a
    
    ; Update checksum of top scores
    call    CalcTopScoresChecksum
    ld      [sChecksum], a
    
    ; Save the index of the new top score for the top scores screen
    ld      a, c
    DB      $01     ; ld bc, d16 to consume the next 2 bytes
.notNewTopScore
    ld      a, NO_NEW_TOP_SCORE
    ldh     [hScratch], a
    
    ASSERT CART_SRAM_DISABLE == 0
    xor     a, a
    ld      [rRAMG], a
    
    jp      Music_Pause

GameOver::
    ldh     a, [hNewKeys]
    and     a, PADF_A | PADF_START
    jp      z, Main
    
    ; Move on to the top scores screen
    ld      b, SFX_OK
    call    SFX_Play
    
    ld      a, GAME_STATE_TOP_SCORES
    call    StartFade
    jp      Main
