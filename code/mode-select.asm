INCLUDE "defines.inc"

SECTION "Mode Select Scree", ROM0

LoadModeSelectScreen::
    ld      de, ModeSelectTiles
    ld      hl, _VRAM9000
    ld      bc, ModeSelectTiles.end - ModeSelectTiles
    call    LCDMemcopy
    ld      de, ModeSelectMap
    ld      hl, _SCRN0
    ld      c, SCRN_Y_B
    call    LCDMemcopyMap
    
    ld      a, CART_SRAM_ENABLE
    ld      [rRAMG], a
    
    ld      de, sClassicHighScore.end - 1
    ld      hl, vModeSelectClassicHighScore
    lb      bc, MODE_SELECT_NUMBER_TILES_START, SCORE_BYTE_COUNT
    call    LCDDrawBCDWithOffset
    ld      de, sSuperHighScore.end - 1
    ld      hl, vModeSelectSuperHighScore
    lb      bc, MODE_SELECT_NUMBER_TILES_START, SCORE_BYTE_COUNT
    call    LCDDrawBCDWithOffset
    
    ASSERT CART_SRAM_DISABLE == 0
    xor     a, a
    ld      [rRAMG], a
    
    ; Selection cursor - a cookie!
    ; Object 1
    ld      hl, wOAM
    ld      [hl], MODE_SELECT_CLASSIC_CURSOR_Y
    inc     l
    ld      [hl], MODE_SELECT_CURSOR_X
    inc     l
    ld      [hl], COOKIE_TILE
    inc     l
    xor     a, a
    ld      [hli], a
    ; Object 2
    ld      [hl], MODE_SELECT_CLASSIC_CURSOR_Y
    inc     l
    ld      [hl], MODE_SELECT_CURSOR_X + 8
    inc     l
    ld      [hl], COOKIE_TILE + 2
    inc     l
    ; a = 0
    ld      [hl], a
    
    ; a = 0
    ldh     [hGameMode], a
    ret

ModeSelect::
    ldh     a, [hGameMode]
    and     a, a
    ld      a, MODE_SELECT_CLASSIC_CURSOR_Y
    jr      z, :+
    ld      a, MODE_SELECT_SUPER_CURSOR_Y
:
    ld      [wOAM + MODE_SELECT_CURSOR_Y1_OFFSET], a
    ld      [wOAM + MODE_SELECT_CURSOR_Y2_OFFSET], a
    
    ldh     a, [hNewKeys]
    bit     PADB_UP, a
    call    nz, .moveSelectionUp
    ldh     a, [hNewKeys]
    bit     PADB_DOWN, a
    call    nz, .moveSelectionDown
    ldh     a, [hNewKeys]
    and     a, PADF_A | PADF_START
    jr      z, :+
    
    ; Start game!
    ld      hl, SetUpGame
    call    StartFade
    jp      Main
    
:
    call    HaltVBlank
    jp      Main

.moveSelectionUp
    ldh     a, [hGameMode]
    and     a, a    ; Already at top
    ret     z
    
    dec     a
    ldh     [hGameMode], a
    ret
.moveSelectionDown
    ldh     a, [hGameMode]
    ASSERT GAME_MODE_COUNT - 1 == 1
    dec     a   ; Already at bottom
    ret     z
    
    inc     a   ; Undo dec
    inc     a
    ldh     [hGameMode], a
    ret
