local skynet = require "skynet"
local s = require "service"
local socket = require "skynet.socket"
local cluster = require "skynet.cluster"
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

local function disconnect(fd)
    local conn = conns[fd]
    if not conn then
        return
    end

    local playerid = conn.playerid
    -- 还未完成登录就下线
    if not playerid then
        return
    -- 已经在游戏中
    else
        players[playerid] = nil
        local reason = "断线"
        cluster.call("agentmgr", "lua", "reqkick", playerid, reason)
    end
end

-- unpack msg
-- 字符串协议格式，每条消息由“\r\n”作为结束符，
-- 消息的各个参数用英文逗号分隔，第一个参数代表消息名称。
local function str_unpack(msgstr)
    local msg = {}
    while true do
        local arg, rest = string.match( msgstr,"(.-),(.*)" )
        if arg then
            msgstr = rest
            table.insert( msg, arg )
        else
            table.insert( msg, msgstr )
            break
        end
    end
    -- cmd, {cmd, ...}
    return msg[1], msg
end

-- pack msg
local function str_pack(cmd, msg)
    return table.concat( msg, "," ).."\r\n"
end

local function random_login()
    local node = skynet.getenv("node")
    local nodecfg = runconfig[node]
    local id = math.random( 1, #nodecfg.login )
    return "login"..id
end

local function process_msg(fd, msgstr)
    skynet.error("gateway"..s.id.." recv from ["..fd.."] msgstr "..msgstr)
    local cmd, msg = str_unpack(msgstr)
    if not cmd then
        skynet.error("gateway recv from ["..fd.."] not cmd.")
        return
    end

    local conn = conns[fd]
    local playerid = conn.playerid
    -- 尚未完成登录
    if not playerid then
        local login = random_login()
        skynet.error("todo require login to "..login.." auth username and password.")
        -- skynet.send(login, "lua", "client", fd, cmd, msg)
    -- 已完成登录
    else
        local gplayer = players[playerid]
        local agent = gplayer.agent
        skynet.error("todo forword msg to the agent.")
        -- skynet.send(agent, "lua", "client", cmd, msg)
    end
end

local function process_buff(fd, readbuff)
    while true do
        local msgstr, rest = string.match( readbuff, "(.-)\r\n(.*)" )
        if msgstr then
            readbuff = rest
            process_msg(fd, msgstr)
        else
            return readbuff
        end
    end
end

-- 每一条新连接接收数据处理
local function recv_loop(fd)
    socket.start(fd)
    skynet.error("socket connected "..fd)
    local readbuff = ""
    while true do
        local recvstr = socket.read(fd)
        if recvstr then
            readbuff = readbuff..recvstr
            readbuff = process_buff(fd, readbuff)
        else
            skynet.error("socket close "..fd)
            disconnect(fd)
            socket.close(fd)
            return
        end
    end
end

-- 接收新连接
local function connect(fd, addr)
    print("connect from "..addr.." "..fd)
    local c = conn();
    conns[fd] = c
    c.fd = fd
    skynet.fork(recv_loop, fd)
end

function s.init()
    skynet.error("[start]"..s.name.." "..s.id)
    local node = skynet.getenv("node")
    local nodecfg = runconfig[node]
    local port = nodecfg.gateway[s.id].port

    local listenfd = socket.listen("0.0.0.0", port)
    skynet.error("gateway listen socket : ", "0.0.0.0 ", port);
    socket.start(listenfd, connect);
end

-- forward login message.
function s.resp.send_by_fd( source, fd, msg )
    local c = conns[fd]
    if not c then
        return
    end

    skynet.error("gateway "..s.id.." send "..fd.."["..msg[1].."] {"..table.concat( msg, "," ))
    socket.write(fd, str_pack(msg[1], msg))
end

-- forward agent message.
function s.resp.send( source, playerid, msg )
    local gplayer = players[playerid]
    if not gplayer then
        return
    end

    local c = gplayer.conn
    if not c then
        return
    end

    s.resp.send_by_fd(source, c.fd, msg)
end

-- login -> gateway
function s.resp.sure_agent( source, fd, playerid, agent )
    local conn = conns[fd]
    -- 登录过程中已经下线
    if not conn then
        cluster.call("agentmgr", "lua", "reqkick", playerid, "未完成登录即下线")
        return false
    end

    conn.playerid = playerid
    local gplayer = gateplayer()
    gplayer.playerid = playerid
    gplayer.agent = agent
    gplayer.conn = conn
    players[playerid] = gplayer

    return true
end

function s.resp.kick( source, playerid )
    local gplayer = players[playerid]
    if not gplayer then
        return
    end

    players[playerid] = nil
    local conn = gplayer.conn
    if not conn then
        return
    end

    disconnect(conn.fd)
    socket.close(conn.fd)
end

s.start(...)