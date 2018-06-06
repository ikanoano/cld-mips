#include <stdint-gcc.h>

volatile uint32_t *dbg = 0;
int main() {
  dbg[0] = 1;
  dbg[1] = 2;
  dbg[2] = 3;
  dbg[3] = 4;
}
