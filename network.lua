--
-- network.lua
-- Handle Data received from network
--

require "utils"
require "constant"

if (Properties["Device IP Address"] == nil or Properties["Device IP Address"] == "") then
    dbg("Invalid/Empty IP Address")
else
    C4:CreateNetworkConnection(6001, Properties["Device IP Address"], "Telnet")
end

function ReceivedFromNetwork(idBinding, nPort, receivestring)
    dbg("Received from Network " .. idBinding .. ":" .. receivestring)
    local response = C4:JsonDecode(receivestring)
    if (response == nil) then error("Invalid JSON response data") end
    if (response["params"] == nil) then dbg("Response: " .. receivestring) end
    for key, value in pairs(response["params"]) do
        if key == "power" then
            if value == "low" then
                Power = false
                SaveLastRGBValue()
                updateLightProperty(0, 0, 0, 0, 1700)
            else
                Power = true
                if (Mode == "Temp") then
                    updateLightProperty(0, 0, 0, LastBrightness, LastTempValue)
                end
                if Mode == "RGB" then
                    updateLightProperty(LastRedValue, LastGreenValue,
                                        LastBlueValue, LastBrightness, 0)
                end
            end
        end
        if key == "bright" then
            print("brightness: " .. value)
            updateLightProperty(nil, nil, nil, value, nil)
        end
        if key == "rgb" then
            print("rgb: " .. value)
            local rgb = convertDecToRGB(value)
		  dbg("RGB Feedback: (" ..rgb["red"].. ",".. rgb["green"] .. "," .. rgb["blue"] .. ")")
            updateLightProperty(rgb["red"], rgb["green"], rgb["blue"], nil, nil)
        end
        if key == "ct" then
            print("ct: " .. value)
            updateLightProperty(0, 0, 0, nil, value)
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
--]]
function updateLightProperty(red, green, blue, brightness, colorTemperature)
    Mode = PersistData["Yeelight_Profile"]["mode"] or "RGB"
    
    -- only update the rgb property when in RGB mode
    if (Mode == "RGB") then
        if (red ~= nil) then
            C4:SendToProxy(RED_PROXY_BINDING, "LIGHT_LEVEL", convertRGBToLevel(red))
            C4:UpdateProperty("Red Value", red)
        end
        if (green ~= nil) then
            C4:SendToProxy(GREEN_PROXY_BINDING, "LIGHT_LEVEL", convertRGBToLevel(green))
            C4:UpdateProperty("Green Value", green)
        end
        if (blue ~= nil) then
            C4:SendToProxy(BLUE_PROXY_BINDING, "LIGHT_LEVEL", convertRGBToLevel(blue))
            C4:UpdateProperty("Blue Value", blue)
        end
        C4:SendToProxy(TEMPERATURE_PROXY_BINDING, "LIGHT_LEVEL", 0)
        C4:UpdateProperty("Color Temperature", 1070)
    end
    
    -- only update the color temperature property when in Temp Mode
    if (Mode == "Temp") then
        if (colorTemperature ~= nil) then
            C4:SendToProxy(TEMPERATURE_PROXY_BINDING, "LIGHT_LEVEL", convertTemperatureToLevel(colorTemperature))
            C4:UpdateProperty("Color Temperature", colorTemperature)
            C4:SendToProxy(BLUE_PROXY_BINDING, "LIGHT_LEVEL", 0)
            C4:UpdateProperty("Blue Value", 0)
            C4:SendToProxy(GREEN_PROXY_BINDING, "LIGHT_LEVEL", 0)
            C4:UpdateProperty("Green Value", 0)
            C4:SendToProxy(RED_PROXY_BINDING, "LIGHT_LEVEL", 0)
            C4:UpdateProperty("Red Value", 0)
        end
    end

    if (brightness ~= nil) then
        C4:SendToProxy(BRIGHTNESS_PROXY_BINDING, "LIGHT_LEVEL", brightness)
        C4:UpdateProperty("Brightness", brightness)
    end
end

-- Save the lighting profile
function SaveProfile(mode, red, green, blue, temperature, brightness)
    if (mode ~= nil) then PersistData["Yeelight_Profile"]["mode"] = mode end
    if (red ~= nil) then PersistData["Yeelight_Profile"]["red"] = red end
    if (green ~= nil) then PersistData["Yeelight_Profile"]["green"] = green end
    if (blue ~= nil) then PersistData["Yeelight_Profile"]["blue"] = blue end
    if (temperature ~= nil) then  PersistData["Yeelight_Profile"]["temperature"] = temperature end
    if (brightness ~= nil) then PersistData["Yeelight_Profile"]["brightness"] = brightness end
end
