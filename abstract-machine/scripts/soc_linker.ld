ENTRY(_start) /* 指定程序的入口点为_start */
PHDRS { text PT_LOAD; data PT_LOAD; bss PT_LOAD;}

MEMORY {
  flash : ORIGIN = 0x30000000, LENGTH = 256M
  sram  : ORIGIN = 0x0f000000, LENGTH = 8K
}

SECTIONS {
  . = ORIGIN(flash);
  .text : {
    *(entry)
    *(.text*)
  } > flash AT> flash :text
  etext = .;
  _etext = .;
  .rodata : {
    *(.rodata*)
    *(.srodata*)
  } > flash AT > flash
  _rom_data_begin = .;
  .data : {
    _data_begin = .;
    *(.data*)
    *(.sdata*)
  } > sram AT> flash :data 
  edata = .;
  _data = .;
	_bss_start = .;
  .bss : {
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  } > sram AT> flash :bss
  _data_end = _bss_start + SIZEOF(.bss); 
}


SECTIONS{
  . = ORIGIN(sram);
  _sram_data_begin = .;
  . = . + (_data_end - _data_begin);
  _heap_start = .;
  . = _heap_start + 0x500;
  _stack_top = .;
  . = _stack_top + 0x1000;
  _stack_pointer = .;
  end = .;
  _end = .;
}
