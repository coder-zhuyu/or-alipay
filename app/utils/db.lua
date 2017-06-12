local mysql = require "resty.mysql"
local config = require "config"
local log = require "utils.log"

local _M = {}

-- 抽象数据库操作
function _M.execute(sql)
    local db, err = mysql:new()
    if not db then
        log.err("failed to instantiate mysql: ", err)
        return nil
    end

    -- 连接超时时间
    db:set_timeout(config.get('mysql_conn_timeout'))

    -- 连接数据库
    local ok, err, errno, sqlstate = db:connect(config.get('mysql_conn'))
    if not ok then
        log.err("failed to connect: ", err, ": ", errno, ": ", sqlstate)
        return nil
    end

    -- execute sql
    local res, err, errno, sqlstate = db:query(sql)
    if not res then
        log.err("query failed: ", err, ": ", errno, ": ", sqlstate)
        return nil
    end

    -- 连接池
    local pool = config.get('mysql_pool')
    local ok, err = db:set_keepalive(pool.timeout, pool.size)
    if not ok then
        log.err("failed to set keepalive: " .. err)
        -- return nil
    end

    return res
end

return _M
