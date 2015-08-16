-- opens saved list of nearby networks and puts into SSIDs table
local SSIDs = {}
file.open('networkList','r')
local counter = 0
local line = ""
while true do
    line = file.readline()
    if line == nil then break end
    counter = counter + 1
    SSIDs[counter] = line
end

-- writes html file up to part with network names
file.open("chooseAP.html","w")
file.writeline("<!DOCTYPE html>")
file.writeline("<html>")
file.writeline("<head>")
file.writeline("<style>")
file.writeline("h2{font-size:500%; font-family:helvetica}")
file.writeline("p{font-size:200%; font-family:helvetica}")
file.writeline("</style>")
file.writeline("</head>")
file.writeline("<div style = \"width:80%; margin: 0 auto\">")
file.writeline("<center><h1>Choose a network to join:</h1></center>")
file.writeline("<form align=\"left\" method=\"POST\" autocomplete=\"off\">")
file.writeline("<p>")
file.writeline("<u><b>1. Choose network:</u></b>")
file.writeline("<br>")

-- send network names one at a time; if there are lots of networks the ESP can run out of memory
for i,network in pairs(SSIDs) do
    netSubSpaces, _ = string.gsub(network, " ", "%%20")
    file.writeline("<input type=\"radio\" name=\"SSID\" value=\""..netSubSpaces.."\">"..network.."<br>")
end

-- write rest of html with submit buttons
file.writeline("other: <input type=\"text\" name=\"otherSSID\">")
file.writeline("<br><br>")
file.writeline("<u><b>2. Enter password (or blank for none):</u></b>")
file.writeline("<br>")
file.writeline("<input type=\"text\" name=\"password\">")
file.writeline("<br><br>")
file.writeline("<input style=\"font-size:30pt\" type=\"submit\" value=\"Submit\">")
file.writeline("</p></form>")
file.writeline("<br><br><br>")
file.writeline("<form align=\"center\" method=\"POST\">")
file.writeline("<input type=\"hidden\" name=\"deleteSaved\" value=\"true\">")
file.writeline("<input type=\"submit\" value=\"Delete all saved networks\" style=\"font-size:30pt; color:red\">")
file.writeline("</form>")
file.writeline("<br><br><br>")
file.writeline("<form align=\"center\" method=\"POST\">")
file.writeline("<input type=\"hidden\" name=\"reloadNets\" value=\"true\">")
file.writeline("<input type=\"submit\" value=\"Re-scan networks\" style=\"font-size:30pt\">")
file.writeline("</form>")
file.writeline("</div>")
file.writeline("</html>")

file.close()
