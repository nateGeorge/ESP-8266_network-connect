currentDust = {}
wifi.setmode(1)

dofile('getAPlist.lc')

tmr.alarm(1,5000,1,function ()
    local wifiStat = wifi.sta.status()
    print(wifiStat)
    if (wifiStat == 0 or wifiStat == 5) then
        tmr.stop(1)
    end
    if (wifiStat ~=5 and file.open('networks')) then
        file.close('networks')
        dofile('tryConnect.lc')
        wifi.sleeptype(1)
    end
end)
