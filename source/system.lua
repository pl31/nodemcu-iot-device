require("config")
require("msgbus")

system={}

function system.status()
  local msg={
    heap=node.heap()
  }
  msgbus.enqueue(config.system.topics.ts,msg,1,1)
end
