--
-- proxy.lua
-- Implementation of ReceivedFromProxy()
-- 
require "utils"
require "constants"
require "lighting_profile"
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

function PROXY_CMD.ON(idBinding, tParams) YON() end
function PROXY_CMD.OFF(idBinding, tParams) YOFF() end
function PROXY_CMD.TOGGLE(idBinding, tParams) Toggle() end
function PROXY_CMD.DO_PUSH(idBinding, tParams)
    if (idBinding == ON_BINDING) then
        YON()
    elseif (idBinding == OFF_BINDING) then
        YOFF()
    elseif (idBinding == TOGGLE_BINDING) then
        Toggle()
    end
end

function PROXY_CMD.RAMP_TO_LEVEL(idBinding, tParams)
    local level = tonumber(tParams["LEVEL"])
    -- When RGB Level is changed, re-calculate the rgb value and send a updated value
    if (idBinding == RED_PROXY_BINDING or idBinding == GREEN_PROXY_BINDING or
        idBinding == BLUE_PROXY_BINDING) then
        local profile = RetrieveLightingProfile()
        local red = profile['red']
        local green = profile['green']
        local blue = profile['blue']
        if (idBinding == RED_PROXY_BINDING) then
            red = convertLevelToRGB(level)
        end
        if (idBinding == GREEN_PROXY_BINDING) then
            green = convertLevelToRGB(level)
        end
        if (idBinding == BLUE_PROXY_BINDING) then
            blue = convertLevelToRGB(level)
        end
        SET_COLOR(convertRGBToDec(red, green, blue), nil)
    end
    -- Color Temperature Change
    if (idBinding == TEMPERATURE_PROXY_BINDING) then
        SET_TEMP(convertLevelToTemperature(level), nil)
    end
    -- Brightness Change
    if (idBinding == BRIGHTNESS_PROXY_BINDING) then SET_BRIGHT(level) end
end

function PROXY_CMD.BUTTON_ACTION(idBinding, tParams)
    if (tonumber(tParams["ACTION"]) ~= 2) then return end
    local profile = RetrieveLightingProfile()
    -- When RGB color is changed
    if (idBinding == RED_PROXY_BINDING or idBinding == GREEN_PROXY_BINDING or
        idBinding == BLUE_PROXY_BINDING) then
        local red = profile['red']
        local green = profile['green']
        local blue = profile['blue']
        if (idBinding == RED_PROXY_BINDING) then
            red = (red > 0) and 0 or 255
        end
        if (idBinding == GREEN_PROXY_BINDING) then
            green = (green > 0) and 0 or 255
        end
        if (idBinding == BLUE_PROXY_BINDING) then
            blue = (blue > 0) and 0 or 255
        end
        SET_COLOR(convertRGBToDec(red, green, blue), nil)
    end

    -- When color temperature is changed
    if (idBinding == TEMPERATURE_PROXY_BINDING) then
        SET_TEMP((profile['temperature'] > 1700) and 1700 and 6500, nil)
    end

    -- When brightness is changed
    if (idBinding == BRIGHTNESS_PROXY_BINDING) then
        SET_BRIGHT((profile['brightness'] == 0) and 100 or 0)
    end
end

function PROXY_CMD.PUSH_SCENE(idBinding, tParams) end

function PROXY_CMD.ACTIVATE_SCENE(idBinding, tParams) end
