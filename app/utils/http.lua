local http = require "resty.http"

local _M = {}

function _M.do_post(url, body)
    local httpc = http.new()
    local res, err = httpc:request_uri(url, {
        method = "POST",
        body = body,
        headers = {
            ["Content-Type"] = "application/x-www-form-urlencoded; charset=UTF-8",
        }
    })

    if not res then
        return nil, err
    end

    if res.status ~= 200 then
        return nil, res.status
    end

    return res.body
end

return _M
