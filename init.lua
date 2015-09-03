dataToSend = {}
wifi.setmode(1)

dofile('getAPlist.lua')

tmr.alarm(1,5000,1,function ()
    local wifiStat = wifi.sta.status()
    print(wifiStat)
    if (wifiStat == 5) then
        tmr.stop(1)
    end
    if (wifiStat ~= 5 and wifiStat ~= 1) then
        if (file.open('networks')) then
            file.close('networks')
        end
        dofile('tryConnect.lua')
        wifi.sleeptype(1)
    end
end)
