INCLUDE "defines.inc"

SECTION "Cookie Tables", WRAM0

wCookieTable::
    DS MAX_COOKIE_COUNT * ACTOR_SIZE
wCookieSpeedTable:
    DS MAX_COOKIE_COUNT * ACTOR_SIZE
wCookieSpeedAccTable:
    DS MAX_COOKIE_COUNT * ACTOR_SIZE

SECTION "Cookie Variables", HRAM

hCookieCount::       DS 1
hTargetCookieCount:: DS 1

SECTION "Cookie Code", ROM0

CreateCookie::
    ld      hl, hCookieCount
    inc     [hl]
    
    ld      hl, wCookieTable
    ld      b, MAX_COOKIE_COUNT
    
    call    FindEmptyActorSlot
    ret     c
    
    ; [hl] = X position
    call    GetRandomNumber
    cp      a, SCRN_X - 16 + 8
    jr      c, .ok
    sub     a, SCRN_X - 16 + 8
.ok
    ld      [hld], a    ; X position
    ld      [hl], COOKIE_START_Y ; Y position
    
    ld      bc, MAX_COOKIE_COUNT * ACTOR_SIZE
    add     hl, bc
    call    GetRandomNumber
    ld      b, a
    and     a, COOKIE_SPEED_Y_MASK
    add     a, COOKIE_MIN_SPEED_Y
    ld      [hli], a
    
    swap    b
    ld      a, b
    and     a, COOKIE_SPEED_X_MASK
    bit     7, b
    jr      z, .gotSpeedX
    cpl
    inc     a
.gotSpeedX
    ld      [hl], a
    
    ret

; Update cookies' positions
UpdateCookies::
    ld      hl, wCookieTable
    ld      b, MAX_COOKIE_COUNT
.loop
    ld      a, [hl]
    and     a, a
    jr      nz, .update
    ; No cookie, skip
    inc     l
    inc     l
    jr      .next
    
.update
    ld      a, l
    add     a, MAX_COOKIE_COUNT * ACTOR_SIZE
    ld      e, a
    adc     a, h
    sub     e
    ld      d, a
    
    ld      a, [de]
    add     a, [hl]     ; Y position
    cp      a, SCRN_Y + 16
    jr      c, .normalY
    ; Past bottom of screen, remove
    xor     a, a
    ld      [hli], a
    inc     l
    jr      .remove
.normalY
    ld      [hli], a
    inc     e
    ld      a, [de]
    add     a, [hl]     ; X position
    cp      a, SCRN_X + 8
    jr      c, .normalX
    cp      a, -16 + 8
    jr      nc, .normalX
    ; Past left/right sides of screen, remove
    xor     a, a
    dec     l
    ld      [hli], a
    inc     l
    jr      .remove
.normalX
    ld      [hli], a
.next
    dec     b
    jr      nz, .loop
    ret
.remove
    ldh     a, [hCookieCount]
    dec     a
    ldh     [hCookieCount], a
    jr      .next
