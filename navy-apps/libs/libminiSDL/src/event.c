#include <NDL.h>
#include <SDL.h>
#include <string.h>
#include <assert.h>

#define keyname(k) #k,

static const char *keyname[] = {
  "NONE",
  _KEYS(keyname)
};

static uint8_t keystate[sizeof(keyname) / sizeof(char *)];

int SDL_PushEvent(SDL_Event *ev) {
  assert(0);
  return 0;
}

int SDL_PollEvent(SDL_Event *ev) {
  int len = 64;
  char buf[len];
  while (NDL_PollEvent(buf, len) == 0)
  {
    return 0;
  }

  char ndl_keydown[4];
  char ndl_keyname[16];

  sscanf(buf, "%s %s\n", ndl_keydown, ndl_keyname);

  if (strcmp(ndl_keydown, "kd") == 0)
  {
    ev->type = SDL_KEYDOWN;
  }
  else
  {
    ev->type = SDL_KEYUP;
  }

  for (int i = 0; i < sizeof(keyname) / sizeof(char *); i++)
  {
    if (strcmp(ndl_keyname, keyname[i]) == 0)
    {
      ev->key.keysym.sym = i;
      keystate[i] = ev->type == SDL_KEYDOWN ? 1 : 0;
      return 1;
    }
  }
  return 0;
}

int SDL_WaitEvent(SDL_Event *event) {
  int len = 64;
  char buf[len];
  while (NDL_PollEvent(buf, len) == 0);

  char ndl_keydown[4];
  char ndl_keyname[16];

  sscanf(buf, "%s %s\n", ndl_keydown, ndl_keyname);

  if (strcmp(ndl_keydown, "kd") == 0)
  {
    event->type = SDL_KEYDOWN;
  }
  else
  {
    event->type = SDL_KEYUP;
  }

  for (int i = 0; i < sizeof(keyname) / sizeof(char *); i++)
  {
    if (strcmp(ndl_keyname, keyname[i]) == 0)
    {
      event->key.keysym.sym = i;
      keystate[i] = ( event->type == SDL_KEYDOWN );
      return 1;
    }
  }

  return 0;
}

int SDL_PeepEvents(SDL_Event *ev, int numevents, int action, uint32_t mask) {
  assert(0);
  return 0;
}

uint8_t* SDL_GetKeyState(int *numkeys) {
  if (numkeys != NULL)
    {
        *numkeys = sizeof(keyname) / sizeof(char *);
    }
  return keystate;
}
