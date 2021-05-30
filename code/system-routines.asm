INCLUDE "defines.inc"

SECTION "System Routines", ROM0

; Copy a block of memory from one place to another
; @param    de  Pointer to beginning of block to copy
; @param    hl  Pointer to destination
; @param    bc  Number of bytes to copy
Memcopy::
    ; Increment B if C is non-zero
    dec     bc
    inc     c
    inc     b
.loop
    ld      a, [de]
    ld      [hli], a
    inc     de
    dec     c
    jr      nz, .loop
    dec     b
    jr      nz, .loop
    ret

; @param    de  Pointer to beginning of block to copy
; @param    hl  Pointer to destination
; @param    b   Number of bytes to copy
MemcopySmall::
    ld      a, [de]
    ld      [hli], a
    inc     de
    dec     b
    jr      nz, MemcopySmall
    ret

PUSHS

SECTION "RST $00", ROM0[$0000]

; Copy a block of memory from one place to another, even if the LCD is
; on
; @param    de  Pointer to beginning of block to copy
; @param    hl  Pointer to destination
; @param    bc  Number of bytes to copy
LCDMemcopy::
    ; Increment B if C is non-zero
    dec     bc
    inc     c
    inc     b
.loop
    ldh     a, [rSTAT]
    and     a, STATF_BUSY
    jr      nz, .loop
    ld      a, [de]
    ld      [hli], a
    inc     de
    dec     c
    jr      nz, .loop
    dec     b
    jr      nz, .loop
    ret

SECTION "RST $18", ROM0[$0018]

; Copy an arbitrary number of rows of map data to the visible background
; map, even if the LCD is on
; @param    de  Pointer to map data
; @param    hl  Pointer to destination
; @param    c   Number of rows to copy
LCDMemcopyMap::
    DEF UNROLL = 2
    ASSERT UNROLL * (2 + 2 + 1) <= 16
    ASSERT SCRN_X_B % UNROLL == 0
    ld      b, SCRN_X_B / UNROLL
.rowLoop
    ldh     a, [rSTAT]
    and     a, STATF_BUSY
    jr      nz, .rowLoop
    
    REPT UNROLL
    ld      a, [de]     ; 2 cycles
    ld      [hli], a    ; 2 cycles
    inc     de          ; 1 cycle
    ENDR
    dec     b
    jr      nz, .rowLoop
    
    push    de
    ld      de, SCRN_VX_B - SCRN_X_B
    add     hl, de
    pop     de
    dec     c
    jr      nz, LCDMemcopyMap
    ret

POPS

; @param    hl  Pointer to destination
; @param    a   Byte value to use
; @param    b   Number of bytes to set
MemsetSmall::
    ld      [hli], a
    dec     b
    jr      nz, MemsetSmall
    ret

; Fill an arbitrary number of rows of the background map, even if the
; LCD is on
; @param    hl  Pointer to destination
; @param    b   Byte value to use
; @param    d   Number of rows to fill
LCDMemsetMap::
    ld      e, LOW(SCRN_VX_B - SCRN_X_B)
.rowLoop
    DEF UNROLL = 16 / (1 + 2)
    ASSERT SCRN_X_B % UNROLL == 0
    ld      c, SCRN_X_B / UNROLL
.tileLoop
    ldh     a, [rSTAT]
    and     a, STATF_BUSY
    jr      nz, .tileLoop
    REPT UNROLL
    ld      a, b        ; 1 cycle
    ld      [hli], a    ; 2 cycles
    ENDR
    dec     c
    jr      nz, .tileLoop
    
    ld      a, d
    ld      d, HIGH(SCRN_VX_B - SCRN_X_B)
    add     hl, de
    ld      d, a
    dec     d
    jr      nz, .rowLoop
    ret
