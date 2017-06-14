This directory contains the key SockPuppet API bits, plus a sample
client that can be compiled and run.  If its all done right, the same
binary client image will run unchanged on multiple platforms, although
you may have to re-compile with different addresses.

----------------------
Contents

Notes - Implementation Notes.

------
Things for Building a sample application to run under SAPI on a LM3S6965:
Makefile 

app.ld app_crt0.c app_main.c app-api.c - Application sample code.

sapi.h - Required header for complilation.

------
sapi-dylink.h - Dynamic Linking Definitions 

------
Bits for adding SAPI support to a C environment host:

ringbuffer.c ringbuffer.h - Ringbuffer routines for use by SAPI.

svchandler.S - Call Dispatch Table
svc-core.s - Core SAPI calls
svc-chario.c - Character IO call layer.  Invokes platform-specific code.
svc-userapp.c - Launch the thread-mode app via the PendSV mechanism.
svc-stubs.c - Defined but not yet implemented.
svc-privs.c - Getting in and out of privileged modes, MPU support

------ Target-Specific code for TI Stellaris/Tiva Cortexes
lm3s-uart.c - Target specific uart code.
lm3s-userapp.c - Getting the part into PendSV 

------
lm3s-testbed - Source files for a minimal SAPI host to run on the LM3S6965

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
Change History 
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

ABI 2.04.0 - ABI change - Purchar, EOL, and Putstring return booleans.
 These system calls take a task control block as an argument, and will clear
 the run bit if they need the calling task to yield/pause.   The system
 calls will take care if the interrupt prep so that the tcbs run bit gets
 set when the blocking condition clears.




