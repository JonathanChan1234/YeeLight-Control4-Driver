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
function OnDriverInit() for k, v in pairs(Properties) do OnPropertyChanged(k) end end
