--
-- utils.lua
-- Utility functions (string manipulation, mathematics operation, logging)
--

--[[
Debug logging
    depending on the debug mode (Driver Property), print/log/ignore the debug message
    debugString (string): the debug message to be logged in the composer lua screen
--]]
function dbg(debugMsg)
    debugMode = Properties["Debug Mode"]
    if (debugMode == "Off") then
	   return
    elseif (debugMode == "Print") then
	   print(debugMsg)
    elseif (debugMode == "Print and Log") then
	   C4:ErrorLog(debugMsg)
	   print(debugMsg)
    elseif (debugMode == "Log") then
	   C4:ErrorLog(debugMsg)
    else
	   print("Invalid Debug Mode: " .. debugMode)
    end
end

-- Convert RGB Value to Level
-- value(number): rgb value
-- return
-- number: rgb level (0-100)
function convertRGBToLevel(value)
    if (type(value) ~= "number") then 
	   error("convertRGBToLevel Error: level must be in type of number")
    end
    if (value == 0) then return 0 end
    return math.ceil(value * 255 / 100)
end

-- Convert Color Temperature to Level
-- value(number): color temperature
-- return
-- number: color temperature level (0-100)
function convertTemperatureToLevel(temperature)
    if (type(temperature) ~= "number") then 
	   error("convertTemperatureToLevel Error: temperature must be in type of number")
    end
    if (temperature == 1700) then return 0 end
    return math.ceil((temperature - 1700) * 100 / 4800)
end