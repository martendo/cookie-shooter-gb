INCLUDE "defines.inc"

SECTION "Top Scores Screen", ROM0

LoadTopScoresScreen::
    ld      de, TopScoresTiles
    ld      hl, _VRAM9000
    ld      bc, TopScoresTiles.end - TopScoresTiles
    call    LCDMemcopy
    ld      de, TopScoresMap
    ld      hl, _SCRN0
    ld      c, SCRN_Y_B
    call    LCDMemcopyMap
    
    ; Check if this score is a new high score
    ld      a, CART_SRAM_ENABLE
    ld      [rRAMG], a
    
    ; Get corresponding top scores list to check based on game mode
    ld      de, sClassicTopScores
    ldh     a, [hGameMode]
    ASSERT GAME_MODE_COUNT - 1 == 1 && GAME_MODE_CLASSIC == 0
    and     a, a
    jr      z, :+
    ASSERT sSuperTopScores == sClassicTopScores + (1 << 8)
    inc     d
:
    push    de      ; Save to draw it onscreen later
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
    jr      nc, .drawTopScores
    
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
    
    ; Show "NEW" sprite
    ld      hl, wShadowOAM
    ; Object 1
    ld      a, c
    add     a, a
    add     a, a
    add     a, a
    add     a, a
    add     a, NEW_TOP_SCORE_START_Y
    ld      [hli], a
    ld      [hl], NEW_TOP_SCORE_X
    inc     l
    ld      [hl], NEW_TOP_SCORE_TILE
    inc     l
    ld      [hl], 0
    inc     l
    ; Object 2
    ld      [hli], a
    ld      [hl], NEW_TOP_SCORE_X + 8
    inc     l
    ld      [hl], NEW_TOP_SCORE_TILE + 2
    inc     l
    ld      [hl], 0
    
.drawTopScores
    ; Draw high score
    pop     de
    DEF OFFSET = 0
    ld      hl, vGameOverTopScores
    lb      bc, TOP_SCORES_NUMBER_TILES_START, SCORE_BYTE_COUNT
    call    LCDDrawBCDWithOffset
    REPT TOP_SCORE_COUNT - 1
    DEF OFFSET = OFFSET + SCRN_VX_B * 2
    ld      hl, vGameOverTopScores + OFFSET
    ld      c, SCORE_BYTE_COUNT
    call    LCDDrawBCDWithOffset
    ENDR
    
    ASSERT CART_SRAM_DISABLE == 0
    xor     a, a
    ld      [rRAMG], a
    ret

TopScores::
    ldh     a, [hNewKeys]
    and     a, PADF_A | PADF_START
    jp      z, Main
    
    ; Reset game
    ld      b, SFX_OK
    call    SFX_Play
    
    ld      a, GAME_STATE_IN_GAME
    ld      hl, SetUpGame
    call    StartFade
    jp      Main
