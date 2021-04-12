SECTION "System Routines", ROM0

; Copy a block of memory from one place to another
; @param hl Pointer to beginning of block to copy
; @param de Pointer to destination
; @param bc Number of bytes to copy
Memcopy::
    ld      a, [hl+]
    ld      [de], a
    inc     de
    dec     bc
    ld      a, c
    or      a, b
    jr      nz, Memcopy
    ret
