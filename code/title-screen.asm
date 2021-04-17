INCLUDE "defines.inc"

SECTION "Title Screen", ROM0

LoadTitleScreen::
    ld      de, TitleScreenMap
    ld      hl, _SCRN0
    ld      c, SCRN_Y_B
    call    LCDMemcopyMap
    
    jp      HideAllActors

TitleScreen::
    ldh     a, [hNewKeys]
    and     a, PADF_A | PADF_START
    jr      z, :+
    
    ld      hl, hGameState
    inc     [hl]
    ld      hl, SetUpGame
    call    StartFade
    jp      Main
    
:
    call    HaltVBlank
    jp      Main
