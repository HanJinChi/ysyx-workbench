ENTRY(_start) /* 指定程序的入口点为_start */
PHDRS { text PT_LOAD; rodata PT_LOAD;  data PT_LOAD; bss PT_LOAD;}
MEMORY {
  flash : ORIGIN = 0x30000000, LENGTH = 256M
  sram  : ORIGIN = 0x0f000000, LENGTH = 8K
  psram : ORIGIN = 0x80000000, LENGTH = 4M
  sdram : ORIGIN = 0xa0000000, LENGTH = 4M
}



SECTIONS {
  . = ORIGIN(sdram);
  .text : {
    _text_begin = .;
    *(entry)
    *(.text*)
    *(.rela*)
    _boot_begin = .;
    *(boot)
    _boot_end = .;
  } > sdram AT> flash :text
  etext = .;
  _etext = .;
  .rodata : {
    *(.rodata*)
    *(.srodata*)
  } > sdram AT > flash :rodata
  _text_end = etext+ SIZEOF(.rodata);
  _rom_data_begin = _text_end;
  .data : {
    _data_begin = .;
    *(.data*)
    *(.sdata*)
  } > sdram AT> flash :data 
  edata = .;
  _data = .;
	_bss_start = .;
  .bss : {
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  } > sdram AT> flash :bss
  _data_end = _bss_start + SIZEOF(.bss); 
}

SECTIONS{
  . = ORIGIN(sdram)-ORIGIN(flash)+ORIGIN(sdram);
  . = . + (_text_end - _text_begin);
  . = . + (_data_end - _data_begin);
  _heap_start = ALIGN(0x1000);
  . = _heap_start + 0x200000;
  _stack_top = .;
  . = _stack_top + 0x100000;
  _stack_pointer = .;
  end = .;
  _end = .;
}
