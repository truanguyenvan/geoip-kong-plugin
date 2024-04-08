local require = require
local kong = kong
local fmt = string.format
local constant = require "kong.plugins.geoip.constant"
local handler = require "kong.plugins.geoip.handler"

return {
    ["/geoip/mmdb/reload"] = {
        resources = "geoip",
        PUT = function ()
            handler:reload_mmdbs()
            local channel = fmt("%s:%s", constant.PLUGIN_NAME, constant.LOAD_MMDB_EVENT)
            kong.cluster_events:broadcast(channel)
            return kong.response.exit(200, {message = "ok"})
        end
    },
    ["/geoip/ipconf/reload"] = {
        resources = "geoip",
        PUT = function ()
            handler:reload_ipconf()
            local channel = fmt("%s:%s", constant.PLUGIN_NAME, constant.LOAD_IPCONF_EVENT)
            kong.cluster_events:broadcast(channel)
            return kong.response.exit(200, {message = "ok"})
        end
    }
}