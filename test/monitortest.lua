DATA_SOURCE = "main_telem"
SEGMENT_LENGTH = {
    {start = 1, width = 13},
    {start = 14, width = 13},
    {start = 27, width = 13}
}
 
local monitor = peripheral.wrap("right")
assert(monitor, "No monitor found.")
monitor.clear()
 
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
 
local function writeMonitor(line, segment, color, string)
    local length = SEGMENT_LENGTH[segment].width
    local start = SEGMENT_LENGTH[segment].start
 
    monitor.setTextScale(1)
    monitor.setTextColor(colors.white)
 
    monitor.setCursorPos(start, line)
    monitor.write(string.rep(" ", length))
    print(string.rep(" ", length))
    
    monitor.setCursorPos(start, line)
    monitor.setTextColor(color)
    monitor.write(string:sub(1,length))
    print(string:sub(1,length))
end
 
local function dataListener()
    while true do
        local senderId, data = rednet.receive(DATA_SOURCE)
        if type(data) == "table" and data.string and data.segment and data.line then
            local color = data.color and data.color or data.white
            print(textutils.serialize(data))
                
            writeMonitor(
                data.line,
                data.segment,
                data.color,
                data.string
            )
        end 
    end
end
 
dataListener()
monitor.clear()