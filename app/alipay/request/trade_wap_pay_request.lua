-- wap支付请求参数

local _M = { _VERSION = '0.1' }

local mt = { __index = _M }

function _M.new(self)
    local this = {}
    this.method = 'alipay.trade.wap.pay'
    this.version = '1.0'
    return setmetatable(this, mt)
end

function _M.set_return_url(self, return_url)
    self.return_url = return_url
end

function _M.set_notify_url(self, notify_url)
    self.notify_url = notify_url
end

function _M.set_biz_content(self, biz_content_str)
    self.biz_content = biz_content_str
end

return _M
