# OpenResty对接支付宝接口demo: 实现了wap支付，退款，查询，异步通知功能

## 用到的第三方库
* router.lua https://github.com/APItools/router.lua.git
* lua-resty-http https://github.com/pintsized/lua-resty-http.git
* lua-resty-rsa https://github.com/doujiang24/lua-resty-rsa.git


## 目录结构
* app  应用代码
* conf nginx配置文件

## 配置文件说明
这是一个模板，根据需要替换其中的变量。
* {{APP_ENV}}       环境，可以配置dev test prod
* {{APP_ROOT}}      项目根目录，绝对路径，如/xx/yy/or-alipay
* {{RETURN_URL}}    支付宝前台回跳地址
* {{NOTIFY_URL}}    支付宝异步通知地址
* {{ALI_APPID}}     支付宝分配的APPID
* {{PRIVATE_KEY}}   用户私钥，在支付宝后台设置 用支付宝工具生成的PKCS8格式
* {{ALIPAY_PUBLIC_KEY}}     支付宝公钥

## 代码结构说明
* alipay        支付宝请求抽象封装
* controllers   各接口demo
* resty         用到的第三方库
* utils         封装的一些工具方法
* config.lua    配置
* init.lua      worker进程初始化执行 主要设置路由
* main.lua      入口
* routers.lua   路由处理
