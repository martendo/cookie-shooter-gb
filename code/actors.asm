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
    ret     z       ; Nothing to do
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

; Use an index to active actors and return it in de
; @param a  N - the index to active actors
; @param c  Maximum number of actors
; @param de Pointer to actor position table
; @return cf Set if no active actors, otherwise reset
; @return de Pointer to Nth active actor
PointDEToNthActiveActor:
    and     a, a        ; Clears carry
    ret     z
    ld      b, a
    ld      l, a        ; Save for comparing
    ld      h, c        ; Save for resetting
.loop
    ld      a, [de]     ; Y position
    and     a, a        ; No actor, skip (clears carry)
    jr      z, .next
    dec     b           ; Doesn't affect carry
    ret     z
.next
    dec     c
    jr      nz, .noWrap
    ; Reached end of table
    ld      a, b
    cp      a, l        ; No active actors?
    jr      nz, :+
    scf
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

; Use actor data to make objects and put them in OAM
CopyLasersToOAM::
    ldh     a, [hLaserRotationIndex]
    ld      de, wLaserPosTable
    ld      c, MAX_LASER_COUNT
    call    PointDEToNthActiveActor
    ret     c
    
    ldh     a, [hNextAvailableOAMSlot]
    ASSERT sizeof_OAM_ATTRS == 4
    add     a, a
    add     a, a
    ld      l, a
    ld      h, HIGH(wShadowOAM)
    
    lb      bc, MAX_LASER_SPRITE_COUNT, MAX_LASER_COUNT
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
    
    ldh     a, [hNextAvailableOAMSlot]
    ASSERT LASER_OBJ_COUNT == 1
    inc     a
    ldh     [hNextAvailableOAMSlot], a
    
    dec     b
    ret     z
    jr      .next
.skip
    inc     e
    inc     e
.next
    dec     c
    ret     z
    
    ld      a, e
    cp      a, LOW(wLaserPosTable.end)
    jr      c, .loop
    ; Gone past end, wrap back to beginning
    ld      e, LOW(wLaserPosTable)
    jr      .loop

CopyCookiesToOAM::
    ldh     a, [hCookieRotationIndex]
    ld      de, wCookiePosTable
    ld      c, MAX_COOKIE_COUNT
    call    PointDEToNthActiveActor
    ret     c
    
    ldh     a, [hNextAvailableOAMSlot]
    ld      b, a
    ASSERT sizeof_OAM_ATTRS == 4
    add     a, a
    add     a, a
    ld      l, a
    ld      h, HIGH(wShadowOAM)
    
    ld      a, OAM_COUNT
    sub     a, b        ; Use all remaining OAM slots
    ASSERT COOKIE_OBJ_COUNT == 2
    srl     a           ; / 2
    ld      b, a
    ld      c, MAX_COOKIE_COUNT
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
    
    ldh     a, [hNextAvailableOAMSlot]
    add     a, COOKIE_OBJ_COUNT
    ldh     [hNextAvailableOAMSlot], a
    
    pop     bc
    dec     b
    ret     z
    jr      .next
.skip
    inc     e
    inc     e
.next
    dec     c
    ret     z
    
    ld      a, e
    cp      a, LOW(wCookiePosTable.end)
    jr      c, .loop
    ; Gone past end, wrap back to beginning
    ld      e, LOW(wCookiePosTable)
    jr      .loop
