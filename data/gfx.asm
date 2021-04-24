SECTION "Graphics Data", ROM0

SpriteTiles::
INCBIN "res/sprite-tiles.2bpp"
.end::
InGameTiles::
INCBIN "res/in-game-tiles.2bpp"
.end::

StatusBarMap::
INCBIN "res/status-bar.tilemap"

PausedStripMap::
INCBIN "res/paused-strip.tilemap"

TitleScreen9000Tiles::
INCBIN "res/title-screen.2bpp", 0, (8 * 2) * $80
.end::
TitleScreen8800Tiles::
INCBIN "res/title-screen.2bpp", (8 * 2) * $80
.end::
TitleScreenMap::
INCBIN "res/title-screen.tilemap"

ModeSelectTiles::
INCBIN "res/mode-select.2bpp"
INCBIN "res/mode-select-numbers.2bpp"
.end::
ModeSelectMap::
INCBIN "res/mode-select.tilemap"

GameOverTiles::
INCBIN "res/game-over.2bpp"
INCBIN "res/game-over-numbers.2bpp"
.end::
GameOverMap::
INCBIN "res/game-over.tilemap"
