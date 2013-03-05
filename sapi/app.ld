/******************************************************************************
 *
 * app.ld - Linker configuration file for SAPI client.
 * Target - 64k of flash starting at 192k
 *        - 32k of ram starting at 64k
 *
 *****************************************************************************/

/* This linker map is hacked:
* 1: Skip the first 2k to make room for the boot loader.
* 2: Skip the last 2k to make room for flash pram.
*
* There doesn't appear to be a good way to Automagically determine the
* stack boundaries so I just declare some lengths.  The M3 does
* a descending stack, so SP gets updated before the write.
* For doubleword support, AAPCS requires that the stack be 8-byte aligned.
*/

/* TUNABLES */

__primary_stack_size = 256;
__overflow_stack_size = 256;
/* You must adjust the sizes in the MEMORY declaration to match */
/* The linker doesn't like math declarations in the MEMORY * declaration. */

/* SRAM = 2k - 7.5k, length 5.5k */
/* Machine stacks start at 7.5k */

MEMORY
{
    FLASH (rx) : ORIGIN = 192k, LENGTH = 64k
    SRAM (rwx) : ORIGIN = 0x20000000 + 64k, LENGTH = 31k
    STACK (rx) : ORIGIN = 0x20000000 + 64k + 31k + 512, LENGTH = 512
}

/*
* The convention used by the Luminary micro linker stuff
* is that things get stuffed into sections, and the last
* thing that happens the the definition of _e<something>
* to mark the end
*/

SECTIONS
{
    .text :
    {
        _text = .;
        KEEP(*(.isr_vector))
        *(.text*)
        *(.rodata*)
        _etext = .;
    } > FLASH
    .data : AT(ADDR(.text) + SIZEOF(.text))
    /*  
     * We tag the beginning of RAM so that we can force things
     * to be put there by the linker, like fault handler data.
     *
     * The NVIC requires that an in-ram vector table be aligned
     * on a 1k boundary.
     * 
     * create a section after the C stuff where the linker can 
     * put the forth bits, so that the dictionaries can grow
     * upwards towards the machine stack.
     */
    {
        _data = .;
	*(SRAM_START) /* Tag the beginning for special stuff */
        *(.data*)
    	. = ALIGN(1024); /* In-RAM NVIC Vector table must be aligned */
        *(vtable)
        _edata = .;
    } > SRAM
    .bss :
    {
        _bss = .;
        *(.bss*)
        *(COMMON)
        _ebss = .;
    } > SRAM
  
    /*
     * Stack is divided into two parts so we can use the MPU 
     * to detect stack overrun - Slotted into a fixed location
     */
    .stack : { 
    	. = ALIGN(8);
	_overflow_stack_start = .;
	. += __overflow_stack_size;

	. = ALIGN(8);
	_pri_stack_start = .;
	. += __primary_stack_size;
	_estack = .; 
	} >STACK
	
}
