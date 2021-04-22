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

SECTION "Graphics Code", ROM0

; Draw hearts to show player's remaining lives
DrawHearts::
    ldh     a, [hPlayerLives]
    and     a, a    ; Nothing to draw
    ret     z
    
    ld      hl, vHearts
    ld      de, SCRN_VX_B
    lb      bc, HEART_TILE1, HEART_TILE2
    ; a = player lives
    call    .draw
    ldh     a, [hPlayerLives]
    ld      b, a
    ld      a, PLAYER_MAX_LIVES
    sub     a, b    ; a = heart spaces to erase
    ret     z       ; None, done
    
    lb      bc, IN_GAME_BACKGROUND_TILE, IN_GAME_BACKGROUND_TILE
    ; Fallthrough

.draw
    ld      [hl], b
    add     hl, de
    ld      [hl], c
    add     hl, de
    dec     a
    jr      nz, .draw
    ret

; Draw a BCD number onto the status bar
; @param de Pointer to most significant byte of BCD number
; @param hl Pointer to destination on map
; @param c  Number of bytes to draw
DrawStatusBarBCD::
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
    jr      nz, DrawStatusBarBCD
    ret

; Draw a BCD number onto the background map with an arbitrary tile
; ID offset, even if the LCD is on
; @param de Pointer to most significant byte of BCD number
; @param hl Pointer to destination on map
; @param c  Number of bytes to draw
; @param b  Tile ID offset
LCDDrawBCDWithOffset::
    ldh     a, [rSTAT]
    and     a, STATF_BUSY
    jr      nz, LCDDrawBCDWithOffset
    
    ld      a, [de]     ; 2 cycles
    ; High nibble
    swap    a           ; 2 cycles
    and     a, $0F      ; 2 cycles
    add     a, b        ; 1 cycle (Add tile ID offset)
    ld      [hli], a    ; 2 cycles
    ld      a, [de]     ; 2 cycles
    ; Low nibble
    and     a, $0F      ; 2 cycles
    add     a, b        ; 1 cycle
    ld      [hli], a    ; 2 cycles
    ; Total 16 cycles! Perfect fit!
    
    dec     e
    dec     c
    jr      nz, LCDDrawBCDWithOffset
    ret
