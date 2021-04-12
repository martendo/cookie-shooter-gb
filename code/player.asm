INCLUDE "constants/constants.asm"

SECTION "Player Code", ROM0

MovePlayerLeft::
    ld      a, -PLAYER_SPEED
    jr      MovePlayer

MovePlayerRight::
    ld      a, PLAYER_SPEED
    jr      MovePlayer

; @param a Change in X position (speed)
MovePlayer:
    ld      hl, wOAM + PLAYER_X1_OFFSET
    add     a, [hl]
    
    cp      a, 8
    ret     c   ; Moving out of bounds on the left
    cp      a, ((SCRN_X - PLAYER_WIDTH) + 8) + 1
    ret     nc  ; Moving out of bounds on the right
    
    ld      [hl], a
    ld      l, LOW(wOAM + PLAYER_X2_OFFSET)
    add     a, 8
    ld      [hl], a
    ret
