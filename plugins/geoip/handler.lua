local kong_meta   = require "kong.meta"
local mmdb = require "kong.plugins.geoip.libs.geoip.mmdb"
local constant = require "kong.plugins.geoip.constant"
local fmt = string.format
local ipmatcher = require "kong.plugins.geoip.libs.ipmatcher"
local lip = require "kong.plugins.geoip.libs.lip"

local GeoIpHandler = {
  VERSION = kong_meta.version,
  PRIORITY = 200,
}



-- mmdb
local country_db, city_db, isp_db
local country_db_path, city_db_path, isp_db_path

--configured ips - the list contains configured IP addresses.
local configured_ips
local configured_ips_path

function GeoIpHandler:reload_mmdbs()
  -- load country mmdb
  if country_db_path then
    local db, err = mmdb.load_database(country_db_path)
    if db then
      country_db = db
    else
      kong.log.err("err in load_country_database: ", err)
    end
  end
  -- load city mmdb
  if city_db_path then
    local db, err = mmdb.load_database(city_db_path)
    if db then
      city_db = db
    else
      kong.log.err("err in load_city_database: ", err)
    end
  end

  -- load isp mmdb
  if isp_db_path then
    local db, err  = mmdb.load_database(isp_db_path)
    if db then
      isp_db = db
    else
      kong.log.err("err in load_isp_database: ", err)
    end
  end
end

local function get_db(conf, type)
  if type == constant.MMDB_COUNTRY_TYPE then
    if not country_db then
      country_db_path = conf.mmdb_country_path
      local db, err = mmdb.load_database(country_db_path)
      if db then
        country_db = db
      else
        kong.log.err("err in load city database: ", err)
      end
    end
    return country_db
  elseif type == constant.MMDB_CITY_TYPE then
    if not city_db then
      city_db_path  = conf.mmdb_city_path
      local db, err = mmdb.load_database(city_db_path)
      if db then
        city_db = db
      else
        kong.log.err("err in load city database: ", err)
      end
    end
    return city_db
  elseif type == constant.MMDB_ISP_TYPE then
    if not isp_db then
      isp_db_path = conf.mmdb_isp_path
      local db, err = mmdb.load_database(isp_db_path)
      if db then
        isp_db = db
      else
        kong.log.err("err in load city database: ", err)
      end
    end
    return isp_db
  end

  kong.log.err("err in load mmdb with invalid type")
  return nil
end

local function country_lookup(conf, ip)
  local country_code
  local db = get_db(conf, constant.MMDB_COUNTRY_TYPE)
  if db then
    local country_code_val, err = db:lookup_value(ip, "country", "iso_code")
    if not err and country_code_val then
      country_code = country_code_val
    end
  end
  return country_code
end

local function city_lookup(conf, ip)
  local city, iso_code
  local db = get_db(conf, constant.MMDB_CITY_TYPE)
  if db then
    local city_val, err = db:lookup_value(ip, "city", "names", "en")
    if not err and city_val then
      city = city_val
      local sub, err = db:lookup(ip)
      if not err and sub then
          iso_code = sub['subdivisions'][1]["iso_code"]
      end
    end
  end
  return city, iso_code
end

local function isp_lookup(conf, ip)
  local isp
  local db = get_db(conf, constant.MMDB_ISP_TYPE)
  if db then
    local isp_val, err = isp_db:lookup_value(ip, "isp")
    if not err and isp_val then
      isp = isp_val
    end
  end
  return isp
end

local function load_mmdb_sub_handler()
  GeoIpHandler:reload_mmdbs()
end

local function toml_parser(path)
  local data = {}
  local default_country_code, default_city, default_iso_code, default_isp
  if not path then
    return nil, "path is required"
  end
  local table = lip.load(path)
  if not table then
    return nil, "read toml file failed"
  end


  -- get default key
  for k, v in pairs(table[constant.TOML_DEFAULT_KEY]) do
    if k == constant.TOML_COUNTRY_KEY then
      default_country_code = v
    elseif k == constant.TOML_CITY_KEY then
      default_city = v
    elseif k == constant.TOML_ISO_CODE_KEY then
      default_iso_code = v
    elseif k == constant.TOML_ISP_KEY then
      default_isp = v
    end
  end


  for key, sub_table in pairs(table) do
      if key ~= constant.TOML_DEFAULT_KEY then
        local info = {country_code = default_country_code, city = default_city, iso_code = default_iso_code, isp = default_isp}
        for sub_key, sub_value in pairs(table[key]) do
          if sub_key == constant.TOML_COUNTRY_KEY then
            info[constant.TOML_COUNTRY_KEY] = sub_value
          elseif sub_key == constant.TOML_CITY_KEY then
            info[constant.TOML_CITY_KEY] = sub_value
          elseif sub_key == constant.TOML_ISO_CODE_KEY then
            info[constant.TOML_ISO_CODE_KEY] = sub_value
          elseif sub_key == constant.TOML_ISP_KEY then
            info[constant.TOML_ISP_KEY] = sub_value
          end
        end
        data[key] = info
      end
  end

  return data, nil
end

local function get_configured_ips_matcher(conf)
  if not configured_ips then
    local data = {}
    configured_ips_path = conf.configured_ips_path
    local p_data, err =  toml_parser(configured_ips_path)
    if not err and p_data then
      data = p_data
    end
    local ip, err = ipmatcher.new_with_value(data)
    if not err and ip then
      configured_ips = ip
    else
      kong.log.err("err in load_configured_ips: ", err)
    end
  end
  
  return configured_ips
end

local function configured_ips_match(conf, ip)
  local data
  local matcher = get_configured_ips_matcher(conf)
  if matcher then
    local matched_data, err = configured_ips:match(ip)
    if not err and matched_data then
      data = matched_data
    end
  end
  return data
end

function GeoIpHandler:reload_ipconf()
  if configured_ips_path then
    local data = {}
    local p_data, err = toml_parser(configured_ips_path)
    if not err and p_data then
      data = p_data
    end
    local ip, err = ipmatcher.new_with_value(data)
    if not err and ip then
      configured_ips = ip
    else
      kong.log.err("err in reload_ipconf: ", err)
    end
  end
end

local function load_ipconf_sub_handler()
  GeoIpHandler:reload_ipconf()
end


function GeoIpHandler:init_worker()
  -- sub channel to load mmdb
  local channel = fmt("%s:%s", constant.PLUGIN_NAME, constant.LOAD_MMDB_EVENT)
  kong.cluster_events:subscribe(channel, load_mmdb_sub_handler)

  -- sub channel to load ip configurations
  local channel = fmt("%s:%s", constant.PLUGIN_NAME, constant.LOAD_IPCONF_EVENT)
  kong.cluster_events:subscribe(channel, load_ipconf_sub_handler)
end


function GeoIpHandler:access(conf)
  local country_code, city, iso_code, isp = conf.default_country_code, conf.default_city, conf.default_iso_code, conf.default_isp
  local current_ip = ngx.var.remote_addr

  if current_ip  then
    -- check if ip in range
    local geo = configured_ips_match(conf, current_ip)
    if geo then
      city =  geo.city
      isp =  geo.isp
      country_code = geo.country_code
      iso_code =  geo.iso_code
    else -- lookup data from mindmax database
      -- lookup coontry code
      country_code = country_lookup(conf, current_ip)
      -- lookup city and iso_code
      city, iso_code = city_lookup(conf, current_ip)
      -- lookup isp
      isp = isp_lookup(conf, current_ip)
    end
  end

  -- set request header
  kong.service.request.set_header(constant.COUNTRY_CODE_HEADER, tostring(country_code))
  kong.service.request.set_header(constant.CITY_HEADER, tostring(city))
  kong.service.request.set_header(constant.ISO_CODE_HEADER, tostring(iso_code))
  kong.service.request.set_header(constant.ISP_HEADER, tostring(isp))
end

return GeoIpHandler
