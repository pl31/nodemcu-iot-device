require("config")
require("msgbus")
require("system")

local sync
local create_alarm

local function on_sync(s,ms,server)
  local msg={
    server=server,
    utc_s=s+ms/1000000
  }
  msgbus.enqueue(config.ntp.topics.ts,msg,1,1)
  -- slow poll
  create_alarm(config.ntp.sync_interval_s)
  -- after each sync, send system status
  system.status()
end

local function on_resolve(server,sk,ip)
  local msg={server=server}
  if (ip) then
    sntp.sync(ip, on_sync)
    msg.ip=ip
    msg.event="resolved"
  else
    msg.error="resolve error"
  end
  msgbus.enqueue(config.ntp.topics.events,msg)
end

function sync()
  if (wifi.sta.getip()==nil or net.dns.getdnsserver()==nil) then
    local msg={error="no valid network configuration"}
    msgbus.enqueue(config.ntp.topics.events,msg)
  else
    net.dns.resolve(config.ntp.server,
      function(sk,ip) on_resolve(config.ntp.server,sk,ip) end)
  end
end

function create_alarm(interval_s)
  tmr.stop(config.ntp.alarm_id)
  tmr.alarm(config.ntp.alarm_id,interval_s*1000,1,sync)
end

ntp={}

function ntp.start()
  sync()
  -- fast poll
  create_alarm(config.ntp.first_sync_interval_s)
end

function ntp.stop()
  tmr.stop(config.ntp.alarm_id)
end
