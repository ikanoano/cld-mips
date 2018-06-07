#include <stdint-gcc.h>
extern const int __debug_head;

volatile uint32_t *dbg = &__debug_head;
int main() {
  dbg[0] = 1;
  dbg[1] = 2;
  dbg[2] = 3;
  dbg[3] = 4;
}
