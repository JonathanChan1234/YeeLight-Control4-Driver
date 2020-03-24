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
    please check the documentation for details
    https://www.yeelight.com/download/Yeelight_Inter-Operation_Spec.pdf
    @params id (number): the light id
    @params method (string): the command method
    @params params(table): the method params associated with the command method
    @return nothing
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
    C4:SendToNetwork(6001, 55443, command)
end

--[[
    Retrieve the Yeelight Current lighting Profile
]]
function GetYeelightProfile()
    dbg("Get Yeelight Profile")
    sendToYeeLight(1, "get_prop", {"bright", "color_mode", "rgb", "ct"})
end

--[[
    Turn on Yeelight
]]
function YON()
    dbg("Turning on Yeelight")
    sendToYeeLight(1, "set_power", {"on", "smooth", 500})
end

--[[
    Turn off Yeelight
]]
function YOFF()
    dbg("Turning off Yeelight")
    sendToYeeLight(1, "set_power", {"off", "smooth", 500})
end

--[[
    Toggle the yeelight
]] 
function Toggle()
    dbg("Toggle Yeelight")
    sendToYeeLight(1, "toggle", {})
end

--[[
    Set brightness level
    1. check the mode of yeelight (RGB or Color Temperature)
    2. Calling set scene method to change the brightness
    Works even when the light is off
    @params brightness the brightness level (0 - 100) to be set
    @return void
]]
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

--[[
    Set color (RGB) level
    Calling set scene method to change rgb color
    @params color RGB dec value
    @params brightness brightness level to be set (nullable)
    @return void
]]
function SET_COLOR(color, brightness)
    dbg("set rgb to: " .. color)
    local setBrightness = brightness or RetrieveLastBrightness()
    sendToYeeLight(1, "set_scene", {"color", color, setBrightness})
end

--[[
    Set color temperature level
    Calling set scene method to change color temperature
    @params temperature color temperature (1700 - 6500) to be set
    @params brightness brightness level to be set
    @return void
]]
function SET_TEMP(temperature, brightness)
    dbg("set color temperature to " .. temperature)
    local setBrightness = brightness or RetrieveLastBrightness()
    sendToYeeLight(1, "set_scene", {"ct", temperature, setBrightness})
end
