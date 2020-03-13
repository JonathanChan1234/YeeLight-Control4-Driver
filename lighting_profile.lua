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

-- Retrieve the last known brightness
function RetrieveLastBrightness()
    local profile = RetrieveLightingProfile()
    local history = RetrieveLightingHistory()
    if (profile["brightness"] ~= 0) then return profile["brightness"] end
    return history["brightness"]
end
