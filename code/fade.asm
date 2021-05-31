INCLUDE "defines.inc"

SECTION "Fade Variables", HRAM

; New game state to switch to after fade
hFadeNewGameState:
    DS 1
; Current fade state
; Bit 7: Fade direction (0: Out, 1: In)
hFadeState:
    DS 1
; Countdown of frames until the next fade "phase", where the palette is
; updated
hFadeCountdown:
    DS 1

SECTION "Fade Code", ROM0

; Start a fade to black and back and wait for it to complete
; The next screen will be set up when the screen is fully black
; @param    a   New game state to set midway through the fade
Fade::
    ldh     [hFadeNewGameState], a
    ld      a, FADE_PHASE_FRAMES
    ldh     [hFadeCountdown], a
    ld      a, FADE_OUT
    ldh     [hFadeState], a

.loop
    ; Wait for VBlank
    halt
    ldh     a, [hVBlankFlag]
    and     a, a
    jr      z, .loop
    xor     a, a
    ldh     [hVBlankFlag], a
    
    ; Update fade
    
    ; Decrement countdown
    ld      hl, hFadeCountdown
    dec     [hl]
    jr      nz, .loop
    
    ; Move on to the next fade phase
    
    ; Fade in the correct direction
    ASSERT hFadeState == hFadeCountdown - 1
    dec     l
    bit     FADE_DIRECTION_BIT, [hl]
    ld      l, LOW(hOBP0)
    jr      nz, .fadeIn
    
    ; Fade out: shift all colours right -> darken each one
    sra     [hl]
    sra     [hl]
    ASSERT hBGP == hOBP0 - 1
    dec     l
    sra     [hl]
    sra     [hl]
    ld      a, [hl]
    inc     a       ; a = $FF = all black
    jr      nz, .nextPhase
    
    ; Midway through fade
    ; Set new game state
    ld      l, LOW(hFadeNewGameState)
    ld      a, [hli]
    ldh     [hGameState], a
    ; Switch to fade in
    ASSERT hFadeState == hFadeNewGameState + 1
    ld      [hl], FADE_IN
    ASSERT hFadeCountdown == hFadeState + 1
    inc     l
    ld      [hl], FADE_PHASE_FRAMES
    
    ; Jump to midway subroutine
    ; a = game state
    add     a, a
    add     a, LOW(SetupRoutineTable)
    ld      l, a
    ASSERT HIGH(SetupRoutineTable.end - 1) == HIGH(SetupRoutineTable)
    ld      h, HIGH(SetupRoutineTable)
    
    ; Delay a frame to allow shadow palette registers to be copied
:
    halt
    ldh     a, [hVBlankFlag]
    and     a, a
    jr      z, :-
    xor     a, a
    ldh     [hVBlankFlag], a
    
    call    JumpToPointerAtHL
    jr      .loop

.fadeIn
    ; Fade in: Shift colours left, shifting in lighter colour to end
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
    ; Completely finished fading, give control to the new game state's
    ; loop
    jr      z, .end

.nextPhase
    ld      l, LOW(hFadeCountdown)
    ld      [hl], FADE_PHASE_FRAMES
    jr      .loop

.end
    ; Jump into the appropriate loop
    ldh     a, [hGameState]
    add     a, a
    add     a, LOW(LoopTable)
    ld      l, a
    ASSERT HIGH(LoopTable.end - 1) == HIGH(LoopTable)
    ld      h, HIGH(LoopTable)
    ; Fall through

JumpToPointerAtHL:
    ld      a, [hli]
    ld      h, [hl]
    ld      l, a
    jp      hl
