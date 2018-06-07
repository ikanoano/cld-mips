#include <stdint-gcc.h>
#define WIDTH   40
#define HEIGHT  30
extern const int __debug_head;

volatile uint32_t *dbg = &__debug_head;

volatile uint32_t array[HEIGHT+2][WIDTH+2] = {{2,3}, {0,1}}; //image data
int main() {
  for (int32_t y=1; y!=HEIGHT+1; y++)
  for (int32_t x=1; x!= WIDTH+1; x++) {
    array[y][x] += y<<16 | x;
  }

  for (int32_t y=1; y!=HEIGHT+1; y++)
  for (int32_t x=1; x!= WIDTH+1; x++) {
    uint32_t sum =
      array[y-1][x-1] + array[y-1][x  ] + array[y-1][x+1] +
      array[y  ][x-1] +                   array[y  ][x  ] +
      array[y+1][x-1] + array[y+1][x  ] + array[y+1][x+1];
    sum += array[y][x] << 3;  // sum = array[y][x] * 8
    array[y][x] = sum >> 4;   // array[y][x] = sum / 16
  }

  for (int i = 0; i < 16; i++) {
    dbg[i] = 0;
  }

  dbg[0] = array[HEIGHT/8][WIDTH/8];
  dbg[1] = array[HEIGHT/4][WIDTH/4];
  dbg[2] = array[HEIGHT/2][WIDTH/4];
  dbg[3] = array[HEIGHT/4][WIDTH/2];
  //printf("%x, %x, %x, %x\n", a, b, c, d);
}
