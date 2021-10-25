local skynet = require "skynet"
local mc = require "skynet.multicast"
local channel

function task( )
    local i = 0
    while i < 100 do
        skynet.sleep(100)
        -- 推送数据
        channel:publish("data"..i)
        i = i + 1
    end
    channel:delete()
    skynet.exit()
end

skynet.start(function ( ... )
    -- 创建一个频道，成功创建后，channel.channel是这个频道的id
    channel = mc.new()
    skynet.error("new channel ID", channel.channel)
    skynet.fork(task)
end)