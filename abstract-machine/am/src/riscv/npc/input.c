#include <am.h>
#include "npc.h"

#define KEYDOWN_MASK 0x8000
void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
 uint32_t k = AM_KEY_NONE;

  k = *(volatile uint32_t *)(KBD_ADDR);
 
  kbd->keydown = (k & KEYDOWN_MASK ? true : false);
  kbd->keycode = k & ~KEYDOWN_MASK;
}

