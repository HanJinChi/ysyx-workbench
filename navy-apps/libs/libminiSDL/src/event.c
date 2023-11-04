#include <NDL.h>
#include <SDL.h>
#include <string.h>
#include <assert.h>
#include <stdlib.h>

#define keyname(k) #k,

static const char *keyname[] = {
  "NONE",
  _KEYS(keyname)
};

static uint8_t key_state[sizeof(keyname) / sizeof(keyname[0])] = {0};


int SDL_PushEvent(SDL_Event *ev) {
  assert(0);
  return 0;
}

static char key_buf[64], *key_action, *key_key;

#define _DEBUG_

static int inline read_keyinfo(uint8_t *type, uint8_t *sym){
  int ret = NDL_PollEvent(key_buf, sizeof(key_buf));
  if (!ret){
    return 0;
  }

  //deal with key_action
  char keys[100], typeo[5]; 
  int sym_sym;
  sscanf(key_buf, "Got kbd: %s (%d) %s\n", keys, &sym_sym, typeo);
  // printf("keys is %s, sym_sym is %d, type0 is %s\n", keys, sym_sym, typeo);
  *sym = (uint8_t)sym_sym;
  if(typeo[0] == 'U') *type = SDL_KEYUP;
  else                *type = SDL_KEYDOWN;

  return 1;
}

int SDL_PollEvent(SDL_Event *ev) {
  uint8_t type = 0, sym = 0;
  if (read_keyinfo(&type, &sym)){
    ev->type = type;
    ev->key.keysym.sym = sym;

    switch(type){
    case SDL_KEYDOWN:
      key_state[sym] = 1;
      break;
    
    case SDL_KEYUP:
      key_state[sym] = 0;
      break;
    }
  }
  else {
    return 0;
  }
  return 1;
}

int SDL_WaitEvent(SDL_Event *event) {
  uint8_t type = 0, sym = 0;
  while (!read_keyinfo(&type, &sym)){}
  
  event->type = type;
  event->key.keysym.sym = sym;

  switch(type){
    case SDL_KEYDOWN:
      key_state[sym] = 1;
      break;
    
    case SDL_KEYUP:
      key_state[sym] = 0;
      break;
  }
  return 1;
}

int SDL_PeepEvents(SDL_Event *ev, int numevents, int action, uint32_t mask) {
  assert(0);
  return 0;
}

uint8_t* SDL_GetKeyState(int *numkeys) {
  SDL_Event ev;

  if (numkeys)
    *numkeys = sizeof(key_state) / sizeof(key_state[0]);
  //SDL_PumpEvents();
  return key_state;
}