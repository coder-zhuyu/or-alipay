-- demo

local log = require "utils.log"
local response = require "utils.response"
local id = require "utils.id"
local u_table = require "utils.table"
local resp_send = response.send
local config = require "config"
local cjson = require "cjson"
local alipay_signature = require "alipay.alipay_signature"
local alipay_client = require "alipay.alipay_client"
local alipay_trade_wap_pay_request = require "alipay.request.trade_wap_pay_request"
local alipay_trade_refund_request = require "alipay.request.trade_refund_request"
local alipay_trade_query_request = require "alipay.request.trade_query_request"

local _M = {}

-- 路由匹配
function _M.router(self)
    local routers = {
        POST = {
            ["/alipay/wap_pay"] = function(params)
                local resp = self:wap_pay(params)
                resp = cjson.encode(resp)
                resp_send(resp)
            end,
            ["/alipay/notify"] = function(params)
                local resp = self:notify(params)
                resp_send(resp)
            end,
            ["/alipay/query"] = function(params)
                local resp = self:query(params)
                resp = cjson.encode(resp)
                resp_send(resp)
            end,
            ["/alipay/refund"] = function(params)
                local resp = self:refund(params)
                resp = cjson.encode(resp)
                resp_send(resp)
            end,
        },
    }
    return routers
end

-- 支付宝wap支付接口
function _M.wap_pay(self, params)
    local resp = {}
    resp.code = '000000'
    resp.msg = response.get_errmsg(resp.code)

    -- 参数检查
    local subject = params.subject
    local total_amount = tonumber(params.total_amount)

    if not subject or not total_amount then
        log.err("缺少参数")
        resp.code = '100001'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    -- alipay client
    local pay_client = alipay_client:new("https://openapi.alipay.com/gateway.do", config.get('ali_appid'), config.get('private_key'),
                                         "JSON", "utf-8", config.get('alipay_public_key'), "RSA2")

    -- alipay request
    local alipay_request = alipay_trade_wap_pay_request:new()
    alipay_request:set_return_url(config.get('return_url'))
    alipay_request:set_notify_url(config.get('notify_url'))

    -- 生成商户订单号
    local out_trade_no = id.gen_orderno()
    if not out_trade_no then
        log.err("生成商户订单号失败")
        resp.code = '200001'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    -- biz_content
    local biz_content = {}
    biz_content.subject = subject
    biz_content.out_trade_no = out_trade_no
    biz_content.total_amount = total_amount
    biz_content.product_code = 'QUICK_WAP_PAY'

    alipay_request:set_biz_content(cjson.encode(biz_content))

    -- execute 生成唤起支付宝app的url
    local alipay_url = pay_client:page_execute(alipay_request)

    resp.alipay_url = alipay_url
    return resp
end


-- 支付宝退款接口
function _M.refund(self, params)
    local resp = {}
    resp.code = '000000'
    resp.msg = response.get_errmsg(resp.code)

    -- 参数检查
    local trade_no = params.trade_no        -- 订单支付时传入的商户订单号,不能和 trade_no同时为空
    local out_trade_no = params.out_trade_no
    local refund_amount = tonumber(params.refund_amount)
    local refund_reason = params.refund_reason

    if (not trade_no and not out_trade_no) or not refund_amount then
        log.err("缺少参数")
        resp.code = '100001'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    -- alipay client
    local pay_client = alipay_client:new("https://openapi.alipay.com/gateway.do", config.get('ali_appid'), config.get('private_key'),
                                         "JSON", "utf-8", config.get('alipay_public_key'), "RSA2")

    -- alipay request
    local alipay_request = alipay_trade_refund_request:new()

    -- biz_content
    local biz_content = {}
    biz_content.out_trade_no = out_trade_no
    biz_content.trade_no = trade_no
    biz_content.refund_amount = refund_amount
    biz_content.refund_reason = refund_reason

    alipay_request:set_biz_content(cjson.encode(biz_content))

    -- 调用支付宝接口
    local alipay_response = pay_client:execute(alipay_request)
    if not alipay_response then
        log.err("退款失败:", out_trade_no or trade_no)
        resp.code = '300001'
        resp.msg = response.get_errmsg(resp.code)
    elseif alipay_response:is_success() then
        log.info("退款成功:", out_trade_no or trade_no)
    else
        log.err("退款失败:", out_trade_no or trade_no)
        resp.code = '300001'
        resp.msg = response.get_errmsg(resp.code)
        resp.sub_code = alipay_response:get_sub_code()
        resp.sub_msg = alipay_response:get_sub_msg()
    end

    return resp
end

-- 查询接口
function _M.query(self, params)
    local resp = {}
    resp.code = '000000'
    resp.msg = response.get_errmsg(resp.code)

    -- 参数检查
    local trade_no = params.trade_no        -- 订单支付时传入的商户订单号,不能和 trade_no同时为空
    local out_trade_no = params.out_trade_no

    if not trade_no and not out_trade_no then
        log.err("缺少参数")
        resp.code = '100001'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    -- alipay client
    local pay_client = alipay_client:new("https://openapi.alipay.com/gateway.do", config.get('ali_appid'), config.get('private_key'),
                                         "JSON", "utf-8", config.get('alipay_public_key'), "RSA2")

    -- alipay request
    local alipay_request = alipay_trade_query_request:new()

    -- biz_content
    local biz_content = {}
    biz_content.out_trade_no = out_trade_no
    biz_content.trade_no = trade_no

    alipay_request:set_biz_content(cjson.encode(biz_content))

    -- 调用支付宝接口
    local alipay_response = pay_client:execute(alipay_request)
    if not alipay_response then
        log.err("查询失败:", out_trade_no or trade_no)
        resp.code = '300002'
        resp.msg = response.get_errmsg(resp.code)
    elseif alipay_response:is_success() then
        log.info("查询成功:", out_trade_no or trade_no)
    else
        log.err("查询失败:", out_trade_no or trade_no)
        resp.code = '300002'
        resp.msg = response.get_errmsg(resp.code)
        resp.sub_code = alipay_response:get_sub_code()
        resp.sub_msg = alipay_response:get_sub_msg()
    end

    return resp
end


-- 异步通知处理
function _M.notify(self, params)
    local FAIL = 'fail'
    local SUCCESS = 'success'

    if u_table.is_empty(params) then
        log.err("支付宝异步通知参数为空")
        return FAIL
    end
    log.info("异步通知请求参数:", cjson.encode(params))

    -- 验签
    local sign_type = params.sign_type
    params.sign_type = nil     -- 不参与签名
    local sign_content = u_table.table2str_order(params)

    local ok, err = alipay_signature.rsa_check(sign_content, params.sign, config.get('alipay_public_key'), sign_type)
    if not ok then
        log.err("签名验证未通过:", err)
        return FAIL
    end

    return SUCCESS
end

return _M
