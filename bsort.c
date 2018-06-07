#include <stdint-gcc.h>
extern const int __debug_head;

volatile uint32_t *dbg = &__debug_head;

//For msort
int b[] = {7, 6, 4, 12, 2, 13, 1, 8, 11, 14, 0, 5, 9, 3, 10, 15};

int main() {
  const int n = sizeof(b)/sizeof(int);
  for (int i = 0; i < n-1; i++)
  for (int j = 0; j < n-i-1; j++) {
    if (b[j] <= b[j+1])
      continue;
    int t   = b[j];
    b[j]    = b[j+1];
    b[j+1]  = t;
  }

  for (int i = 0; i < 16; i++) {
    dbg[i] = b[i];
    //printf("%d \n", b[i]);
  }
}

