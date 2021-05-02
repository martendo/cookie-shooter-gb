INCLUDE "defines.inc"

SECTION "Title Screen", ROM0

LoadTitleScreen::
    call    HideAllObjects
    
    ld      de, TitleScreen9000Tiles
    ld      hl, _VRAM9000
    ld      bc, TitleScreen9000Tiles.end - TitleScreen9000Tiles
    call    LCDMemcopy
    ld      de, TitleScreen8800Tiles
    ld      hl, _VRAM8800
    ld      bc, TitleScreen8800Tiles.end - TitleScreen8800Tiles
    call    LCDMemcopy
    ld      de, TitleScreenMap
    ld      hl, _SCRN0
    ld      c, SCRN_Y_B
    jp      LCDMemcopyMap

TitleScreen::
    ldh     a, [hNewKeys]
    and     a, PADF_A | PADF_START
    jp      z, Main
    
    ; Move on to the game mode select screen
    ld      b, SFX_TITLE_START
    call    SFX_Play
    
    ld      a, GAME_STATE_MODE_SELECT
    ld      hl, LoadModeSelectScreen
    call    StartFade
    jp      Main
