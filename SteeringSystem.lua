local linkAdapter = peripheral.find("redstone_link_bridge")  
assert(linkAdapter, "No redstone link bridge found")
 
THRUSTER_LEFT = {"minecraft:copper_ingot", "minecraft:gold_ingot"}
THRUSTER_RIGHT = {"minecraft:gold_ingot", "minecraft:copper_ingot"}
 
STEERING_LEFT = {"minecraft:clay_ball", "minecraft:copper_ingot"}
STEERING_RIGHT = {"minecraft:copper_ingot", "minecraft:clay_ball"}
 
THROTTLE = {"minecraft:clay_ball", "minecraft:clay_ball"}

OFF = {"minecraft:snowball", "minecraft:slime_ball"}
 
-- steering wheel will output 15 on both channels when centered, and then will start subtracting on the side it is turned, 
-- meaning that the throttle on the selected side will start to reduce to turn

local function controlLoop()
    while true do
        local steeringLeft = linkAdapter.getLinkSignal(STEERING_LEFT[1], STEERING_LEFT[2])
        local throttle = linkAdapter.getLinkSignal(THROTTLE[1], THROTTLE[2])
        if steeringLeft < 15 then -- steer LEFT
            linkAdapter.sendLinkSignal(THRUSTER_LEFT[1], THRUSTER_LEFT[2], throttle * (steeringLeft / 15)) -- LEFT THRUSTER gets LESS POWER
            linkAdapter.sendLinkSignal(THRUSTER_RIGHT[1], THRUSTER_RIGHT[2], throttle) -- RIGHT THRUSTER gets MORE POWER
        else -- steer RIGHT
            local steeringRight = linkAdapter.getLinkSignal(STEERING_RIGHT[1], STEERING_RIGHT[2])
            linkAdapter.sendLinkSignal(THRUSTER_LEFT[1], THRUSTER_LEFT[2], throttle) -- LEFT THUSTER gets MORE POWER
            linkAdapter.sendLinkSignal(THRUSTER_RIGHT[1], THRUSTER_RIGHT[2], throttle * (steeringRight / 15)) -- RIGHT THRUSTER gets LESS POWER
        end
    end
end
 
local function endCondition()
    while true do
        if linkAdapter.getLinkSignal(OFF[1],OFF[2]) > 0 then
            break
        end
        os.sleep(0.25)
    end
end
    
parallel.waitForAny(controlLoop, endCondition)
os.shutdown()