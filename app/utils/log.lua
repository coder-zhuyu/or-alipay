-- 日志封装
local log = ngx.log
local STDERR = ngx.STDERR
local EMERG = ngx.EMERG
local ALERT = ngx.ALERT
local CRIT = ngx.CRIT
local ERR = ngx.ERR
local WARN = ngx.WARN
local NOTICE = ngx.NOTICE
local INFO = ngx.INFO
local DEBUG = ngx.DEBUG

local _M = {}

function _M.debug(...) log(DEBUG, ...) end

function _M.info(...) log(INFO, ...) end

function _M.notice(...) log(NOTICE, ...) end

function _M.warn(...) log(WARN, ...) end

function _M.err(...) log(ERR, ...) end

function _M.crit(...) log(CRIT, ...) end

function _M.alert(...) log(ALERT, ...) end

function _M.emerg(...) log(EMERG, ...) end

function _M.stderr(...) log(STDERR, ...) end

return _M
