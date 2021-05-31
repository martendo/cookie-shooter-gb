INCLUDE "defines.inc"

SECTION "Graphics Code", ROM0

; Draw hearts to show player's remaining lives
DrawHearts::
    ldh     a, [hPlayerLives]
.skip::
    and     a, a    ; No hearts to draw
    
    ld      hl, vHearts
    ld      de, SCRN_VX_B
    
    jr      z, .noHearts
    
    lb      bc, HEART_TILE1, HEART_TILE2
    ; a = player lives
    call    .draw
    ldh     a, [hPlayerLives]
.noHearts
    ld      b, a
    ld      a, PLAYER_MAX_LIVES
    sub     a, b    ; a = heart spaces to erase
    ret     z       ; None, done
    
    lb      bc, IN_GAME_BACKGROUND_TILE, IN_GAME_BACKGROUND_TILE
    ; Fall through

; @param    b   Top tile
; @param    c   Bottom tile
.draw
    ldh     [hScratch], a
:
    ldh     a, [rSTAT]
    and     a, STATF_BUSY
    jr      nz, :-
    
    ldh     a, [hScratch]   ; 3 cycles
    ld      [hl], b         ; 2 cycles
    add     hl, de          ; 2 cycles
    ld      [hl], c         ; 2 cycles
    add     hl, de
    ; Total 9 cycles
    
    dec     a
    jr      nz, .draw
    ret

; Draw all power-ups, including the currently in-use power-up
DrawAllPowerUps::
    ld      hl, vPowerUps
    ld      de, SCRN_VX_B
    
    ldh     a, [hPowerUps.0]
    ld      b, 0
    call    DrawPowerUp
    ldh     a, [hPowerUps.1]
    ld      b, 1
    call    DrawPowerUp
    ldh     a, [hPowerUps.2]
    ld      b, 2
    call    DrawPowerUp
    
    ld      hl, vCurrentPowerUp
    ldh     a, [hCurrentPowerUp]
    ld      b, -1
    ; Fall through

; Draw a power-up slot
; @param    a   Power-up type
; @param    b   Power-up index (0-2 or -1 for current power-up on status bar)
; @param    hl  Pointer to destination on map
; @param    de  SCRN_VX_B
DrawPowerUp::
    ; Get tiles for the power-up using power-up type
    ASSERT POWER_UP_TILE_COUNT == 4
    add     a, a    ; * 2
    add     a, a    ; * 4
    add     a, POWER_UP_TILES_START
    
    ld      c, a
    ; Is this the currently selected power-up?
    ldh     a, [hPowerUpSelection]
    cp      a, b
    ld      a, c
    jr      nz, :+
    ; Currently selected power-up, use special selection cursor tiles
    add     a, POWER_UP_SELECTED_TILES_START - POWER_UP_TILES_START
    jr      .saveAndDraw
:
    inc     b       ; Currently in-use power-up
    jr      nz, .saveAndDraw
    
    ld      b, a
    ; If near the end of the power-up's duration, flash
    ldh     a, [hPowerUpDuration.hi]
    ASSERT HIGH(POWER_UP_END_FLASH_START) == 0
    and     a, a
    jr      nz, .currentNormal
    ldh     a, [hPowerUpDuration.lo]
    cp      a, LOW(POWER_UP_END_FLASH_START)
    jr      nc, .currentNormal
    cp      a, LOW(POWER_UP_END_FLASH_FAST_START)
    jr      nc, .flashSlow
    
    ; Power-up just about finished, flash fast
    bit     POWER_UP_END_FLASH_FAST_BIT, a
    jr      z, .flashFastOn
    ; Flash off
    ld      b, NO_POWER_UP + POWER_UP_CURRENT_TILES_START
    jr      .draw
.flashFastOn
    ; If just flashed back on, play tick sound effect
    cpl     ; Just underflowed from POWER_UP_END_FLASH_FAST_BIT?
    and     a, POWER_UP_END_FLASH_FAST_MASK
    jr      nz, .currentNormal
    jr      .playSoundEffect
.flashSlow
    ; Still a little bit of time left, flash slowly
    bit     POWER_UP_END_FLASH_BIT, a
    jr      z, .flashSlowOn
    ; Flash off
    ld      b, NO_POWER_UP + POWER_UP_CURRENT_TILES_START
    jr      .draw
.flashSlowOn
    ; If just flashed back on, play tick sound effect
    cpl     ; Just underflowed from POWER_UP_END_FLASH_BIT?
    and     a, POWER_UP_END_FLASH_MASK
    jr      nz, .currentNormal
.playSoundEffect
    ; Play tick sound effect
    push    bc
    push    de
    push    hl
    ld      b, SFX_POWER_UP_TICK
    call    SFX_Play
    pop     hl
    pop     de
    pop     bc
    ; Fall through

.currentNormal
    ; Draw currently in-use power-up with special status bar-background
    ; tiles
    ld      a, b
    add     a, POWER_UP_CURRENT_TILES_START - POWER_UP_TILES_START
.saveAndDraw
    ld      b, a
.draw
    ldh     a, [rSTAT]
    and     a, STATF_BUSY
    jr      nz, .draw
    
    ld      a, b        ; 1 cycle
    ASSERT POWER_UP_TILE_WIDTH == 2
    ld      [hli], a    ; 2 cycles
    inc     a           ; 1 cycle
    ld      [hld], a    ; 2 cycles
    inc     a           ; 1 cycle
    
    add     hl, de      ; 2 cycles
    ASSERT POWER_UP_TILE_HEIGHT - 1 == 1
    
    ASSERT POWER_UP_TILE_WIDTH == 2
    ld      [hli], a    ; 2 cycles
    inc     a           ; 1 cycles
    ld      [hld], a    ; 2 cycles
    ; Total 14 cycles
    
    add     hl, de
    
    ret

; Redraw the score and number of cookies blasted on the status bar
UpdateStatusBar::
    ; Draw score
    ld      de, hScore
    ld      hl, vScore
    lb      bc, NUMBER_TILES_START, SCORE_BYTE_COUNT
    call    LCDDrawBCDWithOffset
    
    ; Draw number of cookies blasted
    ASSERT hCookiesBlasted == hScore.end
    ld      hl, vCookiesBlasted
    lb      bc, NUMBER_TILES_START, COOKIES_BLASTED_BYTE_COUNT
    ; Fall through

; Draw a BCD number onto the background map with an arbitrary tile
; ID offset, even if the LCD is on
; @param    de  Pointer to most significant byte of big-endian BCD number
; @param    hl  Pointer to destination on map
; @param    c   Number of bytes to draw
; @param    b   Tile ID offset
LCDDrawBCDWithOffset::
    ldh     a, [rSTAT]
    and     a, STATF_BUSY
    jr      nz, LCDDrawBCDWithOffset
    
    ; High nibble
    ld      a, [de]     ; 2 cycles
    swap    a           ; 2 cycles
    and     a, $0F      ; 2 cycles
    add     a, b        ; 1 cycle   Add tile ID offset
    ld      [hli], a    ; 2 cycles
    ; Low nibble
    ld      a, [de]     ; 2 cycles
    and     a, $0F      ; 2 cycles
    add     a, b        ; 1 cycle
    ld      [hli], a    ; 2 cycles
    ; Total 16 cycles! Perfect fit!
    
    inc     e
    dec     c
    jr      nz, LCDDrawBCDWithOffset
    ret
