package.cpath = "../3rd/?.so"
package.path = "../3rd/?.lua"

local lsocket = require "lsocket"
local jsonpack = require "jsonpack"
local util = require "util"
math.randomseed(os.time())

local addr = "127.0.0.1"
local port = 7001
local msg_type = "reg"
local client_count = 1
local i = 1
local MSG = {}

local reg_count = 0
local login_count = 100000

function MSG.REG()
	reg_count = reg_count + 1
	return "100+2+1+"..jsonpack.pack({user="zhaodj"..tostring(reg_count),pwd="123"})
end

function MSG.LOGIN()
	random_index = math.random(login_count)
	return "200+1+1+"..jsonpack.pack({user="zhaodj"..tostring(random_index),pwd="123"})
end

while arg[i] do
	local key,value = string.match(arg[i], "(%-.)(.*)")
	if key == "-h" then
		addr = value
	elseif key == "-p" then
		port = tonumber(value)
	elseif key == "-c" then
		client_count = tonumber(value)
	elseif key == "-t" then
		msg_type = value
	end
	i = i + 1
end

local sockets = {}
local socket_infos = {}

local function add_socket(addr, port)
	local client, err = lsocket.connect(addr, port)
	if not client then
		print("error: "..err)
		return
	end
	-- wait for connect() to succeed or fail
	lsocket.select(nil, {client})
	local ok, err = client:status()
	if not ok then
		print("error: "..err)
		client:close()
		return
	end
	sockets[#sockets+1] = client
	socket_infos[client] = {status=true, last=""}
end

function remove_socket(client)
	local i, s
	for i, s in ipairs(sockets) do
		if s == client then
			table.remove(sockets, i)
			socketinfo[client] = nil
			return
		end
	end
end

--start connect
while #sockets < client_count do
	add_socket(addr, port)
end

while true do
	--send message
	for k, v in pairs(socket_infos) do  
		if v.status then
			msg_data = MSG[string.upper(msg_type)]()
			--print(msg_data)
			util.send_package(k, msg_data)
			v.status = false
		end
	end 
	--recv message
	ready = lsocket.select(sockets)
	for _, s in ipairs(ready) do
		local v
		v, socket_infos[s].last = util.recv_package(s, socket_infos[s].last)
		if v == false then
			s:close()
			remove_socket(s)
		elseif v then
			--print(v)
			socket_infos[s].status = true
		end
	end
	--add socket
	while #sockets < client_count do
		add_socket(addr, port)
	end
end
