SRCDIR := code
GFXDIR := gfx
BINDIR := bin
RESDIR := res

ROM = $(BINDIR)/$(ROMNAME).$(ROMEXT)

INCDIRS = $(SRCDIR) include
WARNINGS := all extra

ASFLAGS  = -h $(addprefix -i,$(INCDIRS)) -p $(PADVALUE) $(addprefix -W,$(WARNINGS))
LDFLAGS  = -p $(PADVALUE)
FIXFLAGS = -v -p $(PADVALUE) -i "$(MFRCODE)" -k "$(LICENSEE)" -l $(OLDLIC) -m $(MBC) -n $(VERSION) -r $(SRAMSIZE) -t $(TITLE)
GFXFLAGS = -hu -f

SRCS = $(wildcard $(SRCDIR)/*.asm)
GFX = $(RESDIR)/sprite-tiles.2bpp $(RESDIR)/bg-tiles.2bpp $(RESDIR)/status-bar.tilemap $(RESDIR)/game-over.tilemap

# Project configuration
include project.mk

.PHONY: clean all rebuild

all: $(ROM)

clean:
	rm -rf $(BINDIR)
	rm -rf $(RESDIR)

rebuild: clean all

# Build the ROM, along with map and symbol files
$(BINDIR)/%.$(ROMEXT) $(BINDIR)/%.sym $(BINDIR)/%.map: $(GFX) $(patsubst $(SRCDIR)/%.asm,$(BINDIR)/%.o,$(SRCS))
	@mkdir -p $(@D)
	rgblink $(LDFLAGS) -m $(BINDIR)/$*.map -n $(BINDIR)/$*.sym -o $(BINDIR)/$*.$(ROMEXT) $(patsubst $(SRCDIR)/%.asm,$(BINDIR)/%.o,$(SRCS))
	rgbfix $(FIXFLAGS) $(BINDIR)/$*.$(ROMEXT)

# Assemble an assembly file
$(BINDIR)/%.o: $(SRCDIR)/%.asm
	@mkdir -p $(@D)
	rgbasm $(ASFLAGS) -o $(BINDIR)/$*.o $<

# Graphics conversion
$(RESDIR)/sprite-tiles.2bpp: $(GFXDIR)/sprite-tiles.png
	@mkdir -p $(@D)
	rgbgfx -d 2 $(GFXFLAGS) -o $(RESDIR)/sprite-tiles.2bpp $<

$(RESDIR)/%.pal.json: $(GFXDIR)/%.png
	@mkdir -p $(@D)
	superfamiconv palette -M gb -R -i $< -j $@
$(RESDIR)/%.2bpp: $(GFXDIR)/%.png $(RESDIR)/%.pal.json
	@mkdir -p $(@D)
	superfamiconv tiles -M gb -B 2 -R -F -i $< -p $(RESDIR)/$*.pal.json -d $@

$(RESDIR)/%.tilemap: $(GFXDIR)/%.png $(RESDIR)/bg-tiles.2bpp $(RESDIR)/bg-tiles.pal.json
	@mkdir -p $(@D)
	superfamiconv map -M gb -B 2 -F -i $< -t $(RESDIR)/bg-tiles.2bpp -p $(RESDIR)/bg-tiles.pal.json -d $@
