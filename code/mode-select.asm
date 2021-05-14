INCLUDE "defines.inc"

SECTION "Mode Select Screen", ROM0

LoadModeSelectScreen::
    ld      de, ModeSelectTiles
    ld      hl, _VRAM9000
    ld      bc, ModeSelectTiles.end - ModeSelectTiles
    call    LCDMemcopy
    ld      de, ModeSelectMap
    ld      hl, _SCRN0
    ld      c, SCRN_Y_B
    call    LCDMemcopyMap
    
    ; May be coming from exiting a game, hide all objects but the first 2
    call    HideAllActors
    ; Selection cursor - a cookie!
    ; Object 1
    ld      hl, wShadowOAM + 1
    ld      [hl], MODE_SELECT_CURSOR_X
    inc     l
    ld      [hl], COOKIE_TILE
    inc     l
    ld      [hli], a        ; a = 0
    ; Object 2
    inc     l
    ld      [hl], MODE_SELECT_CURSOR_X + 8
    inc     l
    ld      [hl], COOKIE_TILE + 2
    inc     l
    ld      [hl], a         ; a = 0
    
    ; Set cursor position based on previously selected game mode
    ldh     a, [hGameMode]
    and     a, a
    ld      a, MODE_SELECT_CLASSIC_CURSOR_Y
    jr      z, :+
    ld      a, MODE_SELECT_SUPER_CURSOR_Y
:
    ld      [wShadowOAM + MODE_SELECT_CURSOR_Y1_OFFSET], a
    ld      [wShadowOAM + MODE_SELECT_CURSOR_Y2_OFFSET], a
    ret

ModeSelect::
    ldh     a, [hNewKeys]
    bit     PADB_B, a
    jr      z, :+
    
    ; Return to action select screen
    ld      b, SFX_MENU_BACK
    call    SFX_Play
    
    ld      a, GAME_STATE_ACTION_SELECT
    call    StartFade
    jp      Main
    
:
    ldh     a, [hNewKeys]
    bit     PADB_UP, a
    call    nz, MoveSelectionUp
    ldh     a, [hNewKeys]
    bit     PADB_DOWN, a
    call    nz, MoveSelectionDown
    
    ldh     a, [hNewKeys]
    and     a, PADF_A | PADF_START
    jp      z, Main
    
    ; Start game!
    ld      b, SFX_MENU_START
    call    SFX_Play
    
    ldh     a, [hActionSelection]
    cp      a, ACTION_PLAY
    ASSERT ACTION_COUNT - 1 == 1 && ACTION_TOP_SCORES == ACTION_PLAY + 1
    ASSERT GAME_STATE_TOP_SCORES == GAME_STATE_IN_GAME + 1
    adc     a, GAME_STATE_IN_GAME
    call    StartFade
    jp      Main

MoveSelectionUp:
    ldh     a, [hGameMode]
    and     a, a    ; Already at top
    ret     z
    
    dec     a
    ldh     [hGameMode], a
    
    ASSERT GAME_MODE_COUNT - 1 == 1
.setPos
    ld      a, MODE_SELECT_CLASSIC_CURSOR_Y
    ld      [wShadowOAM + MODE_SELECT_CURSOR_Y1_OFFSET], a
    ld      [wShadowOAM + MODE_SELECT_CURSOR_Y2_OFFSET], a
    
    jr      PlaySelectionSfx

MoveSelectionDown:
    ldh     a, [hGameMode]
    ASSERT GAME_MODE_COUNT - 1 == 1
    dec     a   ; Already at bottom
    ret     z
    
    inc     a   ; Undo dec
    inc     a
    ldh     [hGameMode], a
    
    ASSERT GAME_MODE_COUNT - 1 == 1
.setPos
    ld      a, MODE_SELECT_SUPER_CURSOR_Y
    ld      [wShadowOAM + MODE_SELECT_CURSOR_Y1_OFFSET], a
    ld      [wShadowOAM + MODE_SELECT_CURSOR_Y2_OFFSET], a
    
    ; Fallthrough

PlaySelectionSfx:
    ld      b, SFX_MENU_SELECT
    jp      SFX_Play
