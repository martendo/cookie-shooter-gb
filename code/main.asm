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
    
    ASSERT GAME_STATE_IN_GAME == 0
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
    
    ; Status bar
    ld      hl, _SCRN0
    ld      de, StatusBarMap
    ld      c, STATUS_BAR_TILE_HEIGHT
:
    ld      b, SCRN_X_B
    call    MemcopySmall
    push    de
    ld      de, SCRN_VX_B - SCRN_X_B
    add     hl, de
    pop     de
    dec     c
    jr      nz, :-
    ; Background map
    ld      hl, _SCRN0 + (STATUS_BAR_TILE_HEIGHT * SCRN_VX_B)
    xor     a, a
    ld      c, SCRN_Y_B - STATUS_BAR_TILE_HEIGHT
    ld      de, SCRN_VX_B - SCRN_X_B
:
    ld      b, SCRN_X_B
    call    MemsetSmall
    add     hl, de
    dec     c
    jr      nz, :-
    
    ; Copy OAM DMA routine to HRAM
    ld      de, OAMDMA
    ld      hl, hOAMDMA
    ld      b, OAMDMA.end - OAMDMA
    call    MemcopySmall
    
    call    HideAllActors
    ; Set up player
    ld      hl, wOAM + PLAYER_OFFSET
    ; Object 1
    ld      [hl], PLAYER_Y
    inc     l
    ld      [hl], PLAYER_START_X
    inc     l
    ASSERT PLAYER_TILE == 0
    ld      [hli], a    ; a = 0 = PLAYER_TILE
    ld      [hli], a    ; a = 0
    ; Object 2
    ld      [hl], PLAYER_Y
    inc     l
    ld      [hl], PLAYER_START_X + 8
    inc     l
    ld      [hli], a    ; a = 0 = PLAYER_TILE
    ld      [hl], OAMF_XFLIP
    
    ; Reset variables
    ; a = 0
    ldh     [hPressedKeys], a
    ldh     [hNewKeys], a
    ldh     [hCookieCount], a
    ld      hl, hScore
    ld      [hli], a
    ld      [hli], a
    ld      [hli], a
    ld      [hli], a
    ASSERT hScore.end == hCookiesBlasted
    ld      [hli], a
    ld      [hli], a
    dec     a           ; a = $FF
    ldh     [hPlayerInvCountdown], a
    ldh     [hFadeState], a ; Not fading
    ld      a, STARTING_TARGET_COOKIE_COUNT
    ldh     [hTargetCookieCount], a
    ld      a, PLAYER_START_LIVES
    ldh     [hPlayerLives], a
    
    ; Clear actor tables
    ld      hl, wMissileTable
    ld      b, MAX_MISSILE_COUNT
    call    ClearActors
    ld      hl, wCookieTable
    ld      b, MAX_COOKIE_COUNT
    call    ClearActors
    
    ; Set palettes
    ld      a, %11100100
    ldh     [rBGP], a
    ld      a, %10010011
    ldh     [rOBP0], a
    
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
    ; GAME_STATE_IN_GAME
    and     a, a
    jp      z, InGame
    ; GAME_STATE_FADE_GAME_OVER
    dec     a
    jr      z, EmptyLoop
    ; GAME_STATE_GAME_OVER
    dec     a
    jp      z, GameOver

EmptyLoop:
    halt
    
    ldh     a, [hVBlankFlag]
    and     a, a
    jr      z, EmptyLoop
    xor     a, a
    ldh     [hVBlankFlag], a
    
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
