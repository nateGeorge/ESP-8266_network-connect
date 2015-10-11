wifi.setmode(1)

tmr.alarm(2, 30000, 0, function()
node.restart()
end)

tmr.alarm(1,5000,1,function ()
    local wifiStat = wifi.sta.status()
    print(wifiStat)
    if (wifiStat == 5) then
        tmr.stop(1)
        tmr.stop(2)
        dofile('logdata.lc')
    end
    if (wifiStat ~= 5 and wifiStat ~= 1) then
        node.restart()
    end
end)
