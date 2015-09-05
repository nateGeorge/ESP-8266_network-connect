dataToSend = {}
wifi.setmode(1)

tmr.alarm(1,5000,1,function ()
    local wifiStat = wifi.sta.status()
    print(wifiStat)
    if (wifiStat == 5) then
        tmr.stop(1)
        dofile('logdata.lua')
    end
    if (wifiStat ~= 5 and wifiStat ~= 1) then
        dofile('getAPlist.lua')
        if (file.open('networks')) then
            file.close('networks')
        end
        dofile('tryConnect.lua')
        wifi.sleeptype(1)
    end
end)
