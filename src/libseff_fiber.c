#include <fiber.h>
#include <seff.h>
#include <seff_types.h>

#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

DEFINE_EFFECT(co_yield, 0, void*, { void *arg; });

struct fiber {
  bool fresh;
  fiber_entry_point_t entry;
  seff_coroutine_t *rc;
  void *arg;
};

static void* trampoline(void* fiberp) {
  fiber_t fiber = (fiber_t)fiberp;
  return fiber->entry(fiber->arg);
}

fiber_t fiber_alloc(fiber_entry_point_t entry) {
  fiber_t fiber = (fiber_t)malloc(sizeof(struct fiber));
  fiber->fresh = true;
  fiber->entry = entry;
  fiber->rc = seff_coroutine_new(trampoline, fiber);
  fiber->arg = NULL;
  return fiber;
}

void fiber_free(fiber_t fiber) {
  seff_coroutine_delete(fiber->rc);
  free(fiber);
}

void* fiber_yield(void *arg) {
  return PERFORM(co_yield, arg);
}

void* fiber_resume(fiber_t fiber, void *arg, fiber_result_t *status) {
  if (fiber->fresh) {
    fiber->fresh = false;
    fiber->arg = arg;
  }

  seff_request_t request = seff_resume(fiber->rc, arg, HANDLES(co_yield));

  switch (request.effect) {
    CASE_EFFECT(request, co_yield, {
        *status = FIBER_YIELD;
        return payload.arg;
        break;
      });
    CASE_RETURN(request, {
        *status = FIBER_OK;
        return payload.result;
      });
  default:
    assert(false);
  }
}


void fiber_init(void) {
  // Noop
}

void fiber_finalize(void) {
  // Noop
}
