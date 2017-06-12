-----------------------------------------------------------------------------
-- SMTP client support for the Lua language.
-- LuaSocket toolkit.
-- Author: Diego Nehab
-- RCS ID: $Id: smtp.lua,v 1.46 2007/03/12 04:08:40 diego Exp $
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Declare module and import dependencies
-----------------------------------------------------------------------------

local bit = require "bit"
local sub = string.sub
local tcp = ngx.socket.tcp
local strbyte = string.byte
local strchar = string.char
local strfind = string.find
local format = string.format
local strrep = string.rep
local null = ngx.null
local band = bit.band
local bxor = bit.bxor
local bor = bit.bor
local lshift = bit.lshift
local rshift = bit.rshift
local tohex = bit.tohex
local sha1 = ngx.sha1_bin
local concat = table.concat
local unpack = unpack
local setmetatable = setmetatable
local error = error
local tonumber = tonumber

local mime = require("mime")

-----------------------------------------------------------------------------
-- Program constants
-----------------------------------------------------------------------------
-- timeout for connection
TIMEOUT = 6000
-- default server used to send e-mails
SERVER = "localhost"
-- default port
PORT = 25
-- domain used in HELO command and default sendmail
-- If we are under a CGI, try to get from environment
DOMAIN = os.getenv("SERVER_NAME") or "localhost"
-- default time zone (means we don't know)
ZONE = "-0000"

---------------------------------------------------------------------------
-- Low level SMTP API
-----------------------------------------------------------------------------
local _M = { _VERSION = '0.01' }
local metat = { __index = _M }

-- convert headers to lowercase
local function lower_headers(headers)
    local lower = {}
    for i,v in pairs(headers or lower) do
        lower[string.lower(i)] = v
    end
    return lower
end

---------------------------------------------------------------------------
-- Multipart message source
-----------------------------------------------------------------------------
-- returns a hopefully unique mime boundary
local seqno = 0
local function newboundary()
    seqno = seqno + 1
    return string.format('%s%05d==%05u', os.date('%d%m%Y%H%M%S'),
        math.random(0, 99999), seqno)
end

-- yield multipart message body from a multipart message table
local function send_multipart(mesgt)
    -- make sure we have our boundary and send headers
    local bd = newboundary()
    local headers = lower_headers(mesgt.headers or {})
    headers['content-type'] = headers['content-type'] or 'multipart/mixed'
    headers['content-type'] = headers['content-type'] ..
        '; boundary="' ..  bd .. '"'
    send_headers(headers)
    -- send preamble
    if mesgt.body.preamble then
        coroutine.yield(mesgt.body.preamble)
        coroutine.yield("\r\n")
    end
    -- send each part separated by a boundary
    for i, m in ipairs(mesgt.body) do
        coroutine.yield("\r\n--" .. bd .. "\r\n")
        send_message(m)
    end
    -- send last boundary
    coroutine.yield("\r\n--" .. bd .. "--\r\n\r\n")
    -- send epilogue
    if mesgt.body.epilogue then
        coroutine.yield(mesgt.body.epilogue)
        coroutine.yield("\r\n")
    end
end

-- set defaul headers
local function adjust_headers(mesgt)
    local lower = lower_headers(mesgt.headers)
    lower["date"] = lower["date"] or
        os.date("!%a, %d %b %Y %H:%M:%S ") .. (mesgt.zone or ZONE)
    lower["x-mailer"] = lower["x-mailer"] or "LuaSocket 2.0.2"	-- not all version supported
    -- this can't be overriden
    lower["mime-version"] = "1.0"
    return lower
end


local function lsub(line, i, j)
	if not i then return nil end
	local code = string.sub(line, i, j-1)
	local sep = string.sub(line, j, j)
	return code, sep
end

local function get_reply(sock)
	local code, current, sep
	local line, err = sock:receive()
	local reply = line
	if err then return nil, err end

	code, sep = lsub(line, string.find(line, "^(%d%d%d)(.?)"))
	if not code then return nil, "invalid server reply" end
	if sep == "-" then -- reply is multiline
		repeat
			line, err = sock:receive()
			if err then return nil, err end
			current, sep = lsub(line, string.find(line, "^(%d%d%d)(.?)"))
			reply = reply .. "\n" .. line
--			reply ends with same code
		until code == current and sep == " "
	end
	return code, reply
end

local function check(sock, ok)
	local code, reply = get_reply(sock)
	if not code then return nil, reply end
	if type(ok) ~= "function" then
		if type(ok) == "table" then
			for i, v in ipairs(ok) do
				if string.find(code, v) then
					return tonumber(code), reply
				end
			end
			return nil, reply
		else
			if string.find(code, ok) then return tonumber(code), reply
			else return nil, reply end
		end
	else return ok(tonumber(code), reply) end
end

local function command(sock, cmd, arg)
	if arg then
		return sock:send(cmd .. " " .. arg.. "\r\n")
	else
		return sock:send(cmd .. "\r\n")
	end
end

function _M:greet(domain)
	local sock = self.sock
	check(sock, "2..")
	command(sock, "EHLO", domain or DOMAIN)
	local code, reply = check(sock, "2..")
	return reply
end

function _M:mail(from)
	local sock = self.sock
    command(sock, "MAIL", "FROM:" .. from)
    return check(sock, "2..")
end

function _M:rcpt(to)
	local sock = self.sock
    command(sock, "RCPT", "TO:" .. to)
    return check(sock, "2..")
end

function _M:quit()
	local sock = self.sock
    command(sock, "QUIT")
    return check(sock, "2..")
end

function _M:close()
    return self.sock:close()
end

function _M:login(user, password)
	local sock = self.sock
    command(sock, "AUTH", "LOGIN")
    check(sock, "3..")
    command(sock, mime.b64(user))
    check(sock, "3..")
    command(sock, mime.b64(password))
    return check(sock, "2..")
end

function _M:plain(user, password)
	local sock = self.sock
    local auth = "PLAIN " .. mime.b64("\0" .. user .. "\0" .. password)
    command(sock, "AUTH", auth)
    return check(sock, "2..")
end

function _M:auth(user, password, ext)
    if not user or not password then return 1 end
    if string.find(ext, "AUTH[^\n]+LOGIN") then
        return self:login(user, password)
    elseif string.find(ext, "AUTH[^\n]+PLAIN") then
        return self:plain(user, password)
    else
        return nil, "authentication not supported"
    end
end

function _M:data(mesgt)
	local sock = self.sock
	command(sock, "DATA")
	check(sock, "3..")

	local s_headers = {}
	local k, v

	local headers = adjust_headers(mesgt)
	headers['content-type'] = headers['content-type'] or
        	'text/plain; charset="iso-8859-1"'

	for k,v in pairs(headers) do
		table.insert(s_headers, k..": "..v)
	end

	table.insert(s_headers, "\r\n"..mesgt.body)
	table.insert(s_headers, ".\r\n")
	sock:settimeout(6000)
	sock:send(table.concat(s_headers, "\r\n"))

--	if not n then return nil, err end
	return check(sock, "2..")
end
	

-- send message or throw an exception
function _M:send(mailt)
    self:mail(mailt.from)
    if type(mailt.rcpt) == "table" then
        for i,v in ipairs(mailt.rcpt) do
            self:rcpt(v)
        end
    else
        self:rcpt(mailt.rcpt)
    end

    return self:data(mailt.mesgt)
end

function _M:new(server, port, create)
	local ok
	local sock, err = tcp()
	if not sock then
		return nil, err
	end
	sock:settimeout(TIMEOUT)

	ok, err = sock:connect(server or SERVER, port or PORT)
    if not ok then
        return nil, 'failed to connect: ' .. err
    end

    return setmetatable({
		sock = sock
	}, metat)
end

return _M
