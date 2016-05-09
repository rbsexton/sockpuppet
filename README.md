The Sockpuppet API is a minimalist system call interface that is Cortex-M Specific.
This system call interface includes getchar/putchar and friends, plus a runtime linking
mechanism so that the client application can look up selected variables and functions
in the C layer.   This was originally written to simplify porting Forth to new
microcontroller environments, but has since gone on to be a more general-purpose tool.
This code has accumulated over a hundred million hours of runtime.

The basic mechanism is a the SVC instruction that hooks into a system call
layer that is written in C.   The client code can be in any language that 
complies or can comply with the ARM AAPCS calling convention.

This allows you to leverage the large body of vendor-supplied SOC initialization
code (for good or ill!) and write all of the device-specific interupt handlers in C.

If the client application supports threads, interrupt handlers and service calls
can stop threads and wake them for a traditional top half/bottom half arrangement.
This is all discussed in more detail in Architecture.txt

Support for other languages is possible.   main() or it's equivalent can
be substituted as need be. Python comes to mind. The only requirement is that
the client binary be at a known location in memory and the first two words of of the
client application are the initial stack pointer and program counter.  This is a
Cortex-M binary with only the first two vectors.

Currently supported SOCs include Cortex-M3s from TI (Stellaris) and
the ST Micro STM32L family.   Its extensible.

Included:
- Architecture.txt : Detailed 
- SAPI - Key pieces that make up the C-Side layer.
- Forth - Implementation files for MPE Forth


----------------------
Files are supplied for use with MPE Forth (http://www.mpeforth.com).

Not included:  Libraries from TI and/or ST.   Those are covered
under their own licenses and may be obtained directly from the
vendors.

Not Included: Forth compiler from MPE.  


