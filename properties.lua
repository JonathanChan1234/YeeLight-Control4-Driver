--
-- properties.lua
-- Track the change of properties
--

require "utils"

function OnPropertyChanged(strProperty)
    dbg("On Property Change: ".. strProperty .. " changed to ".. Properties[strProperty])
end