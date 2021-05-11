INCLUDE "defines.inc"

SECTION "Fade Variables", HRAM

hFadeNewGameState:
    DS 1
hFadeState::
    DS 1

SECTION "Fade Midway Subroutine Table", ROM0

FadeMidwayRoutineTable:
    DW LoadTitleScreen      ; GAME_STATE_TITLE_SCREEN
    DW LoadModeSelectScreen ; GAME_STATE_MODE_SELECT
    DW LoadTopScoresScreen  ; GAME_STATE_TOP_SCORES
    DW SetUpGame            ; GAME_STATE_IN_GAME
    DW LoadGameOverScreen   ; GAME_STATE_GAME_OVER
.end

SECTION "Fade Code", ROM0

; Start a fade to black and back
; @param a  New game state to set midway through the fade
StartFade::
    ldh     [hFadeNewGameState], a
    ld      a, FADE_OUT | FADE_PHASE_FRAMES
    ldh     [hFadeState], a
    ret

UpdateFade::
    ld      hl, hFadeState
    ld      a, [hl]
    ASSERT NOT_FADING == -1
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
    
    ; Midway through fade
    ; Set new game state
    ld      l, LOW(hFadeNewGameState)
    ld      a, [hli]
    ldh     [hGameState], a
    ; Switch to fade in
    ASSERT hFadeState == hFadeNewGameState + 1
    ld      [hl], FADE_IN | FADE_PHASE_FRAMES
    
    ; Jump to midway subroutine
    ; a = game state
    add     a, a
    add     a, LOW(FadeMidwayRoutineTable)
    ld      l, a
    ASSERT HIGH(FadeMidwayRoutineTable.end - 1) == HIGH(FadeMidwayRoutineTable)
    ld      h, HIGH(FadeMidwayRoutineTable)
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
