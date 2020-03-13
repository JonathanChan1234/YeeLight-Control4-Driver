--
-- utils.lua
-- Utility functions (string manipulation, mathematics operation, logging)
--
--[[
    Debug logging
    depending on the debug mode (Driver Property), print/log/ignore the debug message
    debugString (string): the debug message to be logged in the composer lua screen
]] function dbg(debugMsg)
    debugMode = Properties["Debug Mode"] or "Off"
    print(debugMode)
    if (debugMode == "Off") then
        return
    elseif (debugMode == "Print") then
        print(debugMsg)
    elseif (debugMode == "Print and Log") then
	   print(debugMode)
        C4:ErrorLog(debugMsg)
        print(debugMsg)
    elseif (debugMode == "Log") then
        C4:ErrorLog(debugMsg)
    else
        print("Invalid Debug Mode: " .. debugMode)
    end
end

--[[
    Convert RGB Level (0 - 100) to RGB Value (0 - 255)
    level (number): rgb number (0-255)
    return
    number: rgb value (0-100)
]]
function convertLevelToRGB(level)
    if (type(level) ~= "number") then
        error("convertLevelToRGB Error: level must be in type of number")
    end
    return math.ceil(level * 255 / 100)
end

--[[
    Convert RGB Value to Level
    value(number): rgb value
    return
    number: rgb level (0-100)
]]
function convertRGBToLevel(value)
    if (type(value) ~= "number") then
        error("convertRGBToLevel Error: level must be in type of number")
    end
    if (value == 0) then return 0 end
    return math.ceil(value * 100 / 255)
end

--[[
    Convert Color Temperature to Level
    value(number): color temperature
    return
    number: color temperature level (0-100)
]]
function convertTemperatureToLevel(temperature)
    if (type(temperature) ~= "number") then
        error(
            "convertTemperatureToLevel Error: temperature must be in type of number")
    end
    if (temperature == 1700) then return 0 end
    return math.ceil((temperature - 1700) * 100 / 4800)
end

--[[
    Convert Level (0-100) to color temperature(1700-6500)
    level (number): color temperature level (0 - 100)
    return value
    Color Temperature (number): 1700 - 6500
]]
function convertLevelToTemperature(level)
    if (type(level) ~= "number") then
        error("convertLevelToTemperature Error: level must be in type of number")
    end
    if (level == 0) then return 1700 end
    return math.floor(1700 + (level - 1) * 48.4848)
end

--[[
    convert RGB value to dec
    return value:
    rgb dev value (number)
]]
function convertRGBToDec(red, green, blue)
    -- type check
    if (type(red) ~= "number") then error("red must be in type of number") end
    if (type(green) ~= "number") then
        error("green must be in type of number")
    end
    if (type(blue) ~= "number") then error("blue must be in type of number") end
    return red * 65536 + green * 256 + blue
end

--[[
    Utility function to convert decimal rgb value to hex rgb value
    Return table {red = red, green = green, blue = blue}
]]
function convertDecToRGB(value)
    -- type check
    if (type(value) ~= "number") then
        error("value must be in type of number")
    end
    red = math.floor(value / (256 * 256));
    green = math.floor(value / 256) % 256;
    blue = value % 256;
    return {red = red, green = green, blue = blue}
end

function PrintTable(table, level)
    level = level or 1
    local indent = ""
    for i = 1, level do indent = indent .. "  " end

    if key ~= "" then
        print(indent .. key .. " " .. "=" .. " " .. "{")
    else
        print(indent .. "{")
    end

    key = ""
    for k, v in pairs(table) do
        if type(v) == "table" then
            key = k
            PrintTable(v, level + 1)
        else
            local content = string.format("%s%s = %s", indent .. "  ",
                                          tostring(k), tostring(v))
            print(content)
        end
    end
    print(indent .. "}")
end
