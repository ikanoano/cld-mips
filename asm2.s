    .text
start:
    .set    noreorder
    .set    noat
                              #   int* A = (int*)0
    add     $8,   $0,   $0    #   i = 0
    addi    $9,   $0,   8192  #   end = 8192
L1: add     $24,  $8,   $8    #   p = i + i
    add     $24,  $24,  $24   #   p = p + p
    sw      $8,   0($24)      #   A[p] = i
    addi    $8,   $8,   1     #   i += 1
    bne     $8,   $9,   L1    #   if(i!=end) goto L1
    add     $0,   $0,   $0    #   nop
    addi    $8,   $0,   1     #   i = 1
    addi    $9,   $0,   8191  #   end = 8191
L2: add     $24,  $8,   $8    #   p = i + i
    add     $24,  $24,  $24   #   p = p + p
    lw      $10,  -4($24)     #   tmp1 = A[p-4]
    lw      $11,  0($24)      #   tmp2 = A[p]
    lw      $12,  4($24)      #   tmp3 = A[p+4]
    add     $10,  $10,  $11   #   tmp1 += tmp2
    add     $10,  $10,  $12   #   tmp1 += tmp3
    sw      $10,  0($24)      #   A[p] = tmp1
    addi    $8,   $8,   1     #   i += 1
    bne     $8,   $9,   L2    #   if(i!=end) goto L2
    add     $2,   $0,   $0    #   return 0
    nop                       #   halt
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
