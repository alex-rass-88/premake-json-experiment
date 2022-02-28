#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "minilua.h"
#include "sokol_time.h"

const int iterations = 1000000;
static uint64_t lua_time = 0;
static uint64_t cpp_time = 0;

double run_test_lua() {
  lua_State* lState = luaL_newstate();
  if (lState == NULL) {
    printf("filed create new state");
    return 0;
  }

  // init libs
  luaopen_base(lState);
  luaopen_coroutine(lState);
  luaopen_string(lState);
  luaopen_math(lState);
  luaopen_table(lState);

  int r = luaL_loadstring(
      lState,
      "function process(in1, in2, in3, in4, in5, in6, in7, in8, in9, in10)\n"
      "local result\n"
      "result = (in1 * in3) / (in5 * in7) + in9\n"
      "result = result / in10\n"
      "result = result / (in2 + in4) - (in6 + in8)\n"
      "return result\n"
      "end\n");
  if (r) {
    printf("filed load script: %s\n", lua_tostring(lState, -1));
    return 0;
  }
  // compile script
  lua_pcall(lState, 0, 0, 0);

  double input[10] = {
      1.0, 2.1, 3.2, 4.3, 5.4, 6.5, 7.6, 8.7, 9.8, 10.9,
  };

  double result = 0.0;

  uint64_t start = stm_now();

  for (size_t i = 0; i < iterations; ++i) {
    // find process
    lua_getglobal(lState, "process");

    // push args
    for (size_t i = 0; i < 10; ++i) {
      lua_pushnumber(lState, input[i]);
    }

    // call process
    lua_call(lState, 10, 1);

    // get result
    result = lua_tonumber(lState, -1);
    lua_pop(lState, 1);

    input[i % 10] = result;
  }

  lua_time = stm_since(start);
  printf("time per iteration: %f ms\n", stm_ms(lua_time));

  lua_close(lState);

  return result;
}

double process(double in1, double in2, double in3, double in4, double in5,
               double in6, double in7, double in8, double in9, double in10) {
  double result;

  result = (in1 * in3) / (in5 * in7) + in9;
  result = result / in10;
  result = result / (in2 + in4) - (in6 + in8);

  return result;
}

double run_test_cpp() {
  uint64_t start = stm_now();

  double input[10] = {
      1.0, 2.1, 3.2, 4.3, 5.4, 6.5, 7.6, 8.7, 9.8, 10.9,
  };

  double result = 0.0;

  for (size_t i = 0; i < iterations; ++i) {
    result = process(input[0], input[1], input[2], input[3], input[4], input[5],
                     input[6], input[7], input[8], input[9]);

    input[i % 10] = result;
  }

  cpp_time = stm_since(start);
  printf("time per iteration: %f ms\n", stm_ms(cpp_time));

  return result;
}

int main() {
  stm_setup();

  printf("Run Lua test:\n");
  printf("result: %f\n", run_test_lua());

  printf("Run CPP test:\n");
  printf("result: %f\n", run_test_cpp());

  printf("time scale: %f\n", (float)lua_time / (float)cpp_time);

  return EXIT_SUCCESS;
}
