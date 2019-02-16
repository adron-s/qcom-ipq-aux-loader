OUTPUT_ARCH(arm)
SECTIONS {
	.text : {
		*(.text)
		*(.text.*)
		*(.data)
		*(.data.*)
	}
	. = ALIGN(32);
	_bss_start = .;
	.bss : {
		*(.bss)
		*(.bss.*)
	}
	. = ALIGN(32);
	_bss_end = .;
}
