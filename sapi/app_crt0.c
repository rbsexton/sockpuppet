//*****************************************************************************
//
// app_crt0.c - Startup code for use with GNU tools.
// Hacked up for use with the Sockpuppet machine layer.
// Primarily, no interrupt handlers.
//
//*****************************************************************************
void ResetISR(void);

// Filled in by the linker
extern unsigned long _estack[];

//*****************************************************************************
//
// The entry point for the application.
//
//*****************************************************************************
extern int main(void);

//*****************************************************************************
//
// The vector table.  Note that the proper constructs must be placed on this to
// ensure that it ends up at physical address 0x0000.0000.
//
//*****************************************************************************
__attribute__ ((section(".isr_vector")))
void (* const g_pfnVectors[])(void) =
{
    //(void (*)(void))((unsigned long)pulStack + sizeof(pulStack)),
    // We let the linker fill this in.
    (void (*)(void))((unsigned long)_estack),
                                            // The initial stack pointer
    ResetISR,                               // The reset handler
    // The rest of the interrupt table isn't really needed.  Its a good place
    // to stuff some things like applicaton ID.    
    0,                      // The NMI handler
    0,                      // The hard fault handler
    0,                      // The MPU fault handler
    0,                      // The bus fault handler
    0,                      // The usage fault handler
    0,                                     // Reserved
    0,                                      // Reserved
    0,                                      // Reserved
    0,                                      // Reserved
    0,                      // SVCall handler
    0,                      // Debug monitor handler
    0,                                      // Reserved
    0,                      // The PendSV handler
    0                         // The SysTick handler
};

//*****************************************************************************
//
// The following are constructs created by the linker, indicating where the
// the "data" and "bss" segments reside in memory.  The initializers for the
// for the "data" segment resides immediately following the "text" segment.
//
//*****************************************************************************
extern unsigned long _etext;
extern unsigned long _data;
extern unsigned long _edata;
extern unsigned long _bss;
extern unsigned long _ebss;

//*****************************************************************************
//
// This is the code that gets called when the processor first starts execution
// following a reset event.  Only the absolutely necessary set is performed,
// after which the application supplied entry() routine is called.  Any fancy
// actions (such as making decisions based on the reset cause register, and
// resetting the bits in that register) are left solely in the hands of the
// application.
//
//*****************************************************************************
void
ResetISR(void)
{
    unsigned long *pulSrc, *pulDest;

    //
    // Copy the data segment initializers from flash to SRAM.
    //
    pulSrc = &_etext;
    for(pulDest = &_data; pulDest < &_edata; )
    {
        *pulDest++ = *pulSrc++;
    }

    //
    // Zero fill the bss segment.  This is done with inline assembly since this
    // will clear the value of pulDest if it is not kept in a register.
    //
    __asm("    ldr     r0, =_bss\n"
          "    ldr     r1, =_ebss\n"
          "    mov     r2, #0\n"
          "    .thumb_func\n"
          "zero_loop:\n"
          "        cmp     r0, r1\n"
          "        it      lt\n"
          "        strlt   r2, [r0], #4\n"
          "        blt     zero_loop");

    //
    // Call the application's entry point.
    //
    main();
}


