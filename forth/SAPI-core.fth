\ Wrappers for SAPI Core functions
\ SVC 0: Return the version of the API in use.
\ SVC 1: Return the address of the shared variables table
\ SVC 2: putchar
\ SVC 3: getchar
\ SVC 4: charsavail

\ SVC 5: LaunchUserApp
\ SVC 6: Reserved
\ SVC 7: Reserved

\ SVC 8: Watchdog Refresh
\ SVC 9: Return Millisecond ticker value.
\ SVC 10: The number of CPU cycles consumed in the last second.

\ 2-4 are for use by the serial io routines, and are 
\ defined elsewhere.

\ Note that the system call number is embedded into the instruction,
\ so this is not so easily parameterized.

#0 equ SAPI_VEC_VERSION
#1 equ SAPI_VEC_VARS
#2 equ SAPI_VEC_PUTCHAR
#3 equ SAPI_VEC_GETCHAR
#4 equ SAPI_VEC_CHARSAVAIL
#5 equ SAPI_VEC_STARTAPP

#8 equ SAPI_VEC_PETWATCHDOG
#9 equ SAPI_VEC_USAGE
#10 equ SAPI_VEC_GETMS

\ **********************************************************************
\ SVC 0: Return the version of the API in use.
\ **********************************************************************
CODE SAPI-Version  \ -- n 
	\ Push TOS, and place the result there.	
	svc # SAPI_VEC_VERSION 
	str tos, [ psp, # -4 ] !
	mov tos, r0
	next,
END-CODE

\ **********************************************************************
\ SVC 1: Get the address of the shared variable list
\ **********************************************************************
CODE GetSharedVars  \ -- n 
	svc # SAPI_VEC_VARS 
	str tos, [ psp, # -4 ] !
	mov tos, r0
	next,
END-CODE

\ **********************************************************************
\ SVC 5: Do a stack switch and startup the user App.
\ **********************************************************************
CODE StartForth  \ -- 
	svc # SAPI_VEC_STARTAPP
	next,
END-CODE

\ **********************************************************************
\ SVC 8: Refresh the watchdog
\ **********************************************************************
CODE PetWatchDog  \ -- 
	svc # SAPI_VEC_PETWATCHDOG
	next,
END-CODE

\ **********************************************************************
\ SVC 9: Return Millisecond ticker value.
\ **********************************************************************
CODE Ticks  \ -- n 
	svc # SAPI_VEC_GETMS
	str tos, [ psp, # -4 ] !
	mov tos, r0
	next,
END-CODE

\ **********************************************************************
\ SVC 10: The number of CPU cycles consumed in the last second.
\ **********************************************************************
CODE GetUsage  \ -- n 
	svc # SAPI_VEC_USAGE
	str tos, [ psp, # -4 ] !
	mov tos, r0
	next,
END-CODE

