local skynet = require "skynet"
local cluster = require "skynet.cluster"
local runconfig = require "runconfig"
require "skynet.manager"

skynet.start(function()
    -- 初始化
    skynet.error("[start main]")

    local handle
    local node = skynet.getenv("node")
    local nodecfg = runconfig[node]

    --节点管理
    local nodemgr = skynet.newservice("nodemgr", "nodemgr", 0)
    skynet.name("nodemgr", nodemgr)

    -- 集群
    cluster.reload(runconfig.cluster)
    cluster.open(node)

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

    -- agentmgr
    local anode = runconfig.agentmgr.node
    if anode == node then
        handle = skynet.newservice("agentmgr", "agentmgr")
        skynet.name("agentmgr", handle)
    else
        local proxy = cluster.proxy(anode, "agentmgr")
        skynet.name("agentmgr", proxy)
    end

    skynet.exit()
end)