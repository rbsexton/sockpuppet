// Level 0 
// Wrappers around USART Functions.
// These are named with leading unscores so that the system calls 
// can have the expected names.
//
// These drivers are labeled with _USART so that they can 
// be used with displachers for multiple stream types: 
// int __SAPI_02_PutChar(int c, int channel) {
//   if ( channel < 10 ) return(__SAPI_02_PutChar_USART(c, stream))
//   else return(__SAPI_02_PutChar_Network(c, stream))
//  }


#include <stdint.h>
#include <stdbool.h>

//  
#include "stm32f0xx.h"

#include "stm32f0xx_ll_bus.h"
#include "stm32f0xx_ll_usart.h"

#include "stm32_usart_level0.h"

// A Basic driver for SAPI without callbacks or interrupts.

// USART Table.   There is no USART0 on my device. 

static const unsigned int  uarts[] = {
            0,  USART1_BASE,  USART2_BASE,  USART3_BASE,
  USART4_BASE,  USART5_BASE,  USART6_BASE,  USART7_BASE
  };

// --------------------------------------------------------------
// Blocking & Non-Blocking  putchar.
// Use -1 to get a flush. 
// This version doesn't support tcbs.
// Returns the amount of space left, or -1 for failure. 
// --------------------------------------------------------------
int __SAPI_PutCharGeneral_USART(int c, int stream, bool blocking) {
  unsigned int base = uarts[stream];
  
  if ( c < 0 ) {
    while (! LL_USART_IsActiveFlag_TC( (USART_TypeDef *) base)) { ; };		
    return(1);
    }	

  if ( blocking ) {
    while (! LL_USART_IsActiveFlag_TXE( (USART_TypeDef *) base)) { ; };
    LL_USART_TransmitData8( (USART_TypeDef *) base,c);
    return(0);
  }	

  // See if there is room first.
  if ((! LL_USART_IsActiveFlag_TXE( (USART_TypeDef *) base)) ) return(-1);
  
  LL_USART_TransmitData8( (USART_TypeDef *) base,c);

  // This device only has one byte worth of FIFO.   Its full now.
  return(0);
  }

int __SAPI_02_PutChar_USART(int c, int stream) {
  return(__SAPI_PutCharGeneral_USART(c,stream,true) );
  }

int __SAPI_07_PutCharNonBlocking_USART(int c, int stream) {
  return(__SAPI_PutCharGeneral_USART(c,stream,false) );
}

// --------------------------------------------------------------
// blocking getchar.   Non-blocking is potentially better, 
// but that breaks the existing conventions.
// --------------------------------------------------------------
int __SAPI_03_GetChar_USART(int stream) {
  unsigned int base = uarts[stream];
  
  // Spin until there is a character.
  while (! LL_USART_IsActiveFlag_RXNE( (USART_TypeDef *) base)) { ; };		

  return ( ((USART_TypeDef *) base)->RDR );
  }

// --------------------------------------------------------------
// Check for characters in the FIFO.
// --------------------------------------------------------------
int __SAPI_04_GetCharAvail_USART(int stream) {
  unsigned int base = uarts[stream];
  if (LL_USART_IsActiveFlag_RXNE( (USART_TypeDef *) base)) return(1);
  else return(0);
  }

// --------------------------------------------------------------
// Check for characters in the FIFO.
// --------------------------------------------------------------



