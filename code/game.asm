INCLUDE "defines.inc"

SECTION "In-Game Variables", HRAM

; Countdown to pause the creation of cookies
; Used at the very beginning of a game and after a bomb power-up
hWaitCountdown:
    DS 1

; Last frame's game score in thousands (e.g. score of 14200 = last score
; thousands of 14)
; Used to tell when the player crossed a multiple of 1000 points for
; checking whether or not to give a power-up
hLastScoreThousands:
    DS 1

; Player's 3 power-up slots
hPowerUps:
ASSERT MAX_POWER_UP_COUNT == 3
.0:: DS 1
.1:: DS 1
.2:: DS 1
.end
; Currently selected power-up (out of the 3)
hPowerUpSelection::
    DS 1
; Currently in-use power-up
hCurrentPowerUp::
    DS 1
; Remaining frames with the current power-up
hPowerUpDuration::
.lo:: DS 1
.hi:: DS 1

SECTION "In-Game Code", ROM0

SetUpGame::
    ; Load tiles
    ld      de, InGameTiles
    ld      hl, _VRAM9000
    ld      bc, InGameTiles.end - InGameTiles
    rst     LCDMemcopy
    ; Load background map
    ld      hl, _SCRN0 + (STATUS_BAR_TILE_HEIGHT * SCRN_VX_B)
    ld      b, IN_GAME_BACKGROUND_TILE
    ld      d, SCRN_Y_B - STATUS_BAR_TILE_HEIGHT
    call    LCDMemsetMap
    ; Load status bar tilemap
    ld      de, StatusBarMap
    ld      hl, _SCRN0
    ld      c, STATUS_BAR_TILE_HEIGHT
    rst     LCDMemcopyMap
    
    call    HideAllActors
    ; Set up player
    ld      a, PLAYER_Y
    ldh     [hPlayerY], a
    ld      a, PLAYER_START_X
    ldh     [hPlayerX], a
    ld      c, PLAYER_TILE
    call    DrawPlayer
    
    ; Clear actor tables
    ld      hl, wLaserPosTable
    ld      b, MAX_LASER_COUNT
    ld      a, NO_ACTOR
.clearLasersLoop
    ld      [hli], a
    inc     l
    dec     b
    jr      nz, .clearLasersLoop
    
    ld      hl, wCookiePosTable
    ld      b, MAX_COOKIE_COUNT
.clearCookiesLoop
    ; a = NO_ACTOR
    ld      [hli], a
    inc     l
    dec     b
    jr      nz, .clearCookiesLoop
    
    ; Reset variables
    xor     a, a
    ; Reset score
    ld      hl, hScore
    REPT SCORE_BYTE_COUNT
    ld      [hli], a
    ENDR
    ; Reset number of cookies blasted
    ASSERT hScore.end == hCookiesBlasted
    REPT COOKIES_BLASTED_BYTE_COUNT
    ld      [hli], a
    ENDR
    
    ld      l, LOW(hLastScoreThousands)
    ld      [hli], a
    
    ; Clear power-up slots
    ASSERT hPowerUps == hLastScoreThousands + 1
    ASSERT NO_POWER_UP == 0
    REPT MAX_POWER_UP_COUNT
    ld      [hli], a
    ENDR
    ; Reset currently selected power-up
    ASSERT hPowerUpSelection == hPowerUps.end
    ld      [hli], a
    ; Clear currently in-use power-up
    ASSERT hCurrentPowerUp == hPowerUpSelection + 1
    ASSERT NO_POWER_UP == 0
    ld      [hli], a
    ; Reset power-up duration
    ASSERT hPowerUpDuration == hCurrentPowerUp + 1
    ASSERT NO_POWER_UP_DURATION == HIGH(-1)
    dec     a       ; a = -1
    ld      [hli], a
    ld      [hl], a
    
    ; Draw score and cookies blasted
    call    UpdateStatusBar
    
    ; Set initial player life count
    ld      a, PLAYER_START_LIVES
    ldh     [hPlayerLives], a
    
    ; Draw hearts (player's lives)
    call    DrawHearts.skip     ; a = [hPlayerLives]
    
    ldh     a, [hGameMode]
    ASSERT GAME_MODE_CLASSIC == 0
    and     a, a
    ASSERT GAME_MODE_COUNT - 1 == 1
    
    ; If in Super mode, draw power-ups
    call    nz, DrawAllPowerUps
    
    ; Reset cookie count
    xor     a, a
    ldh     [hCookieCount], a
    ; Reset rotation of actors
    ldh     [hCookieRotationIndex], a
    ldh     [hLaserRotationIndex], a
    ; Reset player invincibility
    ASSERT PLAYER_NOT_INV == -1
    dec     a            ; a = -1
    ldh     [hPlayerInvCountdown], a
    
    ; Set initial target cookie count
    ld      a, START_TARGET_COOKIE_COUNT
    ldh     [hTargetCookieCount], a
    
    ; Delay the cookies for a little bit
    ld      a, GAME_START_DELAY_FRAMES
    ldh     [hWaitCountdown], a
    
    ; Start in-game music
    ld      de, Inst_InGame
    call    Music_PrepareInst
    ld      de, Music_InGame
    jp      Music_Play

InGame::
    ; Wait for VBlank
    halt
    ldh     a, [hVBlankFlag]
    and     a, a
    jr      z, InGame
    xor     a, a
    ldh     [hVBlankFlag], a
    
    ; Pause the game
    ldh     a, [hNewKeys]
    bit     PADB_START, a
    jr      z, :+
    
    ld      a, GAME_STATE_PAUSED
    ldh     [hGameState], a
    
    ; Pause music, stop all sound effects
    call    Music_Pause
    call    SFX_Stop
    ; Play pause sound effect
    ld      b, SFX_PAUSE
    call    SFX_Play
    ; Go to paused loop
    jp      Paused
    
:
    ldh     a, [hGameMode]
    ASSERT GAME_MODE_CLASSIC == 0
    and     a, a
    jp      z, .noPowerUps
    
    ASSERT GAME_MODE_COUNT - 1 == 1
    ; Change power-up selection
    ldh     a, [hNewKeys]
    bit     PADB_UP, a
    jr      nz, :+
    
    bit     PADB_DOWN, a
    jr      z, .noPowerUpSelectionChange
    
    ; Move power-up selection down
    ldh     a, [hPowerUpSelection]
    cp      a, MAX_POWER_UP_COUNT - 1
    jr      nc, .noPowerUpSelectionChange   ; Don't go past bottom
    inc     a
    jr      .selectPowerUp

:
    ; Move power-up selection up
    ldh     a, [hPowerUpSelection]
    and     a, a
    jr      z, .noPowerUpSelectionChange    ; Don't go past top
    dec     a

.selectPowerUp
    ldh     [hPowerUpSelection], a
    ; Play power-up selection sound effect
    ld      b, SFX_POWER_UP_SELECT
    call    SFX_Play
.noPowerUpSelectionChange
    ; Use a power-up
    ldh     a, [hNewKeys]
    bit     PADB_B, a
    jr      z, .notUsingPowerUp
    
    ; Get selected power-up
    ldh     a, [hPowerUpSelection]
    add     a, LOW(hPowerUps)
    ld      l, a
    ld      h, HIGH(hPowerUps)
    
    ld      a, [hl]
    ASSERT NO_POWER_UP == 0
    and     a, a
    ; No power-up in this slot, nothing to use
    jr      z, .notUsingPowerUp
    
    ; Handle "immediate" power-ups
    cp      a, POWER_UP_BOMB
    jr      nz, .notBombPowerUp
    
    ; Remove from power-ups
    ld      [hl], NO_POWER_UP
    ; Clear all cookies
    ld      hl, wCookiePosTable
    ld      d, MAX_COOKIE_COUNT
.clearCookiesLoop
    ld      a, [hl]
    ASSERT NO_ACTOR == -1
    inc     a
    jr      z, :+
    push    hl
    call    BlastCookie
    pop     hl
:
    inc     l
    inc     l
    dec     d
    jr      nz, .clearCookiesLoop
    
    ; Score and cookies blasted has changed
    call    UpdateStatusBar
    
    ; Don't create any new cookies for a while after the bomb
    ld      a, POWER_UP_BOMB_WAIT_FRAMES
    ldh     [hWaitCountdown], a
    
    ; Play special bomb sound effect
    ld      b, SFX_BOMB
    call    SFX_Play
    jr      .notUsingPowerUp
    
.notBombPowerUp
    ; Not the Bomb, is it Extra Life?
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
    call    DrawHearts          ; Update hearts
    jr      .usedPowerUp
    
.normalPowerUp
    ; Not an immediate power-up
    ; Set power-up as current and remove
    ldh     [hCurrentPowerUp], a
    ld      [hl], NO_POWER_UP
    
    ; Get the duration of the power-up
    ASSERT POWER_UPS_START - 1 == 0
    dec     a
    add     a, a    ; 1 entry = 2 bytes
    add     a, LOW(PowerUpDurationTable)
    ld      l, a
    ASSERT HIGH(PowerUpDurationTable.end - 1) == HIGH(PowerUpDurationTable)
    ld      h, HIGH(PowerUpDurationTable)
    ld      a, [hli]
    ld      b, [hl]
    
    ; Set the power-up duration
    ld      hl, hPowerUpDuration
    ld      [hli], a
    ld      [hl], b
    
.usedPowerUp
    ; Play use power-up sound effect
    ld      b, SFX_POWER_UP_USE
    call    SFX_Play
.notUsingPowerUp
    ; Check power-up duration
    ld      hl, hPowerUpDuration.hi
    ld      a, [hld]
    ASSERT NO_POWER_UP_DURATION == HIGH(-1)
    inc     a       ; a = -1
    ; No currently in-use power-up
    jr      z, .noPowerUps
    
    ; Decrement duration countdown
    ld      e, [hl]
    inc     l
    ld      d, [hl]
    
    dec     de
    ; Check for zero
    ld      a, e
    or      a, d
    
    ld      a, d
    ld      [hld], a    ; Preserve the zero flag (don't use `ld [hl], d / dec l`)
    ld      [hl], e
    jr      nz, .noPowerUps
    
    ; Power-up just ended
    ASSERT NO_POWER_UP == 0
    xor     a, a
    ldh     [hCurrentPowerUp], a
    
    ; Play power-up end sound effect
    ld      b, SFX_POWER_UP_END
    call    SFX_Play

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
    
    ; Waiting - don't create any cookies
    ldh     a, [hWaitCountdown]
    and     a, a
    jr      z, :+
    
    dec     a
    ldh     [hWaitCountdown], a
    jr      .skipCookieCount
    
:
    ; Update target cookie count based on score
    ld      hl, hScore.2
    ld      a, [hli]
    ; 1 in MSB (byte 3) = 10 000 points
    ASSERT 01_00_00 / ADD_COOKIE_RATE == 2
    ; 10 000 points (1 in MSB) = 2 cookies
    add     a, a    ; * 2
    ld      b, a
    
    ld      a, [hl] ; hScore.1
    
    ASSERT ADD_COOKIE_RATE / 10_00 < 10 && ADD_COOKIE_RATE / 10_00 > 0
    ; Add an extra cookie if >= ADD_COOKIE_RATE
    cp      a, (ADD_COOKIE_RATE / 10_00) << 4   ; hScore.1 = hundreds
    ccf
    
    ld      a, START_TARGET_COOKIE_COUNT
    adc     a, b
    
    ; Clamp cookie count to MAX_COOKIE_COUNT
    cp      a, MAX_COOKIE_COUNT + 1
    jr      c, :+   ; a <= MAX_COOKIE_COUNT
    ld      a, MAX_COOKIE_COUNT
:
    ld      l, LOW(hTargetCookieCount)
    ld      [hld], a
    ; If cookie count is too low, create a new cookie
    ASSERT hCookieCount == hTargetCookieCount - 1
    dec     a       ; `>` and not `>=`
    cp      a, [hl]
    call    nc, CreateCookie
    
.skipCookieCount
    ; Update actors
    call    UpdateLasers
    call    UpdateCookies
    
    ; Update power-ups
    ldh     a, [hGameMode]
    ASSERT GAME_MODE_CLASSIC == 0
    and     a, a
    jr      z, .donePowerUps
    
    ASSERT GAME_MODE_COUNT - 1 == 1
    ; Check if needed to give power-ups
    ldh     a, [hScore.2]
    swap    a
    and     a, $F0
    ld      b, a
    ldh     a, [hScore.1]
    swap    a
    and     a, $0F
    or      a, b
    ld      b, a    ; b = score (thousands)
    
    ; Score crossed 1000 points?
    ldh     a, [hLastScoreThousands]
    cp      a, b
    ld      a, b
    ldh     [hLastScoreThousands], a
    jr      z, .noNewPowerUps
    
    ; Yes, check which power-ups to give
    ld      hl, PowerUpPointRateTable
    ld      c, POWER_UPS_START
.getPowerUpLoop
    ld      b, [hl]     ; b = power-up point rate
    
    and     a, a
    jr      nz, .modulo
    ; Multiple of 100 000 points, assume 100 000 and start in double
    ; digits
    sub     a, b        ; a = score (thousands)
    daa
.modulo
    sub     a, b        ; a = score (thousands)
    daa
    jr      c, .nextPowerUp
    jr      nz, .modulo
    
    ; score % rate == 0
    call    GetPowerUp
    
.nextPowerUp
    ; score % rate != 0
    ; Move on to next power-up
    inc     c
    ld      a, c
    cp      a, POWER_UP_COUNT   ; Finished?
    jr      nc, .noNewPowerUps
    
    ; Get next power-up's point rate
    ASSERT HIGH(PowerUpPointRateTable.end - 1) == HIGH(PowerUpPointRateTable)
    inc     l
    ldh     a, [hLastScoreThousands]
    jr      .getPowerUpLoop
    
.noNewPowerUps
    ; Draw power-ups
    call    DrawAllPowerUps
    
.donePowerUps
    ; Update player invincibility
    ld      hl, hPlayerInvCountdown
    ld      a, [hl]
    ASSERT PLAYER_NOT_INV == -1
    inc     a       ; a = -1
    ld      c, PLAYER_TILE
    ; Not invincible
    jr      z, .drawPlayer
    
    dec     [hl]    ; Decrement countdown
    
    ; Flash player to show invincibility
    bit     PLAYER_INV_FLASH_BIT, [hl]
    jr      nz, .drawPlayer
    ; Hide player (invincible tiles are empty tiles)
    ASSERT PLAYER_INV_TILE == LOW(-1)
    dec     c   ; c = -1
.drawPlayer
    call    DrawPlayer
    
    ; Copy actor data to OAM
    call    DrawLasers
    call    DrawCookies
    call    HideUnusedObjects
    
    ; Check for game over - no more lives left
    ldh     a, [hPlayerLives]
    and     a, a
    jp      nz, InGame
    
    ; Set up game over screen
    ld      a, GAME_STATE_GAME_OVER
    jp      Fade

; Add a power-up to an empty power-up slot
; @param    c   Power-up type
GetPowerUp:
    ld      de, hPowerUps
    
    REPT MAX_POWER_UP_COUNT - 1
    ld      a, [de]
    ASSERT NO_POWER_UP == 0
    and     a, a
    jr      z, .foundEmptySlot
    inc     e
    ENDR
    ld      a, [de]
    ASSERT NO_POWER_UP == 0
    and     a, a
    ; No more room for a power-up left; all slots taken
    ret     nz
    
.foundEmptySlot
    ; Add power-up to slot
    ld      a, c
    ld      [de], a
    
    ; Play get power-up sound effect
    push    bc
    push    hl
    ld      b, SFX_POWER_UP_GET
    call    SFX_Play
    pop     hl
    pop     bc
    ret
