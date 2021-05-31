SECTION "Sprite Tiles", ROM0

SpriteTiles::
    INCBIN "res/sprite-tiles.2bpp"
.end::

SECTION "In-Game Tiles", ROM0

InGameTiles::
    INCBIN "res/in-game-tiles.2bpp"
    INCBIN "res/power-ups.2bpp"
.end::

SECTION "Status Bar Map", ROM0

StatusBarMap::
    INCBIN "res/status-bar.tilemap"

SECTION "Paused Strip Map", ROM0

PausedStripMap::
    INCBIN "res/paused-strip.tilemap"

SECTION "Title Screen $9000 Tiles", ROM0

TitleScreen9000Tiles::
    INCBIN "res/title-screen.2bpp", 0, (8 * 2) * $80
.end::

SECTION "Title Screen $8800 Tiles", ROM0

TitleScreen8800Tiles::
    INCBIN "res/title-screen.2bpp", (8 * 2) * $80
.end::

SECTION "Title Screen Map", ROM0

TitleScreenMap::
    INCBIN "res/title-screen.tilemap"

SECTION "Action Select Screen Tiles", ROM0

ActionSelectTiles::
    INCBIN "res/action-select.2bpp"
.end::

SECTION "Action Select Screen Map", ROM0

ActionSelectMap::
    INCBIN "res/action-select.tilemap"

SECTION "Mode Select Screen Tiles", ROM0

ModeSelectTiles::
    INCBIN "res/mode-select.2bpp"
.end::

SECTION "Mode Select Screen Map", ROM0

ModeSelectMap::
    INCBIN "res/mode-select.tilemap"

SECTION "Game Over Screen Tiles", ROM0

GameOverTiles::
    INCBIN "res/game-over.2bpp"
.end::

SECTION "Game Over Screen Map", ROM0

GameOverMap::
    INCBIN "res/game-over.tilemap"

SECTION "Top Scores Screen Tiles", ROM0

TopScoresTiles::
    INCBIN "res/top-scores.2bpp"
    INCBIN "res/top-scores-numbers.2bpp"
.end::

SECTION "Top Scores Screen Map", ROM0

TopScoresMap::
    INCBIN "res/top-scores.tilemap"
