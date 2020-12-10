ENTRY(start)
SECTIONS
{
    /* Create a read-only sections, eg, for ROM */
    . = 0xBFC00000;
    .text : { *(.entry_section) }
    .text : { *(.text) }
    .text : { *(.text.startup) }
    .text : { *(.rodata) }
    .text : { *(.rodata.*) }

    /* Create a read-write section, eg for RAM */
    . = 0x00000000;
    .data : { *(.data) }
    .bss : { *(.bss) }
}