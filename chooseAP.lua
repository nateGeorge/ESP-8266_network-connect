--TODO: make the chooseAPHTML a package, so the errmsg can be passed
--add delay before trying to connect?

-- had to chunk up sending of webpage, to deal with low amounts of memory on ESP-8266 devices
-- surely a more elegant way to do it

dofile("makeChooseAPHTML.lua")
local SSID = nil
local pass = nil
local otherSSID = nil
local errMsg = nil
local savedNetwork = false
local resetTimer = 15 -- for resetting the module after successfully connecting to chosen network
-- lookup table for wifi.sta.status()
local statusTable = {}
statusTable["0"] = "neither connected nor connecting"
statusTable["1"] = "still connecting"
statusTable["2"] = "wrong password"
statusTable["3"] = "didn\'t find the network you specified"
statusTable["4"] = "failed to connect"
statusTable["5"] = "successfully connected"
wifi.sta.disconnect()
wifi.setmode(wifi.STATIONAP)
print('wifi status: '..wifi.sta.status())

function url_decode(str)
  str = string.gsub (str, "+", " ")
  str = string.gsub (str, "%%(%x%x)",
      function(h) return string.char(tonumber(h,16)) end)
  str = string.gsub (str, "\r\n", "\n")
  return str
end

local cfg = {}
cfg.ssid = "mysticalNetwork"
cfg.pwd = "mystical5000"
wifi.ap.config(cfg)
local srv=net.createServer(net.TCP, 300)
print("connect to \'"..cfg.ssid.."\", password \""..cfg.pwd.."\", ip "..wifi.ap.getip())
cfg = nil
srv:listen(80,function(conn)
conn:on("receive", function(client,request)
    print("recieve")
    local errMsg = nil
    local _, _, delete = string.find(request, "(deleteSaved=true)")
    if (delete~=nil) then
        file.remove('networks')
        errMsg = "<center><h2>Saved networks deleted.<\h2><\center>"
    end
    -- check if SSID and password have been submitted
    local connecting = false
    local _, _, SSID, pass = string.find(request, "SSID=(.+)%%0D%%0A&otherSSID=&password=(.*)")
    print(node.heap())

    if (pass~=nil and pass~="") then
        if (string.len(pass)<8) then
            local pass = nil
            errMsg = "<center><h2 style=\"color:red\">Whoops! Password must be at least 8 characters, or blank.<\h2><\center>"
        end
    end
    
    if (SSID==nil) then
        _, _, SSID, pass = string.find(request, "SSID=&otherSSID=(.+)%%0D%%0A&password=(.*)")
    end

    print(request)
    local buf = "";

    -- if password for network is nothing, any password should work
    if (SSID~=nil and pass~=nil) then
        if (pass == "") then
            pass = "aaaaaaaa"
        end
        SSID = url_decode(SSID)
        pass = url_decode(pass)
        print(SSID..', '..pass)
        -- TO-DO: add timeout for connection attempt
        local connectStatus = wifi.sta.status()
        print(connectStatus)
        tmr.alarm(5,500,0,function()
            sendWebpage(client, 'header.html')
            buf = buf.."<center><h2 style=\"color:DarkGreen\">Connecting to "..tostring(SSID)
            buf = buf.."!</h2><br><h2>Please hold tight, we'll be back to you shortly.</h2></center></div></html>"
            client:send(buf)
            buf = ""
            wifi.sta.config(tostring(SSID),tostring(pass))
            wifi.sta.connect()
            connecting = true
        end)
        tmr.alarm(1,1000,1, function()
            connectStatus = wifi.sta.status()
            print("connecting")
            print(connectStatus)
            if (connectStatus ~= 1) then
                if (connectStatus == 5) then
                    print("connected!")
                    sendWebpage(client, 'header.html')
                    buf = buf.."<center><h2 style=\"color:DarkGreen\">Successfully connected to "..tostring(SSID).."!"
                    buf = buf.."</h2><br><h2>Added to network list.</h2><br><h2>Resetting module in "..resetTimer.."s...</h1></center></div></html>"
                    client:send(buf)
                    buf = ""
                    file.open("networks","a+")
                    file.writeline(tostring(SSID))
                    file.writeline(tostring(pass))
                    file.close()
                    savedNetwork = true
                    tmr.alarm(2,resetTimer*1000,0,function()
                        srv:close()
                        node.restart()
                        end)
                else
                    print("couldn't connect")
                    buf = buf.."<center><h2 style=\"color:red\">Whoops! Could not connect to "..tostring(SSID)..". "..statusTable[tostring(connectStatus)].."</h2><br></center>"
                    buf = buf.."<form align=\"center\" method=\"POST\">"
                    buf = buf.."<input type=\"hidden\" name=\"reloadNets\" value=\"true\">"
                    buf = buf.."<input type=\"submit\" value=\"Re-scan networks\" style=\"font-size:30pt\">"
                    buf = buf.."</form>"
                    buf = buf.."</div>"
                    buf = buf.."</html>"
                    client:send(buf)
                    buf = ""
                end
                client:send(buf)
                collectgarbage()
                tmr.stop(1)
                client:close()
            end
        end)
    end
    buf = ""
    if(not connecting) then
        sendWebpage(client, "chooseAP.html")
        client:send(buf)
        buf = ""
        client:close()
    end
    collectgarbage()
end)
end)

function sendWebpage(client, pageFile)
    file.open(pageFile)
    line = file.readline()
    line = string.sub(line,1,string.len(line)-1) --hack to remove CR/LF
    while (line~=nul) do
        client:send(line)
        if (line == "<div style = \"width:80%; margin: 0 auto\">") then
            -- add warning about password<8 characters if needed
            if (errMsg~=nil) then
                buf = buf.."<br><br>"..errMsg
                client:send(buf)
            end
        end
        line = file.readline()
    end
    file.close()
end
