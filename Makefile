all: Image

.PHONY=clean run -qemu

bootsect.o:
	@as --32 bootsect.S -o bootsect.o

run-qemu: bootsect
	@qemu-system-i386 -boot a -fda bootsect

bootsect: bootsect.o ld-bootsect.ld
	@ld -melf_i386 -t ld-bootsect.ld bootsect.o -o bootsect
	@objcopy -O binary -j .text bootsect
clean:
	@rm -f *.o
