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
    ASSERT NOT_FADING == -1
    ; a = $FF = -1
    ldh     [hFadeState], a ; Not fading
    
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
    ld      hl, wShadowOAM
    ; a = 0
    ld      b, OAM_COUNT * sizeof_OAM_ATTRS
    call    MemsetSmall
    
    ; Copy OAM DMA routine to HRAM
    ld      de, OAMDMA
    ld      hl, hOAMDMA
    ld      b, OAMDMA.end - OAMDMA
    call    MemcopySmall
    
    ; Check save data header
    ld      a, CART_SRAM_ENABLE
    ld      [rRAMG], a
    ld      de, SaveDataHeader
    ld      hl, sSaveDataHeader
    ld      b, STRLEN(SAVE_DATA_HEADER)
.checkSaveDataHeaderLoop
    ld      a, [de]
    cp      a, [hl]
    jr      nz, .initSRAM
    ASSERT HIGH(SaveDataHeader.end - 1) == HIGH(SaveDataHeader)
    inc     e
    ASSERT HIGH(sSaveDataHeader.end - 1) == HIGH(sSaveDataHeader)
    inc     l
    dec     b
    jr      nz, .checkSaveDataHeaderLoop
    
    ; Save header is correct
    
    ; Check top scores checksum
    call    CalcTopScoresChecksum
    ld      hl, sChecksum
    cp      a, [hl]
    ; Checksum is correct
    jr      z, .doneCheckingSaveData
    ; No need to rewrite header
    jr      .initTopScores
.initSRAM
    ; Write save data header
    ASSERT HIGH(SaveDataHeader.end - 1) == HIGH(SaveDataHeader)
    ld      e, LOW(SaveDataHeader)
    ASSERT HIGH(sSaveDataHeader.end - 1) == HIGH(sSaveDataHeader)
    ld      l, LOW(sSaveDataHeader)
    REPT STRLEN(SAVE_DATA_HEADER) - 1
    ld      a, [de]
    ld      [hli], a
    inc     e
    ENDR
    ld      a, [de]
    ld      [hl], a
.initTopScores
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
    jr      :+
    
.doneCheckingSaveData
    ; Seed random number with top scores
    ld      a, [sChecksum]
    swap    a
:
    xor     a, "C"
    ld      b, a
    ; Use the 2nd bytes because they're the most interesting
    ld      a, [sClassicTopScores + 1]
    and     a, b
    ld      a, [sSuperTopScores + 1]
    xor     a, b
    ldh     [hRandomNumber], a
    
    ASSERT CART_SRAM_DISABLE == 0
    xor     a, a
    ld      [rRAMG], a
    
    call    SoundSystem_Init
    ld      de, SFX_Table
    call    SFX_Prepare
    
    ; Set palettes
    ld      a, %11100100
    ldh     [rBGP], a
    ld      a, %10010011
    ldh     [rOBP0], a
    
    call    LoadTitleScreen
    
    ; Set up interrupts
    ld      a, STATUS_BAR_HEIGHT - 1
    ldh     [rLYC], a
    ld      a, STATF_LYC
    ldh     [rSTAT], a
    
    xor     a, a
    ldh     [rIF], a
    ld      a, IEF_VBLANK | IEF_STAT
    ldh     [rIE], a
    
    ei
    
    ld      a, LCDCF_ON | LCDCF_WINOFF | LCDCF_BG8800 | LCDCF_BG9800 | LCDCF_OBJ16 | LCDCF_OBJON | LCDCF_BGON
    ldh     [rLCDC], a

Main::
    ; Wait for VBlank
    halt
    ldh     a, [hVBlankFlag]
    and     a, a
    jr      z, Main
    xor     a, a
    ldh     [hVBlankFlag], a
    
    ldh     a, [hFadeState]
    ASSERT NOT_FADING == -1
    inc     a       ; a = -1
    ; Currently fading, don't do anything
    jr      nz, Main
    
    ldh     a, [hGameState]
    ASSERT GAME_STATE_TITLE_SCREEN == 0
    and     a, a
    jp      z, TitleScreen
    ASSERT GAME_STATE_ACTION_SELECT == GAME_STATE_TITLE_SCREEN + 1
    dec     a
    jp      z, ActionSelect
    ASSERT GAME_STATE_MODE_SELECT == GAME_STATE_ACTION_SELECT + 1
    dec     a
    jp      z, ModeSelect
    ASSERT GAME_STATE_IN_GAME == GAME_STATE_MODE_SELECT + 1
    dec     a
    jp      z, InGame
    ASSERT GAME_STATE_TOP_SCORES == GAME_STATE_IN_GAME + 1
    dec     a
    jp      z, TopScores
    ASSERT GAME_STATE_GAME_OVER == GAME_STATE_TOP_SCORES + 1
    dec     a
    jp      z, GameOver
    ASSERT GAME_STATE_PAUSED == GAME_STATE_GAME_OVER + 1
    jp      Paused
    
    ASSERT GAME_STATE_COUNT == GAME_STATE_PAUSED + 1

SECTION "Stack", WRAM0[$E000 - STACK_SIZE]

    DS STACK_SIZE
wStackBottom:

SECTION "Shadow OAM", WRAM0, ALIGN[8]

wShadowOAM::
    DS OAM_COUNT * sizeof_OAM_ATTRS

SECTION "Global Variables", HRAM

hPressedKeys:: DS 1
hNewKeys::     DS 1

hGameState::   DS 1

hVBlankFlag::  DS 1

ASSERT SCORE_BYTE_COUNT == 3
hScore::
.2:: DS 1
.1:: DS 1
.0:: DS 1
.end::

ASSERT COOKIES_BLASTED_BYTE_COUNT == 2
hCookiesBlasted::
.hi:: DS 1
.lo:: DS 1
.end::

hGameMode:: DS 1

hScratch:: DS 1

SECTION "OAM DMA Routine", ROM0

OAMDMA:
    ldh     [c], a
.wait
    dec     b           ; 1 cycle
    jr      nz, .wait   ; 3 cycles
    ret
.end

ASSERT DMA_LOOP_CYCLES == 1 + 3

SECTION "OAM DMA", HRAM

hOAMDMA::
    DS OAMDMA.end - OAMDMA
