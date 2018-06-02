    .text
start:
    .set    noreorder
    .set    noat
    addi    $7,   $0,   101 #   end = 101
    addi    $8,   $0,   0   #   sum = 0
    add     $9,   $0,   $0  #   i   = 0
L:  add     $8,   $8,   $9  #L: sum += i
    addi    $9,   $9,   1   #   i++
    bne     $9,   $7,   L   #   if(i!=end) goto L
    addi    $2,   $8,   0   #   return sum
    nop                     #   halt
    nop
    nop
    nop
    nop
    nop
