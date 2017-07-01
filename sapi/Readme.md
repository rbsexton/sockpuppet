This directory contains the key SockPuppet API bits, plus a sample
client that can be compiled and run.  If its all done right, the same
binary client image will run unchanged on multiple platforms, although
you may have to re-compile with different addresses.

----------------------
Contents

Architecture.txt
Licence.txt
README.md

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

=======
- svchandler.S : SVC Exception handler that makes this all go.
- syscalls.h : Declarations for the C functions that underly the system calls.
- pendsv-launcher.c : The PendSV handler that launches the client application by manipulating the exception stack.
- sapi-dylink.c : Sample Runtime linking declation file
- sapi-dylink.h : Definitions for runtime linking
- sample_client: A sample SAPI client written in C.   Built for Stellaris, should run on any Cortex-M.

Plus two more somewhat obsolete sets of files:
- lm3s-testbed : Source files for a minimal SAPI host to run on the LM3S6965
- obsolete : Other stuff thats of historic interest.

