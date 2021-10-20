local skynet = require "skynet"
local runconfig = require "runconfig"
require "skynet.manager"

skynet.start(function()
    -- 初始化
    skynet.error("[start main]")

    local handle
    local node = skynet.getenv("node")
    local nodecfg = runconfig[node]

    -- agentmgr
    if runconfig.agentmgr.node == node then
        handle = skynet.newservice("agentmgr", "agentmgr")
        skynet.name("agentmgr", handle)
    end
    -- gateway
    for i, v in pairs(nodecfg.gateway or {}) do
        handle = skynet.newservice("gateway", "gateway", i)
        skynet.name("gateway"..i, handle)
    end

    -- login
    for i, v in pairs(nodecfg.login or {}) do
        handle = skynet.newservice("login", "login", i)
        skynet.name("login"..i, handle)
    end

    skynet.exit()
end)