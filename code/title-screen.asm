INCLUDE "defines.inc"

SECTION "Title Screen", ROM0

LoadTitleScreen::
    call    HideAllObjects
    
    ; Load tiles
    ld      de, TitleScreen9000Tiles
    ld      hl, _VRAM9000
    ld      bc, TitleScreen9000Tiles.end - TitleScreen9000Tiles
    rst     LCDMemcopy
    ASSERT TitleScreen8800Tiles == TitleScreen9000Tiles.end
    ld      hl, _VRAM8800
    ld      bc, TitleScreen8800Tiles.end - TitleScreen8800Tiles
    rst     LCDMemcopy
    ; Load background map
    ASSERT TitleScreenMap == TitleScreen8800Tiles.end
    ld      hl, _SCRN0
    ld      c, SCRN_Y_B
    rst     LCDMemcopyMap
    
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
    ; Wait for VBlank
    halt
    ldh     a, [hVBlankFlag]
    and     a, a
    jr      z, TitleScreen
    xor     a, a
    ldh     [hVBlankFlag], a
    
    ldh     a, [hNewKeys]
    and     a, PADF_A | PADF_START
    jr      z, TitleScreen
    
    ; Move on to the game mode select screen
    ld      b, SFX_TITLE_START
    call    SFX_Play
    
    ld      a, GAME_STATE_ACTION_SELECT
    jp      Fade
