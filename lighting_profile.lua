--[[
    lighting_profile.lua
    Lighting Profile: The current status of Yeelight
    Lighting History: The last known status of Yeelight (before turning off)
]]

-- Save the lighting profile (current status)
function SaveLightingProfile(red, green, blue, brightness, temperature, mode)
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
    local profile = RetrieveLightingProfile()
    PersistData["YEELIGHT_HISTORY"]["mode"] =
	   profile["mode"]

    PersistData["YEELIGHT_HISTORY"]["red"] =
	   profile["red"]

    PersistData["YEELIGHT_HISTORY"]["green"] =
	   profile["green"]

    PersistData["YEELIGHT_HISTORY"]["blue"] =
	   profile["blue"]

    PersistData["YEELIGHT_HISTORY"]["temperature"] =
	   profile["temperature"]

    PersistData["YEELIGHT_HISTORY"]["brightness"] =
	   profile["brightness"]
end

function RetrieveLightingHistory()
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

-- Retrieve the last known brightness
function RetrieveLastBrightness()
    local profile = RetrieveLightingProfile()
    local history = RetrieveLightingHistory()
    if (profile["brightness"] ~= 0) then return profile["brightness"] end
    return history["brightness"]
end

-- Retrieve last lighting profile
-- If profile is not available (off), return the history profile
function RetrieveLastLightingProfile()
    local profile = RetrieveLightingProfile()
    local history = RetrieveLightingHistory()
    if (profile["brightness"] == 0) then return history end
    return profile
end
