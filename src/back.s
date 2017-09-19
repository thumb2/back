    .syntax unified
    .arch armv6-m

    .section .return_stack
    .equ return_stack_size, 0x200
    .globl __return_stack_top
    .globl __return_stack_limit
__return_stack_limit:
    .space return_stack_size
    .size  __return_stack_limit, . - __return_stack_limit
__return_stack_top:
    .size  __return_stack_top, . - __return_stack_top
    
    .section .param_stack
    .equ param_stack_size, 0x200
    .globl __param_stack_top
    .globl __param_stack_limit
__param_stack_limit:
    .space param_stack_size
    .size  __param_stack_limit, . - __param_stack_limit
__param_stack_top:
    .size  __param_stack_top, . - __param_stack_top

    .section .back_heap
saved_caller_sp:
    .int 0
saved_callee_sp:
    .int __return_stack_top
saved_psp:
    .int __param_stack_top
var_state:
    .int 0
var_latest:
    .int 0
var_here:
    .int 0
var_link:
    .int 0
var_inp:
    .int 0
var_outp:
    .int 0
var_saved_here:
    .int 0
var_saved_link:
    .int 0
var_saved_inp:
    .int 0
var_saved_outp:
    .int 0
var_cfunc_table:
    .int 0

	.macro next
    bx lr   
	.endm
    
	.macro exit
    poprsp pc
	.endm

	.macro	docol
	pushrsp	lr
	.endm
	
 	.macro pushrsp reg
	push {\reg}
	.endm

	.macro poprsp reg
	pop {\reg}
	.endm
	
	.macro pushpsp reg
	stm	psp!, {\reg}
	.endm
	
	.macro poppsp reg
    subs psp, psp, #4
	ldr	\reg, [psp]
	.endm
    
	.set F_IMMED, 0x80000000
    
	.global test
	.global _fini
_fini:  

	top	.req	r0
	rsp	.req	sp
	psp	.req	r7

    .set thumb_code_flag_bit, 1
    .ifdef FOR_SIMULATION
    .set code_offset_ram_to_flash, (0x20004000 - 0x22000)
    .else
    .set code_offset_ram_to_flash, (0x20004000 - 0x28000)
    .endif
	.section .dict_field,"a",%progbits
    .thumb
    .thumb_func
    .long back_setup + thumb_code_flag_bit
    .long back_loop + thumb_code_flag_bit
    .globl back_setup
back_setup:
    @@ Save callee-save registers
    push {r4-r7, lr}
    @@ Save api func table
    ldr r2, =var_cfunc_table
    str r0, [r2]
    @@ Copy code from flash to ram
    ldr    r2, =__code_start__
    ldr    r3, =__ram_start__
    ldr    r4, =__code_end__
    subs    r4, r2
    ble     flash_to_ram_loop_end
    movs    r5, 0
flash_to_ram_loop:
    ldr    r1, [r2,r5]
    str    r1, [r3,r5]
    adds   r5, 4
    cmp    r5, r4
    blt    flash_to_ram_loop
flash_to_ram_loop_end:
    @@ Init the var containing return stack point
    ldr r1, =__return_stack_top
    ldr r2, =saved_callee_sp
    str r1, [r2]
    @@ Init the var containing return stack point
    ldr r1, =__param_stack_top
    ldr r2, =saved_psp
    str r1, [r2]
    @@ Save caller sp
    ldr r2, =saved_caller_sp
    mov r1, sp
    str r1, [r2]
    @@ Restore callee sp
    ldr r2, =saved_callee_sp
    ldr r1, [r2]
    mov sp, r1
    @@ Restore callee psp
    ldr r2, =saved_psp
    ldr r1, [r2]
    mov psp, r1
    @@ Init here point
    ldr r1, =var_here
    ldr r2, =__code_end__
    ldr r5, =init_code_offset
    ldr r5, [r5]
    adds r2, r2, r5
    str r2, [r1]
    @@ Init inp
    ldr r1, =var_inp
    ldr r2, =forth_file
    str r2, [r1]
    @@ Init inp
    ldr r1, =var_latest
    ldr r2, =latest_link_addr
    ldr r2, [r2]
    str r2, [r1]
    @@ Init state
    ldr r1, =var_state
    movs r2, #0
    str r2, [r1]
    @@ Jump to ram code area
    adds r3, r3, #1
    blx r3
    ldr r1, =loop_hash_const
    ldr top, [r1]
    ldr r1, =var_latest
    movs r3, #0
setup_is_not_the_word:   
    ldr r1, [r1]
    @@ If the (link == 0), not found
    cmp r1, r3
    beq setup_not_found
    adds r2, r1, #4
    ldr r2, [r2]
    cmp r2, top
    bne setup_is_not_the_word
    @@ poppsp top 
setup_not_found: 
    movs top, r1
    ldr r1, [top, #12]
    adds r1, r1, #3
    mov lr, r1
    push {r0-r7, lr}    
    @@ Save callee sp
    ldr r2, =saved_callee_sp
    mov r1, sp
    str r1, [r2]
    @@ Restore caller sp
    ldr r2, =saved_caller_sp
    ldr r1, [r2]
    mov sp, r1
    @@ Return
    pop {r4-r7, pc}
    .align 2
init_code_offset:
    .int code_offset_ram_to_flash
    .ltorg
loop_hash_const:
    .int 0x96078804
    .ltorg
    
back_loop:
    push {r4-r7, lr}    
    @@ Save caller sp
    ldr r2, =saved_caller_sp
    mov r1, sp
    str r1, [r2]
    @@ Restore callee sp
    ldr r2, =saved_callee_sp
    ldr r1, [r2]
    mov sp, r1
    @@ Restore all registers
    pop {r0-r7, pc}    
    .ltorg
    
	.set link, 0
	.macro defcode name, hash, flags=0, label
	.section .dict_field,"a",%progbits
	.align 2
	.globl name_\label
	link_\label:
	.int link
	.set link, link_\label
	.int \hash
	.int name_\label + \flags
	.int code_\label + code_offset_ram_to_flash    
	name_\label:
	.ascii "\name"
	.section .code_field,"ax",%progbits
    .ltorg
	.globl code_\label
    code_\label:
	.endm

	.macro defword name, hash, flags=0, label
	.section .dict_field,"a",%progbits
	.align 2
	.globl name_\label
	link_\label:
	.int link
	.set link, link_\label
	.int \hash
	.int name_\label + \flags
	.int code_\label + code_offset_ram_to_flash    
	name_\label:
	.ascii "\name"
	.section .code_field,"ax",%progbits
    .ltorg
	.globl code_\label
    code_\label:
	docol            
	.endm
    
	defword "init", 0x2ed8a004, 0, init
main_loop:
    bl code_interpret
    cmp r1, #0
    beq main_loop               @If neither error, nor end of buffer
    bl code_exit


	defcode "exit", 0xa8408e04, 0, exit
    poprsp pc

    @@ (a b -- a+b )
    defcode "+", 0x00002b01, 0, plus
    poppsp r1
    adds top, top, r1
    next

    @@ (a b -- a-b )
    defcode "-", 0x00002d01, 0, minus
    poppsp r1
    adds top, r1, top
    next

    @@ (a b -- a==b? )
    defcode "=", 0x00003d01, 0, equal
    poppsp r1
    cmp r1, top
    beq equal_equal
    movs top, #0    
    next    
equal_equal:
    movs top, #0        
    mvns top, top
    next

    @@ (a -- a+1 )
    defcode "1+", 0x00193e02, 0, one_plus
    adds top, top, #1
    next

    @@ (a -- a-1 )
    defcode "1-", 0x00194002, 0, one_minus
    subs top, top, #1
    next

    @@ (a b -- a&b )
    defcode "and", 0x199f1703, 0, and
    poppsp r1    
    ands top, top, r1
    next

    @@ (a -- not a )
    defcode "not", 0x1d071f03, 0, not
    cmp top, #0
    beq not_equal
    movs top, #0
    next    
not_equal:
    mvns top, top
    next

    @@ (32b addr -- )   *addr = 32b
    defcode "!", 0x00002101, 0, store
    poppsp r1
    strh r1, [top]
    lsrs r1, #16
    strh r1, [top, #2]    
    poppsp top
    next
    
    @@ (addr -- 32b)    top = *addr 
    defcode "@", 0x00004001, 0, fetch
    ldrh r1, [top, #2]
    lsls r1, #16
    ldrh r2, [top]
    adds top, r1, r2
    next

    @@ (16b addr -- )   *addr = 16b
    defcode "h!", 0x00355902, 0, half_store
    poppsp r1
    strh r1, [top]
    poppsp top
    next
    
    @@ (addr -- 16b)    top = *addr 
    defcode "h@", 0x00357802, 0, half_fetch
    ldrh top, [top]
    next

    @@ (8b addr -- )   *addr = 8b
    defcode "c!", 0x0032ca02, 0, byte_store
    poppsp r1
    strb r1, [top]
    poppsp top
    next
    
    @@ (addr -- 8b)    top = *addr 
    defcode "c@", 0x0032e902, 0, byte_fetch
    ldrb top, [top]
    next

    @@ TBD
    defcode "allot", 0x47532205, 0, allot
    next
    
    @@ ( -- 32b) top = *here
    defcode "here", 0x0a344004, 0, here
    pushpsp top
    ldr r1, =var_here
    ldr top, [r1]
    next

    @@ ( -- 32b) top = *state
    defcode "state", 0x4db2c905, 0, state
    pushpsp top
    ldr r1, =var_state
    ldr top, [r1]
    next

    @@ ( -- 32b) top = inp
    defcode "inp", 0x1bb76b03, 0, inp
    pushpsp top
    ldr top, =var_inp
    next

    @@ ( a b -- a ) drop
    defcode "drop", 0x8463cb04, 0, drop
    poppsp top
    next

    @@ ( a b -- b a) swap
    defcode "swap", 0x8837e304, 0, swap
    poppsp r1
    pushpsp top
    movs top, r1
    next

    @@ ( a -- a a) dup
    defcode "dup", 0x1a6bd303, 0, dup
    pushpsp top
    next

    @@ (32b -- ) *here = 32b, here += 4
    defcode ",", 0x00002c01, 0, comma
    ldr r1, =var_here
    ldr r2, [r1]
    strh top, [r2]
    lsrs top, #16
    strh top, [r2, #2]    
    poppsp top
    adds r2, #4
    str r2, [r1]
    next

    @@ (16b -- ) *here = 16b, here += 16
    defcode "h,", 0x00356402, 0, half_comma
    ldr r1, =var_here
    ldr r2, [r1]
    strh top, [r2]
    poppsp top
    adds r2, #2
    str r2, [r1]
    next

    @@ ( -- 16b ) Fetch the caller's following 16
    defcode "half_lit", 0x20d4fb08, 0, half_lit
    pushpsp top
    mov r1, lr
    subs r1, r1, #1
    ldrh top, [r1]
    adds r1, r1, #3
    mov lr, r1
    next


    @@ ( -- 32b ) Fetch the caller's following 32
    defcode "lit", 0x1c7dfb03, 0, lit
    pushpsp top
    mov r1, lr
    subs r1, r1, #1
    ldrh top, [r1]
    ldrh r2, [r1, #2]
    lsls r2, #16                @Little endian
    adds top, top, r2 
    adds r1, r1, #5
    mov lr, r1
    next

    defword "ascii", 0x3513f105, F_IMMED, ascii
    @@ Load a char from input buffer
    ldr r3, =var_inp
    ldr r1, [r3]    
ascii_skip_leading_blank:  
    ldrb r2, [r1]
    cmp r2, $' '
    bhi ascii_not_leading_blank
    adds r1, r1, #1
    b ascii_skip_leading_blank
ascii_not_leading_blank: 
    adds r1, r1, #1   
    str r1, [r3]
    ldr r1, =var_state
    ldr r1, [r1]
    pushpsp top
    movs top, r2
    cmp r1, 0
    beq ascii_in_compiling_state
    exit
ascii_in_compiling_state:
    bl code_compile
    bl code_half_lit
    bl code_half_comma
    exit

    @@ ( -- nfa hash) when input buffer is not empty or 
    @@ ( -- 0 ) otherwise
    defword "word", 0x0f5eae04, 0, word
    @@ Load a char from input buffer
    ldr r1, =var_inp
    ldr r1, [r1]    
word_skip_leading_blank:  
    ldrb r2, [r1]
    cmp r2, #0
    beq word_input_buffer_end
    cmp r2, $' '
    bhi word_not_leading_blank
    adds r1, r1, #1
    b word_skip_leading_blank
word_not_leading_blank:
    @@ Push NFA address
    pushpsp top
    pushpsp r1
    movs    top, r1
    movs    r3, 0
    movs    r4, #131
word_more_char:  
    @@ Calculate hash and len
    muls r3, r4, r3
    adds r3, r3, r2
    adds r1, r1, #1        
    ldrb r2, [r1]
    cmp r2, $' '
    bhi word_more_char
    lsls r3, r3, #8
    subs top, r1, top
    adds top, top, r3
    ldr r2, =var_inp
    str r1, [r2]
    exit
word_input_buffer_end:  
    @@ Push 0 onto the param stack
    pushpsp top
    movs top, 0
    exit

    @@ ( nfa hash -- lnk / nfa 0 ) Find a word in dict list, lnk = 0 if not found
    defword "find", 0xc6a32104, 0, find
    ldr r1, =var_latest
    movs r3, #0
find_is_not_the_word:   
    ldr r1, [r1]
    @@ If the (link == 0), not found
    cmp r1, r3
    beq find_not_found
    adds r2, r1, #4
    ldr r2, [r2]
    cmp r2, top
    bne find_is_not_the_word
    poppsp top
find_not_found: 
    movs top, r1
    exit

	@@ Enter interpretation mode
	defcode "[", 0x00005b01,F_IMMED,lbrac
	ldr	r1, =var_state
	movs r2, #1
	str	r2, [r1]
    next
	
	@@ Enter compilation mode
	defcode "]", 0x00005d01,,rbrac
	ldr	r1, =var_state
	movs r2, #0
	str	r2, [r1]	
    next
    
	defcode "save_context", 0x2228c10c,,save_context
    ldr r1, =var_latest
    ldr r1, [r1]
    ldr r2, =var_saved_link
    str r1, [r2]
    ldr r1, =var_here
    ldr r1, [r1]
    ldr r2, =var_saved_here
    str r1, [r2]
    ldr r1, =var_inp
    ldr r1, [r1]
    ldr r2, =var_saved_inp
    str r1, [r2]
    next
    
	defcode "restore_context", 0x734bd20f,,restore_context
    ldr r1, =var_saved_link
    ldr r1, [r1]
    ldr r2, =var_latest
    str r1, [r2]
    ldr r1, =var_saved_here
    ldr r1, [r1]
    ldr r2, =var_here
    str r1, [r2]
    ldr r1, =var_saved_inp
    ldr r1, [r1]
    ldr r2, =var_inp
    str r1, [r2]
    ldr r2, =var_outp           @ Roll back out pointer
    str r1, [r2]
    next
    
    @@ Make the latest defined word to immediate word
    defcode "immediate", 0x2d21dd09, F_IMMED, immediate
    ldr r1, =var_latest
    ldr r1, [r1]
    adds r1, r1, #8             @ Name Field Area
    ldr r3, [r1]
    movs r2, #1                 @ Set Immediate flag
    lsls r2, r2, #31
    adds r3, r3, r2
    str r3, [r1]
    next

    @@ always branch to the following addr
    defcode "branch", 0xdc7ac206,, branch
    mov r1, lr
    subs r1, r1, #1
    ldrh r2, [r1]
    adds r2, r2, #1
    ldrh r3, [r1, #2]
    lsls r3, #16                @Little endian
    add r3, r3, r2
    blx r3
    
    @@ if (top == 0) branch else don't branch
    defcode "?branch", 0xd0d52907,, zero_branch
    cmp top, #0
    mov r1, lr
    bne zero_branch_jump
    poppsp top
    subs r1, r1, #1
    ldrh r2, [r1]
    adds r2, r2, #1
    ldrh r3, [r1, #2]
    lsls r3, #16                @Little endian
    add r3, r3, r2
    blx r3
zero_branch_jump:
    poppsp top    
    adds r1, r1, #4
    blx r1
    
    @@ Start of word compiling
    defword ":", 0x00003a01, F_IMMED, colon
    @@ Save context first, in case of broken compiling
    bl code_save_context
    bl code_word
    bl code_create
    bl code_half_lit
    docol
    bl code_half_comma
    bl code_rbrac
    exit
    
    @@ End of word compiling
    defword ";", 0x00003b01, F_IMMED, semicolon
    bl code_half_lit
    exit
    bl code_half_comma
    bl code_lbrac
    exit
    
    @@ Compile a word
    @@ Even if it calls another word, it's still a code instead of a word as the lr is kept
    defcode "compile", 0xe3466f07, , compile
    pushpsp top
    mov r1, lr
    subs r1, r1, #1
    ldrh r3, [r1]
    lsls r3, #21
    asrs r3, #9    
    ldrh r2, [r1, #2]
    adds r1, r1, #4
    lsls r2, #21
    lsrs r2, #20
    adds top, r2, r3          
    adds top, top, r1           @ top = CFA of the word to be compiled
    adds r1, r1, #1
    pushrsp r1                  @ Store the lr
    bl code_to_mc_bl
    bl code_comma    
    exit    
    
    @@ ( -- ) Create a dict header 
    defword "create", 0xe69ddc06, 0, create
    @@ Put link into dict header 
    ldr r1, =var_latest
    ldr r2, [r1]
    ldr r4, =var_here           @ Load here and align it to 4x boundary
    ldr r3, [r4]
    adds r3, r3, #2
    lsrs r3, #2
    lsls r3, #2
    str r3, [r4]
    str r3, [r1]                @ Store here into latest
    pushpsp top
    movs top, r2
    bl code_comma
    bl code_comma               @ Put hash into dict header, "word" put this into stack
    bl code_comma               @ Put nfa into dict header, "word" put this into stack
    ldr r1, =var_here           @ Put cfa into dict header
    ldr r2, [r1]
    pushpsp top    
    adds top, r2, #4
    bl code_comma
    exit

    @@ (lnk -- cfa)
    defcode ">cfa", 0x68ec9804, , to_cfa
    adds top, top, #12
    ldr top, [top]
    next
    
    @@ (cfa -- machine_code_bl at here)
    defcode ">mc_bl", 0xbdfc3106, , to_mc_bl
    ldr r1, =var_here
    ldr r2, [r1]
    subs r3, top, r2
    subs r3, #4
    mov r4, r3
    lsls r3, #9                 @r3 = (r3 & 0x007FFFFF) >> 12 << 16
    lsrs r3, #21
    lsls r4, #20                @r4 = (r4 & 0xFFF) >> 1
    lsrs r4, #21
    movs r5, #0x1F              @r5 = 0xF800
    lsls r5, #11
    adds r4, r4, r5
    lsls r4, #16
    movs r5, #0xF               @r5 = 0xF000    
    lsls r5, #12
    adds r3, r3, r5
    adds top, r3, r4            @top = r3 + r4
    next

    @@ (nfa 0 -- number 1 / 0)
    @@ Only two types of number are supported, decimal and hexadecimal (0x...)
    defcode "number", 0x51a70106, , number
    poppsp r1                   @ A number?
    ldrb r2, [r1]
    cmp r2, $'0'
    blt number_error            @ Less than '0', error
    beq number_hex              @ Equal to '0', maybe a hex
    cmp r2, $'9'
    bhi number_error
    movs r4, $'0'
    subs r3, r2, r4
    movs r5, #10
number_dec_loop:
    adds r1, r1, #1
    ldrb r2, [r1]
    cmp r2, $' '
    ble number_done
    cmp r2, $'0'
    blt number_error
    cmp r2, $'9'
    bhi number_error
    subs r2, r2, r4
    muls r3, r3, r5             @ r3 *= 10
    adds r3, r3, r2             @ r3 += r2
    b number_dec_loop
number_hex:
    adds r1, r1, #1
    ldrb r2, [r1]
    movs r3, #0
    cmp r2, $' '
    ble number_done
    cmp r2, $'x'                @ Not start with "0x"
    bne number_error
    movs r5, #16
number_hex_loop:
    adds r1, r1, #1
    ldrb r2, [r1]
    cmp r2, $' '
    ble number_done
    cmp r2, $'0'
    blt number_error
    cmp r2, $'9'
    ble number_hex_zero_to_nine
    cmp r2, $'A'
    blt number_error
    cmp r2, $'F'
    ble number_hex_A_to_F
    cmp r2, $'a'
    blt number_error
    cmp r2, $'f'
    ble number_hex_a_to_f
    b number_error
number_hex_zero_to_nine:
    movs r4, $'0'
    subs r2, r2, r4
    muls r3, r3, r5             @ r3 *= 16
    adds r3, r3, r2             @ r3 += r2
    b number_hex_loop
number_hex_A_to_F:
    movs r4, $55                @ 'A' - 10 = 65 - 10 = 55
    subs r2, r2, r4
    muls r3, r3, r5             @ r3 *= 16
    adds r3, r3, r2             @ r3 += r2
    b number_hex_loop
number_hex_a_to_f:
    movs r4, $87                @ 'a' - 10 = 97 - 10 = 87
    subs r2, r2, r4
    muls r3, r3, r5             @ r3 *= 16
    adds r3, r3, r2             @ r3 += r2
    b number_hex_loop
number_done:
    movs top, #1
    pushpsp r3
number_error:
    next

    
    defword "key", 0x1c38eb03, , key
    
    next
    
    .include "./src/port.s"
    
    defcode "loop_exit", 0xf922b509, , loop_exit
    push {r0-r7, lr}
    @@ Save callee sp
    ldr r2, = saved_callee_sp
    mov r1, sp
    str r1, [r2]
    @@ Restore caller sp
    ldr r2, =saved_caller_sp
    ldr r1, [r2]
    mov sp, r1
    pop {r4-r7, pc}    
    next
    
    @@
    defword "interpret", 0x29a87d09, , interpret
    bl code_word
    cmp top, #0
    beq interpret_reach_the_end_of_buffer
    bl code_find
    cmp top, #0
    beq interpret_word_not_found
    ldr r1, [top, #8]
    movs r2, #1                 @ Check Immediate flag
    lsls r2, r2, #31             
    ands r1, r2, r1
    ldr r4, =var_state
    ldr r4, [r4]
    add r1, r1, r4              @ Immediate word or in interpretation state
    cmp r1, #0
    bne interpret_execute_word  @ Execute the word
    bl code_to_cfa              @ Otherwise, compile the word
    bl code_to_mc_bl
    bl code_comma
    movs r1, #0
    exit
interpret_execute_word:
    ldr r1, [top, #12]
    adds r1, r1, #1
    poppsp top
    blx r1
    movs r1, #0    
    exit
interpret_word_not_found:
    bl code_number
    cmp top, #0
    beq interpret_error
    ldr r4, =var_state
    ldr r4, [r4]
    cmp r4, #0
    bne interpret_execute_number  @ Execute the number
    ldr r4, =code_lit             @ Compile the lit
    ldr r5, =interpret_code_offset
    ldr r5, [r5]    
    adds top, r4, r5
    bl code_to_mc_bl
    bl code_comma
    bl code_comma
    movs r1, #0
    exit    
interpret_execute_number:
    movs r1, #0    
    poppsp top                  @ Just put the number on TOS
    exit
interpret_error:
    bl code_restore_context
    movs r1, #1
    movs r6, #1        
    exit
interpret_reach_the_end_of_buffer:
    movs r1, #2
    movs r6, #2            
    exit
    .align 2
interpret_code_offset:
    .int code_offset_ram_to_flash
    
    @@ Set __code_end__, should be placed at the end of the file
	.section .code_field,"ax",%progbits
    .ltorg
    .align 2
    .set __code_end__, .
    
	.section .dict_field,"a",%progbits
	.align 2
    
    .set latest_link, link
latest_link_addr:    
    .int latest_link
	.align 2    
forth_file:
	.incbin "../src/test.fs"	
	.align 2    
