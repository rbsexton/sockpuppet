@ SVC Call Table.
@
@ Copyright (C) 2016-2017, Robert Sexton.  All rights reserved.
@ Covered by the terms of the supplied License.txt file
@ 
@ This is a reference copy.  It may need to be customized, depending
@ on how much of the SAPI API is implemented.


@ Version History
@ 3.00.00 - Add the GetCharWillBlock system call
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
.cpu cortex-m0

.thumb_func @ Set the thumb bit in the linker. 
@ Version coding: 0xMMIIPP
@ Major 
@ Minor Release / Feature Change
@ Patchlevel 
__SAPI_00_ABIVersion:
	ldr r0,  =0x00030000
	bx lr  

@ Hang out and wait for debugger help.
.thumb_func
__SAPI_RFU:
	b __SAPI_RFU

// ------------------------------------------------------------
// The first 16 are whats required for bootstrapping forth.
// TYPE and CR are special - They are included for efficiency,
// but can be built from other primitives.
// ------------------------------------------------------------

.global syscall_table
.data 
.align 4
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
	@  Amount of room available in the output buffer
	@
	.word	__SAPI_02_PutChar		@ SVC 2/emit
	.extern __SAPI_02_PutChar

	@ ------------------ Core -----------------
	@ Single character blocking read
	@ R0 - Stream #
	@
	@ Returns - data
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
	@ Returns:
	@  0 - Success/Room for more.
	@  1 - Caller must yield/pause and wait for wake by service layer.
	@ Unsupported/Stub behavior - Fault/Spin/Trap
	.word	__SAPI_05_PutString     @ SVC 5/type	 
	.extern	__SAPI_05_PutString     @ SVC 5

	@ ------------------ Enhanced -----------------	
	@ Send a newline or whatever corresponds to it.
	@ R0 - Stream #
	@ R1 - The address of the caller's tcb if blocking is requested, or zero.
	@ Returns
	@  0 - Success/Room for more.
	@  1 - Caller must yield/pause and wait for wake by service layer.
	@ Unsupported/Stub behavior - Fault/Spin/Trap
	.word	__SAPI_06_EOL			@ SVC 6/cr	 
	.extern	__SAPI_06_EOL

  @ ------------------ Core -----------------
	@ Non-blocking output 
	@ R0 - Stream #
  @ R1 - Character 
  @ R2 - Task TCB 
	@
	@ Returns
	@ R0 - The amount of space in the ouput queue, or -1 for fail.
  .word	__SAPI_07_PutCharNonBlocking		@ SVC 2/emit
	.extern __SAPI_07_PutCharNonBlocking

	.word	__SAPI_RFU @ 8
	.word	__SAPI_RFU @ 9
	.word	__SAPI_RFU @ 10
	.word	__SAPI_RFU @ 11

	@ ------------------ Enhanced -----------------	
	@ A mechanism so that a user task can request a 
	@ wake in response to a specific event.  This is an
	@ Implementation specific thing.  Types 0-15 are reserved
	@ One use case scenario is periodic timers.
	@
	@ Arguments
	@ R0 - Wake Type.
	@ R1 - Wake argument - type-specific.
	@ R2 - TCB of the thing to wake.
	@ Returns true for block requested.
	.word	__SAPI_12_WakeRequest @ 12
	.extern	__SAPI_12_WakeRequest 
	
	@ ------------------ Enhanced -----------------	
	@ The most basic tool for reducing power consumption is to 
	@ clock gate the CPU when there is no work.  The simplest
	@ mechanism for measuring this is a free-running counter
	@ clock-gated by WFI, with an ISR that measures the ticks
	@ of the timer per wall clock unit of time.  
  @ This trick requires a device with automatic clock gating.
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
	.word   __SAPI_15_GetTime     @ SVC 15/ticks
	.extern __SAPI_15_GetTime

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
#else
	.word	__SAPI_RFU @ 20
	.word	__SAPI_RFU @ 21
	.word	__SAPI_RFU @ 22
	.word	__SAPI_RFU @ 23
	.word	__SAPI_RFU @ 24
	.word	__SAPI_RFU @ 25
	.word	__SAPI_RFU @ 26
	.word	__SAPI_RFU @ 27
#endif

.word	__SAPI_RFU @ 28
.word	__SAPI_RFU @ 29
.word	__SAPI_RFU @ 30
.word	__SAPI_RFU @ 31




syscall_table_end:

.end

