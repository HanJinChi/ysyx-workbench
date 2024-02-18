ENTRY(_start) /* 指定程序的入口点为_start */
PHDRS { text PT_LOAD; data PT_LOAD; bss PT_LOAD;}

MEMORY {
  flash : ORIGIN = 0x30000000, LENGTH = 256M
  sram  : ORIGIN = 0x0f000000, LENGTH = 8K
  psram : ORIGIN = 0x80000000, LENGTH = 4M
}

SECTIONS {
  . = ORIGIN(psram);
  _text_begin = .;
  .text : {
    *(entry)
    *(.text*)
    *(.rela*)
  } > psram AT> flash :text
  etext = .;
  _etext = .;
  .rodata : {
    *(.rodata*)
    *(.srodata*)
  } > psram AT > flash
  _text_end = _text_begin + SIZEOF(.text)+ SIZEOF(.rodata);
  _rom_data_begin = _text_end;
  .data : {
    _data_begin = .;
    *(.data*)
    *(.sdata*)
  } > psram AT> flash :data 
  edata = .;
  _data = .;
	_bss_start = .;
  .bss : {
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  } > psram AT> flash :bss
  _data_end = _bss_start + SIZEOF(.bss); 
}


SECTIONS{
  . = ORIGIN(psram)-ORIGIN(flash)+ORIGIN(psram);
  _psram_text_begin = .;
  . = . + (_text_end - _text_begin);

  _psram_data_begin = ORIGIN(psram)-ORIGIN(flash)+ _data_begin;
  . = . + (_data_end - _data_begin);
  _heap_start = ALIGN(0x1000);
  . = _heap_start + 0x200000;
  _stack_top = .;
  . = _stack_top + 0x100000;
  _stack_pointer = .;
  end = .;
  _end = .;
}
