--[[=============================================================================
    Main script file for driver

    Copyright 2018 HKT Limited. All Rights Reserved.
===============================================================================]] -- require "common.c4_driver_declarations"
-- require "common.c4_common"
-- require "common.c4_init"
-- require "common.c4_property"
-- require "common.c4_command"
-- require "common.c4_notify"
-- require "common.c4_utils"
-- require "lib.c4_timer"
-- require "common.c4_url_connection"
PersistData = PersistData or {}
RPersistData = RPersistData or {}
GPersistData = GPersistData or {}
BPersistData = BPersistData or {}
TPersistData = TPersistData or {}

lightProxyBinding = 5001
TemplightProxyBinding = 5002
RedlightProxyBinding = 5003
GreenlightProxyBinding = 5004
BluelightProxyBinding = 5005

ON_BINDING = 300
OFF_BINDING = 301
TOGGLE_BINDING = 302

sceneCollection = PersistData["sceneCollection"] or {}
flashCollection = PersistData["flashCollection"] or {}
elementCounter = 0
currentScene = 0
executeElementTimer = 0

RelementCounter = 0
RcurrentScene = 0
RexecuteElementTimer = 0
RsceneCollection = RPersistData["RsceneCollection"] or {}
RflashCollection = RPersistData["RflashCollection"] or {}

GelementCounter = 0
GcurrentScene = 0
GexecuteElementTimer = 0
GsceneCollection = GPersistData["GsceneCollection"] or {}
GflashCollection = GPersistData["GflashCollection"] or {}

BelementCounter = 0
BcurrentScene = 0
BexecuteElementTimer = 0
BsceneCollection = BPersistData["BsceneCollection"] or {}
BflashCollection = BPersistData["BflashCollection"] or {}

TelementCounter = 0
TcurrentScene = 0
TexecuteElementTimer = 0
TsceneCollection = TPersistData["TsceneCollection"] or {}
TflashCollection = TPersistData["TflashCollection"] or {}

g_deviceAddress = ""
gSwitchValue = "0"

-- Last RGB Level (RGB level before turning off)
LastBlueValue = 0
LastRedValue = 0
LastGreenValue = 0
-- Last Color Temperature Level (Color Temperature level before turning off)
LastTempLevel = 100
-- Last Brightness
LastBrightness = 50
-- Actual Blue Light Level and Value
BlueLevel = 0
BlueValue = 0
-- Actual Red Light Level and Value
RedLevel = 0
RedValue = 0
-- Actual Green Light Level and Value
GreenLevel = 0
GreenValue = 0
-- Actual Temperature Level and Value
TempValue = 6500
TempLevel = 100
-- Actual Brightness
Brightness = 0
-- Power (off: false, on: true)
Power = true
-- Current Lighting Mode (Temp or RGB)
Mode = "Temp"

----------------------------------------------------------------------------
------print table
----------------------------------------------------------------------------
key = ""
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

----------------------------------------------
---sleep function
----------------------------------------------
function sleep(n)
    local t = os.clock()
    while os.clock() - t <= n do
        -- nothing
    end
end
----------------------------------------------
-- xml parser
----------------------------------------------
function parseargs(s)
    local arg = {}
    string.gsub(s, "(%w+)=([\"'])(.-)%2", function(w, _, a) arg[w] = a end)
    return arg
end

function collect(s)
    local stack = {}
    local top = {}
    table.insert(stack, top)
    local ni, c, label, xarg, empty
    local i, j = 1, 1
    while true do
        ni, j, c, label, xarg, empty = string.find(s,
                                                   "<(%/?)([%w:]+)(.-)(%/?)>", i)
        if not ni then break end
        local text = string.sub(s, i, ni - 1)
        if not string.find(text, "^%s*$") then table.insert(top, text) end
        if empty == "/" then -- empty element tag
            table.insert(top, {label = label, xarg = parseargs(xarg), empty = 1})
        elseif c == "" then -- start tag
            top = {label = label, xarg = parseargs(xarg)}
            table.insert(stack, top) -- new level
        else -- end tag
            local toclose = table.remove(stack) -- remove top
            top = stack[#stack]
            if #stack < 1 then
                error("nothing to close with " .. label)
            end
            if toclose.label ~= label then
                error("trying to close " .. toclose.label .. " with " .. label)
            end
            table.insert(top, toclose)
        end
        i = j + 1
    end
    local text = string.sub(s, i)
    if not string.find(text, "^%s*$") then table.insert(stack[#stack], text) end
    if #stack > 1 then error("unclosed " .. stack[#stack].label) end
    return stack[1]
end

function t1()
    starttime = os.clock()
    print(string.format("start time : %.4f", starttime))
end

function quote(str) return "\"" .. str .. "\"" end
--[[
    Utility function to convert RGB value to dec
--]]
function convertRGBToDec(red, green, blue)
    -- type check
    if (type(red) ~= "number") then error("red must be in type of number") end
    if (type(green) ~= "number") then error("green must be in type of number") end
    if (type(blue) ~= "number") then error("blue must be in type of number") end
    return red * 65536 + green * 256 + blue
end

-- Utility function to convert decimal rgb value to hex rgb value
-- Return table {red = red, green = green, blue = blue}
function convertDecToRGB(value)
    -- type check
    if (type(value) ~= "number") then
        error("value must be in type of number")
    end
    red = math.floor(value / (256 * 256));
    green = math.floor(value / 256) % 256;
    blue = value % 256;
    return {
        red = red,
        green = green,
        blue = blue
    }
end



--[[
    Save the last rgb, color temperature value
--]]
function SaveLastRGBValue()
    LastRedLevel = RedLevel
    LastGreenLevel = GreenLevel
    LastBlueLevel = BlueLevel
    LastTempLevel = TempLevel
    LastBrightness = Brightness
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
    -- only update the rgb property when in RGB mode
    if (Mode == "RGB") then
        if (red ~= nil) then
            RedValue = red
            RedLevel = (red == 0) and 0 or math.ceil(red * 100 / 255)
            C4:SendToProxy(RedlightProxyBinding, "LIGHT_LEVEL", RedLevel)
            C4:UpdateProperty("Red Value", RedLevel)
        end
        if (green ~= nil) then
            GreenValue = green
            GreenLevel = (green == 0) and 0 or math.ceil(green * 100 / 255)
            C4:SendToProxy(GreenlightProxyBinding, "LIGHT_LEVEL", GreenLevel)
            C4:UpdateProperty("Green Value", GreenValue)
        end
        if (blue ~= nil) then
            BlueValue = blue
            BlueLevel = (blue == 0) and 0 or math.ceil(blue * 100 / 255)
            C4:SendToProxy(BluelightProxyBinding, "LIGHT_LEVEL", BlueLevel)
            C4:UpdateProperty("Blue Value", BlueValue)
        end
        C4:SendToProxy(TemplightProxyBinding, "LIGHT_LEVEL", 0)
        C4:UpdateProperty("Color Temperature", 1070)
    end
    -- only update the color temperature property when in Temp Mode
    if (Mode == "Temp") then
        if (colorTemperature ~= nil) then
            TempLevel = colorTemperature == 0 and 0 or
                            math.ceil((colorTemperature - 1700) * 100 / 4800)
            TempValue = colorTemperature
            C4:SendToProxy(TemplightProxyBinding, "LIGHT_LEVEL", TempLevel)
            C4:UpdateProperty("Color Temperature", TempValue)

            C4:SendToProxy(BluelightProxyBinding, "LIGHT_LEVEL", 0)
            C4:UpdateProperty("Blue Value", 0)
            C4:SendToProxy(GreenlightProxyBinding, "LIGHT_LEVEL", 0)
            C4:UpdateProperty("Green Value", 0)
            C4:SendToProxy(RedlightProxyBinding, "LIGHT_LEVEL", 0)
            C4:UpdateProperty("Red Value", 0)
        end
    end

    if (brightness ~= nil) then
        Brightness = brightness
        SendToProxy(lightProxyBinding, "LIGHT_LEVEL", brightness)
        C4:UpdateProperty("Brightness", brightness)
    end
end

-- Turn on function
function YON()
    dbg("Turning on")
    sendToYeeLight(1, "set_power", {"on", "smooth", 500})
end

-- Turn off function
function YOFF()
    dbg("Turning off")
    sendToYeeLight(1, "set_power", {"off", "smooth", 500})
end

-- Set brightness level function
function SET_BRIGHT(brightness)
    dbg("set bright level" .. brightness)
    sendToYeeLight(1, "set_power", {"on", "smooth", "100"})
    local t = C4:SetTimer(200, function(timer)
        sendToYeeLight(1, "set_bright", {brightness, "smooth", 500})
        updateLightProperty(nil, nil, nil, brightness, nil)
    end)
end

-- Set color level function
function SET_COLOR(color, brightness)
    local setBrightness = (brightness == nil) and LastBrightness or brightness
    dbg("set brightness to: " .. tostring(setBrightness))
    Mode = "RGB"
    sendToYeeLight(1, "set_scene", {
        "color", color, setBrightness
    })
end

-- Set color temperature function
function SET_TEMP(temperature, brightness)
    dbg("set color temperature to " .. temperature)
    Mode = "Temp"
    sendToYeeLight(1, "set_scene", {
        "ct", temperature, (brightness == nil) and LastBrightness or brightness
    })
end



C4:CreateNetworkConnection(6001, g_deviceAddress, "Telnet")

function ReceivedFromNetwork(idBinding, nPort, receivestring)
    print("Received from Network " .. idBinding .. ":" .. receivestring)
    local response = C4:JsonDecode(receivestring)
    if (response == nil) then error("invalid response data") end
    if (response["params"] == nil) then error("invalid params") end
    for key, value in pairs(response["params"]) do
        if key == "power" then
            print("power: " .. value)
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


-- Release things this driver had allocated...
function OnDriverDestroyed()
    -- Kill open timers
    if (g_DebugTimer ~= nil) then g_DebugTimer = C4:KillTimer(g_DebugTimer) end
end

function InitLightProxy()
    C4:SendToProxy(lightProxyBinding, "LIGHT_LEVEL_CHANGED", Brightness)
end

function SendToProxy(idBinding, strCommand, tParams, ...)
    dbgFunction("SendToProxy (" .. idBinding .. ", " .. strCommand .. ")")
    if ... then
        local callType = ...
        C4:SendToProxy(idBinding, strCommand, tParams, callType)
    else
        C4:SendToProxy(idBinding, strCommand, tParams)
    end
end

function ExecuteCommand(strCommand, tParams)
    dbg("ExecuteCommand function called with : " .. strCommand)
    if (tParams == nil) then
        --    if (strCommand =="GET_PROPERTIES") then
        --      GET_PROPERTIES()
        --    else
        print("From ExecuteCommand Function - Unutilized command: " ..
                  strCommand)
        --    end
    end
    if (strCommand == "LUA_ACTION") then
        if tParams ~= nil then
            for cmd, cmdv in pairs(tParams) do
                print(cmd, cmdv)
                if cmd == "ACTION" then
                    if cmdv == "InitLightProxy" then
                        InitLightProxy()
                    else
                        dbg("From ExecuteCommand Function - Undefined Action")
                        dbg("Key: " .. cmd .. "  Value: " .. cmdv)
                    end
                else
                    dbg("From ExecuteCommand Function - Undefined Command")
                    dbg("Key: " .. cmd .. "  Value: " .. cmdv)
                end
            end
        end
    elseif (strCommand == "TOP_BUTTON_PUSH") then
        SendToProxy(lightProxyBinding, "TOP_BUTTON-PUSH", {})
    elseif (strCommand == "TOP_BUTTON_RELEASE") then
        if (tParams["NUMBER"] == "1") then
            SendToProxy(lightProxyBinding, "TOP_BUTTON-RELEASE", {})
        end
    elseif (strCommand == "CLICK_COUNT") then
        if (tParams["NUMBER"] == "1") then
            SendToProxy(lightProxyBinding, "CLICK_COUNT",
                        {BUTTON = 0, COUNT = 2})
        end
    elseif (strCommand == "Initialize Light Proxy Data") then
        InitLightProxy()
    end
end

function ReceivedFromProxy(idBinding, strCommand, tParams)
    dbgFunction("ReceivedFromProxy (" .. idBinding .. ", " .. strCommand .. ")")
    CommandInterpreter(idBinding, strCommand, tParams)
end

function ColorTemperatureChangeHandler(strCommand, tParams)
    dbg("Color Temperature Binding")
    Mode = "Temp"
    -- Ramp Level Change Listener
    if (strCommand == "RAMP_TO_LEVEL") then
        dbg("Color Temperature Binding: Ramp Level: " .. TempLevel)
        SET_TEMP(math.floor(1700 + (tonumber(tParams["LEVEL"]) - 1) * 48.4848),
                 nil)
        -- Button Click Handler (Action: 2)
    elseif (strCommand == "BUTTON_ACTION") then
        local action = tParams["ACTION"]
        -- Button Click 
        if (action == "2") then
            dbg("brightness button clicked")
            if (TempLevel == 0) then
                dbg("case 1 : TempLevel = 0, set the color temp to 100%")
                SET_TEMP(6500, nil)
            else
                dbg("case 2 : TempLevel = 100, set the color temp to 0%")
                SET_TEMP(1700, nil)
            end
        end

        -- Add Scene Listener
    elseif (strCommand == "PUSH_SCENE") then
        for k, v in pairs(tParams) do dbg(k .. ": " .. v) end
        local sceneNum = tParams["SCENE_ID"]
        local elements = tParams["ELEMENTS"]
        local flash = tParams["FLASH"]
        dbg("scene_id" .. sceneNum)
        dbg("elements: " .. tParams["ELEMENTS"])
        local elementTable = collect(elements)

        local scene = {}

        for i = 1, #elementTable do
            local t = {}
            t["Delay"] = elementTable[i][1][1]
            t["Rate"] = elementTable[i][2][1]
            t["Level"] = elementTable[i][3][1]
            table.insert(scene, t)
        end
        TsceneCollection[sceneNum] = scene
        TflashCollection[sceneNum] = flash
        TPersistData["TsceneCollection"] = TsceneCollection
        TPersistData["TflashCollection"] = TflashCollection

        -- Activate Scene Listener
    elseif (strCommand == "ACTIVATE_SCENE") then
        local sceneNum = tParams["SCENE_ID"]
        -- local RedLevel = tParams["LEVEL"]
        -- dbg("RedLevel: " .. RedLevel)
        for k, v in pairs(tParams) do dbg(k .. ": " .. v) end
        TcurrentScene = sceneNum
        TelementCounter = 1
        playSceneTemp()

        -- Invalid command
    else
        dbg("invalid command from color temperature binding: " .. strCommand)
    end
end

function RgbChangeHandler(idBinding, strCommand, tParams)
    Mode = "RGB"
    -- Level Ramp Action
    if (strCommand == "RAMP_TO_LEVEL") then
        dbg("Ramping level, RGB")
	   PrintTable(tParams)
        local level = tonumber(tParams["LEVEL"])
        if (idBinding == RedlightProxyBinding) then
            RedValue = math.ceil(level * 255 / 100)
        elseif (idBinding == GreenlightProxyBinding) then
            GreenValue = math.ceil(level * 255 / 100)
        elseif (idBinding == BluelightProxyBinding) then
            BlueValue = math.ceil(level * 255 / 100)
        end
	   dbg("RGB Change Handler: (" .. RedValue .. ",".. GreenValue .. "," .. BlueValue .. ")")
        RGB = (RedValue * 65536) + (GreenValue * 256) + BlueValue

        if (RGB == 0) then
            SET_TEMP((TempLevel == 0) and 1700 or
                         math.floor(1700 + (TempLevel - 1) * 48.4848), nil)
        else
		  print(RGB)
            SET_COLOR(RGB, nil)
        end

        -- Button Click Action
    elseif (strCommand == "BUTTON_ACTION") then
        local action = tParams["ACTION"]
        if (action == "2") then
		  dbg("RGB Before Change: (" .. RedValue .. ",".. GreenValue .. "," .. BlueValue .. ")")
            if (idBinding == RedlightProxyBinding) then
                RedValue = (RedLevel == 0) and 255 or 0
            elseif (idBinding == GreenlightProxyBinding) then
                GreenValue = (GreenLevel == 0) and 255 or 0
            elseif (idBinding == BluelightProxyBinding) then
                BlueValue = (BlueLevel == 0) and 255 or 0
            end
            RGB = (RedValue * 65536) + (GreenValue * 256) + BlueValue
		  dbg("RGB After change: (" .. RedValue .. ",".. GreenValue .. "," .. BlueValue .. ")")
            if (RGB == 0) then
                SET_TEMP((TempLevel == 0) and 0 or
                             math.floor(1700 + (TempLevel - 1) * 48.4848), nil)
            else
                SET_COLOR(RGB, nil)
            end
        end
        -- Add Scene Listener
    elseif (strCommand == "PUSH_SCENE") then
        for k, v in pairs(tParams) do dbg(k .. ": " .. v) end
        local sceneNum = tParams["SCENE_ID"]
        local elements = tParams["ELEMENTS"]
        local flash = tParams["FLASH"]
        dbg("scene_id" .. sceneNum)
        dbg("elements: " .. tParams["ELEMENTS"])
        local elementTable = collect(elements)
        local scene = {}

        for i = 1, #elementTable do
            local t = {}
            t["Delay"] = elementTable[i][1][1]
            t["Rate"] = elementTable[i][2][1]
            t["Level"] = elementTable[i][3][1]
            table.insert(scene, t)
        end

        if idBinding == RedlightProxyBinding then
            RsceneCollection[sceneNum] = scene
            RflashCollection[sceneNum] = flash
            RPersistData["RsceneCollection"] = RsceneCollection
            RPersistData["RflashCollection"] = RflashCollection
        elseif idBinding == GreenlightProxyBinding then
            GsceneCollection[sceneNum] = scene
            GflashCollection[sceneNum] = flash
            GPersistData["GsceneCollection"] = GsceneCollection
            GPersistData["GflashCollection"] = GflashCollection
        elseif idBinding == BluelightProxyBinding then
            BsceneCollection[sceneNum] = scene
            BflashCollection[sceneNum] = flash
            BPersistData["BsceneCollection"] = BsceneCollection
            BPersistData["BflashCollection"] = BflashCollection
        end

        -- Activate Scene Listener
    elseif (strCommand == "ACTIVATE_SCENE") then
        local sceneNum = tParams["SCENE_ID"]
        -- local RedLevel = tParams["LEVEL"]
        -- dbg("RedLevel: " .. RedLevel)
        for k, v in pairs(tParams) do dbg(k .. ": " .. v) end
        if idBinding == RedlightProxyBinding then
            RcurrentScene = sceneNum
            RelementCounter = 1
            playSceneRed()
        elseif idBinding == GreenlightProxyBinding then
            GcurrentScene = sceneNum
            GelementCounter = 1
            playSceneGreen()
        elseif idBinding == BluelightProxyBinding then
            BcurrentScene = sceneNum
            BelementCounter = 1
            playSceneBlue()
        end
    else
        dbg("Invalid command from rgb light proxy command: " .. strCommand ..
                " id binding: " .. idBinding)
    end
end

function CommandInterpreter(idBinding, strCommand, tParams)
    dbgFunction("CommandInterpreter (" .. idBinding .. ", " .. strCommand .. ")")
    if (strCommand ~= nil) then
        tParams = tParams or {}
        dbg("Received from Proxy  on binding: " .. idBinding ..
                "; Call Function " .. strCommand .. "()")
        -- Color Temperature
        if (idBinding == TemplightProxyBinding) then
            ColorTemperatureChangeHandler(strCommand, tParams)
            -- RGB 
        elseif (idBinding == RedlightProxyBinding or idBinding ==
            GreenlightProxyBinding or idBinding == BluelightProxyBinding) then
            RgbChangeHandler(idBinding, strCommand, tParams)
            -- Brightness
        elseif (idBinding == lightProxyBinding) then
            if (strCommand == "GET_LIGHT_LEVEL") then
                GET_LIGHT_LEVEL(idBinding, tParams)
            elseif (strCommand == "GET_CONNECTED_STATE") then
                SendToProxy(lightProxyBinding, "ONLINE_CHANGED", "True")
                -- Button Click Action
            elseif (strCommand == "BUTTON_ACTION") then
			 dbg("Brightness Button Action")
                local action = tParams["ACTION"]
                dbg("action:" .. action)
                if (action == "2") then
                    -- If the brightness is 0, restore the last state
                    if (Brightness == 0) then
                        if (Mode == "Temp") then
					   dbg("Brightness on change: (" .. Brightness .. ")")
                            SET_TEMP(LastTempValue, nil)
                        end
                        if (Mode == "RGB") then
					   dbg("Brightness on change: (" .. RedValue .. ",".. GreenValue .. "," .. BlueValue .. "," .. Brightness .. ")")
                            SET_COLOR(convertRGBToDec(LastRedValue,
                                                      LastGreenValue,
                                                      LastBlueValue),
                                      LastBrightness)
                        end
                    else
                        YOFF()
                    end
                end

            elseif (strCommand == "PUSH_SCENE") then
                for k, v in pairs(tParams) do dbg(k .. ": " .. v) end
                local sceneNum = tParams["SCENE_ID"]
                local elements = tParams["ELEMENTS"]
                local flash = tParams["FLASH"]
                dbg("scene_id" .. sceneNum)
                dbg("elements: " .. tParams["ELEMENTS"])
                local elementTable = collect(elements)
                local scene = {}
                for i = 1, #elementTable do
                    local t = {}
                    t["Delay"] = elementTable[i][1][1]
                    t["Rate"] = elementTable[i][2][1]
                    t["Level"] = elementTable[i][3][1]
                    table.insert(scene, t)
                end
                sceneCollection[sceneNum] = scene
                flashCollection[sceneNum] = flash
                PersistData["sceneCollection"] = sceneCollection
                PersistData["flashCollection"] = flashCollection

            elseif (strCommand == "REMOVE_SCENE") then
                local sceneNum = tParams["SCENE_ID"]
                dbg("scene_id:" .. sceneNum)
                sceneCollection[sceneNum] = nil
                flashCollection[sceneNum] = nil
                PersistData["sceneCollection"] = sceneCollection
                PersistData["flashCollection"] = flashCollection

            elseif (strCommand == "ACTIVATE_SCENE") then
                local sceneNum = tParams["SCENE_ID"]
                for k, v in pairs(tParams) do dbg(k .. ": " .. v) end
                currentScene = sceneNum
                elementCounter = 0
                playScene()

            elseif (strCommand == "RAMP_SCENE_UP") then
                TOGGLE_PRESET(tParams)

            elseif (strCommand == "RAMP_SCENE_DOWN") then
                TOGGLE_PRESET(tParams)

            elseif (strCommand == "RAMP_TO_LEVEL") then
			 dbg("Brightness Ramp Level")
                local lightLevel = tonumber(tParams["LEVEL"])
                if lightLevel == 0 then
                    YOFF()
                else
                    if Mode == "RGB" then
				    dbg("Brightness on change: (" .. RedValue .. ",".. GreenValue .. "," .. BlueValue .. "," .. lightLevel .. ")")
                        SET_COLOR(convertRGBToDec(RedValue, GreenValue,
                                                  BlueValue), lightLevel)
                    end
                    if Mode == "Temp" then
				    dbg("Brightness on change: (" .. lightLevel .. ")")
                        SET_TEMP(TempValue, lightLevel)
                    end
                end

            elseif (strCommand == "SET_LEVEL") then
                local lightLevel = tParams["LEVEL"]
                if lightLevel == 0 then
                    YOFF()
                else
                    if Mode == "RGB" then
                        SET_COLOR(convertRGBToDec(RedValue, GreenValue,
                                                  BlueValue), Brightness)
                    end
                    if Mode == "Temp" then
                        SET_TEMP(TempValue, Brightness)
                    end
                end
            elseif (strCommand == "ON") then
                YON()
            elseif (strCommand == "OFF") then
                YOFF()
            elseif (strCommand == "TOGGLE") then
                TOGGLE_PRESET(tParams)
                -- elseif (strCommand == "TOGGLE_PRESET") then
                --    TOGGLE_PRESET(tParams)
            elseif (strCommand == "GET_CONNECTED_STATE") then
                SendToProxy(lightProxyBinding, "ONLINE_CHANGED", {STATE = true})
            elseif (strCommand == "PUSH_TOGGLE_BUTTON") then -- click handles the toggle in the remote and touch screens
                if (POWER) then
                    YOFF()
                else
                    YON()
                end
            end

        elseif (idBinding == TCP) then
            SendToProxy(lightProxyBinding, "ONLINE_CHANGED", {STATE = true})
            dbg("strCommand:" .. strCommand)
            dbg("tParams" .. tParams)

        elseif (idBinding == ON_BINDING) then
            if (strCommand == "DO_PUSH") then YON() end

        elseif (idBinding == OFF_BINDING) then
            if (strCommand == "DO_PUSH") then YOFF() end

        elseif (idBinding == TOGGLE_BINDING) then
            if (strCommand == "DO_PUSH") then
                if (POWER) then
                    YOFF()
                else
                    YON()
                end
            end
        end

    end
end

function printSceneCollection()
    for k, v in pairs(sceneCollection) do
        dbg("scene#:" .. k)
        for y = 1, #sceneCollection[k] do
            dbg("element: " .. y)
            dbg("delay: " .. sceneCollection[k][y]["Delay"])
            dbg("rate: " .. sceneCollection[k][y]["Rate"])
            dbg("level: " .. sceneCollection[k][y]["Level"])
        end
    end
end

function TprintSceneCollection()
    for k, v in pairs(TsceneCollection) do
        dbg("scene#:" .. k)
        for y = 1, #TsceneCollection[k] do
            dbg("element: " .. y)
            dbg("delay: " .. TsceneCollection[k][y]["Delay"])
            dbg("rate: " .. TsceneCollection[k][y]["Rate"])
            dbg("level: " .. TsceneCollection[k][y]["Level"])
        end
    end
end

function RprintSceneCollection()
    for k, v in pairs(RsceneCollection) do
        dbg("scene#:" .. k)
        for y = 1, #RsceneCollection[k] do
            dbg("element: " .. y)
            dbg("delay: " .. RsceneCollection[k][y]["Delay"])
            dbg("rate: " .. RsceneCollection[k][y]["Rate"])
            dbg("level: " .. RsceneCollection[k][y]["Level"])
        end
    end
end

function GprintSceneCollection()
    for k, v in pairs(GsceneCollection) do
        dbg("scene#:" .. k)
        for y = 1, #GsceneCollection[k] do
            dbg("element: " .. y)
            dbg("delay: " .. GsceneCollection[k][y]["Delay"])
            dbg("rate: " .. GsceneCollection[k][y]["Rate"])
            dbg("level: " .. GsceneCollection[k][y]["Level"])
        end
    end
end

function BprintSceneCollection()
    for k, v in pairs(BsceneCollection) do
        dbg("scene#:" .. k)
        for y = 1, #BsceneCollection[k] do
            dbg("element: " .. y)
            dbg("delay: " .. BsceneCollection[k][y]["Delay"])
            dbg("rate: " .. BsceneCollection[k][y]["Rate"])
            dbg("level: " .. BsceneCollection[k][y]["Level"])
        end
    end
end

function playScene()
    dbg("playScene")
    dbg("elementCounter :" .. elementCounter)
    if (elementCounter ~= 0) then
        dbg("playScene-e")
        local level = tonumber(
                          sceneCollection[tostring(currentScene)][elementCounter]["Level"])
        dbg("level:" .. level)
        dbg("playScene-f")
        if (level == 0) then
            YOFF()
            dbg("playScene-g")
        else
            SET_BRIGHT(level)
        end
    end

    elementCounter = elementCounter + 1
    dbg(elementCounter)

    if (elementCounter > #sceneCollection[tostring(currentScene)] and
        flashCollection[tostring(currentScene)] == "1") then
        elementCounter = 1
        dbg("playScene-i")
    end

    if (elementCounter <= #sceneCollection[tostring(currentScene)]) then
        local timeInterval =
            sceneCollection[tostring(currentScene)][elementCounter]["Delay"] or
                -1
        executeElementTimer = C4:KillTimer(executeElementTimer)
        executeElementTimer = C4:AddTimer(timeInterval, "MILLISECONDS")
        dbg("playScene-j")
    else
        dbg("end of scene")
        dbg("playScene-k")
    end

end

function playSceneRed()
    dbg("playSceneRed")
    dbg("RelementCounter :" .. RelementCounter)
    PrintTable(RPersistData)
    RprintSceneCollection()
    local level =
        RsceneCollection[tostring(RcurrentScene)][RelementCounter]["Level"]
    dbg("level:" .. level)
    dbg("playSceneRed-f")
    if (POWER) then
        SET_COLOR(convertRGBToDec(level, GreenValue, BlueValue), nil)
    else
        SET_COLOR(convertRGBToDec(LastRedValue, level, LastBlueValue), nil)
    end
end

function playSceneGreen()
    dbg("playSceneGreen")
    dbg("GelementCounter :" .. GelementCounter)
    PrintTable(GPersistData)
    GprintSceneCollection()
    local level = tonumber(
                      GsceneCollection[tostring(GcurrentScene)][GelementCounter]["Level"])
    dbg("level:" .. level)
    dbg("playSceneGreen-f")
    if (POWER) then
        SET_COLOR(convertRGBtoDec(RedValue, level, BlueValue), nil)
    else
        SET_COLOR(convertRGBtoDec(LastRedValue, level, LastBlueValue), nil)
    end
end

function playSceneBlue()
    dbg("playSceneBlue")
    dbg("BelementCounter :" .. BelementCounter)
    PrintTable(BPersistData)
    BprintSceneCollection()
    local level = tonumber(
                      BsceneCollection[tostring(BcurrentScene)][BelementCounter]["Level"])
    dbg("level:" .. level)
    dbg("playSceneBlue-f")
    if (POWER) then
        SET_COLOR(convertRGBtoDec(RedValue, GreenValue, level), nil)
    else
        SET_COLOR(convertRGBtoDec(LastRedValue, LastGreenValue, level), nil)
    end
end

function playSceneTemp()
    dbg("playSceneTemp")
    dbg("TelementCounter :" .. TelementCounter)
    PrintTable(TPersistData)
    TprintSceneCollection()
    local level =
        TsceneCollection[tostring(TcurrentScene)][TelementCounter]["Level"]
    if (POWER) then
        SET_TEMP(math.floor(1700 + (level - 1) * 48.4848))
    else
        SET_TEMP(math.floor(1700 + (level - 1) * 48.4848))
    end
end

function GET_LIGHT_LEVEL(idBinding, tParams)
    SET_BRIGHT(tParams["LEVEL"])
    C4:SendToProxy(idBinding, "LIGHT_LEVEL_CHANGED", tParams["LEVEL"])
end

function SET_LEVEL(tParams)
    YON()
    SendToProxy(lightProxyBinding, "SET_LIGHT_LEVEL", tParams)
end

function OnVariableChanged(strName)
    dbgFunction("OnVariableChanged(" .. strName .. ")")
end

-----------------------------  INIT   -----------------------------
-- Fire On Property Changed to set the initial Headers and other Property global sets, they'll change if Property is changed.
function OnDriverInit() for k, v in pairs(Properties) do OnPropertyChanged(k) end end
