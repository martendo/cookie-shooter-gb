SRCDIR := code
GFXDIR := gfx
BINDIR := bin
RESDIR := res

ROM = $(BINDIR)/$(ROMNAME).$(ROMEXT)

INCDIRS := $(SRCDIR) include
WARNINGS := all extra

ASFLAGS  = -h $(addprefix -i,$(INCDIRS)) -p $(PADVALUE) $(addprefix -W,$(WARNINGS))
LDFLAGS  = -p $(PADVALUE)
FIXFLAGS = -v -p $(PADVALUE) -i "$(MFRCODE)" -k "$(LICENSEE)" -l $(OLDLIC) -m $(MBC) -n $(VERSION) -r $(SRAMSIZE) -t $(TITLE)
GFXFLAGS = -hu -f

SRCS = $(wildcard $(SRCDIR)/*.asm)
OBJS = $(patsubst $(SRCDIR)/%.asm,$(BINDIR)/%.o,$(SRCS))
GFX = $(wildcard $(GFXDIR)/*.png)

# Project configuration
include project.mk

.PHONY: clean all rebuild

all: $(ROM)

clean:
	rm -rf $(BINDIR)
	rm -rf $(RESDIR)

rebuild: clean all

# Build the ROM, along with map and symbol files
$(BINDIR)/%.$(ROMEXT) $(BINDIR)/%.sym $(BINDIR)/%.map: $(patsubst $(GFXDIR)/%.png,$(RESDIR)/%.2bpp,$(GFX)) $(OBJS)
	@mkdir -p $(@D)
	rgblink $(LDFLAGS) -m $(BINDIR)/$*.map -n $(BINDIR)/$*.sym -o $(BINDIR)/$*.$(ROMEXT) $(OBJS)
	rgbfix $(FIXFLAGS) $(BINDIR)/$*.$(ROMEXT)

# Assemble an assembly file
$(BINDIR)/%.o: $(SRCDIR)/%.asm
	@mkdir -p $(@D)
	rgbasm $(ASFLAGS) -o $(BINDIR)/$*.o $<

# Convert a PNG file
$(RESDIR)/%.2bpp: $(GFXDIR)/%.png
	@mkdir -p $(@D)
	rgbgfx -d 2 $(GFXFLAGS) -o $(RESDIR)/$*.2bpp $<
