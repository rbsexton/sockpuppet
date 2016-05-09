This directory contains the key SockPuppet API bits, plus a sample
client that can be compiled and run.  If its all done right, the same
binary client image will run unchanged on multiple platforms, although
you may have to re-compile with different addresses.

----------------------
Contents

- svchandler.S : SVC Exception handler that makes this all go.
- syscalls.h : Declarations for the C functions that underly the system calls.
- pendsv-launcher.c : The PendSV handler that launches the client application by manipulating the exception stack.
- sapi-dylink.c : Sample Runtime linking declation file
- sapi-dylink.h : Definitions for runtime linking
- sample_client: A sample SAPI client written in C.   Built for Stellaris, should run on any Cortex-M.

Plus two more somewhat obsolete sets of files:
- lm3s-testbed : Source files for a minimal SAPI host to run on the LM3S6965
- obsolete : Other stuff thats of historic interest.
