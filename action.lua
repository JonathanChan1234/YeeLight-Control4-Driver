--
-- action.lua
--
function InitLightProxy()
    C4:SendToProxy(lightProxyBinding, "LIGHT_LEVEL_CHANGED", Brightness)
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
        C4:SendToProxy(lightProxyBinding, "TOP_BUTTON-PUSH", {})
    elseif (strCommand == "TOP_BUTTON_RELEASE") then
        if (tParams["NUMBER"] == "1") then
            C4:SendToProxy(lightProxyBinding, "TOP_BUTTON-RELEASE", {})
        end
    elseif (strCommand == "CLICK_COUNT") then
        if (tParams["NUMBER"] == "1") then
            C4:SendToProxy(lightProxyBinding, "CLICK_COUNT",
                           {BUTTON = 0, COUNT = 2})
        end
    elseif (strCommand == "Initialize Light Proxy Data") then
        InitLightProxy()
    end
end
