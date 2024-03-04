#include "trap.h"

int main(){

    while(true){
        uint8_t data = io_read(AM_INPUT_KEYBRD).keycode;
        if(data != 0) printf("%d", data);
    }
}