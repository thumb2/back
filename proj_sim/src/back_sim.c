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

#define KEY_FIFO_LEN 16
char key_fifo[KEY_FIFO_LEN + 2];
char *pwp;
char *prp;

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

    pwp = &(key_fifo[KEY_FIFO_LEN]);
    *pwp = 0;
    prp = &(key_fifo[KEY_FIFO_LEN + 1]);
    *prp = 0;
    
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

char get_char(void)
{
    if (!(LPC_UART->LSR & 0x01)) return 0;
    return LPC_UART->RBR;
}

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
    (void *)key_fifo,
    0
};

void put_char_to_input_buffer(char ch) 
{
    if (((*prp - *pwp) & (KEY_FIFO_LEN - 1)) != 1) {
        key_fifo[(*pwp)++] = ch;
        if (*pwp >= KEY_FIFO_LEN) *pwp = 0;
    }
}


int to_input_buffer(char ch) 
{
    static int state;
    
    if (ch) {
        switch (state) {
        case 0:
            if (ch == 0x1b) {
                /* ESC */
                state = 1;
            } else {
                put_char_to_input_buffer(ch);
            }
            break;
        case 1:
            if (ch == 0x5b) {
                /* [ */
                state = 2;
            } else {
                state = 0;
            }
            break;
        case 2:
            if (ch == 0x44) {
                put_char_to_input_buffer(0x01);
            } else if (ch == 0x43) {
                put_char_to_input_buffer(0x02);
            } else if (ch == 0x41) {
                /* Use up for delete */
                put_char_to_input_buffer(0x7f);
            } else if (ch == 0x30) {
                put_char_to_input_buffer(0x03);
            }
            
            
            state = 0;
            break;
        }
    }
}

int main (void)
{
    char ch;
    int i;
    volatile forth_table* ft;
    
    ft = (void *)0x26000;
    
//    init = (void*)*addr;
    SystemCoreClockUpdate();
    uart_init();
    i = ft->back_setup((void*)func);
    while (1) {
        ft->back_loop(&i);
        ch = get_char();
        to_input_buffer(ch);
        
        /* if (ch) { */
        /*     test((ch >> 4) >= 10 ? ((ch >> 4) - 10) + 'A' : (ch >> 4) + '0'); */
        /*     test((ch & 0x0F) >= 10 ? ((ch & 0x0F) - 10) + 'A' : (ch & 0x0F) + '0'); */
        /* } */
        
        
//        LPC_UART->THR = i;
    }
}
