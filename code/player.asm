INCLUDE "defines.inc"

SECTION "Player Variables", HRAM

hPlayerY::
    DS 1
hPlayerX::
    DS 1

hPlayerLives::
    DS 1
hPlayerInvCountdown::
    DS 1

SECTION "Player Code", ROM0

MovePlayerLeft::
    ld      a, -PLAYER_SPEED
    jr      MovePlayer

MovePlayerRight::
    ld      a, PLAYER_SPEED
    ; Fallthrough

; @param a Change in X position (speed)
MovePlayer:
    ld      hl, hPlayerX
    add     a, [hl]
    
    ; x > SCRN_X - PLAYER_WIDTH || x < 0
    cp      a, SCRN_X - PLAYER_WIDTH + 1
    ret     nc  ; Moving out of bounds
    
    ld      [hl], a
    ret

; @param c Tile number to draw the player with
DrawPlayer::
    ld      hl, wShadowOAM
    ldh     a, [hPlayerY]
    add     a, 16
    ld      [hli], a
    ld      b, a
    ldh     a, [hPlayerX]
    add     a, 8
    ld      [hli], a
    ld      [hl], c
    inc     l
    ld      [hl], 0
    inc     l
    ld      [hl], b
    inc     l
    add     a, 8
    ld      [hli], a
    ld      [hl], c
    inc     l
    ld      [hl], OAMF_XFLIP
    
    ld      a, PLAYER_OBJ_COUNT
    ldh     [hNextAvailableOAMSlot], a
    ret
