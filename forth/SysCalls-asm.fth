\ Wrappers for SAPI functions, ABI 2.x

\ Note that the system call number is embedded into the instruction,
\ so this is not so easily parameterized.

#0 equ SAPI_VEC_VERSION
#1 equ SAPI_VEC_01_GetRuntimeLinks
#2 equ SAPI_VEC_02_PutChar
#3 equ SAPI_VEC_03_GetChar
#4 equ SAPI_VEC_04_GetCharAvail
#5 equ SAPI_VEC_05_PutString
#6 equ SAPI_VEC_06_EOL
#12 equ SAPI_VEC_12_WakeRequest
#14 equ SAPI_VEC_14_PetWatchdog
#15 equ SAPI_VEC_15_GetTimeMS

CODE SAPI-Version  \ -- n
\ *G Get the version of the binary ABI in use. 
	svc # SAPI_VEC_VERSION 
	sub .s psp, # 4
	str tos, [ psp, # 0 ] 
	mov tos, r0
	next,
END-CODE

CODE GETRUNTIMELINKS  \ type -- n
\ *G Get the runtime linking information.   Type 0 - A Dynamic linking 
\ ** table with name, address pairs.  Type 1 - A Zero-Terminated Jump table.
	mov r0, tos
	svc # SAPI_VEC_01_GetRuntimeLinks 
	mov tos, r0
	next,
END-CODE

\ --------------------------------------------
\ System calls that will require wrappers
\ --------------------------------------------

CODE (SEREMITFC) \ char base --
\ *G Service call for a single char - This one has a special name because
\ ** It'll be wrapped by something that can respond to the flow control 
\ ** return code and PAUSE + Retry 
	mov r0, tos
Cortex-M0? [if]
	ldm psp ! { r1 } 
[else]
	ldr r1, [ psp ], # 4
[then]
	mov r2, up 
	svc # SAPI_VEC_02_PutChar	
	mov tos, r0
    next,
END-CODE

CODE (SERKEYFC) \ base -- char  
\ *G Get a character from the port, or -1 for fail
	mov r0, tos	
	mov r1, up  
	svc # SAPI_VEC_03_GetChar
	mov tos, r0
	next,
END-CODE

CODE (SERTYPEFC) \ caddr len base -- return  
\ *G Output characters.  
	mov r0, tos	
	ldm psp ! { r1, r2 } 
	mov r3, up 
	svc # SAPI_VEC_05_PutString
	mov tos, r0
	next,
END-CODE

CODE (SERCRFC) \ base -- return  
\ *G Send a line terminator to the port.  Return 0 for success, -1 for fail.
	mov r0, tos	
	mov r1, up 
	svc # SAPI_VEC_06_EOL
	mov tos, r0
	next,
END-CODE

\ --------------------------------------------
\ Direct substitutes for existing stuff.
\ --------------------------------------------

CODE (SERKEY?) \ base -- t/f
\ *G Return true if the given stream has a character avilable to read.
\ The call returns the number of chars available.  
	mov r0, tos
	svc # SAPI_VEC_04_GetCharAvail
	mov tos, r0
	next,
END-CODE

CODE PETWATCHDOG  \ n --
\ *G Refresh the watchdog.  Pass in a platform-specific number
\ ** To specify a timerout (if supported), or zero for the default value. 
	mov r0, tos
	svc # SAPI_VEC_14_PetWatchdog
Cortex-M0? [if]
	ldm psp ! { tos } 
[else]
	ldr tos, [ psp ], # 4
[then]
	next,
END-CODE

: push0 0 ; 

CODE TICKS  \ -- n 
\ *G The current value of the millisecond ticker.
        mov .s r0, # 0 \ We want the actual value.
	svc # SAPI_VEC_15_GetTimeMS
	sub .s psp, # 4
	str tos, [ psp, # 0 ] 
	mov tos, r0
	next,
END-CODE

CODE WAKEREQ \ event arg -- t/f  
\ *G Request a wake of the current task.  Implementation Defined.
\ ** Includes an arguement swap...
Cortex-M0? [if]
	ldm psp ! { r0 } 
[else]
	ldr r0, [ psp ], # 4
[then]
	mov r1, tos	
	mov r2, up  
	svc # SAPI_VEC_12_WakeRequest
	mov tos, r0
	next,
END-CODE

