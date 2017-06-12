local ngx_print = ngx.print

-- 异常错误码定义
local error_msg = {
    ['000000'] = '成功',
}

local _M = {}

function _M.send(resp)
    ngx.header['Access-Control-Allow-Origin'] = '*'
    ngx_print(resp)
end

function _M.get_errmsg(key)
    return error_msg[key] or '未知错误'
end

return _M
