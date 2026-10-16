local linkAdapter = peripheral.find("redstone_link_bridge")  
assert(linkAdapter, "No redstone link bridge found")
local display = peripheral.wrap("top")
 
local targetYaw = 0
local targetPitch = 0
local coefficient = 1
local MIN_PITCH = -90
local MAX_PITCH = 15
local MIN_YAW = 325
local MAX_YAW = 35
 
-- get cannon peripherals
local cannons = {}
for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == "cannon_mount" then
        local cannon = peripheral.wrap(name)
        if not cannon.isComputerControl() then
            cannon.setComputerControl(true)
        end
        table.insert(cannons, cannon)
    end
end
print("Connected to " .. #cannons .. " cannons.")
 

local function turnOnComputerControl() 
    for _, cannon in ipairs(cannons) do
            cannon.setComputerControl(true)
    end
end
 
local function applyCannonAngles(targetYaw, targetPitch)
    for _, cannon in ipairs(cannons) do
        cannon.setTargetYaw(targetYaw)
        cannon.setTargetPitch(targetPitch)
    end
end
 
turnOnComputerControl()
applyCannonAngles(0,0)
 
local function normalizeAngle(angle)
    return (angle % 360 + 360) % 360
end
 
local function clampYaw(angle)
    angle = normalizeAngle(angle)
    
    -- The forbidden zone is between MAX_YAW (36) and MIN_YAW (325)
    if angle > MAX_YAW and angle < MIN_YAW then
        -- Snap to whichever edge it is closer to
        if angle < 180 then
            return MAX_YAW
        else
            return MIN_YAW
        end
    end
    return angle
end
 
local function clampPitch(angle)
    if angle < MIN_PITCH then
        return MIN_PITCH
    elseif angle > MAX_PITCH then
        return MAX_PITCH
    else
        return angle
    end  
end
 
local function writeDisplay(display, text, line, color)
    display.setCursorPos(1, line)
    display.setTextColor(color)
    display.clearLine()
    display.write(text)
end
 
local function placeAndWrench() 
    -- place munition
    linkAdapter.sendLinkSignal("minecraft:gold_ingot","minecraft:diamond",15)
    os.sleep(0.5)
    linkAdapter.sendLinkSignal("minecraft:gold_ingot","minecraft:diamond",0)
    os.sleep(0.1)
    writeDisplay(display, "munition placed", 1, colors.white)
    -- wrench munition
    linkAdapter.sendLinkSignal("minecraft:diamond","minecraft:gold_ingot",15)
    os.sleep(0.5)
    linkAdapter.sendLinkSignal("minecraft:diamond","minecraft:gold_ingot",0)
    os.sleep(0.1)
    writeDisplay(display, "munition wrenched", 1, colors.white)
end
 
local function shootAndPrep()
    -- shoot
    linkAdapter.sendLinkSignal("minecraft:emerald", "minecraft:diamond", 15)
    os.sleep(0.1)
    linkAdapter.sendLinkSignal("minecraft:emerald","minecraft:diamond",0)
    os.sleep(0.1)
    writeDisplay(display, "shot", 1, colors.white)
    -- dissasemble
    linkAdapter.sendLinkSignal("minecraft:diamond","minecraft:emerald", 0)
    os.sleep(0.1)
    writeDisplay(display, "dissasembleed", 1, colors.white)
    -- unscrew breach
    linkAdapter.sendLinkSignal("minecraft:iron_ingot","minecraft:lapis_lazuli", 15)
    os.sleep(1)
    writeDisplay(display, "unscrewed", 1, colors.white)
    -- pull screw breach out
    linkAdapter.sendLinkSignal("minecraft:lapis_lazuli","minecraft:iron_ingot",15)
    writeDisplay(display, "breach pulled out", 1, colors.white)
end
 
local function sequence()
    writeDisplay(display, "LOADING", 2, colors.blue)
    parallel.waitForAll(shootAndPrep, placeAndWrench)
 
    -- gantry push in/out
    linkAdapter.sendLinkSignal("minecraft:gold_ingot","minecraft:lapis_lazuli",15)
    os.sleep(2)
    linkAdapter.sendLinkSignal("minecraft:gold_ingot","minecraft:lapis_lazuli",0)
    os.sleep(0.1)
    writeDisplay(display, "gantry pushed ammo", 1, colors.white)
    -- push screw breach in + screw breach
    linkAdapter.sendLinkSignal("minecraft:lapis_lazuli","minecraft:iron_ingot",0) -- screw 
    linkAdapter.sendLinkSignal("minecraft:iron_ingot","minecraft:lapis_lazuli",0) -- push
    os.sleep(0.7)
    writeDisplay(display, "pushed and screwed breach in", 1, colors.white)
    -- reassemble cannon
    linkAdapter.sendLinkSignal("minecraft:diamond","minecraft:emerald",15)
    os.sleep(0.1)
    writeDisplay(display, "reassembled", 1, colors.white)
    turnOnComputerControl()
    applyCannonAngles(targetYaw, targetPitch)
    writeDisplay(display, "READY", 2, colors.red)
end
 
local function controlLoop()
    while true do
        if #cannons > 0 then
            if #cannons > 0 then
                local upVal = linkAdapter.getLinkSignal("minecraft:redstone", "minecraft:nether_brick")
                local downVal = linkAdapter.getLinkSignal("minecraft:nether_brick", "minecraft:redstone")
                local leftVal = linkAdapter.getLinkSignal("minecraft:coal", "minecraft:diamond")
                local rightVal = linkAdapter.getLinkSignal("minecraft:diamond", "minecraft:coal")
                
                local changed = false
                
                -- Modify variables based on signals
                if leftVal > 0 then 
                    targetYaw = targetYaw - (leftVal * coefficient)
                    changed = true 
                end
                if rightVal > 0 then 
                    targetYaw = targetYaw + (rightVal * coefficient)
                    changed = true 
                end
                if upVal > 0 then 
                    targetPitch = targetPitch + (upVal * coefficient) 
                    changed = true 
                end
                if downVal > 0 then 
                    targetPitch = targetPitch - (downVal * coefficient)
                    changed = true 
                end
                
                -- Apply angle limits (Clamping pitch so it stays between MIN and MAX)
                targetPitch = clampPitch(targetPitch)           
                targetYaw = clampYaw(targetYaw)
                
                writeDisplay(display, targetPitch, 3, colors.white)
                
                -- If buttons were pressed, update the cannons using our function
                if changed then
                    applyCannonAngles(targetYaw, targetPitch)
                end
            end
            os.sleep(0.05)
        end
    end
end
 
 
local function loadingLoop()
    while true do
        if linkAdapter.getLinkSignal("minecraft:iron_ingot","") > 0 then
            writeDisplay(display, "starting sequence", 1, colors.white)
            sequence()
        end
        
        if linkAdapter.getLinkSignal("","minecraft:iron_ingot") > 0 then
            writeDisplay(display, "program ending", 1, colors.white)
            break
        end
        os.sleep(0.1)
    end
end
 
parallel.waitForAny(controlLoop, loadingLoop)