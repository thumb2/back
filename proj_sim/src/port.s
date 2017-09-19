    defword "report", 0xf1c6ac06, , report    
    pushpsp top    
    ldr r2, =var_cfunc_table
    ldr r2, [r2]             
    ldr r2, [r2, #0]    
    blx r2                      @ Save the caller's link, do not use bx
    cmp top, #0
    bne report_not_ready
    poppsp r1
report_not_ready:
    exit
    .ltorg


    defword "report1", 0xb8aa3507, , report1
    pushpsp top    
    ldr r1, =uart_flag_reg
    ldr r1, [r1]
    ldr r1, [r1]    
    movs r2, #0x40
    ands r1, r1, r2
    bne report_ready
    movs top, #1
    exit
report_ready:
    poppsp r1    
    ldr r1, =uart_tx_reg
    ldr r1, [r1]    
    str top, [r1]
    subs top, top, top          @ Move 0 to top
    exit
    .align 2
uart_flag_reg:
    .int 0x40008014
uart_tx_reg:    
    .int 0x40008000
