\ serCM3_sapi_p.fth - SAPI polled RX, polled TX, serial communication drivers
\ Written to run against the SockPuppet API.

((
Adapted from: the LPC polled driver.
))

only forth definitions
variable cnt.pause 

\ ==============
\ *! serCM3_sapi_p
\ *T SAPI polled serial driver
\ ==============
\ *P This driver provides polled serial comms for Cortex-M3 CPUs
\ ** using the internal UARTs via the SAPI call layer.


\ ****************
\ *S Configuration
\ ****************
\ *P Configuration is managed by the SAPI

\ ********
\ *S Tools
\ ********

target

\ ********************
\ *S Serial primitives
\ ********************

0 value sercallback 

internal

: +FaultConsole	( -- )  ;
\ *G Because this is a polled driver, *\fo{+FaultConsole} for
\ ** fault handling is a *\fo{NOOP}. See *\i{Cortex/FaultCortex.fth}
\ ** for more details.

target

CODE (seremitfc)	\ char base --
\ *G Service call for a single char - just fill in the registers
\ from the stack and make the call, and get back the flow control feedback
\ Put TOS into r0, pull r1 off the stack, and refresh the stack.
	mov r0, tos
	ldr r1, [ psp ], # 4	
	svc # SAPI_VEC_PUTCHAR	
	mov tos, r0
    next,
END-CODE

: (seremit)	\ char base -- 
\ *G Wrapped call that checks for throttling, and if so,
\ calls PAUSE to let another task run.  Count these events for debugging purposes.
	(seremitfc)
	0<> IF 1 cnt.pause +! #5 ms THEN
	;

: (sertype)	\ caddr len base --
\ *G Transmit a string on the given UART.
  -rot bounds
  ?do  i c@ over (seremit)  loop
  drop
;

: (sercr)	\ base --
\ *G Transmit a CR/LF pair on the given UART.
  $0D over (seremit)  $0A swap (seremit)
;

CODE (sergetchar) \ base -- c
\ *G Get a character from the port
	mov r0, tos	
	svc # SAPI_VEC_GETCHAR
	mov tos, r0
	next,
END-CODE

CODE (serkey?)     \ base -- t/f
\ *G Return true if the given UART has a character avilable to read.
\ The call returns 0 or 1.  
	mov r0, tos
	svc # SAPI_VEC_CHARSAVAIL		
	mov tos, r0
	next,	
END-CODE

: (serkey-basic)
	begin pause 
	dup (serkey?) until 
	(sergetchar)
;

: (serkey-sleep?)
	self tcb.bbstatus @ over 1 setiocallback drop ( base )
	self halt 
	dup (serkey?) IF self restart ELSE PAUSE THEN \ We are now armed and ready to block
    (serkey?) 
;

\ *G Wait for a character to come available on the given UART and
\ ** return the character.
\ Advanced usage - Register a callback. 
\ The tricky part is not screwing things up by missing a character
\ in the window between when you register, and when you pick up your
\ character.   The way to do that is by registering, then self 
\ halting, and then checking for a new character.  That ensures that
\ if a character has slipped in, you will catch it.
: (serkey)	\ base -- char
	begin dup (serkey-sleep?) until (sergetchar)
;

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

\ UART2
: seremit2      #2 (seremit)  ;
: sertype2	#2 (sertype)  ;
: sercr2	#2 (sercr)  ;
: serkey?2	#2 (serkey?)  ;
: serkey2	#2 (serkey)  ;
create Console2 ' serkey2 , ' serkey?2 , ' seremit2 , ' sertype2 , ' sercr2 ,	

\ Versions for use with the TCP Port (10)
: seremit10  #10 (seremit)  ;
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

console-port #1 = [if]
  console1 constant console
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
