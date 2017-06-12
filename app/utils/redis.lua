local redis = require "resty.iredis"
local config = require "config"
local log = require "utils.log"

local _M = {}

-- 自增
function _M.auto_incr(key)
    local redis_conn_opts = config.get('redis_conn')
    local red = redis:new(redis_conn_opts)

    local res, err = red:incrby(key, 1)
    if res then
        return res
    else
        log.err("failed to incrby: ", err)
        return nil
    end
end


-- set
function _M.set(key, val)
    local redis_conn_opts = config.get('redis_conn')
    local red = redis:new(redis_conn_opts)

    local res, err = red:set(key, val)
    if res then
        return res
    else
        log.err("failed to set: ", err)
        return nil
    end
end

return _M
