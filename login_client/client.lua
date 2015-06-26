package.cpath = "../3rd/?.so"
package.path = "../3rd/?.lua"

local lsocket = require "lsocket"
local jsonpack = require "jsonpack"
local util = require "util"

local addr = "127.0.0.1"
local port = 9101
local acc = "robot"
local pass = "123456"
local logfile = "./log.txt"
local i = 1

while arg[i] do
	local key,value = string.match(arg[i], "(%-.)(.*)")
	if key == "-h" then
		addr = value
	elseif key == "-p" then
		port = tonumber(value)
	elseif key == "-A" then
		acc = value
	elseif key == "-P" then
		pass = value
	elseif key == "-l" then
		logfile = value
	end
	i = i + 1
end

print("connect to "..addr..":"..tostring(port).."...")
local client, err = lsocket.connect(addr, port)
if not client then
	print("error: "..err)
	util.write_file(logfile, "0")
	os.exit(1)
end

-- wait for connect() to succeed or fail
lsocket.select(nil, {client})
local ok, err = client:status()
if not ok then
	print("error: "..err)
	util.write_file(logfile, "0")
	os.exit(1)
end

--print "Socket info:"
--for k, v in pairs(client:info()) do
--	io.write(k..": "..tostring(v)..", ")
--end
local socket_info = client:info("socket")
print("socket: "..socket_info.family.." "..socket_info.addr..":"..socket_info.port)
--local peer_info = client:info("peer")
--print("Peer: "..peer_info.family.." "..peer_info.addr..":"..peer_info.port)

local package = string.pack("BBB>s2>s2>s2>s2>I4>I4", 0, 0, 0, acc, pass, "", "1", 0, 999999)
print("send package 0-0 :"..jsonpack.pack(package))
util.send_package(client, package)

local last = ""

local function dispatch_package(client)
	while true do
		local v
		lsocket.select({client})
		v, last = util.recv_package(client, last)
		if v == false then
			client:close()
			util.write_file(logfile, "0")
			os.exit(1)
		end

		if not v then
			return ""
		end
		return v
	end
end

local return_value = ""
local start_time = os.clock()
while true do
	return_value = dispatch_package(client)
	if return_value == "" then
		if os.clock() - start_time > 5 then
			client:close()
			util.write_file(logfile, "0")
			os.exit(1)
		end
	else
		print("recv package 0-0 :"..jsonpack.pack(return_value))
		util.write_file(logfile, "1")
		break
	end
end

client:close()
