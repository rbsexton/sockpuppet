\ serCM3_sapi_level1.fth - SAPI polled RX, polled TX, serial communication drivers
\ with support for blocking IO.
\ Written to run against the SockPuppet API.

\ Level 1 support.   Requires TASKING.  System calls request blocking.
\ KEY requires blocking, so that must be implemented here.

\ Copyright (c) 2017, Robert Sexton.  All rights reserved.
\ Covered by the terms of the supplied Licence.txt file

only forth definitions

\ ==============
\ *T SAPI polled serial driver
\ ==============
\ *P This driver provides polled serial comms for Cortex-M3 CPUs
\ ** using the internal UARTs via the SAPI call layer.   This is 
\ ** The simplest implementation level.
\ ** It doesn't use the CR or TYPE calls, but rather emulates them.

\ ****************
\ *S Configuration
\ ****************
\ *P Configuration is managed by the SAPI

target

[defined] IOProfiling? [if]
variable c_emit
variable c_type
variable c_type_chars
variable c_cr
variable c_key
[then]

\ ********************
\ *S Serial primitives
\ ********************
internal

\ : +FaultConsole	( -- )  ;
\ *G Because this is a polled driver, *\fo{+FaultConsole} for
\ ** fault handling is a *\fo{NOOP}. See *\i{Cortex/FaultCortex.fth}
\ ** for more details.

target

\ CODE (seremitfc)	\ char base --
\ This is a system call.

: (seremit)	\ char base -- 
\ *G Wrapped call that checks for throttling, and if so,
\ calls PAUSE to let another task run, or just does a WFI if no multitasker.
\ The only interesting thing is failure, or -1.  That means retry.
	\ 1 c_emit +! 
    (seremitfc) if [ tasking? ] [if] PAUSE [else] [asm wfi asm] [then] then 
	;

: (sertype) \ caddr len base --
\ *G Transmit a string on the given UART.
  \ 1 c_type +!
  \ over c_type_chars +!
 
  -rot bounds
  ?do  i c@ over (seremit)  loop
  drop
;

: (sercr)	\ base --
\ *G Transmit a CR/LF pair on the given UART.
   \ 2 c_cr +!
   $0D over (seremit)  $0A swap (seremit)
;

: (serkey) \ base -- c
\ *G Get a character from the port.  Retry until we get it.
\ The system call will stop the task and restart it when there is data.
\ See if its negative.  If so, discard it and leave false to re-loop.
\ If not negative, leave true on the stack to exit.
    begin \ base ret t/f 
	dup (serkeyfc) dup 0 <  \ base ret t/f 
	 \ If we have been blocked, drop the useless returned data and try again.
	 IF [ tasking? ] [if] PAUSE [else] [asm wfi asm] [then] drop false 
	 ELSE true \ Leave the return code intact.
	 THEN \ base ret t/f 
	until  \ base ret 
	swap drop 
    \ 1 c_key +!
;

\ THis is a system call.
\ CODE (serkey?)     \ base -- t/f
\ *G Return true if the given UART has a character avilable to read.

external 

: seremit0	\ char --
\ *G Transmit a character on UART0.
  0 (seremit)  ;
: sertype0	\ c-addr len --
\ *G Transmit a string on UART0.
  0 (sertype)  ;
: sercr0	\ --
\ *G Issue a CR/LF pair to UART0.
  0 (sercr)  ;
: serkey?0	\ -- flag
\ *G Return true if UART0 has a character available.
  0 (serkey?)  ;
: serkey0	\ -- char
\ *G Wait for a character on UART0.
  0 (serkey)  ;
create Console0	\ -- addr ; OUT managed by upper driver
\ *G Generic I/O device for UART0.
  ' serkey0 ,		\ -- char ; receive char
  ' serkey?0 ,		\ -- flag ; check receive char
  ' seremit0 ,		\ -- char ; display char
  ' sertype0 ,		\ caddr len -- ; display string
  ' sercr0 ,		\ -- ; display new line

\ --------------------------------------------------------------------
\ Optional devices
\ --------------------------------------------------------------------
[defined] useUART1? [if]   useUART1? 1 = [if] 
: seremit1 #1 (seremit)  ;
: sertype1 #1 (sertype)  ;
: sercr1   #1 (sercr)  ;
: serkey?1 #1 (serkey?)  ;
: serkey1  #1 (serkey)  ;
create Console1 ' serkey1 , ' serkey?1 , ' seremit1 , ' sertype1 , ' sercr1 ,	
[then]  [then]

\ --------------------------------------------------------------------
\ Non-UARTs.
\ --------------------------------------------------------------------
[defined] useStream10? [if] useStream10? 1 = [if] 
: seremit10 #10 (seremit)  ;
: sertype10	#10 (sertype)  ;
: sercr10	#10 (sercr)  ;
: serkey?10	#10 (serkey?)  ;
: serkey10	#10 (serkey)  ;
create Console10 ' serkey10 , ' serkey?10 , ' seremit10 , ' sertype10 , ' sercr10 ,	
[then]  [then]

[defined] useStream11? [if] useStream11? 1 = [if] 
: seremit11 #11 (seremit)  ;
: sertype11	#11 (sertype)  ;
: sercr11	#11 (sercr)  ;
: serkey?11	#11 (serkey?)  ;
: serkey11	#11 (serkey)  ;
create Console11 ' serkey11 , ' serkey?11 , ' seremit11 , ' sertype11 , ' sercr11 ,	
[then]  [then]



console-port 0 = [if]
  console0 constant console
\ *G *\fo{CONSOLE} is the device used by the Forth system for interaction.
\ ** It may be changed by one of the phrases of the form:
\ *C   <device>  dup opvec !  ipvec !
\ *C   <device>  SetConsole
[then]

console-port  #10 = [if]
  console10 constant console
[then]

\ ************************
\ *S System initialisation
\ ************************

\ This is a NOP in the SAPI environment
: init-ser ;	\ --
\ *G Initialise all serial ports

\ ======
\ *> ###
\ ======

decimal
