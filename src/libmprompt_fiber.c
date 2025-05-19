#include <fiber.h>
#include <mpeff.h>

#include <stdint.h>
#include <stdlib.h>

typedef void* voidptr_t;

#define mpe_voidp_voidptr_t(x) (x)
#define mpe_voidptr_t_voidp(x) (x)

MPE_DEFINE_EFFECT1(co, yield);
MPE_DEFINE_OP1(co, yield, voidptr_t, voidptr_t);

struct fiber {
  mpe_resume_t *rc;
  fiber_entry_point_t entry;
};

static void* handle_co_yield(mpe_resume_t* rc, void* fiberp, void* payload) {
  fiber_t fiber = (fiber_t)fiberp;
  fiber->rc = rc;
  return payload;
}

static const mpe_handlerdef_t co_hdef = {
  MPE_EFFECT(co), NULL, {
    { MPE_OP_ONCE, MPE_OPTAG(co, yield), &handle_co_yield },
    { MPE_OP_NULL, NULL, NULL }
  } };

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
  return mpe_perform(MPE_OPTAG(co, yield), arg);
}

void* fiber_resume(fiber_t fiber, void *arg, fiber_result_t *status) {
  void *ans = NULL;
  if (fiber->rc == NULL) {
    ans = mpe_handle(&co_hdef, fiber, fiber->entry, arg);
  } else {
    mpe_resume_t *rc = fiber->rc;
    fiber->rc = NULL;
    ans = mpe_resume(rc, fiber, arg);
  }

  *status = fiber->rc == NULL ? FIBER_OK : FIBER_YIELD;
  return ans;
}


void fiber_init(void) {
  // Noop
}

void fiber_finalize(void) {
  // Noop
}
