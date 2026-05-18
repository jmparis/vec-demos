PRJ := $(patsubst vec-%,%,$(notdir $(CURDIR)))
SRCDIR=src
BUILDDIR=build
SRC=$(SRCDIR)/$(PRJ).asm
OUT=$(BUILDDIR)/$(PRJ).bin

ASM=lwasm

EMU_MAME=mame
EMU_RETROARCH=flatpak run org.libretro.RetroArch
CORE=$(HOME)/.var/app/org.libretro.RetroArch/config/retroarch/cores/vecx_libretro.so

# JSVECX configuration
JSVECX_DIR	=	tools/jsvecx/deploy
JSVECX_PORT?=	8080
JSVECX_ROM	=	$(JSVECX_DIR)/roms/$(PRJ).bin
#JSVECX_BIOS=	$(JSVECX_DIR)/bios/B796 	# BIOS rev.a / v1 (GCE)
#JSVECX_BIOS=	$(JSVECX_DIR)/bios/7931 	# BIOS rev.B / v2 (Milton Bradley)
JSVECX_BIOS	=	$(JSVECX_DIR)/bios/7ADB		# BIOS rev.c / v3 (Milton Bradley EU)
#JSVECX_BOPT=	ori		# Original mode (flicker, sound, gameinfo)
JSVECX_BOPT	=	fast	# Fast mode (no flicker, no sound, no gameinfo)
JSVECX_SOUND=	on

# Colors for help output
GREEN=\033[1;32m
RESET=\033[0m

#
# Makefile for building and running Vectrex ROMs with MAME, RetroArch and JSVECX.
# Adjust paths and commands as needed for your environment.
#

# Default target
help: usage

all: $(OUT)

$(OUT): $(SRC)
	mkdir -p build
	$(ASM) -f raw -o $(OUT) $(SRC)
#	objcopy -I srec -O binary --gap-fill 0xFF build/$(PRJ).srec $(OUT)

run: run_mame

run_mame: $(OUT)
	$(EMU_MAME) vectrex \
	-window        \
	-nomax         \
	-keepaspect    \
	-prescale 2    \
	-skip_gameinfo \
	-flicker 0.2   \
	-speed 1.0     \
	-cart $(OUT)

run_retroarch: $(OUT)
	$(EMU_RETROARCH) -L $(CORE) $(OUT)

run_jsvecx: $(OUT)
	mkdir -p $(JSVECX_DIR)/roms
	cp $(OUT) $(JSVECX_ROM)
	@printf "$(GREEN)Open:$(RESET) http://localhost:$(JSVECX_PORT)/?rom=$(PRJ)&sound=$(JSVECX_SOUND)&bios=$(JSVECX_BIOS)&bopt=$(JSVECX_BOPT)\n"
	cd $(JSVECX_DIR) && python3 -m http.server $(JSVECX_PORT)

usage:
	@printf "$(GREEN)Usage:$(RESET) make <target>\n"
	@printf "  $(GREEN)make all$(RESET)           Build the ROM binary\n"
	@printf "  $(GREEN)make run$(RESET)           Run with MAME (alias for run_mame)\n"
	@printf "  $(GREEN)make run_mame$(RESET)      Run with MAME\n"
	@printf "  $(GREEN)make run_retroarch$(RESET) Run with RetroArch\n"
	@printf "  $(GREEN)make run_jsvecx$(RESET)    Run with JSVecX in browser\n"
	@printf "  $(GREEN)make clean$(RESET)         Remove build artifacts\n"

.PHONY: all run run_mame run_retroarch run_jsvecx help usage clean

clean:
	rm -rf build