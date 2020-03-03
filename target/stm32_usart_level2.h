// Basic API. 

void sapi_init_usart();
void Console_USART_IRQHandler(USART_TypeDef *base);

int __SAPI_02_PutChar_USART           (int c, int stream);
int __SAPI_03_GetChar_USART           (int stream);
int __SAPI_04_GetCharAvail_USART      (int stream, unsigned *tcb);
int __SAPI_02_PutCharNonBlocking_USART(int c, int stream, unsigned *tcb);
