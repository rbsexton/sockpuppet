// A Generic gadget for TCB manipulation.
// 
// Note that there is no need to describe the whole TCB, 
// just the parts that control sleep/wake.
// 
// This can be customized as needed

typedef struct {
  unsigned *next;
  unsigned *stack;
  unsigned control;
} sTask ;
  
#define RUN_MASK          0x1  
#define SLEEP_MASK ~(RUN_MASK)
  
#define TASK_WAKE(x)  ( ((sTask *)x)->control |= RUN_MASK   ) 
#define TASK_SLEEP(x) ( ((sTask *)x)->control &= SLEEP_MASK ) 

  