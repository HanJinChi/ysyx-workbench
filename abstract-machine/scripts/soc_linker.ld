ENTRY(_start) /* 指定程序的入口点为_start */
PHDRS { text PT_LOAD; data PT_LOAD; bss PT_LOAD;}

MEMORY {
  mrom : ORIGIN = 0x20000000, LENGTH = 4K
  sram : ORIGIN = 0x0f000000, LENGTH = 8K
}

SECTIONS {
  . = ORIGIN(mrom);
  .text : {
    *(entry)
    *(.text*)
  } > mrom AT> mrom :text
  etext = .;
  _etext = .;
  .rodata : {
    *(.rodata*)
    *(.srodata*)
  } > mrom AT > mrom
  _rom_data_begin = .;
  .data : {
    _data_begin = .;
    *(.data*)
    *(.sdata*)
  } > sram AT> mrom :data 
  edata = .;
  _data = .;
	_bss_start = .;
  .bss : {
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  } > sram AT> mrom :bss
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
