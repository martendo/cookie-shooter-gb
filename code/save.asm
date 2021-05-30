INCLUDE "defines.inc"

SECTION "Save Data Checksum Calculation", ROM0

CalcTopScoresChecksum::
    xor     a, a
    
    ld      hl, sClassicTopScores
    call    .calcChecksum
    
    ld      hl, sSuperTopScores
    ; Fallthrough

.calcChecksum
    ld      b, TOP_SCORE_COUNT * SCORE_BYTE_COUNT
.loop
    add     a, [hl]
    inc     l
    dec     b
    jr      nz, .loop
    ret

.copy::
    xor     a, a
    
    ld      hl, sClassicTopScoresCopy
    call    .calcChecksum
    
    ld      hl, sSuperTopScoresCopy
    jr      .calcChecksum

SECTION "Classic Mode Top Scores", SRAM, ALIGN[8]

sClassicTopScores::
    DS TOP_SCORE_COUNT * SCORE_BYTE_COUNT
.end::

SECTION "Classic Mode Top Scores Copy", SRAM, ALIGN[8]

sClassicTopScoresCopy::
    DS TOP_SCORE_COUNT * SCORE_BYTE_COUNT
.end::

SECTION "Super Mode Top Scores", SRAM, ALIGN[8]

sSuperTopScores::
    DS TOP_SCORE_COUNT * SCORE_BYTE_COUNT
.end::

SECTION "Super Mode Top Scores Copy", SRAM, ALIGN[8]

sSuperTopScoresCopy::
    DS TOP_SCORE_COUNT * SCORE_BYTE_COUNT
.end::

SECTION "Save Data Checksum", SRAM

sChecksum::
    DS 1
