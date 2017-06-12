local common_config = {
    mysql_conn_timeout = tonumber(os.getenv('db_conn_timeout')) or 10000,
    mysql_pool = {
        timeout = tonumber(os.getenv('db_pool_size')) or 60000,
        size = tonumber(os.getenv('db_pool_size')) or 50
    },
    mysql_conn = {
        host = os.getenv('db_host'),
        port = 3306,
        database = os.getenv('db_name'),
        user = os.getenv('db_user'),
        password = os.getenv('db_passwd'),
        max_packet_size = 1024 * 1024
    },

    redis_conn = {
        timeout = 3,            -- 3s
        ip = "127.0.0.1",
        port = 6379,
        keepalive_size = 100,
        keepalive_timeout = 60000,        -- 30s
        passwd = '111111'
    },

    lrucache_timeout = tonumber(os.getenv('lrucache_timeout')),

    mail_from = os.getenv('mail_from'),
    mail_passwd = os.getenv('mail_passwd'),
    mail_to = {"zhuyu@think-land.com", "617631456@qq.com"},
    mail_cc = {},
}

local config = {
    dev = {
    },
    test = {
    },
    prod = {
    }
}

local _M = {}

function _M.get(key)
    local env = os.getenv('environment')
    return config[env][key] or common_config[key]
end

return _M
