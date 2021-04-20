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
    ld      a, [hli]    ; If Y is 0, slot is empty
    and     a, a        ; Clears carry
    ret     z
    
    inc     l
    dec     b
    jr      nz, FindEmptyActorSlot
    ; No more slots
    scf
    ret     z

; Make objects with actor data and put them in OAM
; @param de Pointer to actor data
CopyActorsToOAM::
    ldh     a, [hNextAvailableOAMSlot]
    ld      c, a
    add     a, a
    add     a, a        ; * sizeof_OAM_ATTRS
    ld      l, a
    ld      h, HIGH(wOAM)
    
    ld      a, d
    cp      a, HIGH(wCookiePosTable)
    jr      z, CopyCookiesToOAM
    ; Fallthrough

CopyLasersToOAM:
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

CopyCookiesToOAM:
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
    add     a, LOW(CookieTileTable)
    ld      l, a
    ASSERT HIGH(CookieTileTable.end - 1) == HIGH(CookieTileTable)
    ld      h, HIGH(CookieTileTable)
    ld      c, [hl]
    ld      b, c
    inc     b
    inc     b
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
