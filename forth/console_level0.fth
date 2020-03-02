\ console_level0.fth - SAPI polled RX, polled TX.

\ Copyright (c) 2020, Robert Sexton.  All rights reserved.
\ Covered by the terms of the supplied Licence.txt file

\ This file obeys the MPE Convention that these things will get wrapped - 
\ EMIT -> EMIT0 -> char 0 (seremit)

\ Supplied System Calls: 
\ __SAPI_02_PutChar            @ SVC 2/emit
\ __SAPI_03_GetChar            @ SVC 3/key
\ __SAPI_04_GetCharAvail	     @ SVC 4/key?
\ __SAPI_07_PutCharNonBlocking @ SVC 7 

\ This is a system call with a little wrapping.
\ *G Transmit a character. 
: (seremit)	\ char stream --  
\  __emit drop ; 

\ Use the non-blocking system call so we can PAUSE.
 begin \ char base 
  2dup 0 __emit_nb
  [ tasking? ] [if] 
    dup 0 <  \ char base ret t/f
    if pause then 
  [then]
  0 >= until  \ base ret 
  2drop  
  ;
   
: (sertype) \ caddr len stream --
\ *G Transmit a string on the given UART.
  -rot bounds
  ?do  i c@ over (seremit)  loop
  drop
;

: (sercr)	\ stream --
\ *G Transmit a CR/LF pair on the given UART.
   $0D over (seremit)  $0A swap (seremit)
;

\ CODE (serkey?)     \ stream -- t/f
\ *G Return true if the given UART has a character avilable to read.
: (serkey?) \ base -- t/f 
  0 __key?  \ Set the TCB to zero, no wake events.  
;

: (serkey) \ stream -- c
\ *G Get a character from the port, or call pause and try again.
 begin \ base -  
	 dup 0 __key? \ Add the tcb place-holder
   [ tasking? ] [if] 
    dup 0=  \ base ret t/f 
     if pause then
   [then]  
	0 > until  \ base ret 
	( base ) __key \ Add the TCB Place-holder   
;

\ ======
\ *> ###
\ ======

decimal
