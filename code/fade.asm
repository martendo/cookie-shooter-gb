INCLUDE "defines.inc"

SECTION "Fade Variables", HRAM

hFadeNewGameState:
    DS 1
hFadeState::
    DS 1

SECTION "Fade Code", ROM0

; Start a fade to black and back, and wait for it to complete
; @param    a   New game state to set midway through the fade
Fade::
    ldh     [hFadeNewGameState], a
    ld      a, FADE_OUT | FADE_PHASE_FRAMES
    ldh     [hFadeState], a
    
.wait
    ; Wait for VBlank
    halt
    ldh     a, [hVBlankFlag]
    and     a, a
    jr      z, .wait
    xor     a, a
    ldh     [hVBlankFlag], a
    
    ld      hl, hFadeState
    ld      a, [hl]
    ASSERT NOT_FADING == -1
    inc     a       ; a = -1
    ; Currently fading
    jr      z, EndFade

UpdateFade:
    dec     a       ; Undo inc
    ASSERT FADE_MIDWAY_BIT == 7
    add     a, a    ; Move bit 7 into carry
    jr      c, .midway
    
    ld      a, [hl]
    and     a, FADE_COUNTDOWN_MASK
    dec     a
    jr      nz, .noChange
    
    ; Next phase
    bit     FADE_DIRECTION_BIT, [hl]
    ld      l, LOW(hOBP0)
    jr      nz, .fadeIn
    
    ; Fade out: shift all colours; darken each one
    sra     [hl]
    sra     [hl]
    ASSERT hBGP == hOBP0 - 1
    dec     l
    sra     [hl]
    sra     [hl]
    ld      a, [hl]
    inc     a       ; a = $FF = all black
    jr      nz, .fadeOutFinished
    
    ; Set midway bit (delay a frame for shadow registers to be copied)
    ld      l, LOW(hFadeState)
    set     FADE_MIDWAY_BIT, [hl]
    jr      Fade.wait
    
.fadeIn
    ; Fade in: Shift colours, add lighter colour to end
    ld      a, [hl] ; hOBP0
    dec     a
    and     a, %11  ; a = new lighter colour to shift in
    ld      b, a
    
    ld      a, [hl]
    sla     a
    sla     a
    or      a, b
    ld      [hl], a
    
    ASSERT hBGP == hOBP0 - 1
    dec     l
    ld      a, [hl]
    dec     a
    and     a, %11  ; a = new lighter colour
    ld      b, a
    
    ld      a, [hl]
    sla     a
    sla     a
    or      a, b
    ld      [hl], a
    
    cp      a, %11100100    ; Palette is back to normal?
    jr      nz, .fadeInFinished
    
    ld      a, NOT_FADING   ; Finished fading
    jr      .finished
    
.fadeInFinished
    ld      a, FADE_IN | FADE_PHASE_FRAMES
    jr      .finished
    
.fadeOutFinished
    ld      a, FADE_OUT | FADE_PHASE_FRAMES
    jr      .finished
.noChange
    ld      b, a
    ld      a, [hl]
    and     a, FADE_DIRECTION_MASK
    or      a, b
.finished
    ld      l, LOW(hFadeState)
    ld      [hl], a
    jr      Fade.wait

.midway
    ; Midway through fade
    ; Switch to fade in
    ld      [hl], FADE_IN | FADE_PHASE_FRAMES
    ; Set new game state
    ld      l, LOW(hFadeNewGameState)
    ld      a, [hli]
    ldh     [hGameState], a
    
    ; Jump to midway subroutine
    ; a = game state
    add     a, a
    add     a, LOW(SetupRoutineTable)
    ld      l, a
    ASSERT HIGH(SetupRoutineTable.end - 1) == HIGH(SetupRoutineTable)
    ld      h, HIGH(SetupRoutineTable)
    call    JumpToPointerAtHL
    jr      Fade.wait

EndFade:
    ; Jump into the appropriate loop
    ldh     a, [hGameState]
    add     a, a
    add     a, LOW(LoopTable)
    ld      l, a
    ASSERT HIGH(LoopTable.end - 1) == HIGH(LoopTable)
    ld      h, HIGH(LoopTable)
    ; Fallthrough

JumpToPointerAtHL:
    ld      a, [hli]
    ld      h, [hl]
    ld      l, a
    jp      hl
