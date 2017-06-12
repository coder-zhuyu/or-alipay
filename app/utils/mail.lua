-- smtp方法发送mail
local smtp = require "resty.smtp"

local _M = {}


function _M.send(from, to, cc, subject, body, password)
    local rcpt = to

    local mesgt = {
        headers = {
            from = from,
            to = table.concat(to, ";"), -- 收件人
            cc = table.concat(cc, ";"), -- 抄送
            subject = subject,
        },
        body = body
    }
    mesgt.headers["content-type"] = 'text/html; charset="utf-8"'

    local mailt = {
        server = "smtp.exmail.qq.com",
        user = from,
        password = password,
        from = from,
        rcpt = rcpt,
        --	source = smtp:message(mesgt)
        mesgt = mesgt
    }

    local s = smtp:new(mailt.server, mailt.port, mailt.create)
    local ext = s:greet(mailt.domain)

    local auth = s:auth(mailt.user, mailt.password, ext)

    --local source = s:message(mesgt)
    --mailt.source = source

    local resp = true
    local code, reply = s:send(mailt)
    if not code then
        resp = false
    end
    s:quit()
    s:close()

    return resp, reply
end


return _M
