-- alipay client
local localtime = ngx.localtime
local cjson = require "cjson"
local log = require "utils.log"
local u_table = require "utils.table"
local u_cipher = require "utils.cipher"
local http = require "utils.http"
local alipay_signature = require "alipay.alipay_signature"
local alipay_response = require "alipay.response.alipay_response"

local _M = { _VERSION = '0.1' }

local mt = { __index = _M }

--[[
    server_url: https://openapi.alipay.com/gateway.do
    app_id: 支付宝分配给开发者的应用ID
    private_key: 开发者设置的私钥 PKCS8
    format: 仅支持JSON
    charset: 请求使用的编码格式，如utf-8,gbk,gb2312等 *暂未实现对不同编码的处理*
    alipay_public_key: 支付宝公钥 PKCS8
    sign_type: 商户生成签名字符串所使用的签名算法类型，目前支持RSA2和RSA，推荐使用RSA2
]]
function _M.new(self, server_url, app_id, private_key, format, charset, alipay_public_key, sign_type)
    local this = {}
    this.server_url = server_url
    this.app_id = app_id
    this.private_key = private_key
    this.format = format
    this.charset = charset
    this.alipay_public_key = alipay_public_key
    this.sign_type = sign_type
    return setmetatable(this, mt)
end

function _M.get_params(self, alipay_request)
    local params = {}

    params.app_id = self.app_id
    params.format = self.format
    params.charset = self.charset
    params.sign_type = self.sign_type
    params.timestamp = localtime()
    params.method = alipay_request.method
    params.version = alipay_request.version
    params.return_url = alipay_request.return_url
    params.notify_url = alipay_request.notify_url

    params.biz_content = alipay_request.biz_content

    return params
end

function _M.get_request_body(self, alipay_request)
    local params = self:get_params(alipay_request)
    local sign_content = u_table.table2str_order(params)
    local sign = alipay_signature.rsa_sign(sign_content, self.private_key, self.sign_type)
    params.sign = sign

    for k, v in pairs(params) do
        -- urlencode
        params[k] = ngx.escape_uri(v)
    end

    return u_table.table2str(params)
end

function _M.page_execute(self, alipay_request)
    local params = self:get_params(alipay_request)
    local sign_content = u_table.table2str_order(params)
    local sign = alipay_signature.rsa_sign(sign_content, self.private_key, self.sign_type)
    params.sign = sign
    local url = self.server_url .. '?' .. u_table.table2str_urlencode(params)
    return url
end

function _M.execute(self, alipay_request)
    local req_body = self:get_request_body(alipay_request)
    local res_body, err = http.do_post(self.server_url, req_body)

    if not res_body then
        log.err("请求支付宝接口异常")
        return nil
    end
    log.info("支付宝接口返回结果:", res_body)

    local res_body_tab = cjson.decode(res_body)

    -- 验签
    local root_node = string.gsub(alipay_request.method, '%.', '_') .. '_response'
    local error_root_node = "error_response"
    local index_of_root_node = string.find(res_body, root_node)
    local index_of_error_node = string.find(res_body, error_root_node)
    local index_start = nil
    local index_end = nil
    if index_of_root_node then
        index_start = index_of_root_node + string.len(root_node) + 2
    elseif index_of_error_node then
        index_start = index_of_error_node + string.len(error_root_node) + 2
    end
    local index_of_sign = string.find(res_body, [["sign"]])
    if index_of_sign then
        index_end = index_of_sign - 2
    end

    if not index_start or not index_end then
        log.err("签名验证未通过: 返回报文无签名验证所需信息")
        return nil
    end

    local sign_content = string.sub(res_body, index_start, index_end)
    local ok, err = alipay_signature.rsa_check(sign_content, res_body_tab.sign, self.alipay_public_key, self.sign_type)
    if not ok then
        log.err("签名验证未通过:", err)
        return nil
    end

    return alipay_response:new(res_body_tab[root_node])
end

return _M
