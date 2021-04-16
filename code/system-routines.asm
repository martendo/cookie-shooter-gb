SECTION "System Routines", ROM0

; Copy a block of memory from one place to another
; @param de Pointer to beginning of block to copy
; @param hl Pointer to destination
; @param bc Number of bytes to copy
Memcopy::
    ld      a, [de]
    ld      [hli], a
    inc     de
    dec     bc
    ld      a, c
    or      a, b
    jr      nz, Memcopy
    ret
; @param de Pointer to beginning of block to copy
; @param hl Pointer to destination
; @param b  Number of bytes to copy
MemcopySmall::
    ld      a, [de]
    ld      [hli], a
    inc     de
    dec     b
    jr      nz, MemcopySmall
    ret

; Set a block of memory to a single byte value
; @param hl Pointer to destination
; @param a  Byte value to use
; @param bc Number of bytes to set
Memset::
    ld      d, a
.loop
    ld      a, d
    ld      [hli], a
    dec     bc
    ld      a, c
    or      a, b
    jr      nz, .loop
    ret
; @param hl Pointer to destination
; @param a  Byte value to use
; @param b  Number of bytes to set
MemsetSmall::
    ld      [hli], a
    dec     b
    jr      nz, MemsetSmall
    ret
