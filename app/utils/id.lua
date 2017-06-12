local uuid = require "resty.uuid"
local uuid_gen = uuid.generate_time
local gsub = ngx.re.gsub
local localtime = ngx.localtime

local _M = {}

-- 生成uuid, 并替换掉-
function _M.uuid()
    local uuid_str = uuid_gen()
    local new_uuid_str, n, err = gsub(uuid_str, "-", "", "jo")
    if not new_uuid_str then
        return nil, err
    else
        return new_uuid_str
    end
end

-- 生成订单号
function _M.gen_orderno()
    local now = localtime()

    local now_str, n, err = gsub(now, "-| |:", "", "jo")
    if not now_str then
        return nil, err
    end

    -- 用共享内存生成sequence
    local auto_incr = ngx.shared.auto_incr
    local num, err = auto_incr:incr('sapi.sequence', 1, 60000)
    if not num then
        return nil, err
    end

    num = tonumber(num)
    if num < 60000 or num >= 90000 then
        local ok, err = auto_incr:set('ccbrecharge.sequence', 60001)
        if not ok then
            return nil, err
        end
        num = 60001
    end

    return now_str .. tostring(num)
end

return _M
