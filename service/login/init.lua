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
    skynet.error("login recv "..msg[1].." "..msg[2])
    return {"login", -1, "测试"}
end
s.start(...)