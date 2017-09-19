/*----------------------------------------------------------------------------
 * Name:    Blinky.c
 * Purpose: LED Flasher for MCB11C14
 *----------------------------------------------------------------------------
 * This file is part of the uVision/ARM development tools.
 * This software may only be used under the terms of a valid, current,
 * end user licence from KEIL for a compatible version of KEIL software
 * development tools. Nothing else gives you the right to use this software.
 *
 * This software is supplied "AS IS" without warranties of any kind.
 *
 * Copyright (c) 2004-2015 Keil - An ARM Company. All rights reserved.
 *----------------------------------------------------------------------------*/

#include "LPC11xx.h"                    // Device header

/*************** System Initialization ***************/
void uart_init()
{
    /* Initialize Pin Select Block for Tx and Rx */
    LPC_IOCON->PIO1_6 = ((1UL << 0) |            /* select GPIO function         */
                         (2UL << 3) |            /* pullup enabled               */
                         (3UL << 6));          /* keep reserved values         */

    LPC_IOCON->PIO1_7 = ((1UL << 0) |            /* select GPIO function         */
                         (2UL << 3) |            /* pullup enabled               */
                         (3UL << 6));          /* keep reserved values         */
    LPC_UART->FCR=0x7;

    /* Set DLAB and word length set to 8bits */
    LPC_UART->LCR=0x83;

    /* Baud rate set to 9600 */
    LPC_UART->DLL=0x10;
    LPC_UART->DLM=0x0;
    /* Clear DLAB */
    LPC_UART->LCR=0x3;
}
/*********************************************************/
/*----------------------------------------------------------------------------
  Main function
 *----------------------------------------------------------------------------*/


typedef struct forth_table
{
    int (*back_setup)(void *);
    int (*back_loop)(void *);    
    
}forth_table;


int const test(int i) 
{
    if (LPC_UART->LSR & 0x20) {
        LPC_UART->THR = i;
        return 0;
    }
    return 1;
}

int const test1(int i) 
{
    return -i;
}

int (*init)(void);


int const (* const func[4])(int) = 
{
    test + 1,
    test1 + 1,
    0,
    0
};


int main (void)
{
    int i;
    volatile forth_table* ft;
    
    ft = (void *)0x20000;
    
//    init = (void*)*addr;
    SystemCoreClockUpdate();
    uart_init();
    i = ft->back_setup((void*)func);
    while (1) {
        ft->back_loop(&i);
//        LPC_UART->THR = i;
    }
}
