dofile("wifi.lua")
-- make ntp depend on wifi
dofile("ntp.lua")

require("am2302")
am2302.start()
