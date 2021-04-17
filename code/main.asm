INCLUDE "defines.inc"

SECTION "Main", ROM0[$0150]

EntryPoint::
    ld      sp, $E000
    
    ; Wait for VBlank to disable the LCD
.waitVBL
    ldh     a, [rLY]
    cp      a, SCRN_Y
    jr      c, .waitVBL
    
    xor     a, a
    ldh     [rLCDC], a
    
    ldh     [hVBlankFlag], a
    
    ASSERT GAME_STATE_TITLE_SCREEN == 0
    ldh     [hGameState], a
    
    ; Copy graphics data to VRAM
    ; Sprites
    ld      de, SpriteTiles
    ld      hl, _VRAM8000
    ld      b, SpriteTiles.end - SpriteTiles
    call    MemcopySmall
    ; Background tiles
    ld      hl, _VRAM9000
    ld      de, BackgroundTiles
    ld      bc, BackgroundTiles.end - BackgroundTiles
    call    Memcopy
    ld      hl, _VRAM8800
    ld      de, TitleScreenTiles
    ld      bc, TitleScreenTiles.end - TitleScreenTiles
    call    Memcopy
    
    ; Copy OAM DMA routine to HRAM
    ld      de, OAMDMA
    ld      hl, hOAMDMA
    ld      b, OAMDMA.end - OAMDMA
    call    MemcopySmall
    
    ; Reset variables
    xor     a, a
    ldh     [hPressedKeys], a
    ldh     [hNewKeys], a
    dec     a   ; a = $FF
    ldh     [hFadeState], a ; Not fading
    
    ; Set palettes
    ld      a, %11100100
    ldh     [rBGP], a
    ld      a, %10010011
    ldh     [rOBP0], a
    
    call    LoadTitleScreen
    
    ; Set up interrupts
    ld      a, STATUS_BAR_HEIGHT - 1
    ldh     [rLYC], a
    ld      a, STATF_LYC
    ldh     [rSTAT], a
    
    xor     a, a
    ldh     [rIF], a
    ld      a, IEF_VBLANK | IEF_LCDC
    ldh     [rIE], a
    
    ;           +-------- LCD on/off
    ;           |+------- Window tilemap - 0: $9800; 1: $9C00
    ;           ||+------ Window on/off
    ;           |||+----- BG tile data   - 0: $9000; 1: $8000
    ;           ||||+---- BG tilemap     - 0: $9800; 1: $9C00
    ;           |||||+--- OBJ size       - 0: 8x8;   1: 8x16
    ;           ||||||+-- OBJ on/off
    ;           |||||||+- BG Priority on/off
    ld      a, %11000111
    ldh     [rLCDC], a
    
    ei

Main::
    ldh     a, [hGameState]
    ; GAME_STATE_TITLE_SCREEN
    and     a, a
    jp      z, TitleScreen
    ; GAME_STATE_FADE_IN_GAME
    dec     a
    jr      z, EmptyLoop
    ; GAME_STATE_WAIT
    dec     a
    jr      z, Wait
    ; GAME_STATE_IN_GAME
    dec     a
    jp      z, InGame
    ; GAME_STATE_FADE_GAME_OVER
    dec     a
    jr      z, EmptyLoop
    ; GAME_STATE_GAME_OVER
    dec     a
    jp      z, GameOver

EmptyLoop:
    call    HaltVBlank
    jr      Main

HaltVBlank::
    halt
    ldh     a, [hVBlankFlag]
    and     a, a
    jr      z, HaltVBlank
    xor     a, a
    ldh     [hVBlankFlag], a
    ret

Wait:
    xor     a, a
    call    DrawHearts
    
    ld      hl, hWaitCountdown
    dec     [hl]
    jr      nz, :+
    
    ld      l, LOW(hGameState)
    inc     [hl]
    jr      Main
    
:
    call    HaltVBlank
    jr      Main

SECTION "Shadow OAM", WRAM0, ALIGN[8]

wOAM::
    DS      OAM_COUNT * sizeof_OAM_ATTRS

SECTION "Global Variables", HRAM

hPressedKeys:: DS 1
hNewKeys::     DS 1

hGameState::   DS 1

hVBlankFlag::  DS 1

hScore::
.0:: DS 1
.1:: DS 1
.2:: DS 1
.3:: DS 1
.end::

hCookiesBlasted::
.lo:: DS 1
.hi:: DS 1
.end::

hWaitCountdown:: DS 1

hScratch:: DS 1

SECTION "OAM DMA Routine", ROM0

OAMDMA:
    ldh     [c], a
.wait
    dec     b
    jr      nz, .wait
    ret
.end

SECTION "OAM DMA", HRAM

hOAMDMA::
    DS OAMDMA.end - OAMDMA
