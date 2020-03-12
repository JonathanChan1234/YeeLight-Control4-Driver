--
-- properties.lua
-- Track the change of properties
--
require "utils"

function OnPropertyChanged(strProperty)
    dbg("On Property Change: " .. strProperty .. " changed to " ..
            Properties[strProperty])
    -- Update Network Connection when Device IP Address was updated
    if (strProperty == "Device IP Address" and Properties[strProperty] ~= "") then
        C4:CreateNetworkConnection(6001, Properties["Device IP Address"],
                                   "Telnet")
    end
end
