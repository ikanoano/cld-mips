    .text
start:
    .set noreorder
    .set noat
    nop
    nop
    addi $20, $0, 0
    addi $21, $0, 3
    add  $12, $0, $0   # sum = 0;

L03:addi $11, $0, 0
    addi $8,  $0, 4096
    addi $9,  $0, 0
    addi $10, $0, 0

L01:sw   $11, 0($10)
    addi $9,  $9, 1
    addi $11, $11,1
    addi $11, $11,1
    addi $11, $11,1
    addi $11, $11,1
    addi $10, $10,4
    bne  $8,  $9, L01
    nop

    addi $8,  $0, 4096
    addi $9,  $0, 0
    addi $10, $0, 0

L02:lw   $11, 0($10)
    addi $9,  $9, 1
    addi $10, $10,4
    add  $12, $12,$11  # sum += $11
    addi $12, $12,1    # sum ++;
    addi $12, $12,-1   # sum --;
    addi $12, $12,1    # sum ++;
    addi $12, $12,1    # sum ++;
    addi $12, $12,-1   # sum --;
    addi $12, $12,1    # sum ++;
    addi $12, $12,-2   # sum -= 2;
    bne  $8,  $9, L02
    nop

    addi $20, $20,1    # j++
    addi $8,  $8, 0x11 #
    addi $8,  $8, 0x12 #
    addi $8,  $8, 0x13 #
    addi $8,  $8, 0x14 #
    bne  $20, $21,L03  # (j<4) ?
    nop
    add  $30, $12,$0
    add  $0,  $30,$0   # 5ffa000
    nop                # halt
    nop
    nop
    nop
    nop
    nop
