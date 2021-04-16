INCLUDE "defines.inc"

SECTION "Fade Variables", HRAM

hFadeState:: DS 1

SECTION "Fade Code", ROM0

StartFade::
    ld      a, FADE_OUT | FADE_PHASE_FRAMES
    ldh     [hFadeState], a
    ret

UpdateFade::
    ld      hl, hFadeState
    ld      a, [hl]
    inc     a       ; a = $FF
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
    dec     l       ; rBGP
    sra     [hl]
    sra     [hl]
    ld      a, [hl]
    inc     a       ; a = $FF = all black
    jr      nz, .fadeOutFinished
    ; Midway - increment game state
    ld      l, LOW(hGameState)
    inc     [hl]
    ; Switch to fade in
    jr      .fadeInFinished
    
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
    
    dec     l       ; rBGP
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
    
    ld      a, $FF  ; Finished fading
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
    jr      :+
.finished
    ld      l, LOW(hFadeState)
:
    ld      [hl], a
    ret
