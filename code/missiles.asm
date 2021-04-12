INCLUDE "constants/constants.asm"

SECTION "Missile Code", ROM0

; Clear all missiles
ClearMissiles::
    ld      hl, wMissiles
    ld      b, MAX_MISSILE_COUNT
    xor     a, a
.loop
    ld      [hl+], a
    inc     l
    dec     b
    jr      nz, .loop
    ret

; Create a new missile
ShootMissile::
    ; Find an empty slot to put the missile in
    ld      hl, wMissiles
    ld      b, MAX_MISSILE_COUNT
.findEmptySlot
    ld      a, [hl+]    ; If Y is 0, slot is empty
    and     a, a
    jr      z, .addMissile
    
    inc     l
    dec     b
    ret     z           ; No more slots
    jr      .findEmptySlot
    
.addMissile
    ; [hl] = X position
    ld      a, [wOAM + PLAYER_X1_OFFSET]
    add     a, (PLAYER_WIDTH / 2) - (MISSILE_WIDTH / 2)
    ld      [hl-], a    ; X position
    ld      [hl], MISSILE_DEFAULT_Y ; Y position
    ret

; Update missiles' positions
UpdateMissiles::
    ld      hl, wMissiles
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
    ASSERT MISSILE_DEFAULT_Y % -MISSILE_SPEED == 0
    
    ld      a, MISSILE_SPEED
    add     a, [hl]     ; Y position
    ld      [hl+], a
    inc     l           ; Leave X as-is
.next
    dec     b
    jr      nz, .loop
    ret
