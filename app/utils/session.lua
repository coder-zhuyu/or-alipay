local _M = {}

function _M.set(k, v)
    local Session = require "resty.session"
    local session = Session.start()
    session.data[k] = v
    session.cookie.persistent = true
    session:save()
end

function _M.get(k)
    local Session = require "resty.session"
    local session = Session.open()
    return session.data[k]
end

function _M.destroy()
    local Session = require "resty.session"
    local session = Session.start()
    session:destroy()
end

return _M
