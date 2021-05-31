INCLUDE "defines.inc"

SECTION "Cookie Position Table", WRAM0, ALIGN[8]

; Positions of cookies (Y, X) in pixels, relative to screen
wCookiePosTable::
    DS MAX_COOKIE_COUNT * ACTOR_SIZE
.end::

SECTION "Cookie Speed Table", WRAM0, ALIGN[8]

; Speeds of cookies, (Y, X) in 16ths subpixels (4.4 fixed point)
wCookieSpeedTable:
    DS MAX_COOKIE_COUNT * ACTOR_SIZE

SECTION "Cookie Speed Fractional Accumulator Table", WRAM0, ALIGN[8]

; Fractional accumulator of cookie speeds
; Fractional part of speeds << 4 added here, overflow from here added to
; integer part of position
wCookieSpeedAccTable:
    DS MAX_COOKIE_COUNT * ACTOR_SIZE

SECTION "Cookie Size Type Table", WRAM0, ALIGN[8]

; Size types of cookies (1 byte, 2nd byte unused)
; See constants/cookies.inc for possible values
wCookieSizeTable::
    DS MAX_COOKIE_COUNT * ACTOR_SIZE

; Set placement and order of tables for optimizations (e.g. `inc h`)
ASSERT wCookieSpeedTable == wCookiePosTable + (1 << 8)
ASSERT wCookieSpeedAccTable == wCookieSpeedTable + (1 << 8)
ASSERT wCookieSizeTable == wCookieSpeedAccTable + (1 << 8)

SECTION "Cookie Variables", HRAM

; Current number of cookies on-screen
hCookieCount::       DS 1
; Number of cookies there should be on-screen based on the current score
hTargetCookieCount:: DS 1

; Index of first cookie to add to OAM
hCookieRotationIndex::
    DS 1

SECTION "Cookie Code", ROM0

; Get a pointer to the dimensions of a certain cookie's hitbox based on
; its size using its position in wCookiePosTable
; @param    hl  Pointer to the cookie's entry any cookie actor data table
; @return   hl  Pointer to the cookie's size's hitbox in CookieHitboxTable
PointHLToCookieHitbox::
    ld      h, HIGH(wCookieSizeTable)
    ld      a, [hl]     ; a = cookie size
    ; Get cookie's size's hitbox
    add     a, a
    add     a, a        ; * 4: Y, H, X, W
    add     a, LOW(CookieHitboxTable)
    ld      l, a
    ASSERT HIGH(CookieHitboxTable.end - 1) == HIGH(CookieHitboxTable)
    ld      h, HIGH(CookieHitboxTable)
    ret

CreateCookie::
    ld      hl, wCookiePosTable
    ld      b, MAX_COOKIE_COUNT
    call    FindEmptyActorSlot
    ret     c           ; No empty slots
    
    ldh     a, [hCookieCount]
    inc     a
    ldh     [hCookieCount], a
    
    ; [hl] = X position
    call    GenerateRandomNumber
    cp      a, SCRN_X - COOKIE_WIDTH
    jr      c, :+
    sub     a, (SCRN_X - COOKIE_WIDTH) / 2
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
; @param    hl  Pointer to the cookie's entry in wCookiePosTable
BlastCookie::
    ; Destroy cookie
    ld      [hl], NO_ACTOR
    
    ; Find number of points to award based on the size of this cookie
    ld      h, HIGH(wCookieSizeTable)
    ld      a, [hl]     ; a = cookie size
    add     a, a        ; 1 entry = 2 bytes
    add     a, LOW(CookiePointsTable)
    ld      l, a
    ASSERT HIGH(CookiePointsTable.end - 1) == HIGH(CookiePointsTable)
    ld      h, HIGH(CookiePointsTable)
    ld      a, [hli]
    ld      b, [hl]
    ld      c, a        ; bc = points
    
    ; Update cookie count
    ld      hl, hCookieCount
    dec     [hl]
    
    ; Add points to score
    ld      l, LOW(hScore.end - 1)
    ld      a, [hl]
    add     a, c
    daa
    ld      [hld], a
    
    ld      a, [hl]
    adc     a, b
    daa
    ld      [hld], a
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
    ld      [hld], a
    ret     nc
    
    ld      a, [hl]     ; hCookiesBlasted.hi
    adc     a, 0
    daa
    ld      [hl], a
    ret

; Update cookies' positions and check for collision with the player
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
    ASSERT NO_ACTOR == -1
    inc     a
    jr      nz, .update
    ; No cookie, skip
    inc     l
    inc     l
    jp      .next
    
.update
    ; Add cookie's speed to its position
    ld      e, l
    ld      d, h
    inc     d           ; wCookieSpeedTable
    
    ; Y position
    ldh     a, [hCurrentPowerUp]
    cp      a, POWER_UP_SLOW_COOKIES
    ld      a, [de]     ; Y speed
    jr      nz, .normalSpeedY
    swap    a
    srl     a           ; Half of regular speed
    swap    a
.normalSpeedY
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
    
    cp      a, SCRN_Y
    ; Past bottom of screen, destroy
    jp      nc, .destroy
    ld      [hli], a
    inc     e
    
    ; X position
    ldh     a, [hCurrentPowerUp]
    cp      a, POWER_UP_SLOW_COOKIES
    ld      a, [de]     ; X speed
    jr      nz, .normalSpeedX
    swap    a
    sra     a           ; Half of regular speed
    swap    a
.normalSpeedX
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
    
    cp      a, SCRN_X
    ASSERT LOW(-COOKIE_WIDTH + 1) > LOW(SCRN_X)
    jr      c, .onscreenX
    cp      a, -COOKIE_WIDTH + 1
    jr      nc, .onscreenX
    ; Past left/right sides of screen, destroy
    dec     l
    jr      .destroy
.onscreenX
    ld      [hld], a
    ld      e, a
    ld      d, [hl]
    
    ; Check if colliding with the player
    ldh     a, [hPlayerInvCountdown]
    ASSERT PLAYER_NOT_INV == -1
    inc     a           ; a = -1
    ; Player is invincible, don't bother
    jr      nz, .skipCollision
    
    push    hl
    push    bc
    ; Get cookie's hitbox dimensions
    call    PointHLToCookieHitbox
    ASSERT HIGH(CookieHitboxTable.end - 1) == HIGH(CookieHitboxTable)
    ld      a, d
    add     a, [hl]     ; cookie.hitbox.y
    ld      d, a        ; d = cookie.hitbox.top
    inc     l
    ld      a, [hli]    ; cookie.hitbox.height
    ld      b, a        ; b = cookie.hitbox.height
    ld      a, e
    add     a, [hl]     ; cookie.hitbox.x
    ld      e, a        ; e = cookie.hitbox.left
    inc     l
    ld      a, [hl]     ; cookie.hitbox.width
    ld      c, a        ; c = cookie.hitbox.width
    
    ldh     a, [hPlayerY]
    add     a, PLAYER_HITBOX_Y
    ld      l, a        ; l = player.hitbox.top
    add     a, PLAYER_HITBOX_HEIGHT
    cp      a, d        ; player.hitbox.bottom < cookie.hitbox.top
    jr      c, .noCollision
    
    ld      a, d        ; cookie.hitbox.top
    add     a, b        ; cookie.hitbox.height
    cp      a, l        ; cookie.hitbox.bottom < player.hitbox.top
    jr      c, .noCollision
    
    ldh     a, [hPlayerX]
    ASSERT PLAYER_HITBOX_X == 1
    inc     a
    ld      l, a        ; l = player.hitbox.left
    add     a, PLAYER_HITBOX_WIDTH
    cp      a, e        ; player.hitbox.right < cookie.hitbox.left
    jr      c, .noCollision
    
    ld      a, c        ; cookie.hitbox.width
    add     a, e        ; cookie.hitbox.left
    cp      a, l        ; cookie.hitbox.right < player.hitbox.left
    jr      c, .noCollision
    
    ; Cookie and player are colliding!
    
    ; Play player hit sound effect
    ld      b, SFX_PLAYER_HIT
    call    SFX_Play
    
    ; Take away one of the player's lives
    ld      hl, hPlayerLives
    dec     [hl]
    ; Give player brief invincibility
    ASSERT hPlayerInvCountdown == hPlayerLives + 1
    inc     l           ; hPlayerInvCountdown
    ld      [hl], PLAYER_INV_FRAMES
    
    ; Update hearts (player's lives)
    call    DrawHearts
    
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
    ld      [hl], NO_ACTOR
    inc     l
    inc     l
    ; Cookie has been removed, update cookie count
    ldh     a, [hCookieCount]
    dec     a
    ldh     [hCookieCount], a
    jr      .next

; Add cookies to shadow OAM
DrawCookies::
    ldh     a, [hCookieRotationIndex]
    ld      de, wCookiePosTable
    ld      c, MAX_COOKIE_COUNT
    call    PointDEToNthActiveActor
    
    ldh     a, [hNextAvailableOAMSlot]
    ASSERT sizeof_OAM_ATTRS == 4
    add     a, a
    add     a, a
    ld      l, a
    ld      h, HIGH(wShadowOAM)
    
    ASSERT MAX_COOKIE_COUNT == MAX_COOKIE_SPRITE_COUNT
    ld      b, MAX_COOKIE_COUNT
.loop
    ld      a, [de]     ; Y position
    ASSERT NO_ACTOR == -1
    inc     a           ; No cookie, skip
    jr      z, .skip
    
    push    bc
    ; Get cookie's size's tiles
    ld      d, HIGH(wCookieSizeTable)
    ld      a, [de]     ; a = cookie size
    ASSERT COOKIE_TILE_COUNT == 4
    add     a, a        ; * 2
    add     a, a        ; * 4
    add     a, COOKIE_TILES_START
    ld      c, a
    add     a, 2
    ld      b, a
    ; c = first tile, b = second tile
    ld      d, HIGH(wCookiePosTable)
    
    ; Object 1
    ld      a, [de]     ; Y position
    add     a, 16
    ld      [hli], a
    inc     e
    ld      a, [de]     ; X position
    add     a, 8
    ld      [hli], a
    ld      [hl], c     ; First tile
    inc     l
    ld      [hl], 0
    inc     l
    
    dec     e
    ; Object 2
    ld      a, [de]     ; Y position
    add     a, 16
    ld      [hli], a
    inc     e
    ld      a, [de]     ; X position
    add     a, 8 + 8
    ld      [hli], a
    ld      [hl], b     ; Second tile
    inc     l
    ld      [hl], 0
    inc     l
    
    ldh     a, [hNextAvailableOAMSlot]
    add     a, COOKIE_OBJ_COUNT
    ldh     [hNextAvailableOAMSlot], a
    
    pop     bc
    dec     b
    jr      nz, .next
    ret
.skip
    dec     b
    ret     z
    inc     e
.next
    inc     e
    ld      a, e
    cp      a, LOW(wCookiePosTable.end)
    jr      c, .loop
    ; Gone past end, wrap back to beginning
    ld      e, LOW(wCookiePosTable)
    jr      .loop
