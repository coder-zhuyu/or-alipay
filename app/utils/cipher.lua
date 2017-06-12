local resty_sha1 = require "resty.sha1"
local resty_aes = require "resty.aes"
local resty_str = require "resty.string"
local resty_rsa = require "resty.rsa"
local base64_decode = ngx.decode_base64
local base64_encode = ngx.encode_base64

local _M = {}

-- sha1签名验证
function _M.verify_sha1_sign(data, signature)
    local sha1 = resty_sha1:new()
    if not sha1 then
        return false, "failed to create the sha1 object"
    end

    local ok = sha1:update(data)
    if not ok then
        return false, "failed to add data"
    end

    local digest = sha1:final()  -- binary digest
    local hex_digest = resty_str.to_hex(digest)
    if hex_digest == signature then
        return true
    else
        return false, "not equal"
    end
end

-- aes解密
function _M.aes_128_cbc_with_iv_decrypt(key, iv, encrypted_data)
    local key = base64_decode(key)
    local iv = base64_decode(iv)
    local encrypted_data = base64_decode(encrypted_data)
    local aes_128_cbc_with_iv = resty_aes:new(key, nil, resty_aes.cipher(128, "cbc"), {iv=iv})
    local decrypted = aes_128_cbc_with_iv:decrypt(encrypted_data)
    return decrypted
end

-- RSA密钥格式转换 64个字符换行 并且前后加上两行 支持pkcs8格式
function _M.trans_rsa_private_key(private_key)
    local res = {}
    table.insert(res, '-----BEGIN PRIVATE KEY-----')
    local str_64= ''
    while true
    do
        str_64 = string.sub(private_key, 1, 64)
        table.insert(res, str_64)
        if #private_key - #str_64 == 0 then
            break
        end
        private_key = string.sub(private_key, 65)
    end
    table.insert(res, '-----END PRIVATE KEY-----')
    return table.concat(res, '\n')
end

function _M.trans_rsa_pub_key(pub_key)
    local res = {}
    table.insert(res, '-----BEGIN PUBLIC KEY-----')
    local str_64= ''
    while true
    do
        str_64 = string.sub(pub_key, 1, 64)
        table.insert(res, str_64)
        if #pub_key - #str_64 == 0 then
            break
        end
        pub_key = string.sub(pub_key, 65)
    end
    table.insert(res, '-----END PUBLIC KEY-----')
    return table.concat(res, '\n')
end

-- RSA签名
function _M.rsa_sign(data, private_key, algorithm)
    local priv, err = resty_rsa:new({
        private_key = private_key,
        algorithm = algorithm,
    })
    if not priv then
        return nil, err
    end

    local sig, err = priv:sign(data)
    if not sig then
        return nil, err
    end
    return base64_encode(sig)
end

-- RSA签名校验
function _M.verify_rsa_sign(data, sig, pub_key, algorithm)
    local pub, err = resty_rsa:new({
        public_key = pub_key,
        algorithm = algorithm,
    })
    if not pub then
        return false, err
    end

    local verify, err = pub:verify(data, base64_decode(sig))
    if not verify then
        return false, err
    end
    return true
end

return _M
