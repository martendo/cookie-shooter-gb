SRCDIR := code
BINDIR := bin

ROM = $(BINDIR)/$(ROMNAME).$(ROMEXT)

INCDIRS := $(SRCDIR) include
WARNINGS := all extra

ASFLAGS  = -h $(addprefix -i,$(INCDIRS)) -p $(PADVALUE) $(addprefix -W,$(WARNINGS))
LDFLAGS  = -p $(PADVALUE)
FIXFLAGS = -v -p $(PADVALUE) -i "$(MFRCODE)" -k "$(LICENSEE)" -l $(OLDLIC) -m $(MBC) -n $(VERSION) -r $(SRAMSIZE) -t $(TITLE)

SRCS = $(wildcard $(SRCDIR)/*.asm)

# Project configuration
include project.mk

.PHONY: clean all rebuild

all: $(ROM)

clean:
	rm -rf $(BINDIR)

rebuild: clean all

# Build the ROM, along with map and symbol files
$(BINDIR)/%.$(ROMEXT) $(BINDIR)/%.sym $(BINDIR)/%.map: $(patsubst $(SRCDIR)/%.asm,$(BINDIR)/%.o,$(SRCS))
	@mkdir -p $(@D)
	rgblink $(LDFLAGS) -m $(BINDIR)/$*.map -n $(BINDIR)/$*.sym -o $(BINDIR)/$*.$(ROMEXT) $^
	rgbfix $(FIXFLAGS) $(BINDIR)/$*.$(ROMEXT)

# Assemble an assembly file
$(BINDIR)/%.o: $(SRCDIR)/%.asm
	@mkdir -p $(@D)
	rgbasm $(ASFLAGS) -o $(BINDIR)/$*.o $<
