    .syntax unified
    .arch armv6-m
    @@ Memory map (RAM)
    @@ 8000(512B) return stack top, full descending
    @@ 7C00(512B) paramter stack top, empty increasing
    @@ 7B00(128B) heap
    @@ 7000(2k)   temp input buffer
    @@ 6000(4k)   user's source code buffer
    @@ 4000(8k)   code region 
    .section .return_stack
    .equ return_stack_size, 0x400 @ In fact it is the total size of r&p.
    .globl __return_stack_top
    .globl __return_stack_limit
__return_stack_limit:
    .space return_stack_size
    .size  __return_stack_limit, . - __return_stack_limit
__return_stack_top:
    .size  __return_stack_top, . - __return_stack_top
    
    .section .param_stack
    .equ param_stack_size, 0x200 @ In fact the size is useless.
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
var_key_fifo:
    .int 0
var_key_fifo_pwp:
    .int 0
var_key_fifo_prp:
    .int 0
var_input_buffer_begin:
    .int 0
var_input_buffer_cursor:
    .int 0
var_input_buffer_end:    
    .int 0
var_user_code_start_here:
    .int 0
var_user_code_start_latest:
    .int 0
var_user_code_begin:
    .int 0
var_user_code_end:
    .int 0
var_word_begin:
    .int 0
var_word_end:
    .int 0
var_edit_mode:
    .int 0
var_clear_input_buffer:
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
    .set input_buffer_start_addr, 0x20007000
    .set user_code_start_addr, 0x20006000    
    
	.global test
	.global _fini
_fini:  

	top	.req	r0
	rsp	.req	sp
	psp	.req	r7

    .set thumb_code_flag_bit, 1
    .set code_offset_ram_to_flash, (0x20004000 - 0x28000)
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
    ldr r3, [r0, #8]
    ldr r2, =var_key_fifo
    str r3, [r2]
    ldr r2, =var_key_fifo_pwp
    adds r3, r3, #16
    str r3, [r2]
    ldr r2, =var_key_fifo_prp    
    adds r3, r3, #1
    str r3, [r2]
    @@ Init source code variables, should be excuted only when power up
    ldr r2, =var_user_code_begin
    ldr r3, =init_user_code_start_addr
    ldr r3, [r3]
    str r3, [r2]
    ldr r2, =var_user_code_end        
    movs r4, #3
    strb r4, [r3]
    adds r3, r3, #1    
    strb r4, [r3]
    movs r4, #0
    adds r3, r3, #1
    strb r4, [r3]
    str r3, [r2]
    @@ Init input buffer variables
    ldr r2, =var_input_buffer_begin
    ldr r3, =init_input_buffer_start_addr
    movs r4, #0
    ldr r3, [r3]
    str r4, [r3]
    str r3, [r2]
    ldr r2, =var_input_buffer_end
    str r3, [r2]
    ldr r2, =var_input_buffer_cursor
    str r3, [r2]
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
    @@ Init latest
    ldr r1, =var_latest
    ldr r2, =latest_link_addr
    ldr r2, [r2]
    str r2, [r1]
    @@ Init state
    ldr r1, =var_state
    movs r2, #0
    str r2, [r1]
    ldr r1, =var_edit_mode
    movs r2, #0
    str r2, [r1]
    @@ Jump to ram code area
    adds r3, r3, #1
    blx r3
    @@ Save user code here
    ldr r1, =var_here
    ldr r1, [r1]
    ldr r2, =var_user_code_start_here
    str r1, [r2]
    ldr r1, =var_latest
    ldr r1, [r1]
    ldr r2, =var_user_code_start_latest
    str r1, [r2]
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
init_input_buffer_start_addr:
    .int input_buffer_start_addr
    .ltorg
init_user_code_start_addr:
    .int user_code_start_addr
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
    movs r1, top
    poppsp top
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
    subs top, r1, top
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

    @@ (a b -- a <>b? )
    defcode "<>", 0x001ef202, 0, not_equal
    poppsp r1
    cmp r1, top
    bne not_equal_equal
    movs top, #0    
    next    
not_equal_equal:
    movs top, #0        
    mvns top, top
    next

    @@ (a b -- b < a? )
    defcode "<", 0x00003c01, 0, less_than
    poppsp r1
    cmp top, r1
    blt less_than_true
    movs top, #0    
    next    
less_than_true:
    movs top, #0        
    mvns top, top
    next

    @@ (a b -- b > a? )
    defcode ">", 0x00003e01, 0, more_than
    poppsp r1
    cmp r1, top
    blt more_than_true
    movs top, #0    
    next    
more_than_true:
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

    @@ (here-to-move-in-byte -- )
    defcode "allot", 0x47532205, 0, allot
    ldr r1, =var_here
    ldr r2, [r1]
    adds top, #1                @ Align top to 2
    lsrs top, #1
    lsls top, #1
    adds r2, top
    str  r2, [r1]
    poppsp top
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
    
    @@ ( -- 32b) top = *edit_mode
    defcode "edit_mode", 0x12907409, 0, edit_mode
    pushpsp top
    ldr r1, =var_edit_mode
    ldr top, [r1]
    next

    @@ ( -- 32b) top = inp
    defcode "inp", 0x1bb76b03, 0, inp
    pushpsp top
    ldr top, =var_inp
    next

    @@ ( -- 32b) top = latest
    defcode "latest", 0x27c14b06, 0, latest
    pushpsp top
    ldr top, =var_latest
    next

    @@ ( -- 32b) top = clear_input_buffer
    defcode "clear_input_buffer", 0xf9054712, 0, clear_input_buffer
    pushpsp top
    ldr top, =var_clear_input_buffer
    next

    @@ ( -- ) 
    defcode "forget_user_code", 0xf0bfaf10, 0, forget_user_code
    ldr r1, =var_user_code_start_here
    ldr r1, [r1]
    ldr r2, =var_here
    str r1, [r2]
    ldr r1, =var_user_code_start_latest
    ldr r1, [r1]
    ldr r2, =var_latest
    str r1, [r2]
    next
    
    @@ ( -- ) 
    defword "recompile_user_code", 0x6413c613, 0, recompile_user_code
    bl code_forget_user_code
    ldr r1, =var_inp
    ldr r2, =var_user_code_begin
    ldr r2, [r2]
    str r2, [r1]
    exit
    
    @@ ( -- 32b) top = input_buffer_begin
    defcode "input_buffer_begin", 0x850d1312, 0, input_buffer_begin
    pushpsp top
    ldr top, =var_input_buffer_begin
    next

    @@ ( -- 32b) top = input_buffer_end
    defcode "input_buffer_end", 0xe895cd10, 0, input_buffer_end
    pushpsp top
    ldr top, =var_input_buffer_end
    next

    @@ ( -- 32b) top = input_buffer_cursor
    defcode "input_buffer_cursor", 0xf1563413, 0, input_buffer_cursor
    pushpsp top
    ldr top, =var_input_buffer_cursor
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

    @@ ( a b -- a b a) over
    defcode "over", 0xfec07c04, 0, over
    pushpsp top
    movs r2, #8
    subs r1, psp, r2
    ldr top, [r1]
    next

    @@ ( a b c -- b c a) rot
    defcode "rot", 0x1e134303, 0, rot
    poppsp r1
    poppsp r2
    pushpsp r1 
    pushpsp top
    movs top, r2
    next

    @@ ( a -- a a) dup
    defcode "dup", 0x1a6bd303, 0, dup
    pushpsp top
    next

    @@ ( a -- 0 | a a) ?dup
    defcode "?dup", 0x8b84f804, 0, qdup
    cmp top, #0
    bne qdup_push
    next
qdup_push:  
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

    @@ ( nfa hash -- lnk / nfa 0 ) Find a word in user code, lnk = 0 if not found
    defword "find_in_user_code", 0xf8f0c111, 0, find_in_user_code
    ldr r1, =var_latest
    ldr r3, =var_user_code_start_latest
    ldr r3, [r3]
find_in_uc_is_not_the_word:   
    ldr r1, [r1]
    @@ If the (link == 0), not found
    cmp r1, r3
    beq find_in_uc_not_found
    adds r2, r1, #4
    ldr r2, [r2]
    cmp r2, top
    bne find_in_uc_is_not_the_word
    poppsp top
    movs top, r1
    exit
find_in_uc_not_found:
    movs top, #0
    exit

    @@ ( nfa hash -- lnk / nfa 0 ) Find a word in user code, lnk = 0 if not found
    defword "cp_uc_to_ib", 0x5fb5660b, 0, cp_uc_to_ib
    bl code_word
    bl code_find_in_user_code
    cmp top, #0
    beq cp_uc_to_ib_end
    adds top, #8
    ldr top, [top]
    movs r1, top
cp_uc_to_ib_find_start:
    subs r1, r1, #1
    ldrb r2, [r1]
    cmp r2, #03
    bne cp_uc_to_ib_find_start
    ldr r2, =var_word_begin
    adds r1, r1, #1
    str r1, [r2]
    movs r3, r1
    movs r1, top
cp_uc_to_ib_find_end:    
    adds r1, r1, #1
    ldrb r2, [r1]
    cmp r2, #03
    bne cp_uc_to_ib_find_end
    ldr r2, =var_word_end
    str r1, [r2]
    subs r4, r1, r3
    subs r4, r4, #1
    ldr r2, =var_input_buffer_begin
    ldr r2, [r2]
    movs r5, #0
cp_uc_to_ib_copy:
    ldrb r1, [r3, r5]
    strb r1, [r2, r5]
    adds r5, #1
    cmp r5, r4
    ble cp_uc_to_ib_copy
    adds r5, r2, r5
    ldr r1, =var_input_buffer_end
    str r5, [r1]
    ldr r1, =var_input_buffer_cursor
    str r5, [r1]
    adds r5, r5, #1
    movs r4, #0
    strb r4, [r5]
    ldr r1, =var_clear_input_buffer
    str r4, [r1]
cp_uc_to_ib_end:    
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

	defcode "new_word", 0x551a8908,,new_word
    ldr r1, =var_user_code_end
    ldr r2, [r1]
    movs r3, #3
    strb r3, [r2]
    subs r2, #1
    ldr r3, =var_word_begin
    str r2, [r3]
    ldr r3, =var_word_end
    str r2, [r3]
    adds r2, r2, #2
    movs r3, #0
    strb r3, [r2]
    str r2, [r1]
    ldr r1, =var_edit_mode
    movs r2, #1
    str r2, [r1]
    next
    
	defcode "save_word", 0x7baca009,,save_word
    @@ Calc the delta, r1 = delta, r6 = new word len
    ldr r2, =var_input_buffer_begin
    ldr r2, [r2]
    ldr r4, =var_input_buffer_cursor
    str r2, [r4]
    ldr r4, =var_input_buffer_end
    ldr r3, [r4]
    str r2, [r4]
    subs r6, r3, r2
    ldr r2, =var_word_begin
    ldr r2, [r2]
    ldr r3, =var_word_end
    ldr r3, [r3]
    subs r4, r3, r2
    subs r1, r6, r4
    @@ r4 = len
    ldr r4, =var_user_code_end
    ldr r2, [r4]
    adds r5, r2, r1
    str r5, [r4]
    movs r4, r2
    subs r4, r4, r3
    @@ r3 = src, r2 = dst
    adds r2, r3, r1
    @@ delta = 0, no need to move
    cmp r1, #0
    beq save_word_copy_code
    movs r5, #0
    blt save_word_move_from_the_beginning
save_word_move_from_the_end:    
    ldrb r1, [r3, r4]
    strb r1, [r2, r4]
    subs r4, #1
    cmp r4, #0
    bge save_word_move_from_the_end    
    b save_word_copy_code
save_word_move_from_the_beginning:
    ldrb r1, [r3, r5]
    strb r1, [r2, r5]
    adds r5, #1
    cmp r5, r4
    ble save_word_move_from_the_beginning
save_word_copy_code:
    @@ r3 = src, r2 = dst, r6 = len
    ldr r3, =var_input_buffer_begin
    ldr r3, [r3]
    ldr r2, =var_word_begin
    ldr r2, [r2]
    cmp r6, #0
    beq save_word_end
    subs r6, #1
save_word_copy_code_loop:
    ldrb r1, [r3, r6]
    strb r1, [r2, r6]
    subs r6, #1
    cmp r6, #0
    bge save_word_copy_code_loop
save_word_end:
    ldr r1, =var_edit_mode
    movs r2, #0
    str r2, [r1]
    ldr r1, =var_input_buffer_begin
    ldr r1, [r1]
    strb r2, [r1]    
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
    bl code_word    
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

    @@ ( -- key_fifo )
    defcode "kf", 0x00372702, , kf
    pushpsp top
    ldr r1, =var_key_fifo
    ldr top, [r1]
    next
    
    @@ ( -- key_fifo_pwp )
    defcode "kf_pwp", 0x9a8b2106, , kf_pwp
    pushpsp top
    ldr r1, =var_key_fifo_pwp
    ldr top, [r1]
    next
    
    @@ ( -- key_fifo_prp )
    defcode "kf_prp", 0x9a889206, , kf_prp
    pushpsp top
    ldr r1, =var_key_fifo_prp
    ldr top, [r1]
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
    pushpsp top
    movs top, #0    
    exit
interpret_execute_word:
    ldr r1, [top, #12]
    adds r1, r1, #1
    poppsp top
    blx r1
    pushpsp top
    movs top, #0    
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
    pushpsp top
    movs top, #0    
    exit    
interpret_execute_number:
    movs top, #0    @ Just put the number on TOS
    exit
interpret_error:
    bl code_restore_context
    movs top, #1    
    exit
interpret_reach_the_end_of_buffer:
    movs top, #2    
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
