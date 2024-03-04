#include <am.h>
#include <ysyxsoc.h>


static uint8_t key_tableA[] = \
  {0,               AM_KEY_F9,     0,                 AM_KEY_F5,           AM_KEY_F3,          AM_KEY_F1,     AM_KEY_F2,        AM_KEY_F12, \
   0,               AM_KEY_F10,    AM_KEY_F8,         AM_KEY_F6,           AM_KEY_F4,          AM_KEY_TAB,    AM_KEY_GRAVE,     0, \
   0,               AM_KEY_LALT,   AM_KEY_LSHIFT,     0,                   AM_KEY_LCTRL,       AM_KEY_Q,      AM_KEY_1,         0, \
   0,               0,             AM_KEY_Z,          AM_KEY_S,            AM_KEY_A,           AM_KEY_W,      AM_KEY_2,         0, \
   0,               AM_KEY_C,      AM_KEY_X,          AM_KEY_D,            AM_KEY_E,           AM_KEY_4,      AM_KEY_3,         0, \
   0,               AM_KEY_SPACE,  AM_KEY_A,          AM_KEY_V,            AM_KEY_T,           AM_KEY_R,      AM_KEY_5,         0, \
   0,               AM_KEY_N,      AM_KEY_B,          AM_KEY_H,            AM_KEY_G,           AM_KEY_Y,      AM_KEY_6,         0, \
   0,               0,             AM_KEY_M,          AM_KEY_J,            AM_KEY_U,           AM_KEY_7,      AM_KEY_8,         0, \
   0,               AM_KEY_COMMA,  AM_KEY_K,          AM_KEY_I,            AM_KEY_O,           AM_KEY_0,      AM_KEY_9,         0, \
   0,               AM_KEY_PERIOD, AM_KEY_SLASH,      AM_KEY_L,            AM_KEY_SEMICOLON,   AM_KEY_P,      AM_KEY_MINUS,     0, \
   0,               0,             AM_KEY_APOSTROPHE, 0,                   AM_KEY_LEFTBRACKET, AM_KEY_EQUALS, 0,                0, \
   AM_KEY_CAPSLOCK, AM_KEY_RSHIFT, AM_KEY_RETURN,     AM_KEY_RIGHTBRACKET, 0,                  0,             0,                0, \
   0,               0,             0,                 0,                   0,                  0,             AM_KEY_BACKSPACE, 0, \
   0,               AM_KEY_1,      0,                 AM_KEY_4,            AM_KEY_7,           0,             0,                0, \
   AM_KEY_0,        AM_KEY_PERIOD, AM_KEY_2,          AM_KEY_5,            AM_KEY_6,           AM_KEY_8,      AM_KEY_NONE,      AM_KEY_NONE, \
   AM_KEY_F11,      AM_KEY_EQUALS, AM_KEY_3,          AM_KEY_MINUS,        AM_KEY_NONE,        AM_KEY_9,      AM_KEY_NONE,      AM_KEY_NONE, \
   AM_KEY_NONE,     AM_KEY_NONE,   AM_KEY_NONE,       AM_KEY_F7 \       
  };
static uint8_t key_tableB[0x7a] = {0};

void __am_keybrd_init(){
  key_tableB[0x11] = AM_KEY_RALT;
  key_tableB[0x14] = AM_KEY_RCTRL;
  key_tableB[0x5a] = AM_KEY_RETURN;
  key_tableB[0x4A] = AM_KEY_SLASH;
  key_tableB[0x70] = AM_KEY_INSERT;
  key_tableB[0x6c] = AM_KEY_HOME;
  key_tableB[0x7d] = AM_KEY_PAGEUP;
  key_tableB[0x71] = AM_KEY_DELETE;
  key_tableB[0x69] = AM_KEY_END;
  key_tableB[0x7A] = AM_KEY_PAGEDOWN;
  key_tableB[0x75] = AM_KEY_UP;
  key_tableB[0x6B] = AM_KEY_LEFT;
  key_tableB[0x72] = AM_KEY_DOWN;
  key_tableB[0x74] = AM_KEY_RIGHT;
} 

void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
  bool is_keydown = true;
  uint8_t scancode = inb(KBD_ADDR);
  uint8_t am_scancode;
  if(scancode == 0xF0) {
    is_keydown = false;
    scancode = inb(KBD_ADDR);
  }
  if(scancode == 0xE0){
    scancode = inb(KBD_ADDR);
    am_scancode = key_tableB[scancode];
  }else{
    am_scancode = key_tableA[scancode];
  }
  kbd->keydown = is_keydown;
  kbd->keycode = am_scancode;
}