INCLUDE "defines.inc"

SECTION "Cookie Tables", WRAM0, ALIGN[8]

wCookiePosTable::
    DS MAX_COOKIE_COUNT * ACTOR_SIZE
.end::

DS $100 - (MAX_COOKIE_COUNT * ACTOR_SIZE)

wCookieSpeedTable:
    DS MAX_COOKIE_COUNT * ACTOR_SIZE

DS $100 - (MAX_COOKIE_COUNT * ACTOR_SIZE)

wCookieSpeedAccTable:
    DS MAX_COOKIE_COUNT * ACTOR_SIZE

DS $100 - (MAX_COOKIE_COUNT * ACTOR_SIZE)

wCookieSizeTable::
    DS MAX_COOKIE_COUNT

ASSERT wCookieSpeedTable == wCookiePosTable + (1 << 8)
ASSERT wCookieSpeedAccTable == wCookieSpeedTable + (1 << 8)
ASSERT wCookieSizeTable == wCookieSpeedAccTable + (1 << 8)

SECTION "Cookie Variables", HRAM

hCookieCount::       DS 1
hTargetCookieCount:: DS 1

; Index of first cookie to add to OAM
hCookieRotationIndex::
    DS 1

SECTION "Cookie Code", ROM0

; Get a cookie's size using its position in wCookiePosTable
; @param hl Pointer to the cookie's entry in wCookiePosTable
; @return a  Cookie size type (see COOKIE_SIZE_* constants)
GetCookieSize::
    srl     l           ; wCookiePosTable entry = 2 bytes, wCookieSizeTable entry = 1 byte
    ld      h, HIGH(wCookieSizeTable)
    ld      a, [hl]     ; a = cookie size
    ret

; Get a pointer to the dimensions of a certain cookie's hitbox based on
; its size using its position in wCookiePosTable
; @param hl Pointer to the cookie's entry in wCookiePosTable
; @return hl Pointer to the cookie's size's hitbox in CookieHitboxTable
PointHLToCookieHitbox::
    call    GetCookieSize
    ; Get cookie's size's hitbox
    add     a, a
    add     a, a        ; * 4: Y, H, X, W
    add     a, LOW(CookieHitboxTable)
    ld      l, a
    ASSERT HIGH(CookieHitboxTable.end - 1) != HIGH(CookieHitboxTable)
    adc     a, HIGH(CookieHitboxTable)
    sub     a, l
    ld      h, a
    
    ret

CreateCookie::
    ld      hl, hCookieCount
    inc     [hl]
    
    ld      hl, wCookiePosTable
    ld      b, MAX_COOKIE_COUNT
    call    FindEmptyActorSlot
    ret     c           ; No empty slots
    
    ; [hl] = X position
    call    GenerateRandomNumber
    cp      a, SCRN_X - 16 + 8
    jr      c, :+
    sub     a, (SCRN_X - 16) / 2
:
    ld      [hld], a    ; X position
    ld      [hl], COOKIE_START_Y ; Y position
    
    inc     h           ; wCookieSpeedTable
    call    GenerateRandomNumber
    and     a, COOKIE_SPEED_Y_MASK
    add     a, COOKIE_MIN_SPEED_Y
    cp      a, COOKIE_MAX_SPEED_Y
    jr      c, :+
    sub     a, COOKIE_MAX_SPEED_Y / 2
:
    swap    a
    ld      [hli], a
    
    call    GenerateRandomNumber
    ASSERT COOKIE_SPEED_X_MASK == $FF
    ASSERT COOKIE_MIN_SPEED_X == 0
    bit     7, a
    jr      nz, :++
:
    cp      a, COOKIE_MAX_SPEED_X
    jr      c, :++
    sub     a, COOKIE_MAX_SPEED_X
    jr      :-
:
    cp      a, -COOKIE_MAX_SPEED_X
    jr      nc, :+
    add     a, COOKIE_MAX_SPEED_X
    jr      :-
:
    swap    a
    ld      [hld], a
    
    inc     h           ; wCookieSpeedAccTable
    xor     a, a
    ld      [hli], a
    ld      [hld], a
    
    srl     l           ; wCookieSpeedAccTable entry = 2 bytes, wCookieSizeTable entry = 1 byte
    inc     h           ; wCookieSizeTable
    call    GenerateRandomNumber
    and     a, COOKIE_SIZE_MASK
    ASSERT COOKIE_SIZE_MASK != COOKIE_SIZE_COUNT - 1
    cp      a, COOKIE_SIZE_COUNT
    jr      c, :+
    sub     a, COOKIE_SIZE_COUNT
:
    ld      [hl], a
    
    ret

; Destroy a cookie and award points
; @param hl Pointer to the cookie's entry in wCookiePosTable
BlastCookie::
    ld      [hl], 0     ; Destroy cookie (Y=0)
    
    call    GetCookieSize
    add     a, a        ; 1 entry = 2 bytes
    add     a, LOW(CookiePointsTable)
    ld      l, a
    ASSERT HIGH(CookiePointsTable.end - 1) == HIGH(CookiePointsTable)
    ld      h, HIGH(CookiePointsTable)
    ld      a, [hli]
    ld      b, [hl]
    ld      c, a        ; bc = points
    
    ld      hl, hCookieCount
    dec     [hl]
    
    ; Add points to score
    ld      l, LOW(hScore)
    ld      a, [hl]
    add     a, c
    daa
    ld      [hli], a
    
    ld      a, [hl]
    adc     a, b
    daa
    ld      [hli], a
    jr      nc, .doneScore
    
    ld      a, [hl]
    adc     a, 0
    daa
    ld      [hl], a
    
.doneScore
    ; Increment cookies blasted counter
    ld      l, LOW(hCookiesBlasted.lo)
    ld      a, [hl]
    add     a, 1        ; `inc` does not affect carry flag
    daa
    ld      [hli], a
    ret     nc
    
    ld      a, [hl]     ; hCookiesBlasted.hi
    add     a, 1
    daa
    ld      [hl], a
    ret

; Update cookies and their positions
UpdateCookies::
    ; Update cookie rotation index
    ldh     a, [hCookieRotationIndex]
    inc     a
    cp      a, MAX_COOKIE_COUNT
    jr      c, :+
    ; Gone past end, wrap back to beginning
    xor     a, a
:
    ldh     [hCookieRotationIndex], a
    
    ld      hl, wCookiePosTable
    ld      b, MAX_COOKIE_COUNT
.loop
    ld      a, [hl]
    and     a, a
    jr      nz, .update
    ; No cookie, skip
    inc     l
    inc     l
    jp      .next
    
.update
    ldh     a, [hGameMode]
    ASSERT GAME_MODE_COUNT - 1 == 1 && GAME_MODE_CLASSIC == 0
    and     a, a
    jr      z, .updatePos
    
    ldh     a, [hCurrentPowerUp]
    cp      a, POWER_UP_FREEZE_COOKIES
    jr      nz, .updatePos
    
    ; Skip updating position
    ld      d, [hl]     ; d = Y position
    inc     l
    ld      e, [hl]     ; e = X position
    dec     l
    jr      .checkCollide
    
.updatePos
    ld      e, l
    ld      d, h
    inc     d           ; wCookieSpeedTable
    
    ; Y position
    ldh     a, [hGameMode]
    ASSERT GAME_MODE_COUNT - 1 == 1 && GAME_MODE_CLASSIC == 0
    and     a, a
    jr      z, .normalSpeedY
    
    ldh     a, [hCurrentPowerUp]
    ASSERT POWER_UP_SLOW_COOKIES - 1 == 0
    dec     a
    jr      nz, .normalSpeedY
    ld      a, [de]     ; Y speed
    swap    a
    sra     a           ; Half of regular speed
    swap    a
    jr      :+
.normalSpeedY
    ld      a, [de]     ; Y speed
:
    ld      c, a        ; Save speed in c
    
    inc     h
    inc     h           ; wCookieSpeedAccTable
    
    and     a, $F0      ; Get fractional part
    add     a, [hl]
    ld      [hl], a
    
    dec     h
    dec     h           ; wCookiePosTable
    
    ld      a, c        ; Get Y speed again
    rr      c           ; Save carry from fractional part in c
    and     a, $0F      ; Get integer part
    rl      c           ; Restore carry from fractional part
    adc     a, [hl]     ; Add integer speed + fractional carry to position
    
    cp      a, SCRN_Y + 16
    jr      c, .onscreenY
    ; Past bottom of screen, destroy
    xor     a, a
    ld      [hli], a
    inc     l
    jp      .destroy
.onscreenY
    ld      [hli], a
    
    ; X position
    inc     e
    ldh     a, [hGameMode]
    ASSERT GAME_MODE_COUNT - 1 == 1 && GAME_MODE_CLASSIC == 0
    and     a, a
    jr      z, .normalSpeedX
    ldh     a, [hCurrentPowerUp]
    ASSERT POWER_UP_SLOW_COOKIES - 1 == 0
    dec     a
    jr      nz, .normalSpeedX
    ld      a, [de]     ; X speed
    swap    a
    sra     a           ; Half of regular speed
    swap    a
    jr      :+
.normalSpeedX
    ld      a, [de]     ; X speed
:
    ld      c, a        ; Save speed in c
    
    inc     h
    inc     h           ; wCookieSpeedAccTable
    
    and     a, $F0      ; Get fractional part
    add     a, [hl]
    ld      [hl], a
    
    dec     h
    dec     h           ; wCookiePosTable
    
    ld      a, c        ; Get X speed again
    rr      c           ; Save carry from fractional part in c
    and     a, $0F      ; Get integer part
    bit     3, a
    jr      z, :+
    or      a, $F0      ; Sign extend
:
    rl      c           ; Restore carry from fractional part
    adc     a, [hl]     ; Add integer speed + fractional carry to position
    
    cp      a, SCRN_X + 8
    jr      c, .onscreenX
    cp      a, -16 + 8
    jr      nc, .onscreenX
    ; Past left/right sides of screen, destroy
    xor     a, a
    dec     l
    ld      [hli], a
    inc     l
    jr      .destroy
.onscreenX
    ld      [hld], a
    ld      e, a
    ld      d, [hl]
    
.checkCollide
    ; Check if colliding with the player
    ldh     a, [hPlayerInvCountdown]
    ASSERT PLAYER_NOT_INV == LOW(-1)
    inc     a           ; a = -1
    ; Player is invincible, don't bother
    jr      nz, .skipCollision
    
    push    hl
    call    PointHLToCookieHitbox
    ASSERT HIGH(CookieHitboxTable.end - 1) != HIGH(CookieHitboxTable)
    ld      a, d
    add     a, [hl]     ; cookie.hitbox.y
    ld      d, a        ; d = cookie.hitbox.top
    inc     hl
    ld      a, e
    add     a, [hl]     ; cookie.hitbox.x
    ld      e, a        ; e = cookie.hitbox.left
    
    inc     hl
    ld      a, [hli]    ; cookie.hitbox.height
    ld      c, a
    ld      a, [hl]     ; cookie.hitbox.width
    ldh     [hScratch], a
    
    ld      hl, wShadowOAM + PLAYER_Y_OFFSET
    push    bc
    
    ld      a, [hli]
    add     a, PLAYER_HITBOX_Y
    ld      b, a
    add     a, PLAYER_HITBOX_HEIGHT
    cp      a, d        ; player.hitbox.bottom < cookie.hitbox.top
    jr      c, .noCollision
    
    ld      a, d
    add     a, c        ; cookie.hitbox.height
    cp      a, b        ; cookie.hitbox.bottom < player.hitbox.top
    jr      c, .noCollision
    
    ld      a, [hli]
    add     a, PLAYER_HITBOX_X
    ld      b, a
    add     a, PLAYER_HITBOX_WIDTH
    cp      a, e        ; player.hitbox.right < cookie.hitbox.left
    jr      c, .noCollision
    
    ldh     a, [hScratch]   ; cookie.hitbox.width
    add     a, e
    cp      a, b        ; cookie.hitbox.right < player.hitbox.left
    jr      c, .noCollision
    
    ; Cookie and player are colliding!
    ld      hl, hPlayerLives
    dec     [hl]
    ASSERT hPlayerInvCountdown == hPlayerLives + 1
    inc     l           ; hPlayerInvCountdown
    ld      [hl], PLAYER_INV_FRAMES
    
.noCollision
    pop     bc
    pop     hl
.skipCollision
    inc     l
    inc     l
    
.next
    dec     b
    jp      nz, .loop
    ret
.destroy
    ldh     a, [hCookieCount]
    dec     a
    ldh     [hCookieCount], a
    jr      .next
