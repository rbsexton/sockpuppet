// Level 0 
// Wrappers around USART Functions.
// These are named with leading unscores so that the system calls 
// can have the expected names.
//
// Interrupt support with ringbuffers from 
// https://github.com/rbsexton/cm3lib.git
//
// These drivers are labeled with _USART so that they can 
// be used with displachers for multiple stream types: 
// int __SAPI_02_PutChar(int c, int channel) {
//   if ( channel < 10 ) return(__SAPI_02_PutChar_USART(c, stream))
//   else return(__SAPI_02_PutChar_Network(c, stream))
//  }
//
// Required #defines:
// USART_INPUT_RBSIZE, USART_OUTPUT_RBSIZE
// Powers 2.   
//
// Required Initialization
/*
// UART needs to be higher priority than SVC.   I don't recall why 
   NVIC_SetPriority( USART2_IRQn, 0x40);
   
   // Hardware Initialization
  LL_USART_Init(USART2, (LL_USART_InitTypeDef *) &USART_Init);
  LL_USART_EnableIT_TC(USART2);
  LL_USART_EnableIT_RXNE(USART2);
  LL_USART_Enable(USART2);
 
*/


#include <stdint.h>
#include <stdbool.h>
#include <string.h>

//  
#include "stm32f0xx.h"

#include "stm32f0xx_ll_bus.h"
#include "stm32f0xx_ll_usart.h"

#include "stm32_usart_level0.h"

#include "ringbuffer.h"

// A Basic driver for SAPI without callbacks or interrupts.

// USART Table.   There is no USART0 on my device. 

static const unsigned int  uarts[] = {
            0,  USART1_BASE,  USART2_BASE,  USART3_BASE,
  USART4_BASE,  USART5_BASE,  USART6_BASE,  USART7_BASE
  };

#ifndef USART_INPUT_RBSIZE
#define USART_INPUT_RBSIZE 64
#endif 

#ifndef USART_OUTPUT_RBSIZE
#define USART_OUTPUT_RBSIZE 128 
#endif 


// This driver only supports a single active USART interface. 

static uint8_t usart_output_buf[USART_OUTPUT_RBSIZE];
static uint8_t usart_input_buf [USART_INPUT_RBSIZE];

static RINGBUF usart_output_ringbuffer;
static RINGBUF usart_input_ringbuffer;

// --------------------------------------------------------------
// Mandatory Initialization Function.   
// No side-effects 
// --------------------------------------------------------------
void sapi_init_usart() {
  memset(usart_output_buf, 0, sizeof(usart_output_buf));
  memset( usart_input_buf, 0, sizeof( usart_input_buf));
  
	ringbuffer_init(&usart_output_ringbuffer, usart_output_buf, sizeof(usart_output_buf) );
  ringbuffer_init(&usart_input_ringbuffer,  usart_input_buf,  sizeof(usart_input_buf) );
}

// --------------------------------------------------------------
// Helper functions
// --------------------------------------------------------------
static void USART_ofifo_drain(USART_TypeDef *base) {
  while (! LL_USART_IsActiveFlag_TC(base)) { ; };		
  }

// Drain the output FIFO and the ring buffer. 
static void USART_output_rbdrain(RINGBUF *r, USART_TypeDef *base) {
  while ( ringbuffer_used(r) ) {
      USART_ofifo_drain(base);
      LL_USART_TransmitData8(base,ringbuffer_getchar(r));
      }
  }

// Flush everthing.
static void USART_output_flush(RINGBUF *r, USART_TypeDef *base) {
  USART_output_rbdrain(r,base);
  USART_ofifo_drain(base);
  }

// --------------------------------------------------------------
// --------------------------------------------------------------
// Blocking putchar.
// Use -1 to get a flush. 
// This version doesn't support tcbs
// Return the amount of space free in the output queue, 
// or -1 if it failed.
// --------------------------------------------------------------
// --------------------------------------------------------------
static int __SAPI_PutCharGeneral_USART(
    int c, int stream, bool blocking) {
      
  unsigned int base = uarts[stream];
  
  RINGBUF *ring = &usart_output_ringbuffer;

  // Check for flush.
  if ( c < 0 ) {
    USART_output_flush(ring,(USART_TypeDef *) base);
    return(ringbuffer_free(ring));
    }	

  if ( blocking && ( ringbuffer_free(ring) == 0 ) ) return(-1);

  // Check for a full ringbuffer, and if so, make room in the 
  // hardware FIFO for a character so that we have a place 
  // to put the new character. 
  if ( ringbuffer_free(ring) == 0 ) { 
    USART_ofifo_drain((USART_TypeDef *) base);
    LL_USART_TransmitData8((USART_TypeDef *) base,ringbuffer_getchar(ring));
    ringbuffer_addchar(ring, c);
    return(ringbuffer_free(ring));
    }
  
  // The data will go in the ringbuffer, or the FIFO
  // At this point we know that there is room for it. 
  // Make a best effort to add data to the hardware fifo, then 
  // decide what to do.    We're usually writing faster than 
  // the USART can go, so the common case is ringbuffer add. 
  
  // If the hardware FIFO is full it goes into the ring buffer. 
  if ( ! LL_USART_IsActiveFlag_TXE((USART_TypeDef *) base) ) {
    ringbuffer_addchar(ring, c);      
    return(ringbuffer_free(ring));      
    }
  
  // Otherwise we pull from the ringbuffer and send that, 
  // or we send the data direct to the hardware.  
  if ( ringbuffer_used(ring) ) { // Send the stuff from the ring.
    LL_USART_TransmitData8( (USART_TypeDef *) base,ringbuffer_getchar(ring));
    ringbuffer_addchar(ring, c);      
    } 
  else { // Empty Ringbuffer.   Straight to hardware. 
      LL_USART_TransmitData8( (USART_TypeDef *) base,c);
    }

  return(ringbuffer_free(ring));        
  }

int __SAPI_02_PutChar_USART(int c, int stream) {
  return(__SAPI_PutCharGeneral_USART(c,stream,true) );
  }

int __SAPI_07_PutCharNonBlocking_USART(int c, int stream) {
  return(__SAPI_PutCharGeneral_USART(c,stream,false) );
}

// --------------------------------------------------------------
// --------------------------------------------------------------
// blocking getchar.   Non-blocking is potentially better, 
// but that breaks the existing conventions.
// Look in the ringbuffer first.
// --------------------------------------------------------------
// --------------------------------------------------------------
int __SAPI_03_GetChar_USART(int stream) {
  unsigned int base = uarts[stream];
  
  RINGBUF *ring = &usart_input_ringbuffer;

  if ( ringbuffer_used(ring) ) return(ringbuffer_getchar(ring));
  
  // Ok.  No data in the ringbuffer.  
  
  // Spin until there is a character.
  while (! LL_USART_IsActiveFlag_RXNE( (USART_TypeDef *) base)) { ; };		

  return ( ((USART_TypeDef *) base)->RDR );
  }


// --------------------------------------------------------------
// Check for characters in the FIFO.
// This returns an available character count.   
// Don't try to get cute by adding the ringbuffer and hardware
// FIFO sizes. 
// --------------------------------------------------------------
int __SAPI_04_GetCharAvail_USART(int stream) {
  unsigned int base = uarts[stream];
  RINGBUF *ring = &usart_input_ringbuffer;

  int used = ringbuffer_used(ring); 
  if ( used > 0 ) return(used);
  
  // Otherwise, check the hardware FIFO.  

  if (LL_USART_IsActiveFlag_RXNE( (USART_TypeDef *) base)) return(1);
  else return(0);
  }

// --------------------------------------------------------------
// The Actual USART Handler.
// This needs to be called by the front-line ISR handler: 
// void USART2_IRQHandler() {
//   Console_USART_IRQHandler(USART2)
//  }
// TODO: Make sure that this doesn't get stuck.   Will TXE 
// trigger over and over?
// --------------------------------------------------------------
int count_handler    = 0;
int count_handler_tx = 0;
int count_handler_rx = 0;
void Console_USART_IRQHandler(USART_TypeDef *base) {

  count_handler++;  

  // Clear the interrupts with a mask 
  base->ICR |= 0x121B5F; 
  uint32_t irq_status_reg = base->ISR; 

  // Output Queue space.
  if ( irq_status_reg & USART_ISR_TXE) {
    count_handler_tx++;
    RINGBUF *ring = &usart_output_ringbuffer;
    if (ringbuffer_used(ring)) 
      LL_USART_TransmitData8(base,ringbuffer_getchar(ring));
    }
    
  // Input Characters 
  if ( (irq_status_reg & USART_ISR_RXNE)  ) {
    count_handler_rx++;
    RINGBUF *ring = &usart_input_ringbuffer;
    ringbuffer_addchar(ring,base->RDR);    
    }		  		
  }

