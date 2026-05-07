SRC=src/main.asm
OUT=build/main.bin

ASM=lwasm

EMU_MAME=mame
 EMU_RETROARCH=flatpak run org.libretro.RetroArch
CORE=$(HOME)/.var/app/org.libretro.RetroArch/config/retroarch/cores/vecx_libretro.so


all: $(OUT)

$(OUT): $(SRC)
	mkdir -p build
	$(ASM) -f raw -o $(OUT) $(SRC)

run: $(OUT)
ifeq ($(EMULATOR),retroarch)
	$(EMU_RETROARCH) -L $(CORE) $(OUT)
else
	$(EMU_MAME) vectrex \
	-window        \
	-nomax         \
	-keepaspect    \
	-prescale 2    \
	-skip_gameinfo \
	-flicker 0.2   \
	-speed 1.0     \
	-cart $(OUT)
endif

clean:
	rm -rf build