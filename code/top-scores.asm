INCLUDE "defines.inc"

SECTION "Top Scores Screen", ROM0

LoadTopScoresScreen::
    ; Load tiles
    ld      de, TopScoresTiles
    ld      hl, _VRAM9000
    ld      bc, TopScoresTiles.end - TopScoresTiles
    rst     LCDMemcopy
    ; Load background map
    ld      de, TopScoresMap
    ld      hl, _SCRN0
    ld      c, SCRN_Y_B
    rst     LCDMemcopyMap
    
    ldh     a, [hActionSelection]
    ASSERT ACTION_COUNT - 1 == 1 && ACTION_TOP_SCORES != 0
    and     a, a
    jr      z, :+
    ; Coming from mode select (after "Top Scores" action), hide
    ; selection cursor
    xor     a, a
    ld      [wShadowOAM + MODE_SELECT_CURSOR_Y1_OFFSET], a
    ld      [wShadowOAM + MODE_SELECT_CURSOR_Y2_OFFSET], a
    ; Just viewing top scores, never a new top score
    jr      .drawTopScores
:
    
    ; Check if there's a new top score
    ldh     a, [hScratch]   ; Index of new top score
    ASSERT NO_NEW_TOP_SCORE + 1 == 0
    inc     a
    jr      z, .drawTopScores
    
    dec     a       ; Undo inc
    ; Show "NEW" sprite
    ld      hl, wShadowOAM
    ; Object 1
    add     a, a    ; * 2
    add     a, a    ; * 4
    add     a, a    ; * 8
    add     a, a    ; * 16
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
    ; Draw top scores
    ld      a, CART_SRAM_ENABLE
    ld      [rRAMG], a
    
    ; Get corresponding top scores list to draw based on game mode
    ld      de, sClassicTopScores
    ldh     a, [hGameMode]
    ASSERT GAME_MODE_CLASSIC == 0
    and     a, a
    jr      z, :+
    ASSERT GAME_MODE_COUNT - 1 == 1
    ASSERT LOW(sSuperTopScores) == LOW(sClassicTopScores)
    ld      d, HIGH(sSuperTopScores)
:
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
    ; Wait for VBlank
    halt
    ldh     a, [hVBlankFlag]
    and     a, a
    jr      z, TopScores
    xor     a, a
    ldh     [hVBlankFlag], a
    
    ldh     a, [hActionSelection]
    ASSERT ACTION_PLAY == 0
    and     a, a
    ldh     a, [hNewKeys]
    jr      nz, .viewing
    
    and     a, PADF_A | PADF_START
    jr      z, TopScores
    
    ; Reset game
    ld      b, SFX_OK
    call    SFX_Play
    jr      .done

.viewing
    bit     PADB_B, a
    jr      z, TopScores
    
    ; Return to mode select screen
    ld      b, SFX_MENU_BACK
    call    SFX_Play
.done
    ld      a, GAME_STATE_MODE_SELECT
    jp      Fade
