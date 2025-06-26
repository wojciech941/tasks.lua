local task_t = require("tasks")

task_t():push(5, function()
    print("5 seconds passed")
end):join()

local t = task_t()
for i = 0, 9 do
  t:push(i, print, "passed", i)
end
t:join()

-- in loop
task_t.consume()
