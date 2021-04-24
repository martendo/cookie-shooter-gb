SRCDIR := code
DATADIR := data
GFXDIR := gfx
BINDIR := bin
OBJDIR := obj
DEPDIR := dep
RESDIR := res

ROM = $(BINDIR)/$(ROMNAME).$(ROMEXT)

INCDIRS = $(SRCDIR) include
WARNINGS := all extra

ASFLAGS  = -h $(addprefix -i,$(INCDIRS)) -p $(PADVALUE) $(addprefix -W,$(WARNINGS))
LDFLAGS  = -p $(PADVALUE)
FIXFLAGS = -v -p $(PADVALUE) -i "$(MFRCODE)" -k "$(LICENSEE)" -l $(OLDLIC) -m $(MBC) -n $(VERSION) -r $(SRAMSIZE) -t $(TITLE)
GFXFLAGS = -hu -f

SRCS = $(wildcard $(SRCDIR)/*.asm) $(wildcard $(DATADIR)/*.asm)
GFX = $(RESDIR)/sprite-tiles.2bpp $(RESDIR)/in-game-tiles.2bpp $(RESDIR)/power-ups.2bpp $(RESDIR)/game-over.2bpp $(RESDIR)/game-over-numbers.2bpp $(RESDIR)/game-over.tilemap $(RESDIR)/title-screen.2bpp $(RESDIR)/title-screen.tilemap $(RESDIR)/mode-select.2bpp $(RESDIR)/mode-select-numbers.2bpp $(RESDIR)/mode-select.tilemap $(IN_GAME_SUBMAPS)
IN_GAME_SUBMAPS = $(RESDIR)/status-bar.tilemap $(RESDIR)/paused-strip.tilemap

# Project configuration
include project.mk
# Graphics conversion configuration
include gfx.mk

.PHONY: clean all rebuild

all: $(ROM)

clean:
	rm -rf $(BINDIR)
	rm -rf $(OBJDIR)
	rm -rf $(DEPDIR)
	rm -rf $(RESDIR)

rebuild:
	$(MAKE) clean
	$(MAKE) all

# Build the ROM, along with map and symbol files
$(BINDIR)/%.$(ROMEXT) $(BINDIR)/%.sym $(BINDIR)/%.map: $(GFX) $(patsubst %.asm,$(OBJDIR)/%.o,$(SRCS))
	@mkdir -p $(@D)
	rgblink $(LDFLAGS) -m $(BINDIR)/$*.map -n $(BINDIR)/$*.sym -o $(BINDIR)/$*.$(ROMEXT) $(patsubst %.asm,$(OBJDIR)/%.o,$(SRCS))
	rgbfix $(FIXFLAGS) $(BINDIR)/$*.$(ROMEXT)

# Assemble an assembly file, save dependencies
$(OBJDIR)/%.o $(DEPDIR)/%.mk: $(GFX) %.asm
	@mkdir -p $(OBJDIR)/$(*D) $(DEPDIR)/$(*D)
	rgbasm $(ASFLAGS) -M $(DEPDIR)/$*.mk -MG -MP -MQ $(OBJDIR)/$*.o -MQ $(DEPDIR)/$*.mk -o $(OBJDIR)/$*.o $*.asm

# Graphics conversion
$(RESDIR)/sprite-tiles.2bpp: $(GFXDIR)/sprite-tiles.png
	@mkdir -p $(@D)
	rgbgfx -d 2 $(GFXFLAGS) -o $(RESDIR)/sprite-tiles.2bpp $<

$(RESDIR)/%.pal.json: $(GFXDIR)/%.png
	@mkdir -p $(@D)
	superfamiconv palette -M gb -R -i $< -j $@
$(RESDIR)/%.2bpp: $(GFXDIR)/%.png $(RESDIR)/%.pal.json
	@mkdir -p $(@D)
	superfamiconv tiles -M gb -B 2 -R -F -T 256 -i $< -p $(RESDIR)/$*.pal.json -d $@

$(IN_GAME_SUBMAPS): $(RESDIR)/%.tilemap: $(GFXDIR)/%.png $(RESDIR)/in-game-tiles.2bpp $(RESDIR)/in-game-tiles.pal.json
	@mkdir -p $(@D)
	superfamiconv map -M gb -B 2 -F -i $< -t $(RESDIR)/in-game-tiles.2bpp -p $(RESDIR)/in-game-tiles.pal.json -d $@

$(RESDIR)/%.tilemap: $(GFXDIR)/%.png $(RESDIR)/%.2bpp $(RESDIR)/%.pal.json
	@mkdir -p $(@D)
	superfamiconv map -M gb -B 2 -F $(SFC_$*_MAP_FLAGS) -i $< -t $(RESDIR)/$*.2bpp -p $(RESDIR)/$*.pal.json -d $@

ifneq ($(MAKECMDGOALS),clean)
-include $(patsubst %.asm,$(DEPDIR)/%.mk,$(SRCS))
endif
