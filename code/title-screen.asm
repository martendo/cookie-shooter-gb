INCLUDE "defines.inc"

SECTION "Title Screen", ROM0

LoadTitleScreen::
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
    call    LCDMemcopyMap
    
    jp      HideAllObjects

TitleScreen::
    ldh     a, [hNewKeys]
    and     a, PADF_A | PADF_START
    jr      z, :+
    
    ld      hl, SetUpGame
    call    StartFade
    jp      Main
    
:
    call    HaltVBlank
    jp      Main
