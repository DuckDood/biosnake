all: build/ build/boot.bin

build/:
	mkdir build/

build/boot.bin: src/boot.asm src/graphics.asm
	nasm -fbin src/boot.asm -o build/boot.bin

clean:
	rm -r build/
.PHONY: clean
