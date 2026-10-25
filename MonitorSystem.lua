DATA_SOURCE = "telem2"
SEGMENT_LENGTH = {
    {start = 1, width = 13},
    {start = 14, width = 13},
    {start = 27, width = 13}
}
 
local monitor = peripheral.find("monitor")
assert(monitor, "No monitor found.")
monitor.clear()

local linkAdapter = peripheral.find("redstone_link_bridge")
assert(linkAdapter, "No redstone link bridge found")
 
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
print("Connection online, computer ID: " .. os.getComputerID())
 
local function writeMonitor(line, segment, stringTab)
 
    local length = SEGMENT_LENGTH[segment].width
    local start = SEGMENT_LENGTH[segment].start
 
    monitor.setTextColor(colors.white)
 
    monitor.setCursorPos(start, line)
    monitor.write(string.rep(" ", length+1))
 
    for index, target in ipairs(stringTab) do
        monitor.setTextColor(target.color)
 
        local totalStart = start
        local totalLength = 0
        for i=1,index do
            if i-1 > 0 then
                totalStart = totalStart + #stringTab[i-1].text
            end
            totalLength = totalLength + #stringTab[i].text
        end
        
        local remainingSpace = length - totalLength - 1
        print("totalStart: " .. totalStart .. ", totalLength: " .. totalLength .. ", remainingSpace: " .. remainingSpace)
        monitor.setCursorPos(totalStart, line)
        -- monitor.write(target.text)
        if remainingSpace > 0 then
            monitor.write(target.text)
        else
            monitor.write(target.text:sub(1, length-totalLength))
        end
    end
end
 
local function dataListener()
    while true do
        local senderId, data = rednet.receive(DATA_SOURCE)
        if type(data) == "table" and data.stringTab and data.segment and data.line then
            writeMonitor(
                data.line,
                data.segment,
                data.stringTab
            )  
        end
    end
end

local function endListener()
    while true do
        if linkAdapter.getLinkSignal("minecraft:snowball","minecraft:slime_ball") > 0 then
            break
        end
    end
    os.sleep(0.25)
end
 
parallel.waitForAny(dataListener, endListener)
monitor.clear()
os.shutdown()
 