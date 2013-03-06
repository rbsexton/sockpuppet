\ Wrappers for SAPI Core functions
\ SVC 0: Return the version of the API in use.
\ SVC 1: Return the address of the shared variables table
\ SVC 2: putchar
\ SVC 3: getchar
\ SVC 4: charsavail

\ SVC 5: Reserved
\ SVC 6: Reserved
\ SVC 7: Reserved

\ SVC 8: Watchdog Refresh
\ SVC 9: Return Millisecond ticker value.
\ SVC 10: The number of CPU cycles consumed in the last second.

\ 2-4 are for use by the serial io routines, and are 
\ defined elsewhere.

\ Note that the system call number is embedded into the instruction,
\ so this is not so easily parameterized.

\ **********************************************************************
\ SVC 0: Return the version of the API in use.
\ **********************************************************************
CODE SAPI-Version  \ -- n 
	\ Push TOS, and place the result there.	
	svc # 0 
	str tos, [ psp, # -4 ] !
	mov tos, r0
	next,
END-CODE

\ **********************************************************************
\ SVC 1: Get the address of the shared variable list
\ **********************************************************************
CODE GetSharedVars  \ -- n 
	svc # 1 
	str tos, [ psp, # -4 ] !
	mov tos, r0
	next,
END-CODE

\ **********************************************************************
\ SVC 8: Update the Watchdog Countdown.
\ **********************************************************************
CODE WDTKICK  \ n --  
	mov r0, tos
	svc # 8
	ldr tos, [ psp ], # 4
	next,
END-CODE

\ **********************************************************************
\ SVC 9: Return Millisecond ticker value.
\ **********************************************************************
CODE Ticks  \ -- n 
	svc # 9
	str tos, [ psp, # -4 ] !
	mov tos, r0
	next,
END-CODE

\ **********************************************************************
\ SVC 10: The number of CPU cycles consumed in the last second.
\ **********************************************************************
CODE GetUsage  \ -- n 
	svc # 10
	str tos, [ psp, # -4 ] !
	mov tos, r0
	next,
END-CODE

