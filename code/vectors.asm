INCLUDE "defines.inc"

SECTION "VBlank Interrupt", ROM0[$0040]

    jp      VBlankHandler

SECTION "VBlank Handler", ROM0

VBlankHandler:
    push    af
    push    bc
    push    de
    push    hl
    
    ld      a, HIGH(wShadowOAM)
    lb      bc, (OAM_COUNT * sizeof_OAM_ATTRS) / DMA_LOOP_CYCLES + 1, LOW(rDMA)
    call    hOAMDMA
    
    ; Disable objects for status bar
    ld      hl, rLCDC
    
    ldh     a, [hGameState]
    cp      a, GAME_STATE_IN_GAME
    jr      z, :+
    cp      a, GAME_STATE_PAUSED
    jr      nz, .noStatusBar
:
    res     LCDCB_OBJ, [hl]
    DB      $01         ; ld bc, d16 to consume the next 2 bytes
.noStatusBar
    set     LCDCB_OBJ, [hl]
    ld      l, LOW(hVBlankFlag)
    ld      [hl], h     ; Non-zero
    
    call    SoundSystem_Process
    
    ; Graphics loading may be done by a subroutine called by UpdateFade,
    ; so don't let that delay the above
    ei
    call    UpdateFade
    
    ; Read joypad
    ld      a, P1F_GET_DPAD
    call    .readPadNibble
    swap    a           ; Move directions to high nibble
    ld      b, a
    
    ld      a, P1F_GET_BTN
    call    .readPadNibble
    xor     a, b        ; Combine buttons and directions + complement
    ld      b, a
    
    ld      a, [hPressedKeys]
    xor     a, b        ; a = keys that changed state
    and     a, b        ; a = keys that changed to pressed
    ld      [hNewKeys], a
    ld      a, b
    ld      [hPressedKeys], a
    
    ld      a, P1F_GET_NONE
    ldh     [rP1], a
    
    pop     hl
    pop     de
    pop     bc
    
    ; SoundSystem_Process may take too long and this may be outside of
    ; VBlank
    ldh     a, [rLY]
    cp      a, SCRN_Y
    jr      nc, .finished
    
    ; Return at the start of HBlank for any code that waits for VRAM to
    ; become accessible, since this interrupt handler might be called
    ; while waiting
:
    ; Wait for mode 3, which comes before HBlank
    ldh     a, [rSTAT]
    ; (%11 + 1) & %11 == 0
    inc     a
    and     a, STAT_MODE_MASK
    jr      nz, :-
    
:
    ; Wait for HBlank -> ensured the beginning of HBlank by above
    ldh     a, [rSTAT]
    and     a, STAT_MODE_MASK
    jr      nz, :-
    
    ; This interrupt handler should return with at least 16 cycles left
    ; of accessible VRAM, which is what any VRAM accessibility-waiting
    ; code would assume it has
    
    ; Remaining time = Minimum HBlank time - Loop above + Mode 2 time
    ;                = 21 cycles - 4 cycles + 20 cycles
    ;                = 37 cycles
.finished
    pop     af  ; 3 cycles
    ret         ; 4 cycles  Interrupts enabled above
    
    ; 30 remaining VRAM-accessible cycles
    
    ; Not waiting for specifically the beginning of HBlank (i.e. just
    ; waiting for HBlank) would result in 16 - 7 (pop + ret) = only 9
    ; cycles!!!

; @param    a   Byte to write to rP1
; @return   a   Reading from rP1, ignoring non-input bits
.readPadNibble
    ldh     [rP1], a
    ; Burn 16 cycles between write and read
    call    .ret        ; 10 cycles
    ldh     a, [rP1]    ; 3 cycles
    ldh     a, [rP1]    ; 3 cycles
    ldh     a, [rP1]    ; Read
    or      a, $F0      ; Ignore non-input bits
.ret
    ret

SECTION "STAT Interrupt", ROM0[$0048]

STATHandler:
    push    af
    
    ldh     a, [hGameState]
    cp      a, GAME_STATE_IN_GAME
    jr      z, :+
    cp      a, GAME_STATE_PAUSED
    ; Nothing to do
    jr      nz, .doNothing
:
    push    hl
.waitHBL
    ldh     a, [rSTAT]
    and     a, STAT_MODE_MASK
    jr      nz, .waitHBL    ; Mode 0 - HBlank
    
    ld      hl, rLCDC
    ldh     a, [rLY]
    cp      a, STATUS_BAR_HEIGHT - 1
    jr      z, .endOfStatusBar
    cp      a, PAUSED_STRIP_Y - 1
    jr      z, .startOfPausedStrip
    
    ; End of "paused" strip
    ld      a, STATUS_BAR_HEIGHT - 1
    ldh     [rLYC], a
    ; Switch back tilemap
    res     LCDCB_BGMAP, [hl]
    jr      .enableObj
.endOfStatusBar
    ldh     a, [hGameState]
    cp      a, GAME_STATE_PAUSED
    jr      nz, .enableObj
    ; Game is paused, set rLYC for "paused" strip
    ld      a, PAUSED_STRIP_Y - 1
    ldh     [rLYC], a
.enableObj
    ; Enable objects - end of status bar or "paused" strip
    set     LCDCB_OBJ, [hl]
    jr      .finished
.startOfPausedStrip
    ld      a, PAUSED_STRIP_Y + PAUSED_STRIP_HEIGHT - 1
    ldh     [rLYC], a
    ; Disable objects - start of "paused" strip
    res     LCDCB_OBJ, [hl]
    ; Switch tilemap
    set     LCDCB_BGMAP, [hl]
.finished
    pop     hl
.doNothing
    
    ; Return at the start of HBlank for any code that waits for VRAM to
    ; become accessible, since this interrupt handler might be called
    ; while waiting
:
    ; Wait for mode 3, which comes before HBlank
    ldh     a, [rSTAT]
    ; (%11 + 1) & %11 == 0
    inc     a
    and     a, STAT_MODE_MASK
    jr      nz, :-
    
:
    ; Wait for HBlank -> ensured the beginning of HBlank by above
    ldh     a, [rSTAT]
    and     a, STAT_MODE_MASK
    jr      nz, :-
    
    ; This interrupt handler should return with at least 16 cycles left
    ; of accessible VRAM, which is what any VRAM accessibility-waiting
    ; code would assume it has
    
    ; Remaining time = Minimum HBlank time - Loop above + Mode 2 time
    ;                = 21 cycles - 4 cycles + 20 cycles
    ;                = 37 cycles
    
    pop     af  ; 3 cycles
    reti        ; 4 cycles
    
    ; 30 remaining VRAM-accessible cycles
    
    ; Not waiting for specifically the beginning of HBlank (i.e. just
    ; waiting for HBlank) would result in 16 - 7 (pop + ret) = only 9
    ; cycles!!!
