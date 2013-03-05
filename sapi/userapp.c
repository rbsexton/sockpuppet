//! \addtogroup SAPI
//! @{
///
/// Userspace - Check for and launch a user mode executable.
///

#include "userapp.h"

/// @brief See it there is a valid executable ready to go
///
/// Return a 1 if it looks like there is a valid user app in place
///
/// Do this by checking for a sane stack pointer and a program counter
/// that points to the right place in memory and has the thumb bit set
int user_app_present(unsigned long addr) {

	unsigned long *pulApp;

    pulApp = (unsigned long *)addr;
    if (((pulApp[0] & 0xfff00000) != 0x20000000) ||
        ((pulApp[1] & 0xfff00001) != 0x00000001))         
        return(0);
	else return(1);
	}

///
/// @brief Assembly Wrapper that loads up SP and PC and jumps to the app.
///
void user_app_launch(unsigned long addr) {

     // Allow the client to own the whole thing.
     __asm(    "@ Base Address of next Image is in r0\n"
	     "ldr r1, [r0]   @ This should be the stack pointer\n"
	     "mov sp, r1    @ Load it into the process sp\n"
	     "ldr r1,[r0, #4] @ Load up the program counter\n"
	     "mov pc,r1 @ branch to official code\n"
	     );

} 

// Close the Doxygen group
//!
//! @}

