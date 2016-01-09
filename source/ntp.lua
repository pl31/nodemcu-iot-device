require("config")
require("msgbus")

local sync
local create_alarm

local function on_sync(s,ms,server)
  msg={}
  msg.server=server
  msg.utc_s=s+ms/1000000
  msgbus.enqueue(config.ntp.topics.ts,msg,1,1)
  -- slow poll
  create_alarm(config.ntp.sync_interval_s)
end

local function on_resolve(server,sk,ip)
  msg={}
  msg.server=server
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
    msg={}
    msg.error="no valid network configuration"
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

sync()
-- fast poll
create_alarm(config.ntp.first_sync_interval_s)