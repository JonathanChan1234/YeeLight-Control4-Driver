--
-- network.lua
-- Handle Data received from network
--
require "utils"
require "constants"

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
            if value == "low" then
                -- Save the previous lighting state after turning off
                UpdateLightHistory()
                UpdateLightProperty(0, 0, 0, 0, 1700, nil, nil)
            else
                local history = RetrieveLightingHistory()
                if Mode == TEMPERATURE_MODE then
                    UpdateLightProperty(0, 0, 0, history["brightness"],
                                        history["temperature"], nil)
                end
                if Mode == RGB_MODE then
                    UpdateLightProperty(history["red"], history["green"],
                                        history["blue"], history["brightness"],
                                        0, nil)
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

-- Save the lighting profile (current status)
function SaveLightingProfile(red, green, blue, temperature, brightness, mode)
    if (mode ~= nil) then PersistData["YEELIGHT_PROFILE"]["mode"] = mode end
    if (red ~= nil) then PersistData["YEELIGHT_PROFILE"]["red"] = red end
    if (green ~= nil) then PersistData["YEELIGHT_PROFILE"]["green"] = green end
    if (blue ~= nil) then PersistData["YEELIGHT_PROFILE"]["blue"] = blue end
    if (temperature ~= nil) then
        PersistData["YEELIGHT_PROFILE"]["temperature"] = temperature
    end
    if (brightness ~= nil) then
        PersistData["YEELIGHT_PROFILE"]["brightness"] = brightness
    end
end

-- Get the lighting profile (current status)
function RetrieveLightingProfile()
    -- Retrieve the lighting profile from persist data
    -- Initialize if null
    PersistData["YEELIGHT_PROFILE"] = PersistData["YEELIGHT_PROFILE"] or
                                          INIT_LIGHTING_PROFILE
    return {
        mode = PersistData["YEELIGHT_PROFILE"]["mode"],
        red = PersistData["YEELIGHT_PROFILE"]["red"],
        green = PersistData["YEELIGHT_PROFILE"]["green"],
        blue = PersistData["YEELIGHT_PROFILE"]["blue"],
        temperature = PersistData["YEELIGHT_PROFILE"]["temperature"],
        brightness = PersistData["YEELIGHT_PROFILE"]["brightness"]
    }
end

-- Backup Lighting Profile
-- Restore the previous lighting state aftering turning on
function SaveLightingHistory()
    PersistData["YEELIGHT_PROFILE"] = PersistData["YEELIGHT_PROFILE"] or
                                          INIT_LIGHTING_PROFILE
    if (mode ~= nil) then
        PersistData["YEELIGHT_HISTORY"]["mode"] =
            PersistData["YEELIGHT_PROFILE"]["mode"]
    end
    if (red ~= nil) then
        PersistData["YEELIGHT_HISTORY"]["red"] =
            PersistData["YEELIGHT_PROFILE"]["red"]
    end
    if (green ~= nil) then
        PersistData["YEELIGHT_HISTORY"]["green"] =
            PersistData["YEELIGHT_PROFILE"]["green"]
    end
    if (blue ~= nil) then
        PersistData["YEELIGHT_HISTORY"]["blue"] =
            PersistData["YEELIGHT_PROFILE"]["blue"]
    end
    if (temperature ~= nil) then
        PersistData["YEELIGHT_HISTORY"]["temperature"] =
            PersistData["YEELIGHT_PROFILE"]["temperature"]
    end
    if (brightness ~= nil) then
        PersistData["YEELIGHT_HISTORY"]["brightness"] =
            PersistData["YEELIGHT_PROFILE"]["brightness"]
    end
end

function RetrieveLightingHistory(red, green, blue, temperature, brightness)
    -- Retrieve the lighting history from persist data
    -- Initialize if null
    PersistData["YEELIGHT_HISTORY"] = PersistData["YEELIGHT_HISTORY"] or
                                          INIT_LIGHTING_PROFILE
    return {
        mode = PersistData["YEELIGHT_HISTORY"]["mode"],
        red = PersistData["YEELIGHT_HISTORY"]["red"],
        green = PersistData["YEELIGHT_HISTORY"]["green"],
        blue = PersistData["YEELIGHT_HISTORY"]["blue"],
        temperature = PersistData["YEELIGHT_HISTORY"]["temperature"],
        brightness = PersistData["YEELIGHT_HISTORY"]["brightness"]
    }
end
