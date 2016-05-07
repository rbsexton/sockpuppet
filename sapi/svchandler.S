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
@ This ABI was designed to support forth's character IO primitives.
@
@ Copyright(C) 2016 Robert Sexton
@ 

@ Version History
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
	ldr r1,  =0x00020101
	str r1, [r0, #0]
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
	
	mov r4, r0 @ We'll over-write R0, so stash it in r4.
	
	ldr  r1, [r0,#24]	@ Get the stacked PC
	ldrb r1, [r1,#-2]	@ Extract the svc call number

	@ Range Checking goes here.
	@ That is, assuming that you don't trust yourself...
	
	ldr  r2,=syscall_table 
	ldr  r12, [r2, r1, LSL #2]

	ldm r4, { r0-r3 }
	blx r12
	str r0, [ r4, # 0 ]
	pop { r4, pc }

	.align 1

// ------------------------------------------------------------
// The first 16 are whats required for bootstrapping forth.
// TYPE and CR are special.
// ------------------------------------------------------------

syscall_table:
	@ ------------------ Mandatory -----------------
	.word	__SAPI_00_ABIVersion		@ SVC 0

	@ ------------------ Core -----------------
	@ This is the main syscall for runtime linking - symbolic lists, 
	@ jump tables, etc.
	@ R0 = 0 - Return a pointer to a symbol table.
	@ R0 = 1 - Return a pointer to a bare jump table.
	@ Unsupported/Stubbed - return 0
	.word	__SAPI_01_GetRuntimeData	@ SVC 1  - 
	.extern __SAPI_01_GetRuntimeData	- 

	@ Notes about stream IO.   There are many cases where the user
	@ app will not succeed.  In the model where threading/tasking
	@ is a user space thing, the task in question must re-try any failing
	@ or partial IO operations.  That allows the thread to yield and try again.


	@ ------------------ Core -----------------
	@ Single Character Write
	@ R0 - Stream #
	@ R1 - The Character.
	@ R2 - The address of the caller's tcb if blocking is requested, or zero.
	@
	@ Returns:
	@ >0 - Success/Room for more.
	@  0 - Success/Warning - The output buffer is full.
	@ -1 - Failure - the client must retry
	@
	.word	__SAPI_02_PutChar		@ SVC 2/emit
	.extern __SAPI_02_PutChar

	@ ------------------ Core -----------------
	@ Single character read
	@ R0 - Stream #
	@ R1 - The address of the caller's tcb if blocking is requested, or zero.
	@
	@ Returns
	@ >= 0 - the Character
	@   -1 - failure/nothing
	@
	.word	__SAPI_03_GetChar		@ SVC 3/key
	.extern	__SAPI_03_GetChar

	@ ------------------ Core -----------------
	@ Input buffer queue check.
	@ R0 - Stream #
	@
	@ Returns
	@ R0 - The number of characters in the input queue.
	.word	__SAPI_04_GetCharAvail	@ SVC 4/key?
	.extern	__SAPI_04_GetCharAvail


	@ --------------------------------------------------
	@ Bulk Character IO - These can improve performance.
	@ but require a higher level of integration.
	@ --------------------------------------------------

	@ ------------------ Enhanced -----------------	
	@ Put a block of characters.  TYPE.
	@ R0 - Stream #
	@ R1 - Number of Characters
	@ R2 - Pointer to the data
	@ R3 - The address of the caller's tcb if blocking is requested, or zero.
	@ Returns - Number of characters written.
	@ Unsupported/Stub behavior - Fault/Spin/Trap
	.word	__SAPI_05_PutString     @ SVC 5/type	 
	.extern	__SAPI_05_PutString     @ SVC 5

	@ ------------------ Enhanced -----------------	
	@ Send a newline or whatever corresponds to it.
	@ R0 - Stream #
	@ R1 - The address of the caller's tcb if blocking is requested, or zero.
	@ Returns
	@  1: Success
	@  0: Failure
	@ Unsupported/Stub behavior - Fault/Spin/Trap
	.word	__SAPI_06_EOL			@ SVC 6/cr	 
	.extern	__SAPI_06_EOL

	.word	__SAPI_RFU @ 7
	.word	__SAPI_RFU @ 8
	.word	__SAPI_RFU @ 9
	.word	__SAPI_RFU @ 10
	.word	__SAPI_RFU @ 11

	@ ------------------ Enhanced -----------------	
	@ A mechanism so that a user task can request a 
	@ wake in response to a specific event.  This
	@ call takes an address and a mask.  When the
	@ event happens, the supervisor will set the mask
	@ into the address.   Note that unlike the IO calls, 
	@ this one takes the address of the task status word.
	@ One use case scenario is periodic timers.
	@
	@ Arguments
	@ R0 - Wake Source - Implementation defined.
	@ R1 - Memory address
	@ R2 - Mask to set, or zero to disable the request.
	@ Returns the previous value.
	.word	__SAPI_12_SetWakeRequest @ 12
	.extern	__SAPI_12_SetWakeRequest 
	
	@ ------------------ Enhanced -----------------	
	@ The most basic tool for reducing power consumption is to 
	@ clock gate the CPU when there is no work.  The simplest
	@ mechanism for measuring this is a free-running counter
	@ clock-gated by WFI, with an ISR that measures the ticks
	@ of the timer per wall clock unit of time.  
	@
	@ No arguments.
	@ Returns a platform-specific measure of CPU utilization.
	@ Unsupported/Stub behavior - Return 0
	.word	__SAPI_13_CPUUsage	 
	.extern	__SAPI_13_CPUUsage	

	@ ------------------ Enhanced -----------------	
	@ R0 - Number of ticks (optional), or zero for the default.
	@ Unsupported/Stub behavior - No Action
	.word	__SAPI_14_PetWatchdog	 
	.extern	__SAPI_14_PetWatchdog	

	@ ------------------ Enhanced -----------------	
	@ Returns
	@ 32-bit Milliseconds
	@ R0 =  0 Return the Current 32-bit value.
	@ R1 =  1 Return the address of the current value.
	@ R2 = -1 Return the 64-Bit value.
	@ Unsupported/Stub behavior - Return 0
	.word   __SAPI_15_GetTimeMS     @ SVC 15/ticks
	.extern __SAPI_15_GetTimeMS

@ --------------------------------------------------
@ End of reserved vectors.
@ --------------------------------------------------

@ When running on a system that uses supervisor/thread
@ Separation, there are a few things that need to be system 
@ Calls

@ Implies user+supervisor mode
#if (SAPI_MPU)
	@ Request upgrade to supervisor mode.
	.word	__SAPI_16_GetPrivs		 
	.extern	__SAPI_16_GetPrivs		 

	@ A hook so the scheduler can install selected MPU slots.
	.word	__SAPI_17_MPULoad		  
	.extern	__SAPI_17_MPULoad		 

	@ This one may require privileges
	.word	__SAPI_18_HWReset 
	.extern __SAPI_18_HWReset 

	@ Depending on the security model, 
	@ This may be better off as a system call
	@ rather than direct manipulation of registers.
	.word	__SAPI_19_LaunchUserApp 
	.extern __SAPI_19_LaunchUserApp 
	
#else
	.word	__SAPI_RFU @ 16
	.word	__SAPI_RFU @ 17
	.word	__SAPI_RFU @ 18
	.word	__SAPI_RFU @ 19
#endif


#if (SAPI_LWIP) 

	.word __SAPI_20_GetIP
	.extern __SAPI_20_GetIP

	.word __SAPI_21_PBuf_Ram_Alloc
	.extern __SAPI_21_PBuf_Ram_Alloc

	.word __SAPI_22_PBuf_Free
	.extern __SAPI_22_PBuf_Free

	.word __SAPI_23_DNS_GetHostByName
	.extern __SAPI_23_DNS_GetHostByName

	.word __SAPI_24_UDP_GetPCB
	.extern __SAPI_24_UDP_GetPCB

	.word __SAPI_25_UDP_Connect
	.extern __SAPI_25_UDP_Connect

	.word __SAPI_26_UDP_Recv
	.extern __SAPI_26_UDP_Recv

	.word __SAPI_27_UDP_Send
	.extern __SAPI_27_UDP_Send
	
	
#endif

syscall_table_end:

.end

