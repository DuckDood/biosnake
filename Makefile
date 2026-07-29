all: assemble

assemble: boot.asm
	nasm -fbin boot.asm -o boot.bin

clean:
	rm boot.bin
.PHONY: clean
