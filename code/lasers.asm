INCLUDE "defines.inc"

SECTION "Laser Table", WRAM0, ALIGN[8]

; Positions of lasers (Y, X) in pixels, relative to screen
wLaserPosTable::
    DS MAX_LASER_COUNT * ACTOR_SIZE
.end::

SECTION "Laser Variables", HRAM

; Index of first laser to add to OAM
hLaserRotationIndex::
    DS 1

SECTION "Laser Code", ROM0

ShootLaser::
    ld      hl, wLaserPosTable
    ld      b, MAX_LASER_COUNT
    call    FindEmptyActorSlot
    ret     c       ; No empty slots
    
    ; Laser positions are different if using double lasers power-up
    ldh     a, [hCurrentPowerUp]
    cp      a, POWER_UP_DOUBLE_LASERS
    ldh     a, [hPlayerX]
    jr      z, .doubleLasers
    
    ; Single laser -> right in the middle of the spaceship
    ; [hl] = X position
    add     a, (PLAYER_WIDTH / 2) - (LASER_WIDTH / 2)
    ld      [hld], a            ; X position
    ld      [hl], LASER_START_Y ; Y position
    
    ; Add second laser if using fast lasers power-up
    ldh     a, [hCurrentPowerUp]
    ASSERT POWER_UP_FAST_LASERS - 1 == 0
    dec     a
    jr      nz, .playSoundEffect
    
    ; Shoot a second laser higher up to act like a longer laser
    ld      l, LOW(wLaserPosTable)
    ld      b, MAX_LASER_COUNT
    call    FindEmptyActorSlot
    jr      c, .noSecondLaser   ; No empty slots
    
    ldh     a, [hPlayerX]
    ; [hl] = X position
    add     a, (PLAYER_WIDTH / 2) - (LASER_WIDTH / 2)
    ld      [hld], a            ; X position
    ld      [hl], LASER_START_Y - LASER_VISUAL_HEIGHT ; Y position
.noSecondLaser
    ; Play a different (higher-pitched) sound effect for fast lasers
    ld      b, SFX_FAST_LASER
    DB      $11     ; ld de, d16 to consume the next 2 bytes
.playSoundEffect
    ; Play laser ("pew") sound effect
    ld      b, SFX_LASER
    call    SFX_Play
    
    ; Generate a random number for more entropy
    jp      GenerateRandomNumber

.doubleLasers
    ; Double lasers -> shoot one from either side of the spaceship
    ; [hl] = X position
    add     a, (PLAYER_WIDTH / 2) - DOUBLE_LASER_X_OFFSET - LASER_WIDTH + 1
    ld      [hld], a            ; X position
    ld      [hl], LASER_START_Y ; Y position
    
    ; Second laser
    ld      l, LOW(wLaserPosTable)
    ld      b, MAX_LASER_COUNT
    call    FindEmptyActorSlot
    jr      c, .playSoundEffect ; No empty slots
    
    ldh     a, [hPlayerX]
    ; [hl] = X position
    add     a, (PLAYER_WIDTH / 2) + DOUBLE_LASER_X_OFFSET
    ld      [hld], a            ; X position
    ld      [hl], LASER_START_Y ; Y position
    jr      .playSoundEffect

; Update lasers' positions and check for collision with cookies
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
    ; If using fast lasers power-up, use a faster laser speed
    ldh     a, [hCurrentPowerUp]
    ASSERT POWER_UP_FAST_LASERS - 1 == 0
    dec     a
    jr      nz, .loop
    ld      c, LASER_FAST_SPEED
.loop
    ld      a, [hl]
    ASSERT NO_ACTOR == -1
    inc     a
    jr      nz, .update
    ; No laser, skip
    inc     l
    inc     l
    jr      .next
    
.update
    ; Add laser speed to its position
    ld      a, c
    add     a, [hl]     ; Y position
    ASSERT (STATUS_BAR_HEIGHT - LASER_HEIGHT) == 0
    jr      z, :+       ; Y == (STATUS_BAR_HEIGHT - LASER_HEIGHT)
    bit     7, a
    jr      nz, :+      ; Y < (STATUS_BAR_HEIGHT - LASER_HEIGHT)
    ld      [hli], a
    jr      .checkCollide
:
    ; Out of sight, destroy
    ld      [hl], NO_ACTOR
    inc     l
    jr      .nextSkipX
    
.checkCollide
    ; Check for collision between this laser and a cookie
    
    ; Get this laser's hitbox dimensions
    add     a, LASER_HITBOX_Y
    ld      d, a        ; d = laser.hitbox.top
    ld      a, [hld]
    add     a, LASER_HITBOX_X
    ld      e, a        ; e = laser.hitbox.left
    
    push    bc
    push    hl          ; Laser Y position
    
    ; Loop over all cookies and check for collision
    ld      hl, wCookiePosTable
    ld      c, MAX_COOKIE_COUNT
.checkCollideLoop
    ld      a, [hli]
    ASSERT NO_ACTOR == -1
    inc     a           ; No cookie
    jr      z, .skipCookie
    
    dec     a           ; Undo inc
    ld      b, a
    ld      a, [hld]    ; cookie.x
    ldh     [hScratch], a
    push    hl          ; Cookie Y position
    
    ; Get cookie's hitbox dimensions
    call    PointHLToCookieHitbox
    ASSERT HIGH(CookieHitboxTable.end - 1) == HIGH(CookieHitboxTable)
    ld      a, b        ; cookie.y
    add     a, [hl]     ; cookie.hitbox.y
    ld      b, a        ; b = cookie.hitbox.top
    inc     l
    add     a, [hl]     ; cookie.hitbox.height
    cp      a, d        ; cookie.hitbox.bottom < laser.hitbox.top
    jr      c, .noCollision
    
    ld      a, d        ; laser.hitbox.top
    add     a, LASER_HITBOX_HEIGHT
    cp      a, b        ; laser.hitbox.bottom < cookie.hitbox.top
    jr      c, .noCollision
    
    ldh     a, [hScratch]   ; cookie.x
    inc     l
    add     a, [hl]     ; cookie.hitbox.x
    ld      b, a        ; b = cookie.hitbox.left
    inc     l
    add     a, [hl]     ; cookie.hitbox.width
    cp      a, e        ; cookie.hitbox.right < laser.hitbox.left
    jr      c, .noCollision
    
    ld      a, e        ; laser.hitbox.left
    add     a, LASER_HITBOX_WIDTH
    cp      a, b        ; laser.hitbox.right < cookie.hitbox.left
    jr      c, .noCollision
    
    ; Laser and cookie are colliding!
    
    ; Play cookie blasted sound effect
    ld      b, SFX_COOKIE_BLASTED
    call    SFX_Play
    
    ; Blast cookie and update score and cookies blasted on status bar
    pop     hl          ; Cookie Y position
    call    BlastCookie
    call    UpdateStatusBar
    pop     hl          ; Laser Y position
    
    ; Destroy laser
    ld      [hl], NO_ACTOR
    jr      .resume
    
.noCollision
    pop     hl          ; Cookie Y position
    inc     l
.skipCookie
    inc     l
    dec     c
    jr      nz, .checkCollideLoop
    
    pop     hl          ; Laser Y position
.resume
    inc     l
    pop     bc
.nextSkipX
    inc     l           ; Leave X as-is
.next
    dec     b
    jr      nz, .loop
    ret

; Add lasers to shadow OAM
DrawLasers::
    ldh     a, [hLaserRotationIndex]
    ld      de, wLaserPosTable
    ld      c, MAX_LASER_COUNT
    call    PointDEToNthActiveActor
    
    ldh     a, [hNextAvailableOAMSlot]
    ASSERT sizeof_OAM_ATTRS == 4
    add     a, a
    add     a, a
    ld      l, a
    ld      h, HIGH(wShadowOAM)
    
    lb      bc, MAX_LASER_SPRITE_COUNT, MAX_LASER_COUNT
.loop
    ld      a, [de]     ; Y position
    ASSERT NO_ACTOR == -1
    inc     a           ; No laser, skip
    jr      z, .skip
    
    add     a, 16 - 1   ; Undo inc
    ld      [hli], a
    inc     e
    ld      a, [de]     ; X position
    add     a, 8
    ld      [hli], a
    ld      [hl], LASER_TILE
    inc     l
    ld      [hl], 0
    inc     l
    
    ldh     a, [hNextAvailableOAMSlot]
    ASSERT LASER_OBJ_COUNT == 1
    inc     a
    ldh     [hNextAvailableOAMSlot], a
    
    dec     b
    jr      nz, .next
    ret
.skip
    inc     e
.next
    inc     e
    dec     c
    ret     z
    
    ld      a, e
    cp      a, LOW(wLaserPosTable.end)
    jr      c, .loop
    ; Gone past end, wrap back to beginning
    ld      e, LOW(wLaserPosTable)
    jr      .loop
