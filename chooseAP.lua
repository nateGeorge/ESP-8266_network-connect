-- this code was inpired by someone else
-- works using least memory if compiled, otherwise you may 
-- run out of memory and the module will randomly restart and 
-- drop connections often if TCP timeout is low (3s seems to short)

local SSID = nil
local pass = nil
local otherSSID = nil
local errMsg = nil
local savedNetwork = false
local SSIDs = {}
local resetTimer = 15 -- for resetting the module after successfully connecting to chosen network
-- lookup table for wifi.sta.status()
local statusTable = {}
-- statusTable[0] = "neither connected nor connecting"
-- statusTable[1] = "still connecting"
statusTable["2"] = "wrong password"
statusTable["3"] = "didn\'t find the network you specified"
statusTable["4"] = "failed to connect"
-- statusTable[5] = "successfully connected"

collectgarbage()
wifi.setmode(wifi.STATIONAP)
print('wifi status: '..wifi.sta.status())
print(node.heap())

-- opens saved list of nearby networks and puts into SSIDs table
file.open('networkList','r')
local counter = 0
local line = ""
while (true) do
    line = file.readline()
    if line == nil then break end
    counter = counter + 1
    SSIDs[counter] = line
end

print(node.heap())

-- start server running on ESP-8266, usually is IP 192.168.4.1
local cfg = {}
cfg.ssid = "myfi"
cfg.pwd = "mystical"
wifi.ap.config(cfg)
cfg = nil
local srv=net.createServer(net.TCP,30000)
print('connect to this ip on your computer/phone: '..wifi.ap.getip())
srv:listen(80,function(conn)
conn:on("connection", function(client,request)
    sendHeader(client)
    sendForm(client)
end)
conn:on("receive", function(client,request)
    -- if someone is just visiting the page, it's a GET request,
    -- otherwise if they're submitting a form it's POST
    local isPOST = nil
    _, _, isPOST = string.find(request, "(POST)")
    if (isPOST~=nil) then
        -- handle click of "edit networks" button
        local _, _, editClicked = string.find(request, "(edit=editClicked)")
        if (editClicked~=nil) then
            editNetworks(client)
        end
        -- handle choice of individual network to edit
        local _, _, editNetwork = string.find(request, "editSSID=(.+)")
        if (editNetwork~=nil) then
            editNetwork(client,editNetwork)
        end
        -- go back to "edit networks" page if clicked cancel from individual network edit page
        local _, _, cancelEdit = string.find(request, "(cancelSingleNetworkEdit)")
        if (cancelEdit~=nil) then
            editNetworks(client)
        end
        -- check if SSID and password have been submitted
        local connecting = false
        -- I noticed the strange characters %%0D%%0A appearing after the SSID, so I put them in the string.find
        local _, _, SSID, pass = string.find(request, "SSID=(.+)%%0D%%0A&otherSSID=&password=(.*)")
        print(node.heap())
    
        if (pass~=nil and pass~="") then
            if (string.len(pass)<8) then
                local pass = nil
                errMsg = "<center><h2 style=\"color:red\">Whoops! Password must be at least 8 characters.<\h2><\center>"
            else
                errMsg = nil
            end
        end
        
        if (SSID==nil) then
            _, _, SSID, pass = string.find(request, "SSID=&otherSSID=(.+)%%0D%%0A&password=(.*)")
        end
    
        print(request)
        local buf = "";
    
        -- if password for network is nothing, any password should work
        if (SSID~=nil) then
            if (pass == "") then
                pass = "aaaaaaaa"
            end
            print(SSID..', '..pass)
            wifi.sta.config(tostring(SSID),tostring(pass))
            wifi.sta.connect()
            connecting = true
        end
    end
    
    -- if found SSID in the POST from the client, try connecting
    if (SSID~=nil) then
    -- TO-DO: add timout for connection attempt
        local connectStatus = wifi.sta.status()
        print(connectStatus)
        sendHeader(client)
        tmr.alarm(5,500,0,function()
            buf = buf.."<center><h2 style=\"color:DarkGreen\">Connecting to "..tostring(SSID)
            buf = buf.."!</h2><br><h2>Please hold tight, we'll be back to you shortly.</h2></center>"
            client:send(buf)
            client:close()
            buf = ""
        end)
        tmr.alarm(1,1000,1, function()
            connectStatus = wifi.sta.status()
            print("connecting")
            if (connectStatus ~= 1) then
                print("connectStatus = "..tostring(connectStatus))
                if (connectStatus == 5) then
                    print(node.heap())
                    sendHeader(client)
                    buf = buf.."<center><h2 style=\"color:DarkGreen\">Successfully connected to "..tostring(SSID).."!"
                    buf = buf.."</h2><br><h2>Added to network list.</h2><br><h2>Resetting module in "..resetTimer.."s...</h1></center>"
                    client:send(buf)
                    buf = ""
                    file.open("networks","a+")
                    file.writeline(tostring(SSID))
                    file.writeline(tostring(pass))
                    file.close()
                    print("SSID/pass written to file")
                    savedNetwork = true
                    tmr.alarm(2,resetTimer*1000,0,function()
                        srv:close()
                        node.restart()
                        end)
                else
                    sendHeader(client)
                    buf = buf.."<center><h2 style=\"color:red\">Whoops! Could not connect to "..tostring(SSID)..". "..statusTable[tostring(connectStatus)].."</h2><br></center>"
                    client:send(buf)
                    buf = ""
                end
                client:send(buf)
                client:close()
                collectgarbage()
                tmr.stop(1)
                print('finished connection func')
            end
        end)
    end
    buf = ""
    if(not connecting and isPOST==nil) then
        sendHeader(client)
        sendForm(client, errMsg)
        client:send(buf)
        buf = ""
        client:close()
        collectgarbage()
    end
end)
end)

function sendHeader(client)
    -- write header to client
    -- had to chunk up sending of webpage, to deal with low amounts of memory on ESP-8266 devices...surely a more elegant way to do it
    buf = ""
    buf = buf.."<!DOCTYPE html><html><head><style>h2{font-size:500%; font-family:helvetica} "
    buf = buf.."p{font-size:200%; font-family:helvetica}</style>"
    buf = buf.."</head><div style = \"width:80%; margin: 0 auto\">"
    client:send(buf)
    buf = ""
end

function sendForm(client, errMsg)
    buf = ""
    -- send top of form to client
    buf = buf.."<center><h1>Choose a network to join:</h1></center>"
    buf = buf.."<form align=\"left\" method=\"POST\" autocomplete=\"off\">"
    buf = buf.."<p><u><b>1. Choose network:</u></b><br>"
    client:send(buf)
    buf = ""
    -- send network names one at a time; if there are lots of networks the ESP can run out of memory
    for i,network in pairs(SSIDs) do
        buf = "<input type=\"radio\" name=\"SSID\" value=\""..network.."\">"..network.."<br>"
        client:send(buf)
        buf = ""
    end
    buf = buf.."other: <input type=\"text\" name=\"otherSSID\"><br><br>"
    buf = buf.."<u><b>2. Enter password (or blank for none):</u></b><br><input type=\"text\" name=\"password\"><br><br>"
    buf = buf.."<input style=\"font-size:30pt\" type=\"submit\" value=\"Submit\">"
    buf = buf.."</p></form></div>"
    client:send(buf)
    buf = ""
    buf = buf.."<br><br><br><form align=\"center\" method=\"POST\">"
    buf = buf.."<input type=\"hidden\" name=\"edit\" value=\"editClicked\">"
    buf = buf.."<input type=\"submit\" value=\"Edit saved network info\" style=\"font-size:30pt\"></form></html>"
    client:send(buf)
    buf = ""
    -- add warning about password<8 characters if needed
    if (errMsg~=nil) then
        buf = buf.."<br><br>"..errMsg
        errMsg = nil
    end
end

function editNetworks(client)
    -- displays page for choosing a network to edit
    sendHeader(client)
    buf = "<center><h1>Choose a network to edit:</h1></center>"
    buf = buf.."<form align=\"left\" method=\"POST\" autocomplete=\"off\">"
    client:send(buf)
    file.open('networks','r')
    while true do
        local line = file.readline()
        if line == nil then break end
        local ssid = string.sub(line,1,string.len(line)-1) --hack to remove CR/LF
        local line = file.readline() -- skip the password line
        if line == nil then break end -- think this line is unecessary, will have to check
        buf = "<input type=\"radio\" name=\"editSSID\" value=\""..ssid.."\">"..ssid.."<br>"
        client:send(buf)
    end
    buf = buf.."<input style=\"font-size:30pt\" type=\"submit\" value=\"Submit\">"
    buf = buf.."<input type=\"button\" name=\"cancel\" value=\"cancelNetworkEdit\"> Cancel"
    -- cancel button automatically takes you back to the main page,
    -- since that is the default action on "recieve"
end

function editNetwork(client,editNetwork)
    -- for editing password or deleting a single network
    sendHeader(client)
    buf = "<center><h1>Choose a network to edit:</h1></center>"
    buf = buf.."<form align=\"left\" method=\"POST\" autocomplete=\"off\">"
    buf = buf.."new password (blank for none): <input type=\"text\" name=\"pass\"><br><br>"
    buf = buf.."<input type=\"checkbox\" name=\"delete\" value=\"deleteSSID\"> "
    client:send(buf)
    buf = buf.."Delete network from saved list"
    buf = buf.."<input style=\"font-size:30pt\" type=\"submit\" value=\"Submit\">"
    buf = buf.."<input type=\"button\" name=\"cancel\" value=\"cancelSingleNetworkEdit\"> Cancel"
    client:send(buf)
end
