INCLUDE "defines.inc"

SECTION "Title Screen", ROM0

LoadTitleScreen::
    call    HideAllObjects
    
    ld      de, TitleScreen9000Tiles
    ld      hl, _VRAM9000
    ld      bc, TitleScreen9000Tiles.end - TitleScreen9000Tiles
    call    LCDMemcopy
    ASSERT TitleScreen8800Tiles == TitleScreen9000Tiles.end
    ld      hl, _VRAM8800
    ld      bc, TitleScreen8800Tiles.end - TitleScreen8800Tiles
    call    LCDMemcopy
    ASSERT TitleScreenMap == TitleScreen8800Tiles.end
    ld      hl, _SCRN0
    ld      c, SCRN_Y_B
    call    LCDMemcopyMap
    
    ; Start menu music if not already playing
    ld      a, [wMusicPlayState]
    ASSERT MUSIC_STATE_STOPPED == 0
    and     a, a
    ret     nz
    
    ld      de, Inst_Menu
    call    Music_PrepareInst
    ld      de, Music_Menu
    jp      Music_Play

TitleScreen::
    ldh     a, [hNewKeys]
    and     a, PADF_A | PADF_START
    jp      z, Main
    
    ; Move on to the game mode select screen
    ld      b, SFX_TITLE_START
    call    SFX_Play
    
    ld      a, GAME_STATE_ACTION_SELECT
    call    StartFade
    jp      Main
