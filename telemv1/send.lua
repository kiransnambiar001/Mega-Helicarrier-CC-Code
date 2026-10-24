TELEMETRY_NAME = "cannon_telem"
 
local modem = nil
for _, device in ipairs(peripheral.getNames()) do
    if peripheral.getType(device) == "modem" then
        modem = device
        break
    end
end
 
if not modem then
    error("No modem found")
end
rednet.open(modem)
 
local function sendTelem(line, segment, color, string) 
    local data = {
        line = line,
        segment = segment,
        color = color,
        string = string
    }
 
    rednet.broadcast(data, TELEMETRY_NAME)
 
    return data
end
 
local function telemetryLoop()
    while true do
        sendTelem(1,2,colors.white,"dsadsdsa")
        os.sleep(1)
    end
end
 
telemetryLoop()
 