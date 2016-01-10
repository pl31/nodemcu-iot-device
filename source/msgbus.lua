require("config")

function debug(msg)
  print(msg)
end

msgbus={}

-- forward declarations
local send_all

-- control variables
local buffer = {}
local msg_id = 0

function msgbus.enqueue(topic,data,qos,retain)
  local qos = qos or 1
  local retain = retain or 0
  -- additional data
  data.uptime_s=tmr.now()/1000000
  local s,subs=rtctime.get()
  if (s~=0) then
    data.utc_s=s+subs/1000000
  end
  data.boot_id=config.boot_id
  data.id=msg_id
  -- pack in msg
  local msg={
    device=config.device_id,
    topic=topic,
    data=data,
    qos=qos,
    retain=retain
  }

  msg_id = msg_id + 1

  debug(cjson.encode(msg))
  table.insert(buffer, msg)

  if (send_all ~= nil) then
    send_all(buffer)
  end
end

-- ***** mqtt part *****

-- control flow variables
local mqttc_connected=false
local mqttc_send_lock=nil

local function is_mqtt_send_lock_active()
  if (mqttc_send_lock==nil) then
    return false
  end

  local new_mqttc_send_lock=tmr.now()/1000000
  return new_mqttc_send_lock-mqttc_send_lock<=config.msgbus.mqtt.send_timeout_s
end

-- cleanup for multiple starts
if (mqttc~=nil) then
  tmr.stop(config.msgbus.mqtt.alarm_id)
  mqttc:close()
end

-- enqueue own events
local function on_mqtt_event(event)
  local msg={event=event}
  msgbus.enqueue(config.msgbus.topics.events,msg)
end

-- single connect
local function mqttc_connect()
  if (is_mqtt_send_lock_active()) then
    debug("reconnect delayed")
    tmr.alarm(config.msgbus.mqtt.alarm_id,
      config.msgbus.mqtt.reconnect_interval_s*1000, 0,
      mqttc_connect)
  else
    debug("connecting")
    mqttc:connect(config.msgbus.mqtt.host, config.msgbus.mqtt.port, 0, 0)
  end
end

local function on_connect(conn)
  mqttc_connected=true
  debug("mqtt connected")
  tmr.stop(config.msgbus.mqtt.alarm_id)
  on_mqtt_event("connected")
end

local function on_offline(conn)
  mqttc_connected=false
  debug("mqtt offline")
  tmr.alarm(config.msgbus.mqtt.alarm_id,
    config.msgbus.mqtt.send_timeout_s*1000, 0,
    mqttc_connect)
  on_mqtt_event("offline")
end

mqttc=mqtt.Client(node.chipid(), 600, 
  config.msgbus.mqtt.user, config.msgbus.mqtt.password)
mqttc:on("connect", on_connect)
mqttc:on("offline", on_offline)
-- first connect
mqttc_connect()

local function on_send()
  local msg=table.remove(buffer,1)
  debug("message "..msg.data.id.." removed")
  mqttc_send_lock=nil
  send_all()
end

function send_all()
  if (#buffer>0 and mqttc_connected) then
    local new_mqttc_send_lock=tmr.now()/1000000
    -- no lock or lock timed out
    if (mqttc_send_lock==nil or 
      new_mqttc_send_lock-mqttc_send_lock>config.msgbus.mqtt.send_timeout_s) then
        debug("trying to send "..#buffer.." pending messages")
        mqttc_send_lock=new_mqttc_send_lock
        local msg=buffer[1];
        debug("send message "..msg.data.id.." ["..mqttc_send_lock.."]")
        local topic="devices/"..msg.device.."/"..msg.topic
        local data=cjson.encode(msg.data)
        mqttc:publish(topic, data, msg.qos, msg.retain, on_send)
    else
      debug("sending already in progress")
    end
  end
end
