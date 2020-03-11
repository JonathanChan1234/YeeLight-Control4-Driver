--[[=============================================================================
    Helper functions

    Copyright 2016 Control4 Corporation. All Rights Reserved.
===============================================================================]]

-- Set template version for this file
if (TEMPLATE_VERSION ~= nil) then
	TEMPLATE_VERSION.c4_utils = "2016.01.08"
end

--[[=============================================================================
    AsciiToBCD(InString)

    Description
    Convert an ascii string to a binary coded decimal. Each decimal digit is
    stored in one byte, with the lower four bits encoding the digit in BCD form.

    Parameters
    InString(string) - Ascii string that is to be converted into bcd

    Returns
    The binary coded decimal
===============================================================================]]
function AsciiToBCD(InString)
	local WorkVal = 0
	local RetValStr = ""
	local DoingHighNybble = false
	local WorkStr = ((#InString % 2) == 0) and (InString) or ("0" .. InString)	-- make sure length is an even number

	for CharCount = 1, #WorkStr do
		local NumVal = tonumber(WorkStr:sub(CharCount, CharCount))

		WorkVal = bit.lshift(WorkVal, 4) + NumVal
		if (DoingHighNybble) then
			RetValStr = RetValStr .. string.char(WorkVal)
			WorkVal = 0
		end

		DoingHighNybble = (not DoingHighNybble)
	end

	return RetValStr
end

--[[=============================================================================
    BCDToAscii(InByte)

    Description
    Convert an BCD string to an ascii string.

    Parameters
    InByte(string) - Binary coded decimal that is to be converted into ascii

    Returns
    The ascii string
===============================================================================]]
function BCDToAscii(InByte)
	return tostring(bit.rshift(InByte, 4)) .. tostring(bit.band(InByte, 0x0F))
end

--[[=============================================================================
    MakeXMLNode(Tag, Value)

    Description
    Create an Xml element

    Parameters
    Tag(string)   - The Xml elements name
    Value(string) - The Xml elements value

    Returns
    The xml element created for the specified value
===============================================================================]]
function MakeXMLNode(Tag, Value)
	return "<" .. Tag .. ">" .. Value .. "</" .. Tag .. ">"
end

--[[=============================================================================
    MakeXMLAttrNode(Tag, Value, Attribute, AttrValue)

    Description
    Create an Xml element with an attribute

    Parameters
    Tag(string)       - The Xml elements name
    Value(string)     - The Xml elements value
    Attribute(string) - The attribute to be added to the Xml element
    AttrValue(string) - The value of the attribute to be added

    Returns
    The xml element created for the specified value
===============================================================================]]
function MakeXMLAttrNode(Tag, Value, Attribute, AttrValue)
    return "<" .. Tag .. " " .. Attribute .. "=\"" .. AttrValue .. "\">" .. Value .. "</" .. Tag .. ">"
end

--[[=============================================================================
    StringFromUnicode(UnicodeString)

    Description
    Convert a unicode string

    Parameters
    UnicodeString(string) - The unicode string to be converted to ascii

    Returns
    The ascii representation of the unicode string
===============================================================================]]
function StringFromUnicode(UnicodeString)
	local RetVal = ""

	-- extract every other byte from the unicode string
	for Index = 2, #UnicodeString, 2 do
		RetVal = RetVal .. string.sub(UnicodeString, Index, Index)
	end

	return RetVal
end

--[[=============================================================================
    StringSplit(s)

    Description
    Splits a string into multiple strings at every space character

    Parameters
    s(string) - The string that is to be split into several strings at the
                space character

    Returns
    A table of strings containing all the seperate values in the given string
===============================================================================]]
function StringSplit(s)
	local delim = " "
	local result = {}

	if s == nil or s == "" then
		return result
	end

	for match in (s..delim):gmatch("(.-)"..delim) do
		table.insert(result, match)
	end

	return result
end

--[[=============================================================================
    toboolean(s)

    Description
    Returns a boolean representation of the given string

    Parameters
    s(string) - The string to evaluate the boolean representation from

    Returns
    The value true or false based on the given string
===============================================================================]]
function toboolean(val)
	rval = false;

	if type(val) == "string" and (string.lower(val) == "true" or val == "1") then
		rval = true
	elseif type(val) == "number" and val ~= 0 then
		rval =  true
	elseif type(val) == "boolean" and val == true then
		rval = true
	end

	return rval
end

--[[=============================================================================
    Go(to, err, ...)

    Description
    Call a function with the given arguments if it exists or report the error

    Parameters
    to(string)  - The string to evaluate the boolean representation from
    err(string) - The error to report if the function does not exist
    ...         - Additional optional parameters for the function specified by
                  the "to" parameter

    Returns
    Nothing
===============================================================================]]
function Go(to, err, ...)
	if (type(to) == "function") then
		return to(...)
	else
		LogTrace(err)
	end
end

--[[=============================================================================
    IsEmpty(str)

    Description
    Identifies if the string given is nil or empty

    Parameters
    str(string) - The string to evaluate for the empty condition

    Returns
    True if the given value is empty, false otherwise
===============================================================================]]
function IsEmpty(str)
	return str == nil or str == ""
end

--[[=============================================================================
    ReverseTable(a)

    Description
    Reverse table entries (key=value, value=key)

    Parameters
    a(table) - The table to reverse

    Returns
    new reversed table
===============================================================================]]
function ReverseTable(a)
	local b = {}
	for k,v in pairs(a) do b[v] = k end
	return b
end

function tonumber_loc(str, base)
  local s = str:gsub(",", ".") -- Assume US Locale decimal separator
  local num = tonumber(s, base)
  if (num == nil) then
    s = str:gsub("%.", ",") -- Non-US Locale decimal separator
    num = tonumber(s, base)
  end
  return num
end

--[[=============================================================================
    HexToString(InString)

    Description
    Converts a string of Hex characters to a readable string of ASCII characters

    Parameters
    InString(string) - The string to be converted

    Returns
    A string showing the hex bytes of the InString
===============================================================================]]
function HexToString(InString)
	local RetVal = ""

	for Index = 1, #InString do
		RetVal = RetVal .. string.format("%02X ", InString:byte(Index))
	end
	return RetVal
end


--[[=============================================================================
    StringToHex(InString)

    Description
    Converts a string of ASCII characters to as string with the actual Hex bytes in them.
	Basically an array of hex bytes.

    Parameters
    InString(string) - The string to be converted

    Returns
    A string of hex bytes (really an array of hex values) 
===============================================================================]]
function StringToHex(InString)
	local RetVal = ""

	for HexByteString in string.gfind(InString, "%x%x") do
		RetVal = RetVal .. string.char(tonumber(HexByteString, 16))
	end
	return RetVal
end

function RecordHistory(severity, eventType, category, subcategory, description)
	C4:RecordHistory(severity, eventType, category, subcategory, description)
end

function RecordCriticalHistory(eventType, category, subcategory, description)
	RecordHistory("Critical", eventType, category, subcategory, description)
end

function RecordWarningHistory(eventType, category, subcategory, description)
	RecordHistory("Warning", eventType, category, subcategory, description)
end

function RecordInfoHistory(eventType, category, subcategory, description)
	RecordHistory("Info", eventType, category, subcategory, description)
end


