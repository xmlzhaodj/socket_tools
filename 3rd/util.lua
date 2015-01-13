local cjson = require "cjson"
local bit32 = require "bit32"
local lsocket = require "lsocket"

local util = {}

local function unpack_package(text)
	local size = #text
	if size < 2 then
		return nil, text
	end
	local s = text:byte(1) * 256 + text:byte(2)
	if size < s+2 then
		return nil, text
	end
	return text:sub(3,2+s), text:sub(3+s)
end

function util.send_package(client, pack)
	local size = #pack
	local package = string.char(bit32.extract(size,8,8)) ..
		string.char(bit32.extract(size,0,8))..
		pack
	client:send(package)
end

function util.recv_package(client, last)
	local result
	result, last = unpack_package(last)
	if result then
		return result, last
	end

	local r, err = client:recv()
	if r then
		return unpack_package(last .. r)
	elseif err then
		print(tostring(err))
		return false, nil
	else
		print("Server closed")
		return false, nil
	end	
end

return util