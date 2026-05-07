ASM=lwasm
EMU=mame

SRC=src/main.asm
OUT=build/main.bin

all: $(OUT)

$(OUT): $(SRC)
	mkdir -p build
	$(ASM) -f raw -o $(OUT) $(SRC)

run: $(OUT)
	$(EMU) vectrex \
	-window        \
	-nomax         \
	-keepaspect    \
	-prescale 2    \
	-skip_gameinfo \
	-flicker 0.2 \
	-cart $(OUT)

clean:
	rm -rf build