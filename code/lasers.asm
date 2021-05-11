INCLUDE "defines.inc"

SECTION "Laser Table", WRAM0, ALIGN[8]

wLaserPosTable::
    DS MAX_LASER_COUNT * ACTOR_SIZE
.end::

SECTION "Laser Variables", HRAM

; Index of first laser to add to OAM
hLaserRotationIndex:: DS 1

SECTION "Laser Code", ROM0

ShootLaser::
    ld      hl, wLaserPosTable
    ld      b, MAX_LASER_COUNT
    call    FindEmptyActorSlot
    ret     c       ; No empty slots
    
    ldh     a, [hCurrentPowerUp]
    cp      a, POWER_UP_DOUBLE_LASERS
    ; [hl] = X position
    ld      a, [wShadowOAM + PLAYER_X1_OFFSET]
    jr      z, .doubleLasers
    
    add     a, (PLAYER_WIDTH / 2) - (LASER_WIDTH / 2)
    ld      [hld], a            ; X position
    ld      [hl], LASER_START_Y ; Y position
    
    ldh     a, [hCurrentPowerUp]
    ASSERT POWER_UP_FAST_LASERS - 1 == 0
    dec     a
    jr      nz, .playSoundEffect
    
    ; Shoot a second laser higher up to act like a longer laser
    ld      l, LOW(wLaserPosTable)
    ld      b, MAX_LASER_COUNT
    call    FindEmptyActorSlot
    jr      c, .noSecondLaser   ; No empty slots
    
    ; [hl] = X position
    ld      a, [wShadowOAM + PLAYER_X1_OFFSET]
    add     a, (PLAYER_WIDTH / 2) - (LASER_WIDTH / 2)
    ld      [hld], a            ; X position
    ld      [hl], LASER_START_Y - LASER_VISUAL_HEIGHT ; Y position
.noSecondLaser
    lb      bc, SFX_LASER, SFX_LASER_FAST_NOTE
    jr      :+
    
.playSoundEffect
    lb      bc, SFX_LASER, SFX_LASER_NOTE
:
    call    SFX_Play
    
    ; Generate a random number
    jp      GenerateRandomNumber

.doubleLasers
    add     a, (PLAYER_WIDTH / 2) - DOUBLE_LASER_X_OFFSET - LASER_WIDTH + 1
    ld      [hld], a            ; X position
    ld      [hl], LASER_START_Y ; Y position
    
    ld      l, LOW(wLaserPosTable)
    ld      b, MAX_LASER_COUNT
    call    FindEmptyActorSlot
    jr      c, .playSoundEffect ; No empty slots
    
    ; [hl] = X position
    ld      a, [wShadowOAM + PLAYER_X1_OFFSET]
    add     a, (PLAYER_WIDTH / 2) + DOUBLE_LASER_X_OFFSET
    ld      [hld], a            ; X position
    ld      [hl], LASER_START_Y ; Y position
    jr      .playSoundEffect

; Update lasers' positions
UpdateLasers::
    ; Update laser rotation index
    ldh     a, [hLaserRotationIndex]
    inc     a
    cp      a, MAX_LASER_COUNT
    jr      c, :+
    ; Gone past end, wrap back to beginning
    xor     a, a
:
    ldh     [hLaserRotationIndex], a
    
    ld      hl, wLaserPosTable
    lb      bc, MAX_LASER_COUNT, LASER_SPEED
    ldh     a, [hCurrentPowerUp]
    ASSERT POWER_UP_FAST_LASERS - 1 == 0
    dec     a
    jr      nz, .loop
    ld      c, LASER_FAST_SPEED
.loop
    ld      a, [hl]
    and     a, a
    jr      nz, .update
    ; No laser, skip
    inc     l
    inc     l
    jr      .next
    
.update
    ld      a, c
    add     a, [hl]     ; Y position
    cp      a, (STATUS_BAR_HEIGHT - LASER_HEIGHT + 16) + 1
    jr      nc, :+      ; Y > Status bar
    xor     a, a        ; Out of sight, destroy
    ld      [hli], a
    jr      .resume
:
    ld      [hli], a
    
    ; Check for collision between this laser and a cookie
    
    add     a, LASER_HITBOX_Y
    ld      d, a        ; d = laser.hitbox.top
    ld      a, [hld]
    add     a, LASER_HITBOX_X
    ld      e, a        ; e = laser.hitbox.left
    
    push    bc
    push    hl          ; Laser Y position
    ld      hl, wCookiePosTable
    ld      c, MAX_COOKIE_COUNT
.checkCollideLoop
    ld      a, [hli]
    and     a, a        ; No cookie
    jr      z, .skipCookie
    
    ld      b, a
    ld      a, [hld]
    ldh     [hScratch], a
    push    hl          ; Cookie Y position
    
    call    PointHLToCookieHitbox
    ASSERT HIGH(CookieHitboxTable.end - 1) == HIGH(CookieHitboxTable)
    ld      a, b        ; cookie.y
    add     a, [hl]     ; cookie.hitbox.y
    ld      b, a
    inc     l
    add     a, [hl]     ; cookie.hitbox.height
    cp      a, d        ; cookie.hitbox.bottom < laser.hitbox.top
    jr      c, .noCollision
    
    ld      a, d
    add     a, LASER_HITBOX_HEIGHT
    cp      a, b        ; laser.hitbox.bottom < cookie.hitbox.top
    jr      c, .noCollision
    
    ldh     a, [hScratch]   ; cookie.x
    inc     l
    add     a, [hl]     ; cookie.hitbox.x
    ld      b, a
    inc     l
    add     a, [hl]     ; cookie.hitbox.width
    cp      a, e        ; cookie.hitbox.right < laser.hitbox.left
    jr      c, .noCollision
    
    ld      a, e
    add     a, LASER_HITBOX_WIDTH
    cp      a, b        ; laser.hitbox.right < cookie.hitbox.left
    jr      c, .noCollision
    
    ; Laser and cookie are colliding!
    ld      b, SFX_COOKIE_BLASTED
    call    SFX_Play
    
    pop     hl          ; Cookie Y position
    call    BlastCookie
    call    UpdateStatusBar
    pop     hl          ; Laser Y position
    xor     a, a
    ld      [hli], a    ; Destroy laser (Y=0)
    pop     bc
    
    jr      .resume
    
.noCollision
    pop     hl          ; Cookie Y position
    inc     l
.skipCookie
    inc     l
    dec     c
    jr      nz, .checkCollideLoop
    
    pop     hl          ; Laser Y position
    inc     l
    pop     bc
.resume
    inc     l           ; Leave X as-is
.next
    dec     b
    jr      nz, .loop
    ret
