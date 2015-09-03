wifi.setmode(1)

dofile('getAPlist.lc')

tmr.alarm(1,5000,1,function ()
    local wifiStat = wifi.sta.status()
    print(wifiStat)
    if (wifiStat == 0) then
        tmr.stop(1)
    elseif (wifiStat == 5) then
        print('connected')
        tmr.stop(1)
        wifi.sleeptype(1)
        wifi.sta.disconnect()
        collectgarbage()
        dofile('monitor dust concentration.lc')
        return
    end
    if (wifiStat ~=5 and wifiStat ~=1 and file.open('networks')) then
        file.close('networks')
        dofile('tryConnect.lc')
        wifi.sleeptype(1)
    end
end)