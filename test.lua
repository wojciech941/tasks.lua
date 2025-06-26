local task_t = require("tasks.lua")

local _benchmark = (function()
  local ffi = require("ffi")

  if jit.os == "Windows" then
    ffi.cdef [[
      int QueryPerformanceCounter(long long*);
      int QueryPerformanceFrequency(long long*);
    ]]

    local freq = ffi.new("long long[1]")
    ffi.C.QueryPerformanceFrequency(freq)

    return function(fmt, func, ...)
      local t = ffi.new("long long[2][1]")
      ffi.C.QueryPerformanceCounter(t[0])
      func(...)
      ffi.C.QueryPerformanceCounter(t[1])
      local ns = (t[1][0] - t[0][0]) * 1e9 / freq[0]
      print(("%s: %s ns (~%s ms)"):format(fmt, ns, ns / 10e5))
    end
  else
    return function(fmt, func, ...)
      local s = os.clock()
      func(...)
      local f = os.clock()
      print(("%s: %s s"):format(ms, f - s))
    end
  end
end)()

local TEST = 10

for _ = 1, TEST do
  collectgarbage("stop")
  local TASK = 1000
  local PUSH = 1000

  local EXPECTED = TASK * PUSH
  local COMPLETED = 0

  local function foo()
    COMPLETED = COMPLETED + 1
  end

  print(("Test #%s [Task: %s | Push: %s | Expected: %s]"):format(_, TASK, PUSH, EXPECTED))

  _benchmark("constructor/push/join", function()
    for _ = 1, TASK do
      local timer = task_t()
      for _ = 1, PUSH do
        timer:push(-1, foo)
      end
      timer:join()
    end
  end)

  _benchmark("consume", function()
    for i = 0, 0 do
      task_t.consume()
    end
  end)

  collectgarbage("restart")
  collectgarbage()

  assert(EXPECTED == COMPLETED, ("Failed\nExpected: %s\nCompleted: %s\n"):format(EXPECTED, COMPLETED))
  print(("Passed [Completed: %s]\n"):format(COMPLETED))
end
