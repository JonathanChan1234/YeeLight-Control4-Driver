--[[=============================================================================
    Base for a network server connection driver

    Copyright 2016 Control4 Corporation. All Rights Reserved.
===============================================================================]]
require "common.c4_device_connection_base"
require "lib.c4_log"

-- Set template version for this file
if (TEMPLATE_VERSION ~= nil) then
	TEMPLATE_VERSION.c4_networkserver_connection = "2016.01.08"
end

DEFAULT_POLLING_INTERVAL_SECONDS = 30

gNetworkKeepAliveInterval = DEFAULT_POLLING_INTERVAL_SECONDS

JK_NETWORK_BINDING_ID = 6001
JK_IP_ADDRESS = "192.168.0.169"
JK_PORT = 0x0C00


NetworkServerConnectionBase = inheritsFrom(DeviceConnectionBase)

function NetworkServerConnectionBase:construct()
	self.superClass():construct()

	self._Port = JK_PORT
	self._Handle = 0
end

function NetworkServerConnectionBase:Initialize(ExpectAck, DelayInterval, WaitInterval)
	print("NetworkServerConnectionBase:Initialize")
	gControlMethod = "NetworkServer"
	self:superClass():Initialize(ExpectAck, DelayInterval, WaitInterval, self)

end

function NetworkServerConnectionBase:ControlMethod()
	return "NetworkServer"
end

function NetworkServerConnectionBase:SendCommand(sCommand, ...)
	if(self._IsConnected) then
		if(self._IsOnline) then
			local command_delay = select(1, ...)
			local delay_units = select(2, ...)
			local command_name = select(3, ...)

			C4:SendToNetwork(self._BindingID, self._Port, sCommand)
			self:StartCommandTimer(command_delay, delay_units, command_name)
		else
			self:CheckNetworkConnectionStatus()
		end
	else
		LogWarn("Not connected to network. Command not sent.")
	end
end


function NetworkServerConnectionBase:SendRaw(sData)
--	LogTrace("Sending raw: %s", HexToString(sData))
	C4:ServerSend(self._Handle, sData, #sData)
end


function NetworkServerConnectionBase:ReceivedFromNetworkServer(nHandle, sData)
	self._Handle = nHandle
	self:ReceivedFromCom(sData)
end


function NetworkServerConnectionBase:StartListening()
	LogTrace("Creating Listener on Port %d", self._Port)
	C4:CreateServer(self._Port)
end


function NetworkServerConnectionBase:StopListening()
	LogTrace("Closing Listener on Port %d", self._Port)
	C4:DestroyServer()
end



-- function NetworkServerConnectionBase:CheckNetworkConnectionStatus()
	-- if (self._IsConnected and (not self._IsOnline)) then
		-- LogWarn("Network status is OFFLINE. Trying to reconnect to the device's Control port...")
		-- C4:NetDisconnect(self._BindingID, self._Port)
		-- C4:NetConnect(self._BindingID, self._Port)
	-- end
-- end

-- function NetworkServerConnectionBase.OnKeepAliveTimerExpired(Instance)
	-- Instance._LastCheckin = Instance._LastCheckin + 1

	-- if(Instance._LastCheckin > 2) then
		-- if(not Instance._IsOnline) then
			-- C4:NetDisconnect(Instance._BindingID, Instance._Port)
			-- C4:NetConnect(Instance._BindingID, Instance._Port)
		-- else
			-- C4:NetDisconnect(Instance._BindingID, Instance._Port)
			-- LogWarn("Failed to receive poll responses... Disconnecting...")
		-- end
	-- end

	-- if (SendKeepAlivePollingCommand ~= nil and type(SendKeepAlivePollingCommand) == "function") then
		-- SendKeepAlivePollingCommand()
	-- end

	-- Instance._KeepAliveTimer:StartTimer(gNetworkKeepAliveInterval)
-- end

-- function NetworkServerConnectionBase:SetOnlineStatus(IsOnline)
	-- self._IsOnline = IsOnline

	-- if(IsOnline) then
		-- self._KeepAliveTimer:StartTimer()
		-- self._LastCheckin = 0
		-- if (UpdateProperty ~= nil and type(UpdateProperty) == "function") then
			-- UpdateProperty("Connected To Network", "true")
		-- end

		-- self:SendNextCommand()
	-- else
		-- self._KeepAliveTimer:KillTimer()
		-- if (UpdateProperty ~= nil and type(UpdateProperty) == "function") then
			-- UpdateProperty("Connected To Network", "false")
		-- end
	-- end
-- end

