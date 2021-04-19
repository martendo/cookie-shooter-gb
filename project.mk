# Project configuration

PADVALUE := 0xFF

VERSION := 0
MFRCODE := MART
TITLE := COOKIESHOOT
LICENSEE := HB
OLDLIC := 0x33
MBC := MBC5+RAM+BATTERY
# 8 KB of SRAM, 1 bank
SRAMSIZE := 0x02
# Non-Japanese
FIXFLAGS += -j

ROMNAME := cookie-shooter
ROMEXT  := gb
