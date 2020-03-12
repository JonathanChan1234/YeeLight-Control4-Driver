--
-- proxy.lua
-- Implementation of ReceivedFromProxy()
-- 
require "utils"
require "constants"
require "network"
require "yeelight_command"

PROXY_CMD = {}

function ReceivedFromProxy(idBinding, strCommand, tParams)
    dbg("Received From Proxy (id binding:  " .. idBinding .. ") strCommand: " ..
            strCommand)
    if (strCommand == nil) then return end
    if (PROXY_CMD[strCommand] ~= nil and type(PROXY_CMD[strCommand]) ==
        "function") then
        PROXY_CMD[strCommand](idBinding, tParams)
    else
        dbg("Unhandled Command: " .. strCommand)
    end
end

function PROXY_CMD.RAMP_TO_LEVEL(idBinding, tParams)
    local level = tonumber(tParams["LEVEL"])
    local profile = RetrieveLightingProfile()
    local red = profile['red']
    local green = profile['green']
    local blue = profile['blue']
    if (idBinding == RED_PROXY_BINDING) then
        red = convertLevelToRGB(level)
    elseif (idBinding == GREEN_PROXY_BINDING) then
        green = convertLevelToRGB(level)
    elseif (idBinding == BLUE_PROXY_BINDING) then
        blue = convertLevelToRGB(level)
    elseif (idBinding == BRIGHTNESS_PROXY_BINDING) then
    end
end

function PROXY_CMD.BUTTON_ACTION(idBinding, tParams) end

function PROXY_CMD.PUSH_SCENE(idBinding, tParams) end

function PROXY_CMD.ACTIVATE_SCENE(idBinding, tParams) end
