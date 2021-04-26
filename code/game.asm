INCLUDE "defines.inc"

SECTION "In-Game Variables", HRAM

hWaitCountdown: DS 1

; Last frame's game score in thousands (e.g. score of 14200 = last score
; thousands of 14)
; Used to tell when the player crossed a multiple of 1000 points for
; checking whether or not to give a power-up
hLastScoreThousands:: DS 1

; Player's power-up slots
hPowerUps::
ASSERT MAX_POWER_UP_COUNT == 3
.1:: DS 1
.2:: DS 1
.3:: DS 1
.end

; Currently selected power-up (out of the 3)
hPowerUpSelection:: DS 1

; Currently in-use power-up
hCurrentPowerUp:: DS 1
; Remaining frames with the current power-up
hPowerUpDuration::
.lo:: DS 1
.hi:: DS 1

SECTION "In-Game Code", ROM0

SetUpGame::
    ; VBlank interrupt handler will read and draw these things on the
    ; screen (graphics loading will take a while) so initialize them
    ; right away
    xor     a, a
    ld      hl, hScore
    REPT SCORE_BYTE_COUNT
    ld      [hli], a
    ENDR
    ASSERT hScore.end == hCookiesBlasted
    REPT COOKIES_BLASTED_BYTE_COUNT
    ld      [hli], a
    ENDR
    
    ASSERT hPowerUps != hCookiesBlasted.end
    ld      l, LOW(hPowerUps)
    ASSERT NO_POWER_UP == 0
    REPT MAX_POWER_UP_COUNT
    ld      [hli], a
    ENDR
    ASSERT hPowerUpSelection == hPowerUps.end
    ld      [hli], a
    ASSERT hCurrentPowerUp == hPowerUpSelection + 1
    ld      [hli], a
    ASSERT hPowerUpDuration == hCurrentPowerUp + 1
    ASSERT NO_POWER_UP_DURATION == HIGH(-1)
    dec     a       ; a = -1
    ld      [hli], a
    ld      [hl], a
    
    ld      a, PLAYER_START_LIVES
    ldh     [hPlayerLives], a
    
    ; Tiles
    ld      de, InGameTiles
    ld      hl, _VRAM9000
    ld      bc, InGameTiles.end - InGameTiles
    call    LCDMemcopy
    ; Background map
    ld      hl, _SCRN0 + (STATUS_BAR_TILE_HEIGHT * SCRN_VX_B)
    ld      b, IN_GAME_BACKGROUND_TILE
    ld      d, SCRN_Y_B - STATUS_BAR_TILE_HEIGHT
    call    LCDMemsetMap
    ; Status bar
    ld      de, StatusBarMap
    ld      hl, _SCRN0
    ld      c, STATUS_BAR_TILE_HEIGHT
    call    LCDMemcopyMap
    
    call    HideAllActors
    ; Set up player
    ld      hl, wShadowOAM + PLAYER_OFFSET
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
    
    ; Clear actor tables
    ; a = 0
    ldh     [hNextAvailableOAMSlot], a
    ld      hl, wLaserPosTable
    ld      b, MAX_LASER_COUNT
    ; a = 0
    call    ClearActors
    ld      hl, wCookiePosTable
    ld      b, MAX_COOKIE_COUNT
    ; a = 0
    call    ClearActors
    
    ; a = 0
    ldh     [hCookieCount], a
    ldh     [hLastScoreThousands], a
    ldh     [hCookieRotationIndex], a
    ASSERT PLAYER_NOT_INV == LOW(-1)
    dec     a            ; a = -1
    ldh     [hPlayerInvCountdown], a
    
    ld      a, START_TARGET_COOKIE_COUNT
    ldh     [hTargetCookieCount], a
    
    ld      a, GAME_START_DELAY_FRAMES
    ldh     [hWaitCountdown], a
    ret

InGame::
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
    ldh     a, [hGameMode]
    ASSERT GAME_MODE_COUNT - 1 == 1 && GAME_MODE_CLASSIC == 0
    and     a, a
    jp      z, .noPowerUps
    
    ; Power-up selection
    ldh     a, [hNewKeys]
    bit     PADB_UP, a
    jr      nz, :+
    
    bit     PADB_DOWN, a
    jr      z, .selectedPowerUp
    
    ; Move power-up selection down
    ldh     a, [hPowerUpSelection]
    cp      a, MAX_POWER_UP_COUNT - 1
    jr      nc, .selectedPowerUp
    inc     a
    ldh     [hPowerUpSelection], a
    jr      .selectedPowerUp

:
    ldh     a, [hPowerUpSelection]
    and     a, a
    jr      z, .selectedPowerUp
    dec     a
    ldh     [hPowerUpSelection], a

.selectedPowerUp
    ld      hl, hPowerUps
    
    ldh     a, [hNewKeys]
    bit     PADB_B, a
    jr      z, .notUsingPowerUp
    
    ; Use a power-up
    ldh     a, [hPowerUpSelection]
    add     a, l
    ld      l, a
    
    ld      a, [hl]
    ASSERT NO_POWER_UP == 0
    and     a, a
    jr      z, .notUsingPowerUp
    
    cp      a, POWER_UP_BOMB
    jr      nz, .notSpecialPowerUp
    
    ; Set power-up as current and remove
    ldh     [hCurrentPowerUp], a
    ld      [hl], NO_POWER_UP
    ; Clear all cookies
    ld      hl, wCookiePosTable
    ld      d, MAX_COOKIE_COUNT
.clearCookiesLoop
    ld      a, [hl]
    and     a, a
    jr      z, :+
    push    hl
    call    BlastCookie
    pop     hl
:
    inc     l
    inc     l
    dec     d
    jr      nz, .clearCookiesLoop
    ld      a, POWER_UP_BOMB
    jr      .setPowerUpDuration
    
.notSpecialPowerUp
    cp      a, POWER_UP_EXTRA_LIFE
    jr      nz, .normalPowerUp
    
    ; Get an extra life
    ldh     a, [hPlayerLives]
    cp      a, PLAYER_MAX_LIVES
    ; Already at max lives, don't add more
    jr      nc, .notUsingPowerUp
    
    ld      [hl], NO_POWER_UP   ; Remove power-up
    ld      l, LOW(hPlayerLives)
    inc     [hl]
    jr      .notUsingPowerUp
    
.normalPowerUp
    ; Set power-up as current and remove
    ldh     [hCurrentPowerUp], a
    ld      [hl], NO_POWER_UP
    
.setPowerUpDuration
    ASSERT POWER_UPS_START - 1 == 0
    dec     a
    add     a, a    ; 1 entry = 2 bytes
    add     a, LOW(PowerUpDurationTable)
    ld      l, a
    ASSERT HIGH(PowerUpDurationTable) == HIGH(PowerUpDurationTable.end)
    ld      h, HIGH(PowerUpDurationTable)
    ld      a, [hli]
    ld      b, [hl]
    
    ld      hl, hPowerUpDuration
    ld      [hli], a
    ld      [hl], b
    
.notUsingPowerUp
    ld      l, LOW(hPowerUpDuration.hi)
    ld      a, [hld]
    ASSERT NO_POWER_UP_DURATION == HIGH(-1)
    inc     a       ; a = -1
    jr      z, .noCurrentPowerUp
    
    ld      e, [hl]
    inc     l
    ld      d, [hl]
    dec     de
    ld      [hl], d
    dec     l
    ld      [hl], e
    jr      .noPowerUps
    
.noCurrentPowerUp
    ASSERT NO_POWER_UP == 0
    xor     a, a
    ldh     [hCurrentPowerUp], a

.noPowerUps
    ; Player movement
    ldh     a, [hPressedKeys]
    ld      b, a    ; Save in b because a will be overwritten
    bit     PADB_LEFT, b
    call    nz, MovePlayerLeft
    bit     PADB_RIGHT, b
    call    nz, MovePlayerRight
    
    ; Shoot a laser
    ldh     a, [hNewKeys]
    bit     PADB_A, a
    call    nz, ShootLaser
    
    ; Delay game start period - don't create any cookies yet
    ldh     a, [hWaitCountdown]
    and     a, a
    jr      z, :+
    
    dec     a
    ldh     [hWaitCountdown], a
    jr      .skipCookieCount
    
:
    ; Don't create any new cookies for certain power-ups
    ldh     a, [hGameMode]
    ASSERT GAME_MODE_COUNT - 1 == 1 && GAME_MODE_CLASSIC == 0
    and     a, a
    jr      z, .updateCookieCount
    
    ldh     a, [hCurrentPowerUp]
    ASSERT POWER_UP_FREEZE_COOKIES + 1 == POWER_UP_BOMB
    ASSERT POWER_UP_BOMB + 1 == ONE_TIME_POWER_UPS_START
    cp      a, POWER_UP_FREEZE_COOKIES
    ; Don't create new cookies when using cookie freeze or bomb power-up
    jr      nc, .skipCookieCount
    
.updateCookieCount
    ; Update target cookie count based on score
    ld      hl, hScore.2
    ld      a, [hld]
    ASSERT 01_00_00 / ADD_COOKIE_RATE == 2
    add     a, a    ; * 2
    ld      b, a
    ld      a, [hl] ; hScore.1
    ASSERT ADD_COOKIE_RATE / 10_00 < 10 && ADD_COOKIE_RATE / 10_00 >= 0
    cp      a, (ADD_COOKIE_RATE / 10_00) << 4
    ccf             ; Add an extra cookie if >= ADD_COOKIE_RATE
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
    
.skipCookieCount
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
    ld      hl, wShadowOAM + PLAYER_TILE1_OFFSET
    ld      [hl], a
    ld      l, LOW(wShadowOAM + PLAYER_TILE2_OFFSET)
    ld      [hl], a
    
:
    ; Update actors
    call    UpdateLasers
    call    UpdateCookies
    
    ldh     a, [hScore.2]
    swap    a
    and     a, $F0
    ld      b, a
    ldh     a, [hScore.1]
    swap    a
    and     a, $0F
    or      a, b
    ld      b, a    ; b = score (thousands)
    
    ; Update power-ups
    ldh     a, [hGameMode]
    ASSERT GAME_MODE_COUNT - 1 == 1 && GAME_MODE_CLASSIC == 0
    and     a, a
    jr      z, .skipPowerUp
    
    ; Score crossed 1000 points?
    ldh     a, [hLastScoreThousands]
    cp      a, b
    jr      z, .skipPowerUp
    
    ld      a, b
    ldh     [hLastScoreThousands], a
    
    ld      hl, PowerUpPointRateTable
    ld      c, POWER_UPS_START
    ld      d, HIGH(hPowerUps)  ; GetPowerUp expects this
.getPowerUpLoop
    ld      b, [hl]     ; b = power-up point rate
.modulo
    sub     a, b
    daa
    jr      c, .nextPowerUp
    jr      nz, .modulo
    
    ; score % rate == 0
    call    GetPowerUp
    
.nextPowerUp
    ; score % rate != 0
    inc     c
    ld      a, c
    cp      a, POWER_UP_COUNT
    jr      nc, .donePowerUps
    
    inc     l
    ldh     a, [hLastScoreThousands]
    jr      .getPowerUpLoop
    
.skipPowerUp
    ld      a, b
    ldh     [hLastScoreThousands], a
    
.donePowerUps
    ld      a, PLAYER_OBJ_COUNT
    ldh     [hNextAvailableOAMSlot], a
    
    ; Copy actor data to OAM
    call    CopyLasersToOAM
    call    CopyCookiesToOAM
    call    HideUnusedObjects
    
    ; Check for game over - no more lives left
    ldh     a, [hPlayerLives]
    and     a, a
    jr      nz, :+
    
    ld      a, GAME_STATE_GAME_OVER
    ld      hl, LoadGameOverScreen
    call    StartFade
    jp      Main
:
    call    HaltVBlank
    jp      Main

; Add a power-up to an empty power-up slot
; @param c  Power-up type
GetPowerUp:
    ld      e, LOW(hPowerUps)
    ld      b, MAX_POWER_UP_COUNT
.findEmptySlotLoop
    ld      a, [de]
    ASSERT NO_POWER_UP == 0
    and     a, a
    jr      z, .foundEmptySlot
    inc     e
    dec     b
    jr      nz, .findEmptySlotLoop
    ; No more room for a power-up left
    ret
    
.foundEmptySlot
    ld      a, c
    ld      [de], a
    ret
