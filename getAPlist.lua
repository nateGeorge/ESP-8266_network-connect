--this retrieves a list of the nearby networks and saves it in a file
--so it doesn't have to be done everytime you want to get a list of nearby networks
--seems to be a problem with releasing memory:
--testing on NodeMCU devkit shows
--before running, first time: heap = 34416
--first print(node.heap()) = 31512
--second one = 31552
--after running: 34160
--second time: 31632, 31672, 34160, so it returns to the same free memory after running once

wifi.setmode(1)

wifi.sta.getap(
function (t)
local k = ''
local v = ''
local counter = 1
if (t == nil) then
    print('no end points')
    collectgarbage();
    return
else
    file.remove('networkList')
    file.open('networkList','w+')
    for k,v in pairs(t) do
        print(k)
        file.writeline(k)
    end
    file.close('networkList')
    print(node.heap())
    collectgarbage()
    print(node.heap())
    file.close()
    return
end
end
)
