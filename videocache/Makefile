all: clean ddbin

boot.bin: boot.s
	nasm boot.s -o boot.bin

ddbin: boot.bin
	dd if=boot.bin of=a.img bs=512 count=1 conv=notrunc

.PHONY: clean ddbin all
clean:
	@-rm -f *.bin
