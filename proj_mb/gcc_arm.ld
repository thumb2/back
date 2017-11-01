/* Linker script to configure memory regions. */
MEMORY
{
  BACK_FLASH (rx)  : ORIGIN = 0x00020000, LENGTH = 128K  
  BACK_RAM (rwx)  : ORIGIN = 0x20004000, LENGTH = 0x04000   /*  16k */  
}

/* Library configurations */
/*GROUP(libgcc.a libc.a libm.a libnosys.a) */

/* Linker script to place sections and symbol values. Should be used together
 * with other linker script that defines memory regions FLASH and RAM.
 * It references following symbols, which must be defined in code:
 *   Reset_Handler : Entry of reset handler
 * 
 * It defines following symbols, which code can use without definition:
 *   __exidx_start
 *   __exidx_end
 *   __etext
 *   __data_start__
 *   __preinit_array_start
 *   __preinit_array_end
 *   __init_array_start
 *   __init_array_end
 *   __fini_array_start
 *   __fini_array_end
 *   __data_end__
 *   __bss_start__
 *   __bss_end__
 *   __end__
 *   end
 *   __HeapLimit
 *   __StackLimit
 *   __StackTop
 *   __stack
 */

ENTRY(back_setup)

SECTIONS
{
	.return_stack_dummy :
	{
		*(.return_stack)
	} > BACK_RAM

	.param_stack_dummy :
	{
		*(.param_stack)
	} > BACK_RAM
    
	.back_heap 0x20007B00:
	{
		*(.back_heap)
	} > BACK_RAM


    .dict_field 0x00028000 :
    {
        KEEP (*(.dict_field))
    } >BACK_FLASH
    .code_field 0x00030000 :
    {
        PROVIDE(__code_start__ = .);    
        KEEP (*(.code_field))
    } >BACK_FLASH

    .ram_field 0x20004000 :
    {
        PROVIDE(__ram_start__ = .);    
        KEEP (*(.ram_field))
    } >BACK_RAM


	/* Set stack top to end of RAM, and stack limit move down by
	 * size of stack_dummy section */
	__return_stack_top = ORIGIN(BACK_RAM) + LENGTH(BACK_RAM);
	__return_stack_limit = __return_stack_top - SIZEOF(.return_stack_dummy);
	PROVIDE(__return_stack = __return_stack_top);
    
	__param_stack_top = ORIGIN(BACK_RAM) + LENGTH(BACK_RAM) - SIZEOF(.return_stack_dummy);
	__param_stack_limit = __param_stack_top - SIZEOF(.param_stack_dummy);
	PROVIDE(__param_stack = __param_stack_top);

}
