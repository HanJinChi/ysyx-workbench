#include <am.h>
#include <klib.h>
#include <rtthread.h>

typedef struct 
{
  void (*tentry)(void* );
  void *parameter;
  void (*texit)();
}package;


void entry_kcontext(void *arg){
  package* pa = (package*)arg;
  // printf("get tentry is 0x%x\n", (uintptr_t)pa->tentry);
  pa->tentry(pa->parameter);
  pa->texit();
}

rt_ubase_t from_pointer = 0;
rt_ubase_t to_pointer = 0;

static Context* ev_handler(Event e, Context *c) {
  switch (e.event) {
    case EVENT_YIELD: 
      if(from_pointer) *(Context**)from_pointer = c;
      c = (*(Context**)to_pointer);
      break;
    default: printf("Unhandled event ID = %d\n", e.event); assert(0);
  }
  return c;
}

void __am_cte_init() {
  cte_init(ev_handler);
}

void rt_hw_context_switch_to(rt_ubase_t to) {
  from_pointer = 0;
  to_pointer = to;
  // printf("to_pointer point to 0x%x\n", *(Context**)to_pointer);
  yield();
}

void rt_hw_context_switch(rt_ubase_t from, rt_ubase_t to) {
  from_pointer = from;
  to_pointer = to;
  // printf("to_pointer point to 0x%x\n", *(Context**)to_pointer);
  yield();
}

void rt_hw_context_switch_interrupt(void *context, rt_ubase_t from, rt_ubase_t to, struct rt_thread *to_thread) {
  assert(0);
}

rt_uint8_t *rt_hw_stack_init(void *tentry, void *parameter, rt_uint8_t *stack_addr, void *texit) {
  package* pa = (package*)((uintptr_t)stack_addr-sizeof(Context)-sizeof(package)-1024);
  pa->parameter = parameter;
  pa->tentry = tentry;
  pa->texit = texit;
  Context* c = kcontext((Area){0, (void*)stack_addr}, entry_kcontext, (void*)pa);
  // printf("context is 0x%x, stack_addr is 0x%x, tentry is 0x%x, store pa is 0x%x\n", (uintptr_t)c, stack_addr, tentry, (void*)pa);
  return (rt_uint8_t *)c;
}
