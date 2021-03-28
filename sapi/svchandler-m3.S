@ SVC Call trampoline.
@ All system calls have to take args from the 
@ Stack, so this code figures out which stack,
@ and passes it along to the routine as r0
@ We're now in supervisor mode, so r0-r4 are 
@ free for us to use as we see fit.
@
@ This is the core definition of whats basically a binary ABI
@ So this is as good a place as any to define it.
@ The tricky part is that the particulars of the ABI parameters are 
@ basically implementation defined.  More below.
@ This ABI was initially designed to support forth's character IO primitives:
@ getchar(), charsavail(), & putchar()
@ later it was extended to support string puts, and end-of-line. 
@ 
@ These cannot be direct substitutes for the forth words in question
@ because system calls are not allowed to block - the client
@ application must provide that functionality.
@
@ Copyright (C) 2016-2017, Robert Sexton.  All rights reserved.
@ Covered by the terms of the supplied Licence.txt file


@ Version History
@ 2.06.00 - Move the jump table to SRAM - it's faster and can be modified.
@ 2.05.00 - Officially define wake request
@ 2.04.00 - Change return codes for putchar, type and eol for use with multitasking.
@ 2.03.00 - Support 64-bit return values.
@ 2.02.01 - Change return code of EOL.
@ 2.02.00 - Add WakeRequest
@ 2.01.00 - Add CPUUsage and clarify behavior of unsupported calls.
@ 2.00.00 - Initial Release.
#include "sapiopts.h"

.text
.syntax unified

.thumb_func @ Set the thumb bit in the linker. 
@ Version coding: 0xMMIIPP
@ Major 
@ Minor Release / Feature Change
@ Patchlevel 
__SAPI_00_ABIVersion:
	ldr r0,  =0x00020600
	bx lr  

@ Hang out and wait for debugger help.
.thumb_func
__SAPI_RFU:
	b __SAPI_RFU

.thumb_func     @  Make sure the linker puts it in the table.
.global SVC_Handler

@ Incorporate register marshalling.   Thats a little wasteful
@ since all system calls don't need it, but it makes the code 
@ cleaner at the system call and it saves a little code at the 
@ function level.
@
@ It might appear on first inspection that you don't have to pull
@ the registers from the stack.   Thats true in most conditions.
@ Its very not true in one case:  Tail-chaining by the NVIC.  If the 
@ SVC handler tail-chains after another exception running at the same 
@ pre-emption priority level, R0-R3 & R12 will no longer be valid.
@ the only safe place to get the pushed registers under all circumstances
@ is the stack.   
SVC_Handler:

	@ bkpt #0

	tst	lr,#0x4		@ Figure out which stack
	ite	eq
	mrseq	r0,msp		@ Main stack
	mrsne	r0,psp		@ Process/Thread Stack

	@ Now that we have a copy of the original 
	@ stack pointer we can put more things on the stack.
	push { r4, lr }
	
	@ This is where you could make a copy of the stack frame pointer
	@ for system calls that need to access it - things like panic,
	@ reboot, etc that will pull the stacked PC, and so on.
	@ ldr r1, =saved_frame_p
	@ str r0, [ r1 ]
	
	mov r4, r0 @ We'll over-write R0, so stash it in r4.
	
	ldr  r1, [r0,#24]	@ Get the stacked PC
	ldrb r1, [r1,#-2]	@ Extract the svc call number

	@ Range Checking goes here.
	@ That is, assuming that you don't trust yourself...
	
	ldr  r2,=syscall_table 
	ldr  r12, [r2, r1, LSL #2]

	ldm r4, { r0-r3 }
	blx r12
	stm r4, { r0-r1 } @ Support 64-bit return values.
	pop { r4, pc }

.end

