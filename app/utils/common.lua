local _M = {}

function _M.get_total_page(total_num, per_page)
    return math.ceil(total_num / per_page)
end

return _M
