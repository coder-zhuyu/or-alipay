local gsub = ngx.re.gsub
local ngx_re = require "ngx.re"

local _M = {}

function _M.time_format(time_stamp)
    local res_tab = {}
    table.insert(res_tab, string.sub(time_stamp, 1, 4))
    table.insert(res_tab, "-")
    table.insert(res_tab, string.sub(time_stamp, 5, 6))
    table.insert(res_tab, "-")
    table.insert(res_tab, string.sub(time_stamp, 7, 8))
    table.insert(res_tab, " ")
    table.insert(res_tab, string.sub(time_stamp, 9, 10))
    table.insert(res_tab, ":")
    table.insert(res_tab, string.sub(time_stamp, 11, 12))
    table.insert(res_tab, ":")
    table.insert(res_tab, string.sub(time_stamp, 13, 14))
    return table.concat(res_tab, "")
end

-- 字符串去掉左右空格
function _M.trim (s)
    return string.gsub(s, "^%s*(.-)%s*$", "%1")
end

-- 手机号码格式校验
function _M.is_phone(phone)
    local m, err = ngx.re.match(phone, "^(13|14|15|17|18)\\d{9}$", "jo")
    if not m then
        return false, err
    end
    return true
end

-- ip字符串转INT
function _M.ip_str2int(ip)
    local res, err = ngx_re.split(ip, "\\.")
    if not res then
        return nil, err
    end

    local sum = 0
    for i, val in ipairs(res) do
        sum = sum + tonumber(val) * math.pow(255, 4-i)
    end

    return sum
end

-- list, 拼接成字符串 用于执行sql的in
function _M.list2str(tab, key)
    local id_list = {}
    for _, tab_info in ipairs(tab) do
        table.insert(id_list, tab_info[key])
    end
    return "('" .. table.concat(id_list, "','") .. "')"
end

return _M
