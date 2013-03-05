The Sockpuppet API is a system call interface for Forth that is Cortex-M3
Specific.  It uses the SVC instruction to hook into a system call
layer that is written in C.   The calling code can be in any language.
Files are supplied for use with MPE Forth (http://www.mpeforth.com).

The intent is to abstract away all of the SOC intialization code and
the console interface.  This allows the platform-specific things to be
written in C so that Forth can serve as an application development
platform that isn't encumbered with the finer points of peripheral
control.

Support for other languages should be possible.  The assumption is
that main() or it's equivalent can be substitited as need be.

Currently supported SOCs include Cortex-M3s from TI (Stellaris) and
the ST Micro STM32L family.  Other devices can be added as need be.

