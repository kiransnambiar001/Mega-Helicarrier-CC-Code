local pgpx = 0
local pgpy = 0
local pgpz = 0

local delay = 0.5

TELEMETRY_NAME = "telem2"
SEGMENT = 1
 
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
 
local function sendTelem(line, segment, stringTable) 
    local data = {
        line = line,
        segment = segment,
        stringTab = stringTable
    }
 
    rednet.broadcast(data, TELEMETRY_NAME)
 
    return data
end

 
local function updateDisplay()
    while true do
        local gpx, gpy, gpz = gps.locate()
        if not gpx or not gpy or not gpz then
            gpx = pgpx
            gpy = pgpy
            gpz = pgpz
            print("Gps connection lost")
        end
 
        sendTelem(1, SEGMENT, {{text = "X: ", color = colors.white}, {text = tostring(math.floor(gpx)), color = colors.blue}})
        sendTelem(2, SEGMENT, {{text = "Y: ", color = colors.white}, {text = tostring(math.floor(gpy)), color = colors.blue}})
        sendTelem(3, SEGMENT, {{text = "Z: ", color = colors.white}, {text = tostring(math.floor(gpz)), color = colors.blue}})
 
        local xVel = math.floor((gpx-pgpx)/delay)
        local yVel = math.floor((gpy-pgpy)/delay)
        local zVel = math.floor((gpz-pgpz)/delay)

        local horizVel = math.floor(math.sqrt(xVel^2 + zVel^2))
        sendTelem(4, SEGMENT, {{text = "H Vel: ", color = colors.white}, {text = tostring(horizVel), color = colors.purple}})
        sendTelem(5, SEGMENT, {{text = "Y Vel: ", color = colors.white}, {text = tostring(yVel), color = colors.purple}})

        pgpx = gpx
        pgpy = gpy
        pgpz = gpz
 
        os.sleep(delay)
 
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
 
parallel.waitForAny(updateDisplay, endListener)