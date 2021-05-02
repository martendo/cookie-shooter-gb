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
    ret

; Use an index to active actors and return it in de
; @param a  N - the index to active actors
; @param c  Maximum number of actors
; @param de Pointer to actor position table
; @return cf Set if no active actors, otherwise reset
; @return de Pointer to Nth active actor
PointDEToNthActiveActor:
    inc     a
    ld      b, a
    ld      l, a        ; Save for comparing
    ld      h, c        ; Save for resetting
.loop
    ld      a, [de]     ; Y position
    and     a, a        ; No actor, skip (clears carry)
    jr      z, .next
    dec     b           ; Doesn't affect carry
    ret     z           ; Carry still reset
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
DrawLasers::
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
    jr      nz, .next
    ret
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

DrawCookies::
    ldh     a, [hCookieRotationIndex]
    ld      de, wCookiePosTable
    ld      c, MAX_COOKIE_COUNT
    call    PointDEToNthActiveActor
    ret     c
    
    ldh     a, [hNextAvailableOAMSlot]
    ASSERT sizeof_OAM_ATTRS == 4
    add     a, a
    add     a, a
    ld      l, a
    ld      h, HIGH(wShadowOAM)
    
    ASSERT MAX_COOKIE_COUNT == MAX_COOKIE_SPRITE_COUNT
    ld      b, MAX_COOKIE_COUNT
.loop
    ld      a, [de]     ; Y position
    and     a, a        ; No cookie, skip
    jr      z, .skip
    
    push    bc
    ; Get cookie's size's tiles
    ld      d, HIGH(wCookieSizeTable)
    ld      a, [de]     ; a = cookie size
    ASSERT COOKIE_TILE_COUNT == 4
    add     a, a
    add     a, a
    add     a, COOKIE_TILES_START
    ld      c, a
    add     a, 2
    ld      b, a
    ; c = first tile, b = second tile
    ld      d, HIGH(wCookiePosTable)
    
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
    jr      nz, .next
    ret
.skip
    dec     b
    ret     z
    inc     e
    inc     e
.next
    ld      a, e
    cp      a, LOW(wCookiePosTable.end)
    jr      c, .loop
    ; Gone past end, wrap back to beginning
    ld      e, LOW(wCookiePosTable)
    jr      .loop
