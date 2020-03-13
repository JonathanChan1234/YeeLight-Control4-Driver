--
-- network.lua
-- Handle Data received from network
--
require "utils"
require "constants"
require "lighting_profile"

INIT_LIGHTING_PROFILE = {
    mode = "RGB",
    red = 255,
    green = 255,
    blue = 255,
    temperature = 0,
    brightness = 100
}

if (Properties["Device IP Address"] == nil or Properties["Device IP Address"] ==
    "") then
    dbg("Invalid/Empty IP Address")
else
    C4:CreateNetworkConnection(6001, Properties["Device IP Address"], "Telnet")
end

function ReceivedFromNetwork(idBinding, nPort, receivestring)
    dbg("Received from Network " .. idBinding .. ":" .. receivestring)
    local response = C4:JsonDecode(receivestring)
    -- Invalid JSON Format Response Data
    if (response == nil) then error("Invalid JSON response data") end
    -- No params feedback is received
    if (response["params"] == nil) then dbg("Response: " .. receivestring) end

    for key, value in pairs(response["params"]) do
        if key == "power" then
            if value == "off" then
                -- Save the previous lighting state after turning off
                SaveLightingHistory()
                UpdateLightProperty(0, 0, 0, 0, 1700, nil, nil)
            else
                local history = RetrieveLightingHistory()
                if Mode == TEMPERATURE_MODE then
                    UpdateLightProperty(0, 0, 0, 100,
                                        history["temperature"], nil)
                end
                if Mode == RGB_MODE then
                    UpdateLightProperty(history["red"], history["green"],
                                        history["blue"], 100,
                                        1700, nil)
                end
            end
        end
        if key == "bright" then
            dbg("brightness: " .. value)
            UpdateLightProperty(nil, nil, nil, value, nil, nil)
        end
        if key == "rgb" then
            local rgb = convertDecToRGB(value)
            dbg("RGB Feedback: (" .. rgb["red"] .. "," .. rgb["green"] .. "," ..
                    rgb["blue"] .. ")")
            UpdateLightProperty(rgb["red"], rgb["green"], rgb["blue"], nil, nil,
                                RGB_MODE)
        end
        if key == "ct" then
            dbg("color temperature: " .. value)
            UpdateLightProperty(0, 0, 0, nil, value, TEMPERATURE_MODE)
        end
    end
end

--[[
    update the light property both on app (proxy level) and driver properties
    red (number): red light level (max: 255)
    green (number): green light level (max: 255)
    blue (number): blue light level (max: 255)
    brightness (number): brightness (max: 100)
    colorTempeature (number): color temperature (1700 - 6500)
    mode(string): RGB mode or Color Temperature mode
--]]
function UpdateLightProperty(red, green, blue, brightness, colorTemperature,
                             mode)
    Mode = mode or RetrieveLightingProfile()["mode"]

    -- only update the rgb property when in RGB mode
    if (Mode == RGB_MODE) then
        if (red ~= nil) then
            C4:SendToProxy(RED_PROXY_BINDING, "LIGHT_LEVEL",
                           convertRGBToLevel(red))
            C4:UpdateProperty(RED_PROPERTY, red)
        end
        if (green ~= nil) then
            C4:SendToProxy(GREEN_PROXY_BINDING, "LIGHT_LEVEL",
                           convertRGBToLevel(green))
            C4:UpdateProperty(GREEN_PROPERTY, green)
        end
        if (blue ~= nil) then
            C4:SendToProxy(BLUE_PROXY_BINDING, "LIGHT_LEVEL",
                           convertRGBToLevel(blue))
            C4:UpdateProperty(COLOR_TEMPERATURE_PROPERTY, blue)
        end
        C4:SendToProxy(TEMPERATURE_PROXY_BINDING, "LIGHT_LEVEL", 0)
        C4:UpdateProperty(COLOR_TEMPERATURE_PROPERTY, 1070)
    end

    -- only update the color temperature property when in Temp Mode
    if (Mode == TEMPERATURE_MODE) then
        if (colorTemperature ~= nil) then
            C4:SendToProxy(TEMPERATURE_PROXY_BINDING, "LIGHT_LEVEL",
                           convertTemperatureToLevel(colorTemperature))
            C4:UpdateProperty(COLOR_TEMPERATURE_PROPERTY, colorTemperature)
            C4:SendToProxy(BLUE_PROXY_BINDING, "LIGHT_LEVEL", 0)
            C4:UpdateProperty(BLUE_PROPERTY, 0)
            C4:SendToProxy(GREEN_PROXY_BINDING, "LIGHT_LEVEL", 0)
            C4:UpdateProperty(GREEN_PROPERTY, 0)
            C4:SendToProxy(RED_PROXY_BINDING, "LIGHT_LEVEL", 0)
            C4:UpdateProperty(RED_PROPERTY, 0)
        end
    end

    -- only update brightness property and proxy when updated
    if (brightness ~= nil) then
        C4:SendToProxy(BRIGHTNESS_PROXY_BINDING, "LIGHT_LEVEL", brightness)
        C4:UpdateProperty(BRIGHTNESS_PROPERTY, brightness)
    end

    -- Save the lighting profile each time the feedback is received
    SaveLightingProfile(red, green, blue, brightness, colorTemperature, mode)
end


