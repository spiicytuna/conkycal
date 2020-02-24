#!/usr/bin/lua
-- load the http socket module
http = require("socket.http")
-- load the json module
json = require("json")

api_url = "http://api.openweathermap.org/data/2.5/weather?"

-- http://openweathermap.org/help/city_list.txt , http://openweathermap.org/find
-- City 1, left
cityid1 = "1667905"
-- City 2, right
cityid2 = "5341430"

-- metric or imperial
cf = "imperial"

-- get an open weather map api key: http://openweathermap.org/appid
apikey = "<api key>"

-- measure is °C if metric and °F if imperial
measure = '°' .. (cf == 'metric' and 'C' or 'F')
wind_units = (cf == 'metric' and 'kph' or 'mph')

currenttime = os.date("!%Y%m%d%H%M%S")

file_exists = function (name)
    f=io.open(name,"r")
    if f~=nil then
        io.close(f)
        return true
    else
        return false
    end
end


-- City #1
if file_exists("weather-city1.json") then
    cache_city1 = io.open("weather-city1.json","r")
    data_city1 = json.decode(cache_city1:read())
    cache_city1.close()
    timepassed_city1 = os.difftime(currenttime, data_city1.timestamp)
else
    timepassed_city1 = 6000
end

-- City #2
if file_exists("weather-city2.json") then
    cache_city2 = io.open("weather-city2.json","r")
    data_city2 = json.decode(cache_city2:read())
    cache_city2.close()
    timepassed_city2 = os.difftime(currenttime, data_city2.timestamp)
else
    timepassed_city2 = 6000
end



-- City #1
makecache_city1 = function (s)
    cache_city1 = io.open("weather-city1.json", "w+")
    s.timestamp = currenttime
    save = json.encode(s)
    cache_city1:write(save)
    cache_city1.close()
end

-- City #2
makecache_city2 = function (v)
    cache_city2 = io.open("weather-city2.json", "w+")
    v.timestamp = currenttime
    save = json.encode(v)
    cache_city2:write(save)
    cache_city2.close()
end

-- City #1
if timepassed_city1 < 3600 then
    response_city1 = data_city1
else
    weather_city1 = http.request(("%sid=%s&units=%s&APPID=%s"):format(api_url, cityid1, cf, apikey))
    if weather_city1 then
        response_city1 = json.decode(weather_city1)
        makecache_city1(response_city1)
    else
        response_city1 = data_city1
    end
end

-- City #2
if timepassed_city2 < 3600 then
    response_city2 = data_city2
else
    weather_city2 = http.request(("%sid=%s&units=%s&APPID=%s"):format(api_url, cityid2, cf, apikey))
    if weather_city2 then
        response_city2 = json.decode(weather_city2)
        makecache_city2(response_city2)
    else
        response_city2 = data_city2
    end
end



-- Both Cities share these
math.round = function (n)
    return math.floor(n + 0.5)
end

degrees_to_direction = function (d)
    val = math.round(d/22.5)
    directions={"N","NNE","NE","ENE",
                "E","ESE", "SE", "SSE",
                "S","SSW","SW","WSW",
                "W","WNW","NW","NNW"}
    return directions[val % 16]
end

-- City #1
name_city1 = response_city1.name
temp_city1 = response_city1.main.temp
conditions_city1 = response_city1.weather[1].description
icon_city1 = response_city1.weather[1].id
humidity_city1 = response_city1.main.humidity
wind_city1 = response_city1.wind.speed
deg_city1 = degrees_to_direction(response_city1.wind.deg)
sunrise_city1 = os.date("%H:%M %p", response_city1.sys.sunrise)
sunset_city1 = os.date("%H:%M %p", response_city1.sys.sunset)

-- City #2
name_city2 = response_city2.name
temp_city2 = response_city2.main.temp
conditions_city2 = response_city2.weather[1].description
icon_city2 = response_city2.weather[1].id
humidity_city2 = response_city2.main.humidity
wind_city2 = response_city2.wind.speed
deg_city2 = degrees_to_direction(response_city2.wind.deg)
sunrise_city2 = os.date("%H:%M %p", response_city2.sys.sunrise)
sunset_city2 = os.date("%H:%M %p", response_city2.sys.sunset)


conky_text = [[
${font ITC Avant Garde Gothic Pro:bold:size=14}%s ${alignr}${offset -6} %s
${image ~/.config/conky/icons/%s.png -p 0,810 -s 80x80}${color1}${font :size=20} ${offset 70}${voffset 20}%s${font}${voffset -5}%s${color}${alignr}${image ~/.config/conky/icons/%s.png -p 172,810 -s 80x80}${color1}${font :size=20} %s${font}${voffset -5}%s${color}
${voffset 33} %s${alignr}${offset -5} %s
 Humidity: ${color1}%s%%${color}${alignr}${offset -5}Humidity: ${color1}%s%%${color}
 Wind: ${color1}%s %s %s${color}${alignr}${offset -5}Wind: ${color1}%s %s %s${color}
]]

-- Removed Sunrise/Sunset
-- ${alignc}${image ~/.config/conky/icons/sunrise.png -p 30,990 -s 32x32}      ${color1}%s${color}         ${image ~/.config/conky/icons/sunset.png -p 150,990 -s 32x32}${color1}%s${color}


io.write((conky_text):format(name_city1,
                             name_city2,
                             icon_city1,
                             math.round(temp_city1),
                             measure,
                             icon_city2,
                             math.round(temp_city2),
                             measure,
                             conditions_city1,
                             conditions_city2,
                             humidity_city1,
                             humidity_city2,
                             math.round(wind_city1),
                             wind_units,
                             deg_city1,
                             math.round(wind_city2),
                             wind_units,
                             deg_city2)
)
