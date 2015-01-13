package.cpath = "../3rd/?.so"
package.path = "../3rd/?.lua"

local lsocket = require "lsocket"
local jsonpack = require "jsonpack"
local util = require "util"

local addr = "127.0.0.1"
local port = 7001
local i = 1

while arg[i] do
	local key,value = string.match(arg[i], "(%-.)(.*)")
	if key == "-h" then
		addr = value
	elseif key == "-p" then
		port = value
	end
	i = i + 1
end

print("connect to "..addr..":"..tostring(port).."...")
local client, err = lsocket.connect(addr, port)
if not client then
	print("error: "..err)
	os.exit(1)
end

-- wait for connect() to succeed or fail
lsocket.select(nil, {client})
local ok, err = client:status()
if not ok then
	print("error: "..err)
	os.exit(1)
end

--print "Socket info:"
--for k, v in pairs(client:info()) do
--	io.write(k..": "..tostring(v)..", ")
--end
local socket_info = client:info("socket")
print("Socket: "..socket_info.family.." "..socket_info.addr..":"..socket_info.port)
--local peer_info = client:info("peer")
--print("Peer: "..peer_info.family.." "..peer_info.addr..":"..peer_info.port)

print("Message format: model_id+action_id+version_id+{message data table}")
print("Type quit to quit...")

local last = ""

local function dispatch_package(client)
	while true do
		local v
		lsocket.select({client})		
		v, last = util.recv_package(client, last)

		if v == false then
			client:close()
			os.exit(1)
		end

		if not v then
			break
		end
		print("response:", v)
		break
	end
end

repeat
	io.write("Enter a message: ")
	local s = io.read()
	if s then
		local model_id, action_id, version_id, msg_data = string.match(s, "(%d+)%+(%d+)%+(%d+)%+(.*)")
		if model_id and action_id and version_id and msg_data then
			local f = loadstring("return "..msg_data);
			temp_data = f()
			if temp_data then
				util.send_package(client, tostring(model_id).."+"..tostring(action_id).."+"..tostring(version_id).."+"..jsonpack.pack(temp_data))
				dispatch_package(client)			
			end
		end
	end
until s == "quit"

client:close()
