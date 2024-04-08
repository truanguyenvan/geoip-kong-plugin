# Kong plugin GeoIP
Plugin passes location headers based on results from a Maxmind database.

# Required libs
## libmaxminddb
* https://github.com/maxmind/libmaxminddb
```
Ubuntu
apt install libmaxminddb0 libmaxminddb-dev mmdb-bin libgeoip-dev
```
## Kong
Required version: 3.1.x  [Github](https://github.com/Kong/kong/tree/release/3.1.x)

# Request headers
- X-Kong-Geo-Country-Code : country code
- X-Kong-Geo-City: city name
- X-Kong-Geo-ISO-Code: iso code
- X-Kong-Geo-ISP: isp name

# APIs

Searches all geoip plugins to reload mindmax database
```
PUT kong-admin-domain/geoip/mmdb/reload

curl -X PUT http://localhost:8001/geoip/mmdb/reload
```

# Configuration reference
This plugin is compatible with DB-less mode
## Parameters
Here's a list of all the parameters which can be used in this plugin's configuration:
- default_country_code (string) | default country code value, this value is used when can't find in mmdb \
-- default: nil \
-- example: VN
- default_city (string) | default city value, this value is used when can't find in mmdb
-- default: nil \
-- example: HN
- default_iso_code (string) | default iso value, this value is used when can't find in mmdb \
-- default: nil \
-- example: 71
- default_isp (string) | default isp value, this value is used when can't find in mmdb \
-- default: nil \
-- example: VNPT
- mmdb_city_path (string) | maxmind city database path \
-- default: /usr/share/GeoIP/GeoIP2-City.mmdb
- mmdb_country_path (string) | maxmind country database path \
-- default: /usr/share/GeoIP/GdseoIP2-Country.mmdb
- mmdb_isp_path (string) | maxmind isp database path \
-- default: /usr/share/GeoIP/GeoIP2-ISP.mmdb

- configured_ips_path (string) | configured ips path \
-- default: /usr/share/GeoIP/configured_ips.toml \
-- example:
```
[default]
country_code=VN
iso_code = 71
city=HN
isp= VNPT


[192.168.0.0/16]
country_code=US
[192.168.1.0/16]
[192.168.2.0/16]
country_code=UK
```
