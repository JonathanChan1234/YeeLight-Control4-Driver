--[[=============================================================================
    Main script file for driver

    Copyright 2018 HKT Limited. All Rights Reserved.
===============================================================================]] -- require "common.c4_driver_declarations"
require "action"
require "utils"
require "proxy"
require "network"
require "connection"
require "properties"

-- Release things this driver had allocated...
function OnDriverDestroyed() end

function OnVariableChanged(strName) dbg("OnVariableChanged(" .. strName .. ")") end

-----------------------------  INIT   -----------------------------
-- Fire On Property Changed to set the initial Headers and other Property global sets, they'll change if Property is changed.
do
  if (C4.GetDriverConfigInfo) then
    VERSION = C4:GetDriverConfigInfo ("version")
  else
    VERSION = 'check version with info...'
  end
end

function OnDriverLateInit()
    OnPropertyChanged ('Driver Version')
    -- Only for development stage
    PersistData["YEELIGHT_PROFILE"] = {}
    PersistData["YEELIGHT_HISTORY"] = {}
end
