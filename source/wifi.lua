require("config")
require("ntp")
require("msgbus")

local wifi_states = {
  [wifi.STA_IDLE]="idle",
  [wifi.STA_CONNECTING]="connecting",
  [wifi.STA_WRONGPWD]="wrong password",
  [wifi.STA_APNOTFOUND]="ap not found",
  [wifi.STA_FAIL]="fail",
  [wifi.STA_GOTIP]="got ip"
}

local function try_set(v,t,name)
  if(v~=nil) then t[name]=v end
end

local function wifi_event(state, previous_state)
  if (state==wifi.STA_GOTIP) then
    ntp.start()
  end

  local msg={event=(wifi_states[state])}
  try_set(previous_state,msg,"previous_state")
  try_set(wifi.sta.getmac(),msg,"mac")
  try_set(wifi.sta.getip(),msg,"ip")

  msgbus.enqueue(config.wifi.sta.topics.events,msg)
end

local function start()
  for state, desc in pairs(wifi_states) do
    wifi.sta.eventMonReg(state, 
      function(previous_state) 
        wifi_event(state, previous_state) 
      end)
  end
  wifi.sta.eventMonStart()

  wifi.setmode(config.wifi.mode)
  if (config.wifi.mode==wifi.STATION or 
    config.wifi.mode==wifi.STATIONAP) then
      wifi.sta.config(config.wifi.sta.ssid,config.wifi.sta.pwd)
      wifi.sta.connect()
  end
end

start()
