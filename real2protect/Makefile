all: clean ddbin

init.bin: init.s
	nasm init.s -o init.bin

boot.bin: boot.s
	nasm boot.s -o boot.bin

ddbin: boot.bin init.bin
	dd if=boot.bin of=a.img bs=512 count=1
	dd if=init.bin of=a.img bs=512 count=6 seek=1 conv=notrunc

.PHONY: clean ddbin all

clean:
	@-rm -f *.bin
