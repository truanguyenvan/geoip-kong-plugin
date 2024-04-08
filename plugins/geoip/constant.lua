local _M = {}

_M.PLUGIN_NAME = 'geoip'

_M.MMDB_COUNTRY_TYPE = "country"
_M.MMDB_CITY_TYPE = "city"
_M.MMDB_ISP_TYPE = "isp"
_M.MMDB_ALL_TYPE = "all"
_M.MMDB_TYPES =  {
    _M.MMDB_COUNTRY_TYPE,
    _M.MMDB_CITY_TYPE,
    _M.MMDB_ISP_TYPE,
    _M.MMDB_ALL_TYPE,
}

_M.LOAD_MMDB_EVENT = "load_mmdb"
_M.LOAD_IPCONF_EVENT = "load_ipconf"


_M.COUNTRY_CODE_HEADER = "X-Kong-Geo-Country-Code"
_M.CITY_HEADER = "X-Kong-Geo-City"
_M.ISO_CODE_HEADER = "X-Kong-Geo-ISO-Code"
_M.ISP_HEADER = "X-Kong-Geo-ISP"


_M.TOML_DEFAULT_KEY = "default"
_M.TOML_COUNTRY_KEY = "country_code"
_M.TOML_CITY_KEY = "city"
_M.TOML_ISO_CODE_KEY = "iso_code"
_M.TOML_ISP_KEY = "isp"

return _M