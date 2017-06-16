-- 返回结果

local _M = { _VERSION = '0.1' }

local mt = { __index = _M }

function _M.new(self, body)
    local this = {}
    this.body = body
    return setmetatable(this, mt)
end

function _M.is_success(self)
    return not self.body.sub_code
end

function _M.get_body(self)
    return self.body
end

function _M.get_sub_code(self)
    return self.body.sub_code
end

function _M.get_sub_msg(self)
    return self.body.sub_msg
end

return _M
