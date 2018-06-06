#include <stdint-gcc.h>
#define WIDTH   40
#define HEIGHT  30

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

  register int a, b, c, d;
  a = array[HEIGHT/4][WIDTH/4];
  b = array[HEIGHT/2][WIDTH/2];
  c = array[HEIGHT  ][WIDTH/2];
  d = array[HEIGHT/2][WIDTH  ];
  //printf("%x, %x, %x, %x\n", a, b, c, d);
}
