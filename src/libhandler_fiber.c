#include <fiber.h>
#include <libhandler.h>

#include <stdint.h>
#include <stdlib.h>

LH_DEFINE_EFFECT1(co, yield);
LH_DEFINE_OP1(co, yield, lh_voidptr, lh_voidptr);

struct fiber {
  lh_resume rc;
  fiber_entry_point_t entry;
  void* arg;
};

static lh_voidptr trampoline(lh_voidptr fiberp) {
  fiber_t fiber = (fiber_t)lh_lh_voidptr_value(fiberp);
  return fiber->entry(fiber->arg);
}

LH_WRAP_FUN1(trampoline, lh_voidptr, lh_voidptr);

static lh_value co_return(lh_value local, lh_value x) {
  (void)local;
  return x;
}

static lh_value handle_co_yield(lh_resume rc, lh_value fiberp, lh_value payload) {
  fiber_t fiber = (fiber_t)lh_lh_voidptr_value(fiberp);
  fiber->rc = rc;
  return payload;
}

static const lh_operation ops[] = {
  { LH_OP_GENERAL, LH_OPTAG(co, yield), &handle_co_yield },
  { LH_OP_NULL, lh_op_null, NULL }
};

static const lh_handlerdef co_hdef = {
  LH_EFFECT(co), NULL, NULL, &co_return, ops
};

fiber_t fiber_alloc(fiber_entry_point_t entry) {
  fiber_t fiber = (fiber_t)malloc(sizeof(struct fiber));
  fiber->entry = entry;
  fiber->rc = NULL;
  return fiber;
}

void fiber_free(fiber_t fiber) {
  free(fiber);
}

void* fiber_yield(void *arg) {
  return co_yield(arg);
}

void* fiber_resume(fiber_t fiber, void *arg, fiber_result_t *status) {
  lh_value ans = 0;
  if (fiber->rc == NULL) {
    fiber->arg = arg;
    ans = lh_handle(&co_hdef, lh_value_lh_voidptr((void*)fiber), wrap_trampoline, lh_value_lh_voidptr((void*)fiber));
  } else {
    lh_resume rc = fiber->rc;
    fiber->rc = NULL;
    ans = lh_release_resume(rc, lh_value_lh_voidptr((void*)fiber), lh_value_lh_voidptr(arg));
  }

  *status = fiber->rc == NULL ? FIBER_OK : FIBER_YIELD;
  return lh_lh_voidptr_value(ans);
}


void fiber_init(void) {
  // Noop
}

void fiber_finalize(void) {
  // Noop
}
