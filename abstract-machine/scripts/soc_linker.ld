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
  .text : ALIGN(0x4) { 
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
  .rodata : ALIGN(0x4) {
    *(.rodata*)
    *(.srodata*)
  } > sdram AT > flash :rodata

  . = etext+ SIZEOF(.rodata);
  _text_end = ALIGN(0x4);
  _rom_data_begin = _text_end;
  .data : ALIGN(0x4){
    _data_begin = .;
    *(.data*)
    *(.sdata*)
  } > sdram AT> flash :data 
  edata = ALIGN(0x4);
  _data = ALIGN(0x4);
	_bss_start = ALIGN(0x4);
  .bss : ALIGN(0x4){
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  } > sdram AT> flash :bss
  . = _bss_start + SIZEOF(.bss);
  _data_end = ALIGN(0x4);
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
