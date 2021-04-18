INCLUDE "defines.inc"

SECTION "Cookie Tables", WRAM0

wCookieTable::
    DS MAX_COOKIE_COUNT * ACTOR_SIZE
.end::
wCookieSpeedTable:
    DS MAX_COOKIE_COUNT * ACTOR_SIZE
wCookieSpeedAccTable:
    DS MAX_COOKIE_COUNT * ACTOR_SIZE
wCookieSizeTable::
    DS MAX_COOKIE_COUNT

SECTION "Cookie Variables", HRAM

hCookieCount::       DS 1
hTargetCookieCount:: DS 1

SECTION "Cookie Data", ROM0

CookieTileTable::
    DB      4   ; COOKIE_SIZE_16
    DB      8   ; COOKIE_SIZE_14
    DB      12  ; COOKIE_SIZE_12
    DB      16  ; COOKIE_SIZE_10
    DB      20  ; COOKIE_SIZE_8
.end::

CookieHitboxTable::
    ;       Y,  H, X,  W
    DB      2, 12, 2, 12    ; COOKIE_SIZE_16
    DB      3, 10, 3, 10    ; COOKIE_SIZE_14
    DB      4,  8, 4,  8    ; COOKIE_SIZE_12
    DB      5,  6, 5,  6    ; COOKIE_SIZE_10
    DB      6,  4, 6,  4    ; COOKIE_SIZE_8
.end::

; Points values in BCD
CookiePointsTable::
    DW      $25     ; COOKIE_SIZE_16
    DW      $50     ; COOKIE_SIZE_14
    DW      $75     ; COOKIE_SIZE_12
    DW      $100    ; COOKIE_SIZE_10
    DW      $125    ; COOKIE_SIZE_8
.end::

SECTION "Cookie Code", ROM0

; Get a cookie's size using its position in wCookieTable
; @param hl Pointer to the cookie's entry in wCookieTable
; @return a  Cookie size type (see COOKIE_SIZE_* constants)
GetCookieSize::
    ld      a, l
    sub     a, LOW(wCookieTable)
    srl     a           ; wCookieTable entry = 2 bytes, wCookieSizeTable entry = 1 byte
    add     a, LOW(wCookieSizeTable)
    ld      l, a
    ASSERT HIGH(wCookieSizeTable) == HIGH(wCookieSizeTable + MAX_COOKIE_COUNT - 1)
    ld      h, HIGH(wCookieSizeTable)
    ld      a, [hl]     ; a = cookie size
    ret

; Get a pointer to the dimensions of a certain cookie's hitbox based on
; its size using its position in wCookieTable
; @param hl Pointer to the cookie's entry in wCookieTable
; @return hl Pointer to the cookie's size's hitbox in CookieHitboxTable
PointHLToCookieHitbox::
    call    GetCookieSize
    ; Get cookie's size's hitbox
    add     a, a
    add     a, a        ; * 4: Y, H, X, W
    add     a, LOW(CookieHitboxTable)
    ld      l, a
    ASSERT HIGH(CookieHitboxTable.end - 1) == HIGH(CookieHitboxTable)
    ld      h, HIGH(CookieHitboxTable)
    
    ret

CreateCookie::
    ld      hl, hCookieCount
    inc     [hl]
    
    ld      hl, wCookieTable
    ld      b, MAX_COOKIE_COUNT
    call    FindEmptyActorSlot
    ret     c           ; No empty slots
    
    ; [hl] = X position
    call    GetRandomNumber
    cp      a, SCRN_X - 16 + 8
    jr      c, :+
    sub     a, (SCRN_X - 16) / 2
:
    ld      [hld], a    ; X position
    ld      [hl], COOKIE_START_Y ; Y position
    
    ld      bc, MAX_COOKIE_COUNT * ACTOR_SIZE
    add     hl, bc      ; wCookieSpeedTable
    call    GetRandomNumber
    and     a, COOKIE_SPEED_Y_MASK
    add     a, COOKIE_MIN_SPEED_Y
    cp      a, COOKIE_MAX_SPEED_Y
    jr      c, :+
    sub     a, COOKIE_MAX_SPEED_Y / 2
:
    swap    a
    ld      [hli], a
    
    call    GetRandomNumber
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
    
    add     hl, bc      ; wCookieSpeedAccTable
    xor     a, a
    ld      [hli], a
    ld      [hld], a
    
    ld      bc, -wCookieSpeedAccTable & $FFFF
    add     hl, bc
    srl     l           ; wCookieSpeedAccTable entry = 2 bytes, wCookieSizeTable entry = 1 byte
    ld      bc, wCookieSizeTable
    add     hl, bc
    call    GetRandomNumber
    and     a, COOKIE_SIZE_MASK
    ASSERT COOKIE_SIZE_MASK != COOKIE_SIZE_COUNT - 1
    cp      a, COOKIE_SIZE_COUNT
    jr      c, :+
    sub     a, COOKIE_SIZE_COUNT
:
    ld      [hl], a
    
    ret

; Update cookies' positions
UpdateCookies::
    ASSERT HIGH(wCookieTable.end - 1) == HIGH(wCookieTable)
    ld      hl, wCookieTable
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
    ld      a, l
    add     a, MAX_COOKIE_COUNT * ACTOR_SIZE
    ld      e, a
    adc     a, h
    sub     e
    ld      d, a
    
    ; Y position
    ld      a, [de]     ; Y speed
    ld      c, a        ; Save speed in c
    
    push    hl
    
    ld      a, e
    add     a, MAX_COOKIE_COUNT * ACTOR_SIZE
    ld      l, a
    adc     a, d
    sub     a, l
    ld      h, a
    
    ld      a, c        ; Get Y speed
    and     a, $F0      ; Get fractional part
    add     a, [hl]
    ld      [hl], a
    
    pop     hl
    
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
    jr      .destroy
.onscreenY
    ld      [hli], a
    inc     e
    
    ; X position
    ld      a, [de]     ; X speed
    ld      c, a        ; Save speed in c
    
    push    hl
    
    ld      a, e
    add     a, MAX_COOKIE_COUNT * ACTOR_SIZE
    ld      l, a
    adc     a, d
    sub     a, l
    ld      h, a
    
    ld      a, c        ; Get X speed
    and     a, $F0      ; Get fractional part
    add     a, [hl]
    ld      [hl], a
    
    pop     hl
    
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
    
    ; Check if colliding with the player
    ldh     a, [hPlayerInvCountdown]
    inc     a           ; a = $FF
    ; Player is invincible, don't bother
    jr      nz, .skipCollision
    
    push    hl
    call    PointHLToCookieHitbox
    ASSERT HIGH(CookieHitboxTable.end - 1) == HIGH(CookieHitboxTable)
    ld      a, e
    inc     l
    inc     l
    add     a, [hl]     ; cookie.hitbox.x
    ld      e, a        ; e = cookie.hitbox.left
    ld      a, d
    dec     l
    dec     l
    add     a, [hl]     ; cookie.hitbox.y
    ld      d, a        ; d = cookie.hitbox.top
    
    inc     l
    ld      a, [hli]    ; cookie.hitbox.height
    ld      c, a
    inc     l
    ld      a, [hl]     ; cookie.hitbox.width
    ldh     [hScratch], a
    
    ld      hl, wOAM + PLAYER_Y_OFFSET
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
