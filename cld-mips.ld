ENTRY(_start)

MEMORY {
  IMEM (x)  : ORIGIN = 0x00000000, LENGTH = 16K
  DMEM (rw) : ORIGIN = 0x10000000, LENGTH = 16K
}

SECTIONS {
  . = 0x00000000;
  .startup    : { . = ALIGN(4); startup.o(.text) } > IMEM
  .init       : { . = ALIGN(4); KEEP (*(.init)) } > IMEM
  .text       : { . = ALIGN(4); *(.text)
                  . = ALIGN(4); *(.text*)} > IMEM

  . = 0x10000000;
  .simdebug   : { __debug_head = .; . = . + 0x40; } > DMEM
  .rodata     : { . = ALIGN(4); *(.rodata) } > DMEM
  .data       : { . = ALIGN(4); *(.data) } > DMEM
  .bss        : { . = ALIGN(4); *(.bss) } > DMEM
}
