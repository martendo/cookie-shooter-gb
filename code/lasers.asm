INCLUDE "defines.inc"

SECTION "Laser Table", WRAM0, ALIGN[8]

wLaserPosTable::
    DS MAX_LASER_COUNT * ACTOR_SIZE
.end::

SECTION "Laser Code", ROM0

ShootLaser::
    ld      hl, wLaserPosTable
    ld      b, MAX_LASER_COUNT
    call    FindEmptyActorSlot
    ret     c       ; No empty slots
    
    ; [hl] = X position
    ld      a, [wShadowOAM + PLAYER_X1_OFFSET]
    add     a, (PLAYER_WIDTH / 2) - (LASER_WIDTH / 2)
    ld      [hld], a            ; X position
    ld      [hl], LASER_START_Y ; Y position
    
    ; Generate a random number
    jp      GenerateRandomNumber

; Update lasers' positions
UpdateLasers::
    ld      hl, wLaserPosTable
    ld      b, MAX_LASER_COUNT
.loop
    ld      a, [hl]
    and     a, a
    jr      nz, .update
    ; No laser, skip
    inc     l
    inc     l
    jr      .next
    
.update
    ld      a, LASER_SPEED
    add     a, [hl]     ; Y position
    cp      a, STATUS_BAR_HEIGHT - LASER_HEIGHT + 16
    jr      nc, :+
    xor     a, a        ; Out of sight, destroy
    ld      [hli], a
    jr      .resume
:
    ld      [hli], a
    jr      nz, CheckLaserCollide
.resume
    inc     l           ; Leave X as-is
.next
    dec     b
    jr      nz, .loop
    ret

; Check for collision between a laser and a cookie
; @param hl Pointer to laser's X position
; @param a  Laser's Y position
CheckLaserCollide:
    push    bc
    
    add     a, LASER_HITBOX_Y
    ld      d, a        ; d = laser.hitbox.top
    ld      a, [hld]
    push    hl          ; Laser Y position
    add     a, LASER_HITBOX_X
    ld      e, a        ; e = laser.hitbox.left
    
    ld      hl, wCookiePosTable
    ld      c, MAX_COOKIE_COUNT
.loop
    ld      a, [hli]
    and     a, a        ; No cookie
    jr      z, .skip
    
    ld      b, a
    ld      a, [hld]
    ldh     [hScratch], a
    push    hl          ; Cookie Y position
    
    call    PointHLToCookieHitbox
    ASSERT HIGH(CookieHitboxTable.end - 1) != HIGH(CookieHitboxTable)
    ld      a, b        ; cookie.y
    add     a, [hl]     ; cookie.hitbox.y
    ld      b, a
    inc     hl
    add     a, [hl]     ; cookie.hitbox.height
    cp      a, d        ; cookie.hitbox.bottom < laser.hitbox.top
    jr      c, .noCollision
    
    ld      a, d
    add     a, LASER_HITBOX_HEIGHT
    cp      a, b        ; laser.hitbox.bottom < cookie.hitbox.top
    jr      c, .noCollision
    
    ldh     a, [hScratch]   ; cookie.x
    inc     hl
    add     a, [hl]     ; cookie.hitbox.x
    ld      b, a
    inc     hl
    add     a, [hl]     ; cookie.hitbox.width
    cp      a, e        ; cookie.hitbox.right < laser.hitbox.left
    jr      c, .noCollision
    
    ld      a, e
    add     a, LASER_HITBOX_WIDTH
    cp      a, b        ; laser.hitbox.right < cookie.hitbox.left
    jr      c, .noCollision
    
    ; Laser and cookie are colliding!
    pop     hl          ; Cookie Y position
    call    BlastCookie
    pop     hl          ; Laser Y position
    xor     a, a
    ld      [hli], a    ; Destroy laser (Y=0)
    pop     bc
    
    jr      UpdateLasers.resume
    
.noCollision
    pop     hl          ; Cookie Y position
    inc     l
.skip
    inc     l
    dec     c
    jr      nz, .loop
    
    pop     hl          ; Laser Y position
    inc     l
    pop     bc
    jr      UpdateLasers.resume
