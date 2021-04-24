INCLUDE "defines.inc"

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

; Draw a power-up slot
; @param a  Power-up type
; @param hl Pointer to destination on map
; @param de SCRN_VX_B
DrawPowerUp::
    ; Get tiles with power-up type
    ASSERT POWER_UP_TILE_COUNT == 4
    add     a, a    ; * 2
    add     a, a    ; * 4
    add     a, POWER_UP_TILES_START
    
    ASSERT POWER_UP_TILE_WIDTH == 2
    ld      [hli], a
    inc     a
    ld      [hld], a
    inc     a
    
    add     hl, de
    ASSERT POWER_UP_TILE_HEIGHT - 1 == 1
    
    ASSERT POWER_UP_TILE_WIDTH == 2
    ld      [hli], a
    inc     a
    ld      [hld], a
    
    add     hl, de
    
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
