INCLUDE "defines.inc"

SECTION "Missile Table", WRAM0

wMissileTable::
    DS MAX_MISSILE_COUNT * ACTOR_SIZE
.end::

SECTION "Missile Code", ROM0

ShootMissile::
    ld      hl, wMissileTable
    ld      b, MAX_MISSILE_COUNT
    call    FindEmptyActorSlot
    ret     c           ; No empty slots
    
    ; [hl] = X position
    ld      a, [wOAM + PLAYER_X1_OFFSET]
    add     a, (PLAYER_WIDTH / 2) - (MISSILE_WIDTH / 2)
    ld      [hld], a    ; X position
    ld      [hl], MISSILE_START_Y ; Y position
    ret

; Update missiles' positions
UpdateMissiles::
    ASSERT HIGH(wMissileTable.end) != HIGH(wMissileTable)
    ld      hl, wMissileTable
    ld      b, MAX_MISSILE_COUNT
.loop
    ld      a, [hl]
    and     a, a
    jr      nz, .update
    ; No missile, skip
    inc     hl
    inc     hl
    jr      .next
    
.update
    ld      a, MISSILE_SPEED
    add     a, [hl]     ; Y position
    cp      a, STATUS_BAR_HEIGHT - MISSILE_HEIGHT + 16
    jr      nc, :+
    xor     a, a        ; Out of sight, destroy
    ld      [hli], a
    jr      .resume
:
    ld      [hli], a
    jr      nz, CheckMissileCollide
.resume
    inc     hl          ; Leave X as-is
.next
    dec     b
    jr      nz, .loop
    ret

; Check for collision between a missile and a cookie
; @param hl Pointer to missile's X position
; @param a  Missile's Y position
CheckMissileCollide:
    push    bc
    
    add     a, MISSILE_HITBOX_Y
    ld      d, a        ; d = missile.hitbox.top
    ld      a, [hld]
    push    hl
    add     a, MISSILE_HITBOX_X
    ld      e, a        ; e = missile.hitbox.left
    
    ld      hl, wCookieTable
    ld      c, MAX_COOKIE_COUNT
.loop
    ld      a, [hli]
    and     a, a        ; No cookie
    jr      z, .skip
    
    ld      b, a
    ld      a, [hld]
    ldh     [hScratch], a
    push    hl
    
    call    PointHLToCookieHitbox
    
    ld      a, b        ; cookie.y
    add     a, [hl]     ; cookie.hitbox.y
    ld      b, a
    inc     l
    add     a, [hl]     ; cookie.hitbox.height
    cp      a, d        ; cookie.hitbox.bottom < missile.hitbox.top
    jr      c, .noCollision
    
    ld      a, d
    add     a, MISSILE_HITBOX_HEIGHT
    cp      a, b        ; missile.hitbox.bottom < cookie.hitbox.top
    jr      c, .noCollision
    
    ldh     a, [hScratch]   ; cookie.x
    inc     l
    add     a, [hl]     ; cookie.hitbox.x
    ld      b, a
    inc     l
    add     a, [hl]     ; cookie.hitbox.width
    cp      a, e        ; cookie.hitbox.right < missile.hitbox.left
    jr      c, .noCollision
    
    ld      a, e
    add     a, MISSILE_HITBOX_WIDTH
    cp      a, b        ; missile.hitbox.right < cookie.hitbox.left
    jr      c, .noCollision
    
    ; Missile and cookie are colliding!
    pop     hl
    xor     a, a
    ld      d, a        ; d = 0
    ld      [hl], a     ; Destroy cookie (Y=0)
    
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
    ld      a, c
    add     a, [hl]
    daa
    ld      [hli], a
    ld      a, b
    adc     a, [hl]
    daa
    ld      [hli], a
    jr      nc, .doneScore
    
    ld      a, [hl]
    adc     a, d        ; d = 0
    daa
    ld      [hli], a
    jr      nc, .doneScore
    
    ld      a, [hl]
    adc     a, d
    daa
    ld      [hl], a
    
.doneScore
    ; Increment cookies blasted counter
    ld      l, LOW(hCookiesBlasted.lo)
    ld      a, [hl]
    and     a, a        ; Clear carry flag
    inc     a
    daa
    ld      [hli], a
    jr      nc, .finished
    
    ld      a, [hl]     ; hCookiesBlasted.hi
    and     a, a        ; Clear carry flag
    inc     a
    daa
    ld      [hli], a
    
.finished
    pop     hl
    xor     a, a
    ld      [hli], a    ; Destroy missile (Y=0)
    pop     bc
    
    jr      UpdateMissiles.resume
    
.noCollision
    pop     hl
    inc     l
.skip
    inc     l
    dec     c
    jr      nz, .loop
    
    pop     hl
    inc     hl
    pop     bc
    jp      UpdateMissiles.resume
