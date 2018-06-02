  .text
main:
  .set  noreorder
  .set  nomacro
  li    $4, 8192      # max = 8192
  move  $2, $0        # i = 0
  move  $3, $0        # p = 0
L2:
  sw    $2, 0($3)     # *p = i
  addi  $2, $2,   1   # i += 1
  addi  $3, $3,   4   # p +=4
  bne   $2, $4,   L2  # goto L2 if i != max

  li    $9, 4         # j = 4
  addi  $8, $0,   32752#pmax = 8188*4
L3:
  move  $2, $0        # p = 0
L4:
  lw    $5, 0($2)     # a = *p
  lw    $4, 4($2)     # b = *(p+1)
  lw    $7, 8($2)     # c = *(p+2)
  addu  $4, $5,   $4  # b = a + b
  lw    $3, 12($2)    # d = *(p+3)
  addu  $4, $4,   $7  # b = b + c
  lw    $5, 16($2)    # e = *(p+4)
  addu  $3, $4,   $3  # d = b + d
  addu  $3, $3,   $5  # d = d + e
  sw    $3, 8($2)     # *(p+2) = d
  lw    $4, 8($2)     # f = *(p+2)
  lw    $3, 0($0)     # g = *0
  addiu $2, $2,   4   # p += 1
  addu  $3, $3,   $4  # g = g + f
  sw    $3, 0($0)     # *0 = g
  bne   $8, $2,   L4  # goto L4 if p != pmax
  nop

  addiu $9, $9,   -1  # j -= 1
  bne   $9, $0,   L3  # goto L3 if j != 0
  move  $2, $0        # return 0

  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop

