INCLUDE "hardware.inc/hardware.inc"

SECTION "Main", ROM0[$0150]

EntryPoint::
    ld      sp, $E000
    
    ; Wait for VBlank to disable the LCD
.waitVBL
    ldh     a, [rLY]
    cp      a, SCRN_Y
    jr      c, .waitVBL
    
    xor     a, a
    ldh     [rLCDC], a
    
    ld      de, SpriteTiles
    ld      hl, _VRAM8000
    ld      bc, SpriteTiles.end - SpriteTiles
    call    Memcopy
    ld      hl, _VRAM9000
    ld      a, $FF
    ld      b, 8 * 2
    call    MemsetSmall
    ld      hl, _SCRN0
    xor     a, a
    ld      bc, SCRN_VX_B * SCRN_VY_B
    call    Memset
    
    ld      de, DMATransfer
    ld      hl, hDMATransfer
    ld      bc, DMATransfer.end - DMATransfer
    call    Memcopy
    
    call    HideAllActors
    ; Set up player
    ld      hl, wOAM + PLAYER_OFFSET
    ld      [hl], PLAYER_DEFAULT_Y
    inc     l
    ld      [hl], PLAYER_DEFAULT_X
    inc     l
    ASSERT PLAYER_TILE == 0
    ; a = 0 = PLAYER_TILE
    ld      [hl+], a
    ld      [hl+], a
    ld      [hl], PLAYER_DEFAULT_Y
    inc     l
    ld      [hl], PLAYER_DEFAULT_X + 8
    inc     l
    ; a = 0 = PLAYER_TILE
    ld      [hl+], a
    ld      [hl], OAMF_XFLIP
    
    call    ClearMissiles
    
    ld      a, %11100100
    ldh     [rBGP], a
    ld      a, %10010011
    ldh     [rOBP0], a
    
    xor     a, a
    ldh     [rIF], a
    inc     a           ; 1 = VBlank interrupt
    ldh     [rIE], a
    
    ;           +-------- LCD on/off
    ;           |+------- Window tilemap - 0: $9800; 1: $9C00
    ;           ||+------ Window on/off
    ;           |||+----- BG tile data   - 0: $9000; 1: $8000
    ;           ||||+---- BG tilemap     - 0: $9800; 1: $9C00
    ;           |||||+--- OBJ size       - 0: 8x8;   1: 8x16
    ;           ||||||+-- OBJ on/off
    ;           |||||||+- BG Priority on/off
    ld      a, %11000111
    ldh     [rLCDC], a
    
    ei

Main:
    ; Read joypad
    ld      c, LOW(rP1)
    ld      a, P1F_5    ; D-pad
    ldh     [c], a
    
    ldh     a, [c]
    ldh     a, [c]
    
    or      a, $F0      ; "Erase" high nibble
    swap    a
    ld      b, a
    
    ld      a, P1F_4    ; Buttons
    ldh     [c], a
    
    ldh     a, [c]
    ldh     a, [c]
    ldh     a, [c]
    ldh     a, [c]
    ldh     a, [c]
    ldh     a, [c]
    
    or      a, $F0
    xor     a, b        ; Combine buttons + d-pad and complement
    
    ld      b, a
    ld      a, [hPressedKeys]
    xor     a, b        ; a = keys that changed state
    and     a, b        ; a = keys that changed to pressed
    ld      [hNewKeys], a
    ld      a, b
    ld      [hPressedKeys], a
    
    ld      a, P1F_5 | P1F_4
    ldh     [c], a
    
    ldh     a, [hPressedKeys]
    bit     PADB_LEFT, a
    call    nz, MovePlayerLeft
    ldh     a, [hPressedKeys]
    bit     PADB_RIGHT, a
    call    nz, MovePlayerRight
    
    ldh     a, [hNewKeys]
    bit     PADB_A, a
    call    nz, ShootMissile
    
    call    UpdateMissiles
    
    ld      a, PLAYER_END_OFFSET / sizeof_OAM_ATTRS
    ldh     [hNextAvailableOAMSlot], a
    call    HideAllActors
    
    ld      de, wMissiles
    call    CopyActorsToOAM
    
    halt
    
    jr      Main

DMATransfer::
    ldh     [c], a
.wait
    dec     b
    jr      nz, .wait
    ret
.end

INCLUDE "constants/memory/wram.asm"
INCLUDE "constants/memory/hram.asm"

SECTION "Graphics", ROM0

SpriteTiles:
INCBIN "res/sprite-tiles.2bpp"
.end
