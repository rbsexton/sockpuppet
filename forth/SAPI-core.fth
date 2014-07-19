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
#4 equ SAPI_VEC_GETCHARAVAIL
#5 equ SAPI_VEC_PUTCHARHASROOM
#6 equ SAPI_VEC_SET_IO_CALLBACK
#7 equ SAPI_VEC_GETMS

#10 equ SAPI_VEC_STARTAPP
#11 equ SAPI_VEC_MPULOAD
#12 equ SAPI_VEC_PRIVMODE
#13 equ SAPI_VEC_USAGE
#14 equ SAPI_VEC_PETWATCHDOG

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
\ Do a stack switch and startup the user App.  Its a one-way
\ trip, so don't worry about stack cleanup.
\ **********************************************************************
CODE RestartForth ( c-addr ) \ -- 
	mov r0, tos
	svc # SAPI_VEC_STARTAPP
	next,
END-CODE

\ **********************************************************************
\ Request Privileged Mode.  In some systems, this is a huge
\ Security hole.
\ **********************************************************************
CODE privmode  \ -- 
	svc # SAPI_VEC_PRIVMODE
	next,
END-CODE

\ **********************************************************************
\ Ask for MPU entry updates.
\ **********************************************************************
CODE MPULoad  \ -- 
	mov r0, tos
	svc # SAPI_VEC_MPULOAD
	ldr tos, [ psp ], # $04	
	next,
END-CODE

\ **********************************************************************
\ Refresh the watchdog
\ **********************************************************************
CODE PetWatchDog  \ -- 
	svc # SAPI_VEC_PETWATCHDOG
	next,
END-CODE

\ **********************************************************************
\ Return Millisecond ticker value.
\ **********************************************************************
CODE Ticks  \ -- n 
	svc # SAPI_VEC_GETMS
	str tos, [ psp, # -4 ] !
	mov tos, r0
	next,
END-CODE

\ **********************************************************************
\ The number of CPU cycles consumed in the last second.
\ **********************************************************************
CODE GetUsage  \ -- n 
	svc # SAPI_VEC_USAGE
	str tos, [ psp, # -4 ] !
	mov tos, r0
	next,
END-CODE

\ **********************************************************************
\ Set the IO Callback address for a stream.
\ iovec, read/write (r=1), address to set as zero.
\ Note the minor parameter swizzle here to keep the old value on TOS.
\ **********************************************************************
CODE SetIOCallback  \ addr iovec read/write -- n 
	mov r1, tos
	ldr r0, [ psp ], # 4 !
	ldr r2, [ psp ], # 4 !
   	svc # SAPI_VEC_SET_IO_CALLBACK
	mov tos, r0
	next,
END-CODE



