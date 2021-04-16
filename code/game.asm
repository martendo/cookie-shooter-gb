INCLUDE "defines.inc"

SECTION "In-Game Code", ROM0

SetUpGame::
    ; Background map
    ld      hl, _SCRN0 + (STATUS_BAR_TILE_HEIGHT * SCRN_VX_B)
    ld      b, 0
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
    jp      ClearActors

InGame::
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
    jr      z, .gameOver
    ; It's possible for 2 cookies to hit the player in the same frame
    bit     7, a
    jr      z, :+
    
.gameOver
    ld      hl, hGameState
    ASSERT GAME_STATE_FADE_GAME_OVER == GAME_STATE_IN_GAME + 1
    inc     [hl]
    ld      hl, LoadGameOverScreen
    call    StartFade
    jp      Main
:
    
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
    
    call    HaltVBlank
    
    jp      Main
