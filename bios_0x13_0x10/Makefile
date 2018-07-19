all: clean ddbin

init.bin: init.s
	nasm init.s -o init.bin

bootsect.bin: bootsect.s
	nasm bootsect.s -o bootsect.bin

ddbin: bootsect.bin init.bin
	dd if=bootsect.bin of=a.img bs=512 count=1
	dd if=init.bin of=a.img bs=512 count=3 seek=1 conv=notrunc

.PHONY: clean ddbin all
clean:
	@-rm -f *.bin

