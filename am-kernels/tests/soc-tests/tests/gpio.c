#include "trap.h"

int main(){

    while(true){
        uint8_t data = io_read(AM_UART_RX).data;
        if(data != 0xff) printf("%c", data);
    }
}