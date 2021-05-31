INCLUDE "defines.inc"

SECTION "Actor Variables", HRAM

; The index of the next available OAM slot
hNextAvailableOAMSlot::
    DS 1

SECTION "Common Actor Code", ROM0

; Hide all objects in OAM by zeroing their Y positions
HideAllObjects::
    ld      hl, wShadowOAM
HideAllObjectsAtAddress::
    ld      d, OAM_COUNT
HideObjects:
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
    ld      hl, wShadowOAM + (PLAYER_OBJ_COUNT * sizeof_OAM_ATTRS)
    ld      d, OAM_COUNT - PLAYER_OBJ_COUNT
    jr      HideObjects

; Hide objects starting at hNextAvailableOAMSlot
HideUnusedObjects::
    ldh     a, [hNextAvailableOAMSlot]
    ld      b, a
    ld      a, OAM_COUNT
    sub     a, b
    ret     z       ; Nothing to do
    ld      d, a
    
    ld      a, b
    ASSERT sizeof_OAM_ATTRS == 4
    add     a, a
    add     a, a
    ld      l, a
    ld      h, HIGH(wShadowOAM)
    
    jr      HideObjects

; Find an empty slot in an actor table
; @param    hl  Pointer to actor data
; @param    b   Maximum number of actors
; @return   cf  Set if no empty slot was found, otherwise reset
FindEmptyActorSlot::
    ; Clear carry (no instructions in the loop affect the carry)
    and     a, a
.loop
    ld      a, [hli]
    ASSERT NO_ACTOR == -1
    inc     a
    ret     z
    
    inc     l
    dec     b
    jr      nz, .loop
    ; No more slots
    scf
    ret

; Use an index to active actors and return it in de
; @param    a   N - the index to active actors
; @param    c   Maximum number of actors
; @param    de  Pointer to actor position table
; @return   de  Pointer to Nth active actor
PointDEToNthActiveActor::
    inc     a
    ld      b, a
    ld      l, a        ; Save for comparing
    ld      h, c        ; Save for resetting
.loop
    ld      a, [de]     ; Y position
    ASSERT NO_ACTOR == -1
    inc     a           ; No actor, skip
    jr      z, .next
    dec     b
    ret     z
.next
    dec     c
    jr      nz, .noWrap
    ; Reached end of table
    ld      a, b
    cp      a, l        ; No active actors?
    jr      nz, :+
    ; Don't draw anything -> skip return to DrawXXX
    pop     af
    ret
:
    ; Wrap back to beginning
    ASSERT LOW(wCookiePosTable) == LOW(wLaserPosTable)
    ld      e, LOW(wCookiePosTable)
    ld      c, h
    jr      .loop
.noWrap
    ASSERT ACTOR_SIZE == 2
    inc     e
    inc     e
    jr      .loop
