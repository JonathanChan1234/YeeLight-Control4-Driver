--
-- connection.lua
--

function OnConnectionStatusChanged(idBinding, nPort, strStatus)
  if (idBinding == 6001) then
    if (strStatus == "ONLINE") then
	   dbg("OnConnectionStatusChanged: Online")
	   C4:UpdateProperty("Connection Status", "online")
    else
	   dbg("OnConnectionStatusChanged: Offline")
	   C4:UpdateProperty("Connection Status", "online")
    end
  end
end
