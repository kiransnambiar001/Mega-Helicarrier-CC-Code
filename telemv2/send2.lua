TELEMETRY_NAME = "telem2"
 
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
 
local function sendTelem(line, segment, stringTable) 
    local data = {
        line = line,
        segment = segment,
        stringTab = stringTable
    }
 
    rednet.broadcast(data, TELEMETRY_NAME)
 
    return data
end
 
local function telemetryLoop()
    local stringTable = {
        {text = "hello ", color = colors.white},
        {text = "nv", color = colors.red},
        {text = "djui", color = colors.yellow}
    }
 
    sendTelem(1,1, stringTable)
    
    sendTelem(2,2,stringTable)
    
    sendTelem(3,3,stringTable)
end
 
telemetryLoop()