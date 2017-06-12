local routers = require "routers"
local traceback = debug.traceback

local log = require "utils.log"

local _M = {}

function _M.init()
    local status, err_msg = xpcall(function() routers.set_routers() end,
    function(msg) local ret_msg = traceback() return ret_msg end)
    if not status then
        log.crit('--init worker error--')
        log.err(err_msg)
        return
    end
end

return _M
