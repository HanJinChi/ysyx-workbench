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
  .text : ALIGN(8) { 
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
  .rodata : ALIGN(8) {
    *(.rodata*)
    *(.srodata*)
  } > sdram AT > flash :rodata

  . = etext+ SIZEOF(.rodata);
  _text_end = ALIGN(8);

  .data.extra : ALIGN(8){
    _data_begin = .;
    /* section information for finsh shell */
    __fsymtab_start = .;
    KEEP(*(FSymTab))
    __fsymtab_end = .;
    . = ALIGN(8);
    __vsymtab_start = .;
    KEEP(*(VSymTab))
    __vsymtab_end = .;
    . = ALIGN(8);

    /* section information for initial. */
    . = ALIGN(8);
    __rt_init_start = .;
    KEEP(*(SORT(.rti_fn*)))
    __rt_init_end = .;
    . = ALIGN(8);

    __rt_utest_tc_tab_start = .;
    KEEP(*(UtestTcTab))
    __rt_utest_tc_tab_end = .;

    . = ALIGN(8);
    __am_apps_data_start = .;
    *(__am_apps.data*)
    *(__am_apps.sdata*)
    __am_apps_data_end = .;
    . = ALIGN(8);
  } > sdram AT> flash :data 

  .data : ALIGN(8){
    *(.data*)
    *(.sdata*)
  } > sdram AT> flash :data 
  edata = ALIGN(8);
  _data = ALIGN(8);
	_bss_start = ALIGN(8);

  .bss.extra : {
    . = ALIGN(8);
    __am_apps_bss_start = .;
    *(__am_apps.bss*)
    *(__am_apps.sbss*)
    *(__am_apps.scommon*)
    __am_apps_bss_end = .;
    . = ALIGN(8);
  }  > sdram AT> flash :bss
  .bss : ALIGN(8){
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  } > sdram AT> flash :bss
  . = _bss_start + SIZEOF(.bss);
  _data_end = ALIGN(8);
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


