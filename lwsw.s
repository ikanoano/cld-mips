    .text
start:
    .set    noreorder
    .set    noat
                              #   int* A = (int*)0
    addi    $8,   $0,   4     #   i = 4
    sw      $8,   0($8)       #   A[i] = i
    addi    $8,   $8,   4     #   i += 4
    sw      $8,   0($8)       #   A[i] = i
    nop
    nop
    nop
    lw      $11,  0($8)
    nop
    addi    $8,   $8,   -4    #   i -= 4
    lw      $12,  0($8)
    nop
    nop
    nop
    nop                       #   halt
    nop
    nop
    nop
    nop
