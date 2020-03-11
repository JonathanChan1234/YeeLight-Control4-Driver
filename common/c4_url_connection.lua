--[[=============================================================================
    Base for a url connection driver

    Copyright 2016 Control4 Corporation. All Rights Reserved.
===============================================================================]]
require "common.c4_device_connection_base"

-- Set template version for this file
if (TEMPLATE_VERSION ~= nil) then
	TEMPLATE_VERSION.c4_url_connection = "2016.01.08"
end

UrlConnectionBase = inheritsFrom(DeviceConnectionBase)

function UrlConnectionBase:construct(Url)
	self.superClass():construct()
	self._Url = Url
end

function UrlConnectionBase:Initialize(ExpectAck, DelayInterval, WaitInterval)
	gControlMethod = "URL"
	self:superClass():Initialize(ExpectAck, DelayInterval, WaitInterval, self)
	OnURLConnectionChanged()
end

function UrlConnectionBase:ControlMethod()
	return "URL"
end

function UrlConnectionBase:SetUrl(Url)
	self._Url = Url
end

function UrlConnectionBase:SendCommand(sCommand, sHeader, ignoreConnect)
	ignoreConnect = ignoreConnect or false

	local ticketId
	if(self._IsConnected or ignoreConnect) then
		if (sHeader ~= nil) then
			ticketId = C4:urlPost(self._Url, sCommand, sHeader)
		else
			ticketId = C4:urlPost(self._Url, sCommand)
		end
	else
		LogWarn("Not connected. Command not sent.")
	end
	
	return ticketId
end

function UrlConnectionBase:SendCommandUrl(sCommand, url, sHeader, ignoreConnect)
	ignoreConnect = ignoreConnect or false

	local ticketId
	if(self._IsConnected or ignoreConnect) then
		if (sHeader ~= nil) then
			ticketId = C4:urlPost(url, sCommand, sHeader)
		else
			ticketId = C4:urlPost(url, sCommand)
		end
	else
		LogWarn("Not connected. Command not sent.")
	end
	
	return ticketId
end

function UrlConnectionBase:UrlPost(sCommand, url, sHeader, ignoreConnect)
	ignoreConnect = ignoreConnect or false

	local ticketId
	if(self._IsConnected or ignoreConnect) then
		if (sHeader ~= nil) then
			ticketId = C4:urlPost(url, sCommand, sHeader)
		else
			ticketId = C4:urlPost(url, sCommand)
		end
	else
		LogWarn("Not connected. Command not sent.")
	end
	
	return ticketId
end

function UrlConnectionBase:UrlGet(url, sHeader, ignoreConnect)
	ignoreConnect = ignoreConnect or false

	local ticketId
	if(self._IsConnected or ignoreConnect) then
		if (sHeader ~= nil) then
			ticketId = C4:urlGet(url, sHeader)
		else
			ticketId = C4:urlGet(url)
		end
	else
		LogWarn("Not connected. Command not sent.")
	end
	
	return ticketId
end

function UrlConnectionBase:ReceivedAsync(ticketId, sData, responseCode, tHeaders)
	LogTrace("ReceivedAsync[" .. ticketId .. "]: Response Code: " .. responseCode .. " Length: " .. string.len(sData))
	LogTrace(tHeaders)
	local tMessage = {
		["ticketId"] = ticketId,
		["sData"] = sData,
		["responseCode"] = responseCode,
		["tHeaders"] = tHeaders
	}
	
	status, err = pcall(HandleMessage, tMessage)
	if (not status) then
		LogError("LUA_ERROR: " .. err)
	end
end

function ConnectURL()
	gIsUrlConnected = true
	SetControlMethod()
end

function DisconnectURL()
	gIsUrlConnected = false
	SetControlMethod()
end
