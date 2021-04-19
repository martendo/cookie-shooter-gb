SRCDIR := code
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

SRCS = $(wildcard $(SRCDIR)/*.asm)
GFX = $(RESDIR)/sprite-tiles.2bpp $(RESDIR)/in-game-tiles.2bpp $(RESDIR)/status-bar.tilemap $(RESDIR)/game-over.2bpp $(RESDIR)/game-over-numbers.2bpp $(RESDIR)/game-over.tilemap $(RESDIR)/title-screen.2bpp $(RESDIR)/title-screen.tilemap

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
$(BINDIR)/%.$(ROMEXT) $(BINDIR)/%.sym $(BINDIR)/%.map: $(GFX) $(patsubst $(SRCDIR)/%.asm,$(OBJDIR)/%.o,$(SRCS))
	@mkdir -p $(@D)
	rgblink $(LDFLAGS) -m $(BINDIR)/$*.map -n $(BINDIR)/$*.sym -o $(BINDIR)/$*.$(ROMEXT) $(patsubst $(SRCDIR)/%.asm,$(OBJDIR)/%.o,$(SRCS))
	rgbfix $(FIXFLAGS) $(BINDIR)/$*.$(ROMEXT)

# Assemble an assembly file, save dependencies
$(OBJDIR)/%.o $(DEPDIR)/%.mk: $(GFX) $(SRCDIR)/%.asm
	@mkdir -p $(OBJDIR) $(DEPDIR)
	rgbasm $(ASFLAGS) -M $(DEPDIR)/$*.mk -MG -MP -MQ $(OBJDIR)/$*.o -MQ $(DEPDIR)/$*.mk -o $(OBJDIR)/$*.o $(SRCDIR)/$*.asm

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

$(RESDIR)/status-bar.tilemap: $(GFXDIR)/status-bar.png $(RESDIR)/in-game-tiles.2bpp $(RESDIR)/in-game-tiles.pal.json
	@mkdir -p $(@D)
	superfamiconv map -M gb -B 2 -F -i $< -t $(RESDIR)/in-game-tiles.2bpp -p $(RESDIR)/in-game-tiles.pal.json -d $@

$(RESDIR)/%.tilemap: $(GFXDIR)/%.png $(RESDIR)/%.2bpp $(RESDIR)/%.pal.json
	@mkdir -p $(@D)
	superfamiconv map -M gb -B 2 -F $(SFC_$*_MAP_FLAGS) -i $< -t $(RESDIR)/$*.2bpp -p $(RESDIR)/$*.pal.json -d $@

ifneq ($(MAKECMDGOALS),clean)
-include $(patsubst $(SRCDIR)/%.asm,$(DEPDIR)/%.mk,$(SRCS))
endif
