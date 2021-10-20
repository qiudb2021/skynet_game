local skynet = require "skynet"
local s = require "service"

local STATUS = {
    LOGIN = 2,
    GAME  = 3,
    LOGOUT = 4,
}

local players = {} -- [playerid] = mgrplayer

local function mgrplayer()
    local m = {
        playerid = nil,
        node = nil,
        agent = nil,
        status = nil,
        gate = nil,
    }
    return m
end

-- login -> agentmgr
function s.resp.reqlogin( source, playerid, node, gate )
    local mplayer = players[playerid]
    -- 登出过程中禁止顶替
    if mplayer and mplayer.status == STATUS.LOGOUT then
        skynet.error("reqlogin fail, at status LOGOUT "..playerid)
        return false
    end

    -- 登录过程中禁止顶替
    if mplayer and mplayer.status == STATUS.LOGIN then
        skynet.error("reqlogin fail, at status LOGIN "..playerid)
        return false
    end

    -- 在线，顶替
    if mplayer then
        local pnode = mplayer.node
        local pagent = mplayer.agent
        local pgate = mplayer.pgate

        s.call(pnode, pagent, "kick")
        s.send(pnode, pagent, "exit")

        s.send(pnode, pgate, "send", playerid, {"kick", "顶替下线"})
        s.call(pnode, pgate, "kick", playerid)
    end

    --上线
    local player = mgrplayer()
    player.playerid = playerid
    player.node = node
    player.gate = gate
    player.agent = nil
    player.status = STATUS.LOGIN

    players[playerid] = player

    local agent = s.call(node, "nodemgr", "newservice", "agent", "agent", playerid)
    player.agent = agent
    player.status = STATUS.GAME
    return true, agent
end

function s.resp.reqkick( source, playerid, reason )
    local mplayer = players[playerid]
    if not mplayer then
        return false
    end

    if mplayer.status ~= STATUS.GAME then
        return false
    end

    local pnode = mplayer.node
    local pagent = mplayer.agent
    local pgate = mplayer.gate

    mplayer.status = STATUS.LOGOUT

    s.call(node, pagent, "kick")
    s.send(node, pagent, "exit")

    s.send(node, pgate, "kick", playerid)
    
    players[playerid] = nil

    return true
end

s.start(...)


