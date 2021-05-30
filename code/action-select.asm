INCLUDE "defines.inc"

SECTION "Action Select Variables", HRAM

hActionSelection::
    DS 1

SECTION "Action Select Screen", ROM0

LoadActionSelectScreen::
    ld      de, ActionSelectTiles
    ld      hl, _VRAM9000
    ld      bc, ActionSelectTiles.end - ActionSelectTiles
    rst     LCDMemcopy
    ld      de, ActionSelectMap
    ld      hl, _SCRN0
    ld      c, SCRN_Y_B
    rst     LCDMemcopyMap
    
    ; Selection cursor - a cookie!
    ; Object 1
    ld      hl, wShadowOAM + 1
    ld      [hl], ACTION_SELECT_CURSOR_X
    inc     l
    ld      [hl], COOKIE_TILE
    inc     l
    xor     a, a
    ld      [hli], a
    ; Object 2
    inc     l
    ld      [hl], ACTION_SELECT_CURSOR_X + 8
    inc     l
    ld      [hl], COOKIE_TILE + 2
    inc     l
    ld      [hl], a         ; a = 0
    
    ; Set cursor position based on previously selected game mode
    ldh     a, [hActionSelection]
    and     a, a
    ld      a, ACTION_SELECT_PLAY_CURSOR_Y
    jr      z, :+
    ld      a, ACTION_SELECT_TOP_SCORES_CURSOR_Y
:
    ld      [wShadowOAM + ACTION_SELECT_CURSOR_Y1_OFFSET], a
    ld      [wShadowOAM + ACTION_SELECT_CURSOR_Y2_OFFSET], a
    ret

ActionSelect::
    ldh     a, [hNewKeys]
    bit     PADB_B, a
    jr      z, :+
    
    ; Return to title screen
    ld      b, SFX_MENU_BACK
    call    SFX_Play
    
    ASSERT GAME_STATE_TITLE_SCREEN == 0
    xor     a, a
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
    
    ; Move on to the next screen!
    ld      b, SFX_MENU_START
    call    SFX_Play
    
    ld      a, GAME_STATE_MODE_SELECT
    call    StartFade
    jp      Main

MoveSelectionUp:
    ldh     a, [hActionSelection]
    and     a, a    ; Already at top
    ret     z
    
    dec     a
    ldh     [hActionSelection], a
    
    ASSERT ACTION_COUNT - 1 == 1
.setPos
    ld      a, ACTION_SELECT_PLAY_CURSOR_Y
    ld      [wShadowOAM + ACTION_SELECT_CURSOR_Y1_OFFSET], a
    ld      [wShadowOAM + ACTION_SELECT_CURSOR_Y2_OFFSET], a
    
    jr      PlaySelectionSfx

MoveSelectionDown:
    ldh     a, [hActionSelection]
    ASSERT ACTION_COUNT - 1 == 1
    dec     a   ; Already at bottom
    ret     z
    
    inc     a   ; Undo dec
    inc     a
    ldh     [hActionSelection], a
    
    ASSERT ACTION_COUNT - 1 == 1
.setPos
    ld      a, ACTION_SELECT_TOP_SCORES_CURSOR_Y
    ld      [wShadowOAM + ACTION_SELECT_CURSOR_Y1_OFFSET], a
    ld      [wShadowOAM + ACTION_SELECT_CURSOR_Y2_OFFSET], a
    
    ; Fallthrough

PlaySelectionSfx:
    ld      b, SFX_MENU_SELECT
    jp      SFX_Play
