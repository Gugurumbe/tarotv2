#ifndef STUBS_PRIVATE_TAROTV_VALUE
#define STUBS_PRIVATE_TAROTV_VALUE

#include <caml/mlvalues.h>
#include <caml/callback.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#include "stubs.h"

struct tarotv_value * copy_value_from_caml(value v);
value copy_value_to_caml(struct tarotv_value * v);

#endif
