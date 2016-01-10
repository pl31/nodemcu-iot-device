require "utils"

tmr.alarm(0,3000, 0,
  function() utils.dofile("main") end)
