--[[
    yeelight_command.lua
    Functions of yeelight command for different actions
    This lua file contains the following commands
    1. Turn On
    2. Turn Off
    3. Toggle
    4. Set Brightness
    5. Set Color Temperature
    6. Set RGB Color
--]] 
require "utils"
require "constants"
require "lighting_profile"

--[[
    Send command to YeeLight through TCP Telent
    id (number): the light id
    method (string): the command method
    params (table): the method params associated with the command method
    please check the documentation for details
    https://www.yeelight.com/download/Yeelight_Inter-Operation_Spec.pdf
--]]
function sendToYeeLight(id, method, params)
    -- type check
    if (type(id) ~= "number") then error("id must be in type of number") end
    if (type(method) ~= "string") then
        error("method must be in type of string")
    end
    if (type(params) ~= "table") then
        error("params must be in type of table")
    end
    -- check valid ip address
    if (Properties["Device IP Address"] == nil) then
        dbg("Empty/Invalid Device IP Address")
        return
    end

    local command_table = {id = id, method = method, params = params}
    local command = C4:JsonEncode(command_table, false, true) .. "\r\n"
    dbg("Sent Command to Network: " .. command)
    local url = "http://" .. Properties["Device IP Address"] .. ":55443"
    C4:urlCancelAll()
    C4:urlPost(url, command)
end

-- Turn on Yeelight
function YON()
    dbg("Turning on Yeelight")
    sendToYeeLight(1, "set_power", {"on", "smooth", 500})
end

-- Turn off Yeelight
function YOFF()
    dbg("Turning off Yeelight")
    sendToYeeLight(1, "set_power", {"off", "smooth", 500})
end

-- Toggle
function Toggle()
    dbg("Toggle Yeelight")
    sendToYeeLight(1, "toggle", {})
end

-- Set brightness level
function SET_BRIGHT(brightness)
    dbg("set bright level" .. brightness)
    local lastLightingProfile = RetrieveLastLightingProfile()
    if (lastLightingProfile["mode"] == RGB_MODE) then
	   SET_COLOR(convertRGBToDec(lastLightingProfile["red"], 
		  lastLightingProfile["green"], lastLightingProfile["blue"]), 
		  brightness)
    else
	   SET_TEMP(lastLightingProfile["temperature"], brightness)
    end
end

-- Set RGB Color
function SET_COLOR(color, brightness)
    dbg("set rgb to: " .. color)
    local setBrightness = brightness or RetrieveLastBrightness()
    sendToYeeLight(1, "set_scene", {"color", color, setBrightness})
end

-- Set color temperature
function SET_TEMP(temperature, brightness)
    dbg("set color temperature to " .. temperature)
    local setBrightness = brightness or RetrieveLastBrightness()
    sendToYeeLight(1, "set_scene", {"ct", temperature, setBrightness})
end
