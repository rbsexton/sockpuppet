The Sockpuppet API is a minimalist system call interface for Forth
that is Cortex-M3 Specific.   This system call interface includes 
getchar/putchar and friends, plus a runtime linking mechanism so that Forth
can look up selected variables and functions in the C layer.

It does this via SVC instruction to hook into a system call
layer that is written in C.   The calling code can be in any language.
Files are supplied for use with MPE Forth (http://www.mpeforth.com).

This moves all SOC initialization into the C layer, and allows
you to use existing C code for these things, as well as writing
interrupt handlers in C.   Interrupt handlers can trigger Forth 
threads in a traditional top half/bottom half arrangement.

Support for other languages should be possible.  The assumption is
that main() or it's equivalent can be substitited as need be.

Currently supported SOCs include Cortex-M3s from TI (Stellaris) and
the ST Micro STM32L family.   Its extensible.

Compilation enviroment is GNU gcc.   I use the summon-arm-toolchain
script.   The Makefiles are based upon the ones that ship with the
TI/Stellaris libraries.

----------------------
Not included:  Libraries from TI and/or ST.   Those are covered
under their own licenses and may be obtained directly from the
vendors.

Not Included: Forth compiler from MPE.  


