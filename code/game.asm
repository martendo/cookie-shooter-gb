INCLUDE "defines.inc"

SECTION "In-Game Code", ROM0

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
    
    ; Wait for VBlank
.waitVBL
    halt
    ldh     a, [hVBlankFlag]
    and     a, a
    jr      z, .waitVBL
    xor     a, a
    ldh     [hVBlankFlag], a
    
    jp      Main
