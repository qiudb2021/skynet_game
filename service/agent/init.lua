local skynet = require "skynet"
local s = require "service"

s.client = {}
s.gate = nil

function s.init()
    -- 在此处加载角色数据
    skynet.sleep(200)
    s.data = {
        coin = 100,
        hp   = 200
    }
end

function s.resp.client( source, cmd, msg )
    s.gate = source;
    local func = s.client[cmd]
    if func then
        local ret_msg = s.client[cmd](msg, source)
        if ret_msg then
            skynet.send(source, "lua", "send", s.id, ret_msg)
        end
    else
        skynet.error("s.resp.client fail ", cmd)
    end
end

function s.resp.kick( source )
    -- 在此处保存角色数据
    skynet.sleep(200)
    skynet.error("保存玩家数据成功")
end

function s.resp.exit( source )
    skynet.exit()
end

function s.client.work( msg, source )
    s.data.coin = s.data.coin + 1
    return {"work", s.data.coin}
end

s.start(...)