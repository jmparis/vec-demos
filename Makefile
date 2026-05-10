PRJ := $(patsubst vec-%,%,$(notdir $(CURDIR)))
SRCDIR=src
BUILDDIR=build
SRC=$(SRCDIR)/$(PRJ).asm
OUT=$(BUILDDIR)/$(PRJ).bin

ASM=lwasm

EMU_MAME=mame
EMU_RETROARCH=flatpak run org.libretro.RetroArch
CORE=$(HOME)/.var/app/org.libretro.RetroArch/config/retroarch/cores/vecx_libretro.so

GREEN=\033[1;32m
RESET=\033[0m

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

help: usage

usage:
	@printf "$(GREEN)Usage:$(RESET) make <target>\n"
	@printf "  $(GREEN)make all$(RESET)           Build the ROM binary\n"
	@printf "  $(GREEN)make run$(RESET)           Run with MAME (alias for run_mame)\n"
	@printf "  $(GREEN)make run_mame$(RESET)      Run with MAME\n"
	@printf "  $(GREEN)make run_retroarch$(RESET) Run with RetroArch\n"
	@printf "  $(GREEN)make clean$(RESET)         Remove build artifacts\n"

.PHONY: all run run_mame run_retroarch help usage clean

clean:
	rm -rf build