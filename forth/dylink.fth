\ Code to support runtime/dynamic into the C side via SAPI.
\
\ In the MPE environment, VALUEs work very well for this.
\ values are defined at compile time and can be updated at runtime.

\ So the basic logic is - walk the dynamic list, and if you find something
\ that is already defined, assume its a VALUE
\ otherwise, generate a constant.

\ Copyright (c) 2011-2016, Robert Sexton.  All rights reserved.
\ Covered by the terms of the supplied Licence.txt file


\ Walk the table and make the constants.
: dy-populate
  dy-first 
  begin  
     dup dy.val 0<> 
  while
     dup dy-create
     dy-next
  repeat
  drop
  ;   

\ The key bit.  Look for an entry and if its a value, update it.
\ otherwise, add a constant to the dictionary.
: dy-create ( c-addr -- )
        \ Start by looking it up
        DUP dy.name count pad place \ Make a counted string out of it.

        pad find 
        0= IF \ If failure, cleanup and make-const 
                2DROP \ Drop the length and pointer.
                dup dy.val \ c-addr n 
                over dy.name count \ n c-addr b
                make-const
        ELSE \ If Success, get the value and stuff it in there.
                SWAP dy.val \ Fetch the value
                SWAP dy-stuff
        THEN
    ;




: dy-first   ( -- c-addr ) getsharedvars dy-recordlen + ; 
: dy-next    ( c-addr -- c-addr ) dy-recordlen + ; 

\ ************************************************************************
\ ************************************************************************
\ Secondary support functions 
\ ************************************************************************
\ ************************************************************************

\ *********************************************
\ Accessors - Tightly tied the data structure
\ *********************************************
: dy.val           @ ;  
: dy.size    #4 + w@ ; 
: dy.count   #6 + w@ ; 
: dy.type    #8 + c@ ;
: dy.name    #9 +    ; \ Counted string.

UDATA \ We need a scratch buffer.
create dy.buf $20 allot
CDATA

\ Return the recordlength.  Its the first thing.
: dy-recordlen getsharedvars @ ;

: dy-string ( addr -- caddr n ) 
  dy.name count
;  

\ Create a constant from scratch by laying down some assembly
\ A key trick is that we have to lay down a pointer to 
\ the first character of the defintion after we finish
\ See the definition above for the template
: make-const \ n s-addr c --
	here 4+ >r \ This should point to the newly-created header.
	makeheader \

\ This is what a constant looks like after emerging from the compiler.	
\ ( 0002:0270 4CF8047D Lx.} )  str r7, [ r12, # $-04 ]!
\ ( 0002:0274 004F .O )        ldr r7, [ PC, # $00 ] ( @$20278=$7D04F84C )
\ ( 0002:0276 7047 pG )        bx LR

	$7D04F84C , \  str r7, [ r12, # $-04 ]!
	$4f00 w,    \  ldr r7, [ PC, # $00 ]
	$4770 w,    \ bx LR
	, 	        \ Lay down the payload

	r> ,        \ lay down the link field for the next word - required
	;

\ Take an XT of a VALUE, and stuff something in there.
: dy-stuff ( n xt -- )  $8 + @ ! ; 

\ Dump out an entry as a set of constants
: dy-print \ c-addr --
     S" $" type
     DUP dy.val .    \ Fetch the value
     
     DUP dy.type [CHAR] V = \ check the type 
     
     IF
     	S" VALUE "
     ELSE
     	S" CONSTANT "
     THEN type \ Display the result
     dup dy.size . ." x " DUP dy.count .
     dy-string TYPE
     CR
   ; 

\ Given a record address and a string, figure out
\ if thats the one we're looking for
: dy-compare ( caddr n addr -- n )  
  dy-string compare  
;

\ Walk the list and find a string.
: dy-find ( c-addr n -- addr|0 ) 
  dy-first
  >R \ Put it onto the return stack
  BEGIN
   R@ dy.val 0<>
  WHILE 
   2DUP R@ dy-compare
   \ If we find it, clean the stack and leave the address on R
   0= IF 2DROP R> EXIT THEN
   R> dy-recordlen + >R
  REPEAT
  \ If we fall out, there will be a string caddr/n on the stack
  2DROP R> DROP 
  0 \ Leave behind a zero to indicate failure
;

