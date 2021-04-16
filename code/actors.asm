INCLUDE "defines.inc"

SECTION "Actor Variables", HRAM

hNextAvailableOAMSlot::
    DS 1

SECTION "Common Actor Code", ROM0

; Hide all objects in OAM by zeroing their Y positions
HideAllObjects::
    ld      hl, wOAM
    ld      d, OAM_COUNT
.skip
    ld      bc, sizeof_OAM_ATTRS
    xor     a, a
.loop
    ld      [hl], a
    add     hl, bc
    dec     d
    jr      nz, .loop
    ret

; Hide all objects that aren't the player
HideAllActors::
    ld      hl, wOAM + PLAYER_END_OFFSET
    ld      d, OAM_COUNT - PLAYER_OBJ_COUNT
    jr      HideAllObjects.skip

; Clear actors
; @param hl Pointer to actor data to clear
; @param b  Maximum number of actors
ClearActors::
    xor     a, a
.loop
    ld      [hli], a
    inc     l
    dec     b
    jr      nz, .loop
    ret

; Find an empty slot to in an actor table
; @param  hl Pointer to actor data
; @param  b  Maximum number of actors
; @return cf Set if no empty slot was found, otherwise reset
FindEmptyActorSlot::
.loop
    ld      a, [hli]    ; If Y is 0, slot is empty
    and     a, a
    ret     z
    
    inc     l
    dec     b
    jr      nz, .loop
    ; No more slots
    scf
    ret     z

; Make objects with actor data and put them in OAM
; @param de Pointer to actor data
CopyActorsToOAM::
    ld      h, HIGH(wOAM)
    ldh     a, [hNextAvailableOAMSlot]
    ld      c, a
    add     a, a
    add     a, a        ; * sizeof_OAM_ATTRS
    ld      l, a
    
    ld      a, e
    cp      a, LOW(wCookieTable)
    jr      z, CopyCookiesToOAM
    ; Fallthrough

CopyMissilesToOAM:
    ld      b, MAX_MISSILE_COUNT
.loop
    ld      a, [de]     ; Y position
    and     a, a        ; No missile, skip
    jr      z, .skip
    ld      [hli], a
    inc     e
    ld      a, [de]     ; X position
    ld      [hli], a
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
    
    jr      EndCopyActors

CopyCookiesToOAM:
    ld      b, MAX_COOKIE_COUNT
.loop
    ld      a, [de]     ; Y position
    and     a, a        ; No cookie, skip
    jr      z, .skip
    ld      [hli], a
    inc     e
    ld      a, [de]     ; X position
    ld      [hli], a
    inc     e
    ld      [hl], COOKIE_TILE1
    inc     l
    ld      [hl], 0
    inc     l
    
    dec     e
    dec     e
    ld      a, [de]     ; Y position
    ld      [hli], a
    inc     e
    ld      a, [de]     ; X position
    add     a, 8
    ld      [hli], a
    inc     e
    ld      [hl], COOKIE_TILE2
    inc     l
    ld      [hl], 0
    inc     l
    
    inc     c
    inc     c
    jr      .next
.skip
    inc     e
    inc     e
.next
    dec     b
    jr      nz, .loop
    
    ; Fallthrough
    
EndCopyActors:
    ld      a, c
    ldh     [hNextAvailableOAMSlot], a
    ret
