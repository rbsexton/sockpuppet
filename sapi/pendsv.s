@ PendSV handler to launch forth on M3.
@ 
@ This re-starts forth by modifying the exception
@ return stack.
@
.data
.global pendsv_args
pendsv_args:
.int 0 @ address 
.int 0 @ target argument

.text
.global PendSV_Handler
PendSV_Handler:
	movs r0, #4
	mov  r1, lr 
	tst  r0, r1
	bne done
	add sp, sp, #32 @ Discard the supervisor stack frame\n"
done:	
	mov r1, #3 @ We want 0xFFFFFFFD, aka -3
	mvn r1, r1 
	mov lr, r1  @ Force Return into thread mode via PSP

	newpsp .req r1
	arg    .req r3

	ldr r0, =pendsv_args
	ldr arg, [ r0, # 4] @ Fetch the argument
	ldr r0, [ r0, # 0] @ Fetch the address of the client app. 

	ldr newpsp, [r0, #0 ] @ Retrieve the client PSP\n
	mov r2, #32 
	sub newpsp, newpsp, r2 @ Point it at the bottom of a fake stack frame

	str arg, [r1, #0]   @ New R0 = arg

	ldr r0, [r0, #4]  @ New PC 
	str r0, [newpsp, #24] @ Save it into the soon-to be unwound stack frame

	mov r2, #1 @ Final value: 0x01000000 (T) - Legal value for XPSR.
	lsl r2, r2, #24
	str r2, [newpsp, #28]  @ Into the stack

	msr psp, newpsp @ Load it into the process sp
	bx lr @ Return from the exception

.end
