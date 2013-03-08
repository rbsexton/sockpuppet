\ Code to support runtime/dynamic into the C side via SAPI.

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
: dy.namelen #9 + c@ ;
: dy.name   #12 +  @ ;

\ Return the recordlength.  Its the first thing.
: dy-recordlen getsharedvars @ ;

\ Heres some assembly code to use as a template.
\ I experimented a bit, and the simplest thing in the MPE
\ Forth environment is to lay down the assembly
((
CODE rawconstant
	str tos, [ psp, # -4 ] ! \ register push
    ldr tos, L$1
	bx lr
L$1: str tos, [ psp, # -4 ] ! \ 32-bit dummy instruction
END-CODE
))

\ Create a constant from scratch by laying down some assembly
\ A key trick is that we have to lay down a pointer to 
\ the first character of the defintion after we finish
\ See the definition above for the template
: make-const \ n s-addr c --
	here 4+ >r \ This should point to the newly-created header.
	makeheader \
	
\ ( 0002:0270 4CF8047D Lx.} )  str r7, [ r12, # $-04 ]!
\ ( 0002:0274 004F .O )        ldr r7, [ PC, # $00 ] ( @$20278=$7D04F84C )
\ ( 0002:0276 7047 pG )        bx LR

	$7D04F84C , \  str r7, [ r12, # $-04 ]!
	$4f00 w,    \  ldr r7, [ PC, # $00 ]
	$4770 w,    \ bx LR
	, 	        \ Lay down the payload

	r> ,        \ lay down the link field for the next word - required
	;
	
\ Dump out an entry as a set of constants
: dy-print \ c-addr --
     S" $" type
     DUP dy.val .    \ Fetch the value
     
     DUP dy.type [CHAR] V = \ check the type 
     
     IF
     	S" VALUE "
     ELSE
     	S" CONSTANT "
     THEN
     TYPE \ Display the result
     DUP dy.size . S" x" DUP dy.count .
     dy-string TYPE
     CR
   ; 

\ Take a pointer to a dynamic link record, and add a constant to the dictionary
: dy-create \ addr --
	DUP \ addr addr 
	dy.val \ c-addr n 
	SWAP dy-string \ n c-addr b
    make-const
    ;


\ Walk the table and make the constants.
: dy-populate
  getsharedvars dy-recordlen + \ Skip over the empty first record
  BEGIN  
     dup dy.val 0<> 
  WHILE
     dup dy-create
     dy-recordlen +
  REPEAT
  2DROP R> DROP 0
  ;   
    
