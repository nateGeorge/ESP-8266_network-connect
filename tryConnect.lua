local networks = {}
local networkCount = 0
local SSIDs = {}
--lookup table for statuses from wifi.sta.status()
local statusTable = {}
statusTable["2"] = "wrong password"
statusTable["3"] = "didn\'t find the network you specified"
statusTable["4"] = "failed to connect"

wifi.setmode(wifi.STATION) -- equivalent to wifi.STATION I think...will have to check

--checks if any of the saved SSIDs with passwords (in 'networks' file) are available and tries to connect to them
function checkSavedNets()
    file.open('networks','r')
    while true do
        local line = file.readline()
        if line == nil then break end
        local ssid = string.sub(line,1,string.len(line)-1) --hack to remove CR/LF
        local line = file.readline()
        if line == nil then break end -- think this line is unecessary, will have to check
        local pass = string.sub(line,1,string.len(line)-1)
        print(ssid..', '..pass)
        print(SSIDs[ssid])
        if (SSIDs[ssid] == true) then --if saved network is is the list of nearby networks
            print('connecting to: '..ssid)
            wifi.sta.config(ssid,pass)
            wifi.sta.connect()
            SSIDs[ssid] = nil
            file.close()
			checkConn()
            return
        else
            SSIDs[ssid] = nil
            print('removing: '..ssid..', because it\'s not in saved networks')
        end
    end
    print('done with saved networks, found none to connect to')
    collectgarbage()
    file.close()
    dofile('chooseAP.lc')
end

--function is called after connection to network is initiated; it 
function checkConn()
    tmr.alarm(1,1000,1, function()
        local connectStatus = wifi.sta.status()
        print("connecting")
        if (connectStatus ~= 1 and connectStatus ~= 0) then
            print("connectStatus = "..tostring(connectStatus))
            if (connectStatus == 5) then
                print("successfully connected")
                tmr.stop(1)
            else
                print("Whoops! Could not connect to "..tostring(SSID)..". "..statusTable[tostring(connectStatus)])
				tmr.stop(1)
                checkSavedNets()
            end
            collectgarbage()
        end
    end)
end

--gets a table of the SSIDs/
file.open('networkList','r')
local counter = 0
local line = ""
while (true) do
    line = file.readline()
    if line == nil then break end
    line = string.sub(line,1,string.len(line)-1) --for some reason without this hack, I think it was showing the line breaks
    print(line)
    counter = counter + 1
    SSIDs[line] = true
end
checkSavedNets()