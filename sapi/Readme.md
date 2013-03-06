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
app.ld app_crt0.c app_main.c - Application sample code.
sapi.c sapi.h - SAPI interface calls used by C client

------
sapi-dylink.h - Dynamic Linking Definitions 

------
Bits for adding SAPI support to a C environment host:
ringbuffer.c ringbuffer.h - Ringbuffer routines for use by SAPI.
svc.S - Call Dispatch Table
syscalls.c - System Call Code.
userapp.c userapp.h - Functions for detecting and starting the SAPI Client


------
lm3s-testbed - Source files for a minimal SAPI host to run on the LM3S6965
