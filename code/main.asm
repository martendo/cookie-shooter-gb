INCLUDE "defines.inc"

SECTION "Initialization and Main Loop", ROM0

Initialize::
    ; Wait for VBlank to disable the LCD
.waitVBL
    ldh     a, [rLY]
    cp      a, SCRN_Y
    jr      c, .waitVBL
    
    xor     a, a
    ldh     [rLCDC], a
    
    ld      sp, wStackBottom
    
    ; Reset variables
    ldh     [hVBlankFlag], a
    
    ASSERT INITIAL_GAME_STATE == 0
    ldh     [hGameState], a
    ASSERT DEFAULT_GAME_MODE == 0
    ldh     [hGameMode], a
    ASSERT DEFAULT_ACTION == 0
    ldh     [hActionSelection], a
    
    ; a = 0
    ldh     [hNewKeys], a
    dec     a               ; a = $FF = all pressed
    ; Make all keys pressed so hNewKeys is correct
    ldh     [hPressedKeys], a
    
    ; Copy sprite tiles (never change) to VRAM
    ld      de, SpriteTiles
    ld      hl, _VRAM8000
    ld      bc, SpriteTiles.end - SpriteTiles
    call    Memcopy
    
    ; Draw "paused" strip
    ld      de, PausedStripMap
    ld      hl, vPausedStrip
    ld      c, PAUSED_STRIP_TILE_HEIGHT
    rst     LCDMemcopyMap
    
    ; Clear OAM
    ld      hl, _OAMRAM
    call    HideAllObjectsAtAddress
    ; Clear shadow OAM
    ld      hl, wShadowOAM
    ; a = 0
    ld      b, OAM_COUNT * sizeof_OAM_ATTRS
    call    MemsetSmall
    
    ; Copy OAM DMA routine to HRAM
    ld      de, OAMDMA
    ld      hl, hOAMDMA
    ld      b, OAMDMA.end - OAMDMA
    call    MemcopySmall
    
    ld      a, CART_SRAM_ENABLE
    ld      [rRAMG], a
    
    ; Check top scores checksum
    call    CalcTopScoresChecksum
    ld      hl, sChecksum
    cp      a, [hl]
    ; Checksum is correct, carry on
    jr      z, .doneCheckingSaveData
    
    ; Checksum is incorrect, check copy's checksum
    call    CalcTopScoresChecksum.copy
    ld      hl, sCopyChecksum
    cp      a, [hl]
    jr      nz, .initSRAM
    
    ; Copy is valid, use it instead
    ld      de, sClassicTopScoresCopy
    ld      hl, sClassicTopScores
    ld      b, sClassicTopScores.end - sClassicTopScores
    call    MemcopySmall
    ld      de, sSuperTopScoresCopy
    ld      hl, sSuperTopScores
    ld      b, sSuperTopScores.end - sSuperTopScores
    call    MemcopySmall
    ld      a, [sCopyChecksum]
    ld      [sChecksum], a
    jr      :+
    
.initSRAM
    ; Clear top scores
    ld      hl, sClassicTopScores
    ld      b, sClassicTopScores.end - sClassicTopScores
    xor     a, a
    call    MemsetSmall
    ld      hl, sSuperTopScores
    ld      b, sSuperTopScores.end - sSuperTopScores
    ; a = 0
    call    MemsetSmall
    ; a = 0
    ld      [sChecksum], a
    ld      hl, sClassicTopScoresCopy
    ld      b, sClassicTopScoresCopy.end - sClassicTopScoresCopy
    ; a = 0
    call    MemsetSmall
    ld      hl, sSuperTopScoresCopy
    ld      b, sSuperTopScoresCopy.end - sSuperTopScoresCopy
    ; a = 0
    call    MemsetSmall
    ; a = 0
    ld      [sCopyChecksum], a
    jr      :++
    
.doneCheckingSaveData
    ; Seed random number with top scores
    ld      a, [sChecksum]
    ; Do some funky stuff with the checksum
:   swap    a
:   xor     a, "C"
    ld      b, a
    ; Use the 2nd bytes of scores because they're the most interesting
    ld      a, [sClassicTopScores + 1]
    and     a, b
    ld      a, [sSuperTopScores + 1]
    xor     a, b
    ldh     [hRandomNumber], a
    
    ASSERT CART_SRAM_DISABLE == 0
    xor     a, a
    ld      [rRAMG], a
    
    ; Initialize SoundSystem and prepare sound effects
    call    SoundSystem_Init
    ld      de, SFX_Table
    call    SFX_Prepare
    
    ; Set palettes
    ld      a, %11100100
    ldh     [rBGP], a
    ldh     [hBGP], a
    ld      a, %10010011
    ldh     [rOBP0], a
    ldh     [hOBP0], a
    
    ; Set up the title screen (displayed first)
    call    LoadTitleScreen
    
    ; Set up interrupts
    ; Set up LYC STAT interrupt - LY of 0 for sound update
    xor     a, a
    ldh     [rLYC], a
    ld      a, STATF_LYC
    ldh     [rSTAT], a
    
    ; Clear any pending interrupts
    xor     a, a
    ldh     [rIF], a
    ; Enable interrupts
    ld      a, IEF_VBLANK | IEF_STAT
    ldh     [rIE], a
    ei
    
    ; Turn on the LCD
    ld      a, LCDCF_ON | LCDCF_WINOFF | LCDCF_BG8800 | LCDCF_BG9800 | LCDCF_OBJ16 | LCDCF_OBJON | LCDCF_BGON
    ldh     [rLCDC], a
    
    ; Start with the title screen
    jp      TitleScreen

SECTION "Game State Routine Tables", ROM0

; Setup routines for each game state, called when midway through a fade
; (screen is all black)
SetupRoutineTable::
    DW LoadTitleScreen          ; GAME_STATE_TITLE_SCREEN
    DW LoadActionSelectScreen   ; GAME_STATE_ACTION_SELECT
    DW LoadModeSelectScreen     ; GAME_STATE_MODE_SELECT
    DW SetUpGame                ; GAME_STATE_IN_GAME
    DW LoadTopScoresScreen      ; GAME_STATE_TOP_SCORES
    DW LoadGameOverScreen       ; GAME_STATE_GAME_OVER
.end::

; Loops for each game state
; This table is used to jump into the appropriate loop once a fade has
; completed
LoopTable::
    DW TitleScreen  ; GAME_STATE_TITLE_SCREEN
    DW ActionSelect ; GAME_STATE_ACTION_SELECT
    DW ModeSelect   ; GAME_STATE_MODE_SELECT
    DW InGame       ; GAME_STATE_IN_GAME
    DW TopScores    ; GAME_STATE_TOP_SCORES
    DW GameOver     ; GAME_STATE_GAME_OVER
.end::

SECTION "Stack", WRAM0[$E000 - STACK_SIZE]

; Allocate some space for the stack
    DS STACK_SIZE
wStackBottom:

SECTION "Shadow OAM", WRAM0, ALIGN[8]

; Shadow OAM, copied to OAM via OAM DMA each VBlank
wShadowOAM::
    DS OAM_COUNT * sizeof_OAM_ATTRS

SECTION "Global Variables", HRAM

; Bitfield of all inputs, updated every frame
; 1 = Pressed
hPressedKeys:: DS 1
; Keys that have just gone from low to high (just pressed)
hNewKeys::     DS 1

; Current game state and mode
; See constants/game.inc for possible values
hGameState:: DS 1
hGameMode::  DS 1

; Flag to signal that VBlank has occurred, check this after `halt`ing to
; tell if the last interrupt was for VBlank
hVBlankFlag:: DS 1

; Shadow palette registers, copied to the real registers each VBlank
hBGP::  DS 1
hOBP0:: DS 1

; Current score, 3-byte big-endian BCD
ASSERT SCORE_BYTE_COUNT == 3
hScore::
.2:: DS 1
.1:: DS 1
.0:: DS 1
.end::

; Number of cookies blasted, 2-byte big-endian BCD
ASSERT COOKIES_BLASTED_BYTE_COUNT == 2
hCookiesBlasted::
.hi:: DS 1
.lo:: DS 1
.end::

; Scratch/Temporary value
hScratch:: DS 1

SECTION "OAM DMA Routine", ROM0

; Initiate an OAM DMA
; This routine is copied to HRAM (hOAMDMA)
; @param    a   HIGH(wShadowOAM)
; @param    c   LOW(rDMA)
; @param    b   (OAM_COUNT * sizeof_OAM_ATTRS) / DMA_LOOP_CYCLES + 1
OAMDMA:
    ldh     [c], a
.wait
    dec     b           ; 1 cycle
    jr      nz, .wait   ; 3 cycles
    ret
.end

ASSERT DMA_LOOP_CYCLES == 1 + 3

SECTION "OAM DMA", HRAM

; HRAM location of OAMDMA routine above
hOAMDMA::
    DS OAMDMA.end - OAMDMA
