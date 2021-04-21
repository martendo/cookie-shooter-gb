INCLUDE "defines.inc"

SECTION "In-Game Code", ROM0

SetUpGame::
    ; VBlank interrupt handler will read score and cookies blasted
    ; (graphics loading will take a while) so initialize them right away
    xor     a, a
    ld      hl, hScore
    ld      [hli], a
    ld      [hli], a
    ld      [hli], a
    ASSERT hScore.end == hCookiesBlasted
    ld      [hli], a
    ld      [hl], a
    
    ; Tiles
    ld      de, InGameTiles
    ld      hl, _VRAM9000
    ld      bc, InGameTiles.end - InGameTiles
    call    LCDMemcopy
.skipTiles::
    ; Background map
    ld      hl, _SCRN0 + (STATUS_BAR_TILE_HEIGHT * SCRN_VX_B)
    ld      b, IN_GAME_BACKGROUND_TILE
    lb      de, SCRN_Y_B - STATUS_BAR_TILE_HEIGHT, SCRN_VX_B - SCRN_X_B
:
    ld      c, SCRN_X_B
    call    LCDMemsetSmall
    ld      a, d
    ld      d, 0
    add     hl, de
    ld      d, a
    dec     d
    jr      nz, :-
    ; Status bar
    ld      de, StatusBarMap
    ld      hl, _SCRN0
    ld      c, STATUS_BAR_TILE_HEIGHT
    call    LCDMemcopyMap
    
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
    
    ; a = 0
    ldh     [hCookieCount], a
    ASSERT PLAYER_NOT_INV == LOW(-1)
    dec     a            ; a = -1
    ldh     [hPlayerInvCountdown], a
    
    ld      a, START_TARGET_COOKIE_COUNT
    ldh     [hTargetCookieCount], a
    ld      a, PLAYER_START_LIVES
    ldh     [hPlayerLives], a
    
    ; Clear actor tables
    ld      hl, wLaserPosTable
    ld      b, MAX_LASER_COUNT
    call    ClearActors
    ld      hl, wCookiePosTable
    ld      b, MAX_COOKIE_COUNT
    call    ClearActors
    
    call    DrawHearts
    
    ld      a, GAME_START_DELAY_FRAMES
    ldh     [hWaitCountdown], a
    ret

InGame::
    ; Wait before starting the game
    ldh     a, [hWaitCountdown]
    and     a, a
    jr      z, .notWaiting
    
    dec     a
    ldh     [hWaitCountdown], a
    call    HaltVBlank
    jp      Main
    
.notWaiting
    ; Pause the game
    ldh     a, [hNewKeys]
    bit     PADB_START, a
    jr      z, :+
    
    ; Don't immediately resume the game
    res     PADB_START, a
    ldh     [hNewKeys], a
    
    call    PauseGame
    jp      Main
    
:
    ; Player movement
    ldh     a, [hPressedKeys]
    bit     PADB_LEFT, a
    call    nz, MovePlayerLeft
    ldh     a, [hPressedKeys]
    bit     PADB_RIGHT, a
    call    nz, MovePlayerRight
    
    ; Shoot a laser
    ldh     a, [hNewKeys]
    bit     PADB_A, a
    call    nz, ShootLaser
    
    ; Update target cookie count based on score
    ld      hl, hScore.2
    ld      a, [hld]
    ASSERT 10000 / ADD_COOKIE_RATE == 2
    add     a, a
    ld      b, a
    ld      a, [hl] ; hScore.1
    ASSERT ADD_COOKIE_RATE / 1000 < 10 && ADD_COOKIE_RATE / 1000 >= 0
    cp      a, (ADD_COOKIE_RATE / 1000) << 4
    ccf
    ld      a, 0    ; Preserve carry
    adc     a, b
    add     a, START_TARGET_COOKIE_COUNT
    cp      a, MAX_COOKIE_COUNT + 1
    jr      c, :+   ; a <= MAX_COOKIE_COUNT
    ld      a, MAX_COOKIE_COUNT
:
    ld      l, LOW(hTargetCookieCount)
    ld      [hl], a
    ; Cookie count is too low, create a new cookie
    ldh     a, [hCookieCount]
    cp      a, [hl]
    call    c, CreateCookie
    
    ; Update player invincibility
    ld      hl, hPlayerInvCountdown
    ld      a, [hl]
    ASSERT PLAYER_NOT_INV == LOW(-1)
    inc     a       ; a = -1
    jr      z, :+
    
    dec     [hl]
    
    ; Flash player to show invincibility
    ASSERT PLAYER_TILE == 0
    xor     a, a
    bit     PLAYER_INV_FLASH_BIT, [hl]
    jr      nz, .writePlayerTile
    ASSERT PLAYER_INV_TILE == LOW(-1)
    dec     a
.writePlayerTile
    ld      hl, wOAM + PLAYER_TILE1_OFFSET
    ld      [hl], a
    ld      l, LOW(wOAM + PLAYER_TILE2_OFFSET)
    ld      [hl], a
    
:
    ; TODO: Add "Super" mode things - currently exactly the same as classic!!!
    
    ; Update actors
    call    UpdateLasers
    call    UpdateCookies
    
    ; Check for game over - no more lives left
    ldh     a, [hPlayerLives]
    and     a, a
    jr      nz, :+
    
    ld      hl, LoadGameOverScreen
    call    StartFade
    jp      Main
:
    
    call    DrawHearts
    ; Copy actor data to OAM
    ld      de, wLaserPosTable
    call    CopyActorsToOAM
    ld      de, wCookiePosTable
    call    CopyActorsToOAM
    call    HideUnusedObjects
    
    call    HaltVBlank
    
    jp      Main

; Draw hearts to show player's remaining lives
; NOTE: hNextAvailableOAMSlot is overridden, call this before
; CopyActorsToOAM!
DrawHearts::
    ld      b, 0
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
    ret
