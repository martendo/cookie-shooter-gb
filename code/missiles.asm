INCLUDE "defines.inc"

SECTION "Missile Table", WRAM0

wMissileTable::
    DS MAX_MISSILE_COUNT * ACTOR_SIZE

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
    ld      hl, wMissileTable
    ld      b, MAX_MISSILE_COUNT
.loop
    ld      a, [hl]
    and     a, a
    jr      nz, .update
    ; No missile, skip
    inc     l
    inc     l
    jr      .next
    
.update
    ; Missiles will automatically become disabled after reaching Y = 0
    ASSERT MISSILE_START_Y % -MISSILE_SPEED == 0
    
    ld      a, MISSILE_SPEED
    add     a, [hl]     ; Y position
    ld      [hli], a
    jr      nz, CheckMissileCollide
.resume
    inc     l           ; Leave X as-is
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
    jr      z, .noCollisionY
    
    add     a, COOKIE_HITBOX_Y
    ld      b, a
    add     a, COOKIE_HITBOX_HEIGHT
    cp      a, d        ; cookie.hitbox.bottom < missile.hitbox.top
    jr      c, .noCollisionY
    
    ld      a, d
    add     a, MISSILE_HITBOX_HEIGHT
    cp      a, b        ; missile.hitbox.bottom < cookie.hitbox.top
    jr      c, .noCollisionY
    
    ld      a, [hld]
    add     a, COOKIE_HITBOX_X
    ld      b, a
    add     a, COOKIE_HITBOX_WIDTH
    cp      a, e        ; cookie.hitbox.right < missile.hitbox.left
    jr      c, .noCollisionX
    
    ld      a, e
    add     a, MISSILE_HITBOX_WIDTH
    cp      a, b        ; missile.hitbox.right < cookie.hitbox.left
    jr      c, .noCollisionX
    
    ; Missile and cookie are colliding!
    xor     a, a
    ld      [hl], a     ; Destroy cookie (Y=0)
    ld      hl, hCookieCount
    dec     [hl]
    pop     hl
    ld      [hli], a    ; Destroy missile (Y=0)
    pop     bc
    jr      UpdateMissiles.resume
    
.noCollisionX
    inc     l
.noCollisionY
    inc     l
    dec     c
    jr      nz, .loop
    
    pop     hl
    inc     l
    pop     bc
    jr      UpdateMissiles.resume
