local skynet = require "skynet"
local cluster = require "skynet.cluster"

local M = {
    -- 类型和id
    name = "",
    id   = 0,
    -- 回调函数
    exit = nil,
    init = nil,
    -- 分发方法
    resp = {}
}
--[[
note:
    1) skynet.ret(msg, sz) 将打包好的消息回应给当前任务的请求源头
    2) skynet.retpack(...) 将消息用pack打包，并调用skynet.ret回应
    3) xpcall(...) 安全的调用func方法。如果func报错，程序不会中断，而是会把错误信息转交给第2个参数traceback。如果程序报错xpcall会返回false;
--]]

local function traceback(err)
    skynet.error(tostring(err))
    skynet.error(debug.traceback())
end

local function dispatch(session, address, cmd, ...)
    local func = M.resp[cmd]
    if not func then
        skynet.ret()
        return
    end

    --[[
        xpcall(...) 安全的调用func方法。如果func报错，程序不会中断，而是会把错误信息转交给第2个参数traceback。
        如果程序报错xpcall会返回false; 如果程序正常执行，xpcall返回的第1个值为true，从第2个值开始才是func的返回值
        xpcall会把第3个及后面的参数传给fun，即funcS第1个参数是address，从第2参数开始是可变参数
    ]]
    local ret = table.pack(xpcall(func, traceback, address, ...))
    local isok = ret[1]
    if not isok then
        skynet.ret()
        return
    end

    skynet.retpack(table.unpack(ret, 2))
end

local function init()
    skynet.dispatch("lua", dispatch)
    if M.init then
        M.init()
    end
end

function M.start(name, id, ...)
    M.name = name
    M.id = tonumber(id)
    skynet.start(init)
end

function M.call(node, addr, ...)
    local mynode = skynet.getenv("node")
    if node == mynode then
        return skynet.call(addr, "lua", ...)
    else
        return cluster.call(node, addr, ...)
    end
end

function M.send( node, addr, ... )
    local mynode = skynet.getenv("node")
    if node == mynode then
        return skynet.send(addr, "lua", ...)
    else
        return cluster.send(node, addr, ...)
    end
end

return M