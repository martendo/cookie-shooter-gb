INCLUDE "defines.inc"

SECTION "Game Over Screen", ROM0

LoadGameOverScreen::
    call    HideAllObjects
    
    ; Load tiles
    ld      de, GameOverTiles
    ld      hl, _VRAM8800
    ld      bc, GameOverTiles.end - GameOverTiles
    rst     LCDMemcopy
    ; Load background map
    ld      de, GameOverMap
    ld      hl, _SCRN0 + (STATUS_BAR_TILE_HEIGHT * SCRN_VX_B)
    ld      c, SCRN_Y_B - STATUS_BAR_TILE_HEIGHT
    rst     LCDMemcopyMap
    
    ; Erase the current power-up if in Super mode
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
    ; In Super mode, so use the Super mode top scores
    ASSERT LOW(sSuperTopScores) == LOW(sClassicTopScores)
    ld      d, HIGH(sSuperTopScores)
:
    ; Loop over all top scores
    ld      hl, hScore
    lb      bc, SCORE_BYTE_COUNT, 0
    ; c = new top score index
.checkHighScoreLoop
    ld      a, [de]
    cp      a, [hl]
    ; If new score >= top score, insert the new score before it
    jr      c, .insertTopScore  ; Top score < Score
    jr      nz, .nextTopScore   ; Top score > Score
    dec     b
    jr      z, .insertTopScore  ; Top score == Score
    inc     e
    inc     l
    jr      .checkHighScoreLoop
    
.nextTopScore
    ; c = new top score index
    inc     c
    ld      a, c
    cp      a, TOP_SCORE_COUNT
    ; Gone through all top scores -> not a new top score
    jr      nc, .notNewTopScore
    
    ; Move to next top score
    ASSERT SCORE_BYTE_COUNT == 3
    add     a, a
    add     a, c
    ld      e, a
    ld      l, LOW(hScore)
    ld      b, SCORE_BYTE_COUNT
    jr      .checkHighScoreLoop
    
.insertTopScore
    ; Shift all top scores below the new one down a spot
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
    ; c = new top score index
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
    ld      [sCopyChecksum], a
    
    ; Update the copy of the top scores
    ASSERT LOW(sClassicTopScores) == LOW(sSuperTopScores)
    ld      e, LOW(sClassicTopScores)
    ASSERT LOW(sClassicTopScoresCopy) == LOW(sClassicTopScores)
    ASSERT LOW(sSuperTopScoresCopy) == LOW(sSuperTopScores)
    ld      l, e
    ASSERT HIGH(sClassicTopScoresCopy) == HIGH(sClassicTopScores) + 1
    ASSERT HIGH(sSuperTopScoresCopy) == HIGH(sSuperTopScores) + 1
    ld      h, d
    inc     h
    ld      b, sClassicTopScores.end - sClassicTopScores
    call    MemcopySmall
    
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
    ; Wait for VBlank
    halt
    ldh     a, [hVBlankFlag]
    and     a, a
    jr      z, GameOver
    xor     a, a
    ldh     [hVBlankFlag], a
    
    ldh     a, [hNewKeys]
    and     a, PADF_A | PADF_START
    jr      z, GameOver
    
    ; Move on to the top scores screen
    ld      b, SFX_OK
    call    SFX_Play
    
    ld      a, GAME_STATE_TOP_SCORES
    jp      Fade
