local skynet = require "skynet"
local runconfig = requre "runconfig"

skynet.start(function()
    -- 初始化
    skynet.error("[start main]")
    skynet.error(runconfig.agentmgr.node)
    skynet.exit()
end)