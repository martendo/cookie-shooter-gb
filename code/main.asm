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
    
    ; Copy graphics data to VRAM
    ; Sprites
    ld      de, SpriteTiles
    ld      hl, _VRAM8000
    ld      bc, SpriteTiles.end - SpriteTiles
    call    Memcopy
    ; Background tiles
    ld      hl, _VRAM9000
    ld      a, $FF
    ld      b, 8 * 2
    call    MemsetSmall
    ; Background map
    ld      hl, _SCRN0
    xor     a, a
    ld      c, SCRN_Y_B
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
    ld      bc, OAMDMA.end - OAMDMA
    call    Memcopy
    
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
    ldh     [hCookieCount], a   ; a = 0
    dec     a           ; a = $FF
    ldh     [hPlayerInvCountdown], a
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
    xor     a, a
    ldh     [rIF], a
    inc     a           ; 1 = VBlank interrupt
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

Main:
    ; Read joypad
    ld      c, LOW(rP1)
    ld      a, P1F_5    ; D-pad
    ldh     [c], a
    
    ldh     a, [c]
    ldh     a, [c]
    
    or      a, $F0      ; "Erase" high nibble
    swap    a
    ld      b, a
    
    ld      a, P1F_4    ; Buttons
    ldh     [c], a
    
    ldh     a, [c]
    ldh     a, [c]
    ldh     a, [c]
    ldh     a, [c]
    ldh     a, [c]
    ldh     a, [c]
    
    or      a, $F0
    xor     a, b        ; Combine buttons + d-pad and complement
    
    ld      b, a
    ld      a, [hPressedKeys]
    xor     a, b        ; a = keys that changed state
    and     a, b        ; a = keys that changed to pressed
    ld      [hNewKeys], a
    ld      a, b
    ld      [hPressedKeys], a
    
    ld      a, P1F_5 | P1F_4
    ldh     [c], a
    
    ; Player movement
    ldh     a, [hPressedKeys]
    bit     PADB_LEFT, a
    call    nz, MovePlayerLeft
    ldh     a, [hPressedKeys]
    bit     PADB_RIGHT, a
    call    nz, MovePlayerRight
    
    ; Shoot a missile
    ldh     a, [hNewKeys]
    bit     PADB_A, a
    call    nz, ShootMissile
    
    ; Cookie count is too low, create a new cookie
    ldh     a, [hTargetCookieCount]
    ld      b, a
    ldh     a, [hCookieCount]
    cp      a, b
    call    c, CreateCookie
    
    ; Update player invincibility
    ld      hl, hPlayerInvCountdown
    ld      a, [hl]
    inc     a       ; a = $FF
    jr      z, :+
    
    dec     [hl]
    
    ; Flash player to show invincibility
    bit     PLAYER_INV_FLASH_BIT, [hl]
    jr      nz, .hidePlayer
    ld      a, PLAYER_INV_TILE
    jr      .writePlayerTile
.hidePlayer
    ld      a, PLAYER_TILE
.writePlayerTile
    ld      hl, wOAM + PLAYER_TILE1_OFFSET
    ld      [hl], a
    ld      l, LOW(wOAM + PLAYER_TILE2_OFFSET)
    ld      [hl], a
    
:
    ; Update actors
    call    UpdateMissiles
    call    UpdateCookies
    
    ; Check for game over - no more lives left
    ldh     a, [hPlayerLives]
    and     a, a
    jr      z, GameOver
    ; It's possible for 2 cookies to hit the player in the same frame
    bit     7, a
    jr      nz, GameOver
    
    call    HideAllActors
    
    ; Draw hearts to show player's remaining lives
    ; a = 0
    ld      b, a
    ld      hl, wOAM + PLAYER_END_OFFSET
.drawHeartsLoop
    ld      a, HEART_START_Y
    ld      c, b
    inc     c
:
    dec     c
    jr      z, :+
    add     a, HEART_HEIGHT
    jr      :-
:
    ld      [hli], a
    ld      [hl], HEART_X
    inc     l
    ld      [hl], HEART_TILE
    inc     l
    ld      [hl], 0
    inc     l
    
    inc     b
    ldh     a, [hPlayerLives]
    cp      a, b
    jr      nz, .drawHeartsLoop
    
    add     a, PLAYER_OBJ_COUNT
    ldh     [hNextAvailableOAMSlot], a
    
    ; Copy actor data to OAM
    ld      de, wMissileTable
    call    CopyActorsToOAM
    ld      de, wCookieTable
    call    CopyActorsToOAM
    
    ; Wait for VBlank
    halt
    
    jp      Main

GameOver:
    ; TODO: Make game over screen
    jr      GameOver

SECTION "Shadow OAM", WRAM0, ALIGN[8]

wOAM::
    DS      OAM_COUNT * sizeof_OAM_ATTRS

SECTION "Global Variables", HRAM

hPressedKeys: DS 1
hNewKeys:     DS 1

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
