local skynet = require "skynet"
local s = require "service"

function s.resp.newservice (source, name, ...)
    local srv = skynet.newservice(name, ...)
    return srv
end

s.start(...)