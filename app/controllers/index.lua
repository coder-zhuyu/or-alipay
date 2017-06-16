local log = require "utils.log"
local response = require "utils.response"
local resp_send = response.send
local config = require "config"
local cjson = require "cjson"

local _M = {}

-- 路由匹配
function _M.router(self)
    local routers = {
        GET = {
            ["/"] = function(params)
                local resp = self:index(params)
                resp_send(resp)
            end,
        },
    }
    return routers
end

function _M.index(self, params)
    return "welcome to or-sapi!"
end

return _M
