INCLUDE "defines.inc"

SECTION "Entry Point", ROM0[$0100]

    di
    jp      Initialize
    
    DS      $0150 - @, 0

SECTION "Initialization and Main Loop", ROM0

Initialize:
    ld      sp, wStackBottom
    
    ; Wait for VBlank to disable the LCD
.waitVBL
    ldh     a, [rLY]
    cp      a, SCRN_Y
    jr      c, .waitVBL
    
    xor     a, a
    ldh     [rLCDC], a
    
    ; Reset variables
    ldh     [hVBlankFlag], a
    
    ASSERT INITIAL_GAME_STATE == 0
    ldh     [hGameState], a
    ASSERT DEFAULT_GAME_MODE == 0
    ldh     [hGameMode], a
    
    ; a = 0
    ldh     [hNewKeys], a
    dec     a               ; a = $FF = all pressed
    ; Make all keys pressed so hNewKeys is correct
    ldh     [hPressedKeys], a
    ASSERT NOT_FADING == LOW(-1)
    ; a = $FF = -1
    ldh     [hFadeState], a ; Not fading
    
    ; Copy sprite tiles (never change) to VRAM
    ld      de, SpriteTiles
    ld      hl, _VRAM8000
    ld      bc, SpriteTiles.end - SpriteTiles
    call    Memcopy
    
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
    ASSERT HIGH(SaveDataHeader) == HIGH(SaveDataHeader.end)
    inc     e
    ASSERT HIGH(sSaveDataHeader) == HIGH(sSaveDataHeader.end)
    inc     l
    dec     b
    jr      nz, .checkSaveDataHeaderLoop
    
    ; Save header is correct
    jr      .doneCheckingSaveData
    
.initSRAM
    ; Write save data header
    ASSERT HIGH(SaveDataHeader) == HIGH(SaveDataHeader.end)
    ld      e, LOW(SaveDataHeader)
    ASSERT HIGH(sSaveDataHeader) == HIGH(sSaveDataHeader.end)
    ld      l, LOW(sSaveDataHeader)
    ld      b, STRLEN(SAVE_DATA_HEADER)
    call    MemcopySmall
    ; Clear high score
    xor     a, a
    ASSERT sClassicHighScore == sSaveDataHeader.end
    REPT SCORE_BYTE_COUNT
    ld      [hli], a
    ENDR
    ASSERT sSuperHighScore == sClassicHighScore.end
    REPT SCORE_BYTE_COUNT
    ld      [hli], a
    ENDR
    
.doneCheckingSaveData
    ; Seed random number with high scores
    ; Use the 2nd byte because it is the most interesting
    ld      a, [sClassicHighScore.1]
    ld      b, a
    ld      a, [sSuperHighScore.1]
    xor     a, b
    ldh     [hRandomNumber], a
    
    ASSERT CART_SRAM_DISABLE == 0
    xor     a, a
    ld      [rRAMG], a
    
    call    SoundSystem_Init
    
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
    ld      a, IEF_VBLANK | IEF_LCDC
    ldh     [rIE], a
    
    ld      a, LCDCF_ON | LCDCF_WINOFF | LCDCF_BG8800 | LCDCF_BG9800 | LCDCF_OBJ16 | LCDCF_OBJON | LCDCF_BGON
    ldh     [rLCDC], a
    
    ei

Main::
    ldh     a, [hFadeState]
    ASSERT NOT_FADING == LOW(-1)
    inc     a               ; a = -1
    jr      nz, EmptyLoop   ; Currently fading
    
    ldh     a, [hGameState]
    ; GAME_STATE_TITLE_SCREEN
    and     a, a
    jp      z, TitleScreen
    ; GAME_STATE_MODE_SELECT
    dec     a
    jp      z, ModeSelect
    ; GAME_STATE_IN_GAME
    dec     a
    jp      z, InGame
    ; GAME_STATE_GAME_OVER
    dec     a
    jp      z, GameOver
    ; GAME_STATE_PAUSED
    jp      Paused

EmptyLoop:
    call    HaltVBlank
    jr      Main

HaltVBlank::
    halt
    ldh     a, [hVBlankFlag]
    and     a, a
    jr      z, HaltVBlank
    xor     a, a
    ldh     [hVBlankFlag], a
    ret

SECTION "Stack", WRAMX[$E000 - STACK_SIZE]

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
.0:: DS 1
.1:: DS 1
.2:: DS 1
.end::

ASSERT COOKIES_BLASTED_BYTE_COUNT == 2
hCookiesBlasted::
.lo:: DS 1
.hi:: DS 1
.end::

hGameMode:: DS 1

hWaitCountdown:: DS 1

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

SECTION "Save Data Header", ROM0

SaveDataHeader:
    DB SAVE_DATA_HEADER
.end

SECTION "Save Data", SRAM

sSaveDataHeader:
    DS STRLEN(SAVE_DATA_HEADER)
.end

ASSERT SCORE_BYTE_COUNT == 3
sClassicHighScore::
.0:: DS 1
.1:: DS 1
.2:: DS 1
.end::

ASSERT SCORE_BYTE_COUNT == 3
sSuperHighScore::
.0:: DS 1
.1:: DS 1
.2:: DS 1
.end::
