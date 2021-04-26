INCLUDE "defines.inc"

SECTION "Actor Variables", HRAM

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
    ld      hl, wShadowOAM + PLAYER_END_OFFSET
    ld      d, OAM_COUNT - PLAYER_OBJ_COUNT
    jr      HideObjects

; Hide objects starting at hNextAvailableOAMSlot
HideUnusedObjects::
    ldh     a, [hNextAvailableOAMSlot]
    ld      b, a
    ld      a, OAM_COUNT
    sub     a, b
    ld      d, a
    
    ld      a, b
    ASSERT sizeof_OAM_ATTRS == 4
    add     a, a
    add     a, a
    ld      l, a
    ld      h, HIGH(wShadowOAM)
    
    jr      HideObjects

; Clear actors
; @param hl Pointer to actor data to clear
; @param b  Maximum number of actors
; @param a  0
ClearActors::
    ld      [hli], a
    inc     l
    dec     b
    jr      nz, ClearActors
    ret

; Find an empty slot to in an actor table
; @param  hl Pointer to actor data
; @param  b  Maximum number of actors
; @return cf Set if no empty slot was found, otherwise reset
FindEmptyActorSlot::
    ld      a, [hli]    ; If Y is 0, slot is empty
    and     a, a        ; Clears carry
    ret     z
    
    inc     l
    dec     b
    jr      nz, FindEmptyActorSlot
    ; No more slots
    scf
    ret     z

; Use actor data to make objects and put them in OAM
CopyLasersToOAM::
    ldh     a, [hNextAvailableOAMSlot]
    ld      c, a
    ASSERT sizeof_OAM_ATTRS == 4
    add     a, a
    add     a, a
    ld      l, a
    ld      h, HIGH(wShadowOAM)
    
    ld      de, wLaserPosTable
    ld      b, MAX_LASER_COUNT
.loop
    ld      a, [de]     ; Y position
    and     a, a        ; No laser, skip
    jr      z, .skip
    ld      [hli], a
    inc     e
    ld      a, [de]     ; X position
    ld      [hli], a
    inc     e
    ld      [hl], LASER_TILE
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

CopyCookiesToOAM::
    ldh     a, [hNextAvailableOAMSlot]
    ld      c, a
    ASSERT sizeof_OAM_ATTRS == 4
    add     a, a
    add     a, a
    ld      l, a
    ld      h, HIGH(wShadowOAM)
    
    ldh     a, [hCookieRotationIndex]
    ASSERT ACTOR_SIZE == 2
    add     a, a
    ld      e, a
    ld      d, HIGH(wCookiePosTable)
    
    ld      b, MAX_COOKIE_COUNT
.loop
    ld      a, [de]     ; Y position
    and     a, a        ; No cookie, skip
    jr      z, .skip
    
    push    bc
    push    hl
    ; Get cookie's size's tiles
    ld      l, e
    ld      h, d
    call    GetCookieSize
    ASSERT COOKIE_TILE_COUNT == 4
    add     a, a
    add     a, a
    add     a, COOKIE_TILES_START
    ld      c, a
    add     a, 2
    ld      b, a
    ; c = first tile, b = second tile
    pop     hl
    
    ld      a, [de]     ; Y position
    ld      [hli], a
    inc     e
    ld      a, [de]     ; X position
    ld      [hli], a
    inc     e
    ld      [hl], c     ; First tile
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
    ld      [hl], b     ; Second tile
    inc     l
    ld      [hl], 0
    inc     l
    
    pop     bc
    inc     c
    inc     c
    dec     b
    jr      z, EndCopyActors
    jr      .next
.skip
    dec     b
    jr      z, EndCopyActors
    
    inc     e
    inc     e
.next
    ld      a, e
    cp      a, LOW(wCookiePosTable.end)
    jr      c, .loop
    ; Gone past end, wrap back to beginning
    ld      e, LOW(wCookiePosTable)
    jr      .loop
    
EndCopyActors:
    ld      a, c
    ldh     [hNextAvailableOAMSlot], a
    ret
