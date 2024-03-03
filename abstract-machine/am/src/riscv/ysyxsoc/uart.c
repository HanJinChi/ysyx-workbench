#include <am.h>
#include <klib-macros.h>
#include <ysyxsoc.h>

void __am_uart_rx(AM_UART_RX_T *rx){
    uint8_t uart_lsr = inb(SERIAL_BASE+SERIAL_LS);
    if(uart_lsr&0x1) // 代表有数据
        rx->data = inb(SERIAL_BASE);
    else
        rx->data = 0xff;
}