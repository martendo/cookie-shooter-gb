INCLUDE "constants/constants.asm"

SECTION "Common Actor Code", ROM0

; Hide all objects in OAM that aren't the player by zeroing their Y
; positions
HideAllActors::
    ld      hl, wOAM + PLAYER_END_OFFSET
    ld      bc, sizeof_OAM_ATTRS
    ld      d, OAM_COUNT - (PLAYER_END_OFFSET / sizeof_OAM_ATTRS)
    xor     a, a
.loop
    ld      [hl], a
    add     hl, bc
    dec     d
    jr      nz, .loop
    ret

; Make objects with actor data and put them in OAM
; @param de Pointer to actor data
CopyActorsToOAM::
    ld      h, HIGH(wOAM)
    ldh     a, [hNextAvailableOAMSlot]
    ld      c, a
    add     a, a
    add     a, a        ; * sizeof_OAM_ATTRS
    ld      l, a
    
    ; Fallthrough

CopyMissilesToOAM:
    ld      b, MAX_MISSILE_COUNT
.loop
    ld      a, [de]     ; Y position
    and     a, a        ; No missile, skip
    jr      z, .skip
    ld      [hl+], a
    inc     e
    ld      a, [de]     ; X position
    ld      [hl+], a
    inc     e
    ld      [hl], MISSILE_TILE
    inc     l
    ld      [hl], 0
    inc     l
    inc     c
    jr      .next
.skip
    inc     e
    inc     e
.next
    dec     b
    jr      nz, .loop
    
    ld      a, c
    ldh     [hNextAvailableOAMSlot], a
    ret
