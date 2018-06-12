OUTPUT_FORMAT(elf32_i386)
OUTPUT_ARCH(i386)

SECTIONS {
	.text 0x0000 : {
		*(.text)
	}

	/DISCARD/ : {
	

	}
}
