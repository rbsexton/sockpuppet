//*****************************************************************************
//
// app_main.c
// 
// Bare bones client for testing.
// 
//*****************************************************************************
#include <stdint.h>
#include <string.h>

#include "sapi.h"

void SayHello() {
	char message[] = "Client Boot!\r\n";
	char* p;

	p = message;
	while(*p != 0) { 
		// UARTCharPut(UART_BASE,*p);
		SAPI_StreamPutChar(0,*p);
		p++;
		}
	}

//*****************************************************************************
// Main - Set things up, launch forth
//*****************************************************************************
// Let the C compiler know that it doesn't need to push any registers.
int main(void) __attribute__ ((naked));
int main(void) {
	SayHello();
	while(1) { 
		int x;
		if (SAPI_StreamCharsAvail(0) != 0 ) {
			x = SAPI_StreamGetChar(0);
			x++;
			SAPI_StreamPutChar(0,x);
			}
		}
	}

