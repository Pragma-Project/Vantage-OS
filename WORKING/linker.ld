/* linker.ld - x86_64 higher-half kernel linker script for nimos */

OUTPUT_FORMAT(elf64-x86-64)
OUTPUT_ARCH(i386:x86-64)
ENTRY(_start)

/* Higher-half kernel base address */
KERNEL_BASE = 0xFFFFFFFF80000000;

PHDRS
{
    text PT_LOAD FLAGS(5);  /* RX - readable + executable */
    data PT_LOAD FLAGS(6);  /* RW - readable + writable */
}

SECTIONS
{
    /* Start at higher-half + 2MB */
    . = KERNEL_BASE + 0x200000;

    .text ALIGN(4K) : {
        *(.text*)
    } :text

    /* Limine request structures - must be in PT_LOAD segment */
    .requests ALIGN(16) : {
        KEEP(*(.requests))
    } :text

    .rodata ALIGN(4K) : {
        *(.rodata*)
    } :text

    .data ALIGN(4K) : {
        *(.data*)

        /* Embedded logo binary data */
        _binary_logo_bin_start = .;
        *(.logo)
        _binary_logo_bin_end = .;
    } :data

    .bss ALIGN(4K) : {
        *(COMMON)
        *(.bss*)
    } :data

    /* Discard unneeded sections */
    /DISCARD/ : {
        *(.note*)
        *(.comment*)
        *(.eh_frame*)
    }
}
