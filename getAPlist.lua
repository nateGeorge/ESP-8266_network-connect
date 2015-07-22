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
    print(node.heap())
    collectgarbage()
    file.close()
    return
end
end
)
