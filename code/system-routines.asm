SECTION "System Routines", ROM0

; Copy a block of memory from one place to another
; @param de Pointer to beginning of block to copy
; @param hl Pointer to destination
; @param bc Number of bytes to copy
Memcopy::
    ld      a, [de]
    ld      [hl+], a
    inc     de
    dec     bc
    ld      a, c
    or      a, b
    jr      nz, Memcopy
    ret
