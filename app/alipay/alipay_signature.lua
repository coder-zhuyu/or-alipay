-- alipay signature
local localtime = ngx.localtime
local u_cipher = require "utils.cipher"

local _M = { _VERSION = '0.1' }

-- RSA 签名
function _M.rsa_sign(sign_content, private_key, sign_type)
    -- 转成lua-resty-rsa库需要的格式
    local private_key = u_cipher.trans_rsa_private_key(private_key)
    local sign = nil
    if 'RSA2' == sign_type then
        sign = u_cipher.rsa_sign(sign_content, private_key, 'RSA-SHA256')
    else
        sign = u_cipher.rsa_sign(sign_content, private_key, 'RSA-SHA1')
    end
    return sign
end

-- 验签
function _M.rsa_check(sign_content, sig, pub_key, sign_type)
    -- 转成lua-resty-rsa库需要的格式
    local pub_key = u_cipher.trans_rsa_pub_key(pub_key)
    if 'RSA2' == sign_type then
        return u_cipher.verify_rsa_sign(sign_content, sig, pub_key, 'RSA-SHA256')
    else
        return u_cipher.verify_rsa_sign(sign_content, sig, pub_key, 'RSA-SHA1')
    end
end


return _M
