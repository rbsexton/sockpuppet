\ serCM3_sapi_level0.fth - SAPI polled RX, polled TX, serial communication drivers
\ Written to run against the SockPuppet API.

\ Level 0 support, with WFI instead of pause.
\ The SAPI is a system call interace, so there is no blocking.
\ KEY requires blocking, so that must be implemented here.

\ Copyright (c) 2016, Robert Sexton.  All rights reserved.
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

\ ********************
\ *S Serial primitives
\ ********************
internal

: +FaultConsole	( -- )  ;
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
	begin 
	2dup (seremitfc) dup 0 < \ char base ret t/f
	IF [ tasking? ] [if] PAUSE [else] [asm wfi asm] [then] THEN \ char base ret 
    0 >= until
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

: (serkey) \ base -- c
\ *G Get a character from the port.  Retry until we get it.
\ See if its negative.  If so, discard it and leave false to re-loop.
\ If not negative, leave true on the stack to exit.
    begin \ base ret t/f 
	dup (serkeyfc) dup 0 <  \ base ret t/f 
	 IF [ tasking? ] [if] PAUSE [else] [asm wfi asm] [then] drop false 
	 ELSE true 
	 THEN \ base ret t/f 
	until  \ base ret 
	swap drop 
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

\ Non-UARTs.
: seremit10 #10 (seremit)  ;
: sertype10	#10 (sertype)  ;
: sercr10	#10 (sercr)  ;
: serkey?10	#10 (serkey?)  ;
: serkey10	#10 (serkey)  ;
create Console10 ' serkey10 , ' serkey?10 , ' seremit10 , ' sertype10 , ' sercr10 ,	

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
