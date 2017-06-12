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
            ["/mail"] = function(params)
                local resp = self:mail(params)
                resp = cjson.encode(resp)
                resp_send(resp)
            end
        },
    }
    return routers
end

function _M.index(self, params)
    return "welcome to or-sapi!"
end

function _M.mail(self, params)
    local resp = {}

    local mail_from = config.get('mail_from')
    local mail_to = config.get('mail_to')
    local mail_cc = config.get('mail_cc')
    local mail_passwd = config.get('mail_passwd')

    local mail_subject = "邮件发送测试"
    local mail_body = "使用lua-resty-stmp非阻塞发送邮件"
    local u_mail = require "utils.mail"
    local ret, reply = u_mail.send(mail_from, mail_to, mail_cc, mail_subject, mail_body, mail_passwd)
    if ret then
        log.info("邮件发送成功")
    else
        log.err("邮件发送失败:", reply)
    end

    resp.code = '000000'
    resp.msg = response.get_errmsg(resp.code)
    return resp
end

return _M
