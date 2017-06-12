local session = require "utils.session"

local _M = {}

function _M.get_current_user()
    -- dev环境不做检查
    local env = os.getenv('environment')
    if env == 'dev' then
        return {openid="xdfoejofaoejowjof", session_key="session_key"}
    end

    local user = session.get('__uid')
    return user
end

function _M.is_login()
    local user = session.get('__uid')
    if user then
        return true
    else
        return false
    end
end

return _M
