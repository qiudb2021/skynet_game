local skynet = require "skynet"
local s = require "service"

s.client = {}

function s.resp.client( source, fd, cmd, msg )
    local func = s.client[cmd]
    if func then
       local ret_msg = func(fd, msg, source)
       skynet.send(source, "lua", "send_by_fd", fd, ret_msg)
    else
        skynet.error("s.resp.client fail", cmd) 
    end
end

function s.client.login( fd, msg, source )
    local playerid = tonumber(msg[2])
    local password = msg[3]
    local gate = source
    local node = skynet.getenv("node")
   
    skynet.error("password type " ..type(password).."value "..msg[3])
    --校验密码
    if password ~= '123' then
        return {"login", 1, "密码错误"}
    end

    -- 发送给agentmgr
    local isok, agent = skynet.call("agentmgr", "lua", "reqlogin", playerid, node, gate)
    if not isok then
        return {"login", 1, "请求mgr失败"}
    end

    -- 回应gate
    local isok = skynet.call(gate, "lua", "sure_agent", fd, playerid, agent)
    if not isok then
        return {"login", 1, "gate注册失败"}
    end
    skynet.error("login success "..playerid)
    return {"login", 0, "登录成功"}
end
s.start(...)