require("config")
require("msgbus")

local function read_sensor_data()
  local status,temp,humi,temp_decimial,humi_decimial=
    dht.read(config.am2302.pin)
  if(status==dht.OK) then
    local msg={
      temperature=temp+config.am2302.temperature_offset,
      humidity=humi
    }
    msgbus.enqueue(config.am2302.topics.ts,msg,1,1)
  else
    local msg={}
    if(status==dht.ERROR_CHECKSUM) then
      msg.error="checksum error"
    elseif(status==dht.ERROR_TIMEOUT) then
      msg.error="timeout"
    else
      msg.error="unknown"
    end
    msgbus.enqueue(config.am2302.topics.events,msg)
  end
end

am2302={}

function am2302.start()
  read_sensor_data()
  tmr.stop(config.am2302.alarm_id)
  tmr.alarm(config.am2302.alarm_id,
    config.am2302.read_sensor_interval_s * 1000, 
    1, read_sensor_data)
end

function am2302.stop()
  tmr.stop(config.am2302.alarm_id)
end
