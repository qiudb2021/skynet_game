local skynet = require "skynet"
local runconfig = require "runconfig"
require "skynet.manager"

skynet.start(function()
    -- 初始化
    skynet.error("[start main]")

    local handle
    local node = skynet.getenv("node")
    local nodecfg = runconfig[node]


    for i, v in pairs(nodecfg.gateway or {}) do
        handle = skynet.newservice("gateway", "gateway", i)
        skynet.name("gateway"..i, handle)
    end
    skynet.exit()
end)