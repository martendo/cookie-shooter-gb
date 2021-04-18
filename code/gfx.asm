INCLUDE "defines.inc"

SECTION "Graphics", ROM0

SpriteTiles::
INCBIN "res/sprite-tiles.2bpp"
.end::
InGameTiles::
INCBIN "res/in-game-tiles.2bpp"
.end::

StatusBarMap::
INCBIN "res/status-bar.tilemap"

TitleScreen9000Tiles::
INCBIN "res/title-screen.2bpp", 0, (8 * 2) * $80
.end::
TitleScreen8800Tiles::
INCBIN "res/title-screen.2bpp", (8 * 2) * $80
.end::
TitleScreenMap::
INCBIN "res/title-screen.tilemap"

GameOverTiles::
INCBIN "res/game-over.2bpp"
.end::
GameOverMap::
INCBIN "res/game-over.tilemap"

SECTION "Graphics Code", ROM0

; Draw a BCD number onto the background map
; @param de Pointer to most significant byte of BCD number
; @param hl Pointer to destination on map
; @param c  Number of bytes to draw
DrawBCD::
    ASSERT NUMBER_TILES_START == 1
    ld      a, [de]
    dec     e
    ld      b, a
    ; High nibble
    swap    a
    and     a, $0F
    inc     a       ; add a, NUMBER_TILES_START
    ld      [hli], a
    ld      a, b
    ; Low nibble
    and     a, $0F
    inc     a       ; add a, NUMBER_TILES_START
    ld      [hli], a
    dec     c
    jr      nz, DrawBCD
    ret
