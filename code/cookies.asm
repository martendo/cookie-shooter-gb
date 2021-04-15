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
    jr      c, :+
    sub     a, SCRN_X - 16 + 8
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
:
    cp      a, COOKIE_MAX_SPEED_X
    jr      c, :+
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
    ld      [hli], a
.next
    dec     b
    jr      nz, .loop
    ret
.destroy
    ldh     a, [hCookieCount]
    dec     a
    ldh     [hCookieCount], a
    jr      .next
