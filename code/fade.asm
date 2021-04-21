INCLUDE "defines.inc"

SECTION "Fade Variables", HRAM

hFadeState:: DS 1
hFadeMidwayCall:
.lo DS 1
.hi DS 1

SECTION "Fade Code", ROM0

; @param hl Address to call midway through the fade
StartFade::
    ld      a, FADE_OUT | FADE_PHASE_FRAMES
    ldh     [hFadeState], a
    ld      a, l
    ldh     [hFadeMidwayCall.lo], a
    ld      a, h
    ldh     [hFadeMidwayCall.hi], a
    ret

UpdateFade::
    ld      hl, hFadeState
    ld      a, [hl]
    ASSERT NOT_FADING == LOW(-1)
    inc     a       ; a = -1
    ret     z       ; Not fading, nothing to do
    
    dec     a       ; Undo inc
    and     a, FADE_COUNTDOWN
    dec     a
    jr      nz, .noChange
    
    ; Next phase
    bit     FADE_DIRECTION_BIT, [hl]
    ld      l, LOW(rOBP0)
    jr      nz, .fadeIn
    
    ; Fade out: shift all colours; darken each one
    sra     [hl]
    sra     [hl]
    ASSERT rBGP == rOBP0 - 1
    dec     l
    sra     [hl]
    sra     [hl]
    ld      a, [hl]
    inc     a       ; a = $FF = all black
    jr      nz, .fadeOutFinished
    
    ; Midway - increment game state, call subroutine
    ld      l, LOW(hGameState)
    inc     [hl]
    ; Switch to fade in
    ld      l, LOW(hFadeState)
    ld      [hl], FADE_IN | FADE_PHASE_FRAMES
    
    ASSERT hFadeMidwayCall == hFadeState + 1
    inc     l
    ld      a, [hli]
    ld      h, [hl]
    ld      l, a
    jp      hl
    
.fadeIn
    ; Fade in: Shift colours, add lighter colour to end
    ld      a, [hl] ; rOBP0
    dec     a
    and     a, %11  ; a = new lighter colour to shift in
    ld      b, a
    
    ld      a, [hl]
    sla     a
    sla     a
    or      a, b
    ld      [hl], a
    
    ASSERT rBGP == rOBP0 - 1
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
    and     a, FADE_DIRECTION
    or      a, b
.finished
    ld      l, LOW(hFadeState)
    ld      [hl], a
    ret
