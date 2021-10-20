local skynet = require "skynet"
local s = require "service"
local socket = require "skynet.socket"
local runconfig = require "runconfig"

-- 保存客户端连接
local conns = {} -- [fd] = conn
-- 保存已登录玩家信息
local players = {} -- [playerid] = gateplayer

local function conn()
    local m = {
        fd       = nil,
        playerid = nil,
    }
    return m;
end

local function gateplayer()
    local m = {
        playerid = nil,
        agent    = nil,
        conn     = nil,
    }
    return m;
end

local function connect(fd, addr)
    print("connect from "..addr.." "..fd)
    local c = conn();
    conns[fd] = c
    c.fd = fd
    -- skynet.fork(recv_loop, fd)
end

function s.init()
    skynet.error("[start]"..s.name.." "..s.id)
    local node = skynet.getenv("node")
    local nodecfg = runconfig[node]
    local port = nodecfg.gateway[s.id]

    local listenfd = socket.listen("0.0.0.0", port)
    skynet.error("gateway listen socket : ", "0.0.0.0 ", port);
    socket.start(listenfd, connect);
end

s.start(...)