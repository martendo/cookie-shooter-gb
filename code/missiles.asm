INCLUDE "constants/constants.asm"

SECTION "Missile Code", ROM0

ShootMissile::
    ld      hl, wMissiles
    ld      b, MAX_MISSILE_COUNT
    
    call    FindEmptyActorSlot
    ret     c
    
    ; [hl] = X position
    ld      a, [wOAM + PLAYER_X1_OFFSET]
    add     a, (PLAYER_WIDTH / 2) - (MISSILE_WIDTH / 2)
    ld      [hld], a    ; X position
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
    ld      [hli], a
    inc     l           ; Leave X as-is
.next
    dec     b
    jr      nz, .loop
    ret
