\ console_level2.fth - SAPI polled RX, polled TX with interrupt support.
\ Support for blocking system calls.
\
\ Note that there is no WFI here.   If you've got tasks,
\ the scheduler is the only place where WFI works well.
\
\ This code requires TASKING 
\
\ Copyright (c) 2020, Robert Sexton.  All rights reserved.
\ Covered by the terms of the supplied Licence.txt file

\ This file obeys the MPE Convention that these things will get wrapped - 
\ EMIT -> EMIT0 -> char 0 (seremit)

\ Supplied System Calls: 
\ __SAPI_02_PutChar            @ SVC 2/emit
\ __SAPI_03_GetChar            @ SVC 3/key
\ __SAPI_04_GetCharAvail	     @ SVC 4/key?
\ __SAPI_07_PutCharNonBlocking @ SVC 7?
\
\ Forth Notes:
\ The Main Interpretation loop is QUIT
\ QUIT -> QUERY -> ACCEPT -> KEY 

: (seremit)	\ char base -- ; 
\ *G 
\ Make this non-blocking with help from the Non-Blocking system call.
\ There are a few different ways to do this.    The system call 
\ returns the amount of space in the output queue, or -1 if its full.   
  begin \ char base -  
	 2dup self __emit_nb   \ Pass in the TCB.  Result: char base ret 
	 dup 0 < if PAUSE then  
	 0 >= until  \ base ret 
  2drop  
	;

: (sertype) \ caddr len base --
\ *G Transmit a string on the given UART.
  -rot bounds
  ?do  i c@ over (seremit)  loop
  drop
;

: (sercr)	\ base --
\ *G Transmit a CR/LF pair on the given UART.
   $0D over (seremit)  $0A swap (seremit)
;

\ CODE (serkey?)     \ base -- t/f
\ *G Return true if the given UART has a character avilable to read.
\ The underlying gadget supports a TCB argument, but we don't want 
\ to use it for this case.
: (serkey?) \ base -- t/f 
  0 __key?  \ Set the TCB to zero, no wake events.  
;

: (serkey) \ base -- c
\ *G Get a character from the port, or call pause and try again.
\ This goes all the way back to QUIT, so this is the place to PAUSE
  begin \ base -  
	 dup self __key?  \ base ret
	 dup 0=  if PAUSE then  
	 0 > until  \ base ret 
	( base ) __key   
;

\ ======
\ *> ###
\ ======

decimal
