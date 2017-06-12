local log = require "utils.log"

-- 将路由和function映射关系加进去
local routers = {
}

local _M = {}

function _M.set_routers()
    routers['GET'] = {}
    routers['POST'] = {}
    routers['PUT'] = {}
    routers['PATCH'] = {}
    routers['DELETE'] = {}
    routers['TRACE'] = {}
    routers['CONNECT'] = {}
    routers['OPTIONS'] = {}
    routers['HEAD'] = {}

    filenames = io.popen("ls " .. os.getenv('app_root') .. "/app/controllers/*.lua")
    for filename in filenames:lines() do
        log.debug(filename)
        begin = #filename - filename:reverse():find("/") + 2
        lua_filename = string.sub(filename, begin, -5)
        log.crit(lua_filename)
        local module = require("controllers." .. lua_filename)

        if module.router then
            for k, v in pairs(module:router()) do
                log.crit(k)
                for key, val in pairs(v) do
                    log.crit(key)
                    routers[k][key] = val
                end
            end
        end
    end
end

function _M.get_routers()
    return routers
end

return _M
