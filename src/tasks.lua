local task_t = (function()
  local ffi = require("ffi")

  local this = {}
  local meta = {}
  meta.__index = this

  local queue = {}
  queue[1] = 1

  local os_clock
  local table_unpack = table.unpack
  local select = select

  if jit.os == "Windows" then
    ffi.cdef "unsigned __stdcall GetTickCount(void);"
    os_clock = ffi.C.GetTickCount
  else
    os_clock = os.clock
  end

  function this:push(...)
    self[1] = self[1] + 1
    self[(self[1])] = {...}
    return self
  end

  function this:join()
    self[2] = os_clock()
    queue[1] = queue[1] + 1
    queue[(queue[1])] = self
  end

  function this:consume()
    local clock = os_clock()
    for i = queue[1], 2, -1 do
      local s = queue[i]
      local d = clock - s[2]
      for j = s[1], 3, -1 do
        local n = s[j]
        if n[1] < d then
          if n[6] then
            n[2](select(3, table_unpack(n)))
          elseif n[3] then
            n[2](n[3], n[4], n[5])
          else
            n[2]()
          end
          s[j] = s[(s[1])]
          s[1] = s[1] - 1
        end
      end
      if s[1] == 2 then
        queue[i] = queue[(queue[1])]
        queue[(queue[1])] = nil
        queue[1] = queue[1] - 1
      end
    end
  end

  local function constructor()
    return setmetatable({ 2, 0 }, meta)
  end

  return setmetatable(this, { __call = constructor })
end)()

return task_t
