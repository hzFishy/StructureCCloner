local inventory = require "modules.inventory"
local build = require "modules.building"

local selffilename = "movement"

local spawnCoordsVector
local spawnFacingValue
local lastCoordsVector
local lastFacingValue

local dropoff = Config.scan.dropoff
local dropoffChest = Config.scan.dropoffChest
local goingTodropoffChest = false
local needTodropoffChest = false

-- Generate default moving and rotate functions from turtle module
local defmov_whitelist = {["forward"] = true, ["back"] = true, ["up"] = true, ["down"] = true}
local defmov = {}
local defturn_whitelist = {["turnLeft"] = true, ["turnRight"] = true}
local defturn = {}
for k, v in pairs(turtle) do
    if defmov_whitelist[k] then
        defmov[k] = function()
            local try = v()
            Utils.logtoFile(selffilename,"defmov."..k,nil,"Turtle tried to move, result: "..(Utils.ternary(try,"Success","Failed")),true)
            return try
        end
    elseif defturn_whitelist[k] then
        defturn[k] = function()
            local try = v()
            Utils.logtoFile(selffilename,"defmov."..k,nil,"Turtle tried to rotate, result: "..(Utils.ternary(try,"Success","Failed")),true)
            return try
        end
    end
end


--[[ Turtle fuel ]]--
-- refuel
local function refuel(amount)
    Utils.logtoFile(selffilename,"refuel","(amount: "..amount..")","",true)
    local slot = inventory.getFuelSlot()
    if slot then
        turtle.select(slot)
        turtle.refuel(amount or 2)
        return true
    else
        Utils.logtoFile(selffilename,"refuel",nil,"refuel failed",true)
        Term.errorr("Cannot refuel, is there still fuel ?")
        return false
    end
end
-- check fuel
local function checkFuel(amountToCheck,amountRefill)
    Utils.logtoFile(selffilename,"checkFuel","(amountToCheck: "..amountToCheck.." amountRefill: "..amountRefill..")","",true)
    if turtle.getFuelLevel() < amountToCheck then
        return refuel(amountRefill)
    end
    return true
end


--[[ Initialize Coords ]]--
-- set Coords
local function initCoords(initvector)
    lastCoordsVector = initvector*1
    Utils.logtoFile(selffilename,"InitCoords()","("..(textutils.serialise(initvector,{compact = true}))..")","")
end
-- set facing direction
local function initFacing(facing)
    lastFacingValue = facing
    Utils.logtoFile(selffilename,"initFacing()","(face: '"..facing.."')","")
end
-- get last saved current coods
local function lastCoords()
    Utils.logtoFile(selffilename,"lastCoords",nil," result: ("..lastCoordsVector:tostring()..")",true)
    return lastCoordsVector
end
-- get last saved current facing direction
local function lastFacing()
    Utils.logtoFile(selffilename,"lastFacing",nil," result: ("..lastFacingValue..")",true)
    return lastFacingValue
end


--[[ Initialize Spawn Coords ]]--
-- set Spawn Coords
local function initSpawnCoords(initvector)
    spawnCoordsVector = initvector*1
    Utils.logtoFile(selffilename,"initSpawnCoords","("..(textutils.serialise(initvector,{compact = true}))..")","")
    if lastCoordsVector == nil then initCoords(initvector*1) end
end
-- set Spawn facing direction
local function initSpawnFacing(facing)
    spawnFacingValue = facing
    Utils.logtoFile(selffilename,"initSpawnFacing","(face: '"..facing.."')","")
    if lastFacingValue == nil then initFacing(facing) end
end
-- get Spawn coods
local function getSpawnCoords()
    return spawnCoordsVector
end
-- get Spawn facing direction
local function getSpawnFacing()
    return spawnFacingValue
end


--[[ Estimate ]]--
local function estimate(startVector,endVector)
    local totalPoints = (endVector.x - startVector.x + 1) * (endVector.z - startVector.z + 1) * (endVector.y - startVector.y + 1)
    local totalseconds = (totalPoints*0.4)*2

    return {
        time = Utils.formatTime(totalseconds),
        fuel = math.ceil(totalPoints/80) -- coal
    }
end

--[[ Rotation handling ]]--
-- Rotated by 180 degrees
local function rotateBehind()
    for _ = 1, 2, 1 do
        defturn.turnRight()
    end
end
-- Returns if the facing direction 1 (f1) and the facing direction 2 (f2) are opposite
local function oppositeFace(f1, f2)
    local t1 = f1:len() == 1 and f1 or f2
    return (f1:match(t1) and f2:match(t1)) and true or false
end
-- Rotate to given facing direction
local function rotateToFace(gface)
    local startT = Utils.C_ElapsedTime.new()
    local rightOrder = {"x", "z", "-x", "-z"}
    local cface = lastFacing()
    if cface == gface then
        return
    end
    if oppositeFace(cface,gface) then
        rotateBehind()
    else
        local currentIndex = nil
        local goalIndex = nil


        for i, face in ipairs(rightOrder) do
            if face == cface then
                currentIndex = i
            elseif face == gface then
                goalIndex = i
            end
        end
        local right = false
        local rotationDirection = goalIndex - currentIndex

        if (rotationDirection < 2) and (rotationDirection > 0) then
            right = true
        end

        if not right then
            if rotationDirection == -3 then
                defturn.turnRight()
            else
                defturn.turnLeft()
            end
        else
            if rotationDirection > 0 then
                for _ = 1, rotationDirection do
                    defturn.turnRight()
                end
            else
                for _ = 1, math.abs(rotationDirection) do
                    defturn.turnLeft()
                end
            end
        end
    end
    Utils.logtoFile(selffilename,"rotateToFace()", nil, "finished with: (gface: "..gface..") in "..startT:getElapsedTime().." milliseconds")
    initFacing(gface)
end


--[[ Movement handling ]]--
-- returns the distance between 2 vectors
local function vectordistance(v1,v2)
    return math.abs(v1.x - v2.x) + math.abs(v1.y - v2.y) + math.abs(v1.z - v2.z)
end
-- returns if the the first vector is close from one block to the other one
local function isClose(vector1,vector2)
    local xDiff = math.abs(vector1.x - vector2.x)
    local zDiff = math.abs(vector1.z - vector2.z)
    local yDiff = math.abs(vector1.y - vector2.y)

    local b = false
    if ((xDiff == 1 and zDiff == 0) and (yDiff == 0)) or ((xDiff == 0 and zDiff == 1) and (yDiff == 0)) then
        b = true
    end
    Utils.logtoFile(selffilename,"isClose","(vector1: "..vector1:tostring().." vector2: "..vector2:tostring()..")",Utils.tern4Bool(b),true)
    return b
end
-- Returns if the turtle can move to a position
--[[
local function canMoveTo(cVector,gVector)
    Utils.logtoFile(selffilename,"canMoveTo",nil,"(cVector: "..cVector:tostring().." gVector: "..gVector:tostring()..")")
    if cVector.x ~= gVector.x then
        if lastFacing() ~= "x" then
            rotateToFace("x")
        end
    elseif  cVector.z ~= gVector.z then
        if lastFacing() ~= "z" then
            rotateToFace("z")
        end
    end
    local inspRes, _ = turtle.inspect()
    Utils.logtoFile(selffilename,"canMoveTo",nil," result: ("..Utils.ternary(not inspRes,"true","false")..")")
    return not inspRes
end
-- Tries to get an alternative route depedning of blocking direction
local function findAlternativeRoute(cVector,blockingAxe,blockingAxeDir)
    local startT = Utils.C_ElapsedTime.new()
    Utils.logtoFile(selffilename,"findAlternativeRoute",nil,"(cVector: "..cVector:tostring().." blockingAxe: "..blockingAxe.." blockingAxeDir: "..blockingAxeDir..")","")
        if blockingAxeDir == "x" then
            --vector.new(cVector.x, cVector.y, cVector.z+Utils.ternary(blockingAxe[1] == "-",,))
        elseif blockingAxe == "z" then
            local v1 = vector.new(cVector.x+1, cVector.y, cVector.z)
            local v2 = vector.new(cVector.x-1, cVector.y, cVector.z)
            if canMoveTo(cVector,v1) then
                Utils.logtoFile(selffilename,"findAlternativeRoute()",nil," finished with: (result: true, v: "..v1:tostring()..") in "..startT:getElapsedTime().." milliseconds")
                return true, v1
            elseif canMoveTo(cVector,v2) then
                Utils.logtoFile(selffilename,"findAlternativeRoute()",nil," finished with: (result: true, v: "..v2:tostring()..") in "..startT:getElapsedTime().." milliseconds")
                return true, v2
            else
                Utils.logtoFile(selffilename,"findAlternativeRoute()",nil," finished with: (result: false) in "..startT:getElapsedTime().." milliseconds")
                return false
            end
        end
    Utils.logtoFile(selffilename,"findAlternativeRoute()",nil," finished with: **[WARNING: 'blockingAxe' didn't satisfied 'if' statsements]**, (result: false) in "..startT:getElapsedTime().." milliseconds")
    return false
end
]]

--sets the value of 'needTodropoffChest'
local function setneedTodropoffChest(bool)
    needTodropoffChest = bool
end
--- moves the turtle to given coords  -- cannot work with obstacles (for now) (all comments that is code is a old try of this implementation, in goTo, findAlternativeRoute,canMoveTo)
local function goTo(goalCoords,lookFront,candestroy,scan_callback,skipRefuel)
    lookFront = Utils.ternary(lookFront == nil,false,lookFront)
    candestroy = Utils.ternary(candestroy == nil,false,candestroy)
    skipRefuel = Utils.ternary(skipRefuel == nil, false, skipRefuel)

    local startT = Utils.C_ElapsedTime.new()

    local cVector = lastCoords()
    local gVector = goalCoords

    --[[local gVectorTable = {}
    local oldgVectorTable = {}
    local refresh = false
    local successRefresh = false
    local wasStuck = {}

    local function addStuckKey(vector)
        wasStuck[vector:tostring()] = {
            x = false,
            z = false
        }
        Utils.logtoFile(selffilename,"goTo,addVectorGoal",nil,"addStuckTemplate: "..textutils.serialise(wasStuck,{ allow_repetitions = true }),true)
    end

    local function addStuckDirection(dir)
        wasStuck[gVector:tostring()][dir] = true
        Utils.logtoFile(selffilename,"goTo,addStuckDirection","gVector: "..gVector:tostring().." dir: "..dir,"",true)
        Utils.logtoFile(selffilename,"goTo,addStuckDirection",nil,textutils.serialise(wasStuck,{ allow_repetitions = true }),true)
    end

    local function wasStuckPreviously(coord)
        local bool
        if (#oldgVectorTable > 0) then
            bool = (wasStuck[gVector:tostring()][coord]) or (wasStuck[oldgVectorTable[1]:tostring()][coord])
            Utils.logtoFile(selffilename,"goTo,wasStuckPreviously","coord: "..coord," gVector: "..gVector:tostring().." old: "..oldgVectorTable[1]:tostring().." Result: "..Utils.tern4Bool(bool),true)
        else
            bool = (wasStuck[gVector:tostring()][coord])
            Utils.logtoFile(selffilename,"goTo,wasStuckPreviously","coord: "..coord.." gVector: "..gVector:tostring(),"Result: "..Utils.tern4Bool(bool),true)
        end
        return bool
    end

    local function addVectorGoal(vector)
        table.insert(gVectorTable,1,vector)
        Utils.logtoFile(selffilename,"goTo,addVectorGoal",nil," inserted new vector (gVectorTable: "..textutils.serialise(gVectorTable)..")",true)
        successRefresh = false
        Utils.logtoFile(selffilename,"goTo,addVectorGoal",nil,"successRefresh = false",true)

        if gVector ~= nil then
            addStuckKey(vector)
        end
        refresh = true
    end
    addVectorGoal(goalCoords)
    addStuckKey(goalCoords)
    refresh = false]]

    Utils.logtoFile(selffilename,"goTo","(cVector: "..cVector:tostring()..--[[" gVectorTable: "..textutils.serialise(gVectorTable)]]" gVector: "..gVector:tostring()..")","")
    --while #gVectorTable > 0  do
        --gVector = gVectorTable[1]

        --cVector = lastCoords()
        --Utils.logtoFile(selffilename,"goTo",nil," new loop with: (gVector: "..gVector:tostring()..")")
        while (cVector ~= gVector) --[[and (not refresh)]] do
            --Utils.logtoFile(selffilename,"goTo",nil," new sub loop with: (cVector: "..cVector:tostring()..")")
            if (not skipRefuel) and (not checkFuel(vectordistance(cVector,inventory.getFuelChestposition())+20,1)) then
                Utils.logtoFile(selffilename,"goTo",nil,"No more fuel in turtle, going to fuelChest for refill",true)
                goTo(inventory.getFuelChestposition(),false,false,nil,true)
                print("Refuelling...")
                inventory.refillFuel()
                print("Refuel finished")
                Utils.logtoFile(selffilename,"goTo",nil,"refill finished",true)
                cVector = lastCoords()
                needTodropoffChest = true -- while close, drop items
                skipRefuel = false
            end

            if  (dropoff and (needTodropoffChest or inventory.getinventoryisFull()) and (not goingTodropoffChest)) then
                goingTodropoffChest = true
                Utils.logtoFile(selffilename,"goTo",nil,"inventory is full, going to dropoffChest for draining",true)
                goTo(getSpawnCoords())
                cVector = lastCoords()
                goTo(dropoffChest,true)
                inventory.drop()
                Utils.logtoFile(selffilename,"goTo",nil,"draining finished",true)
                cVector = lastCoords()
                inventory.setinventoryisFull(false)
                setneedTodropoffChest(false)
                goingTodropoffChest = false
            end

            --successRefresh = true
            --Utils.logtoFile(selffilename,"goTo",nil,"successRefresh = true",true)
            -- X
            --if (not wasStuckPreviously("x")) or (canMoveTo(cVector,cVector:add(vector.new(1,0,0))) or canMoveTo(cVector,cVector:add(vector.new(-1,0,0))))  then
                while(cVector.x ~= gVector.x --[[and (not refresh)]]) do
                    if (lastFacing() ~= "x") and (lastFacing() ~= "-x") then
                        rotateToFace("x")
                    end
                    while cVector.x > gVector.x do
                        if lookFront then
                            rotateToFace("-x")
                            if scan_callback and isClose(cVector,gVector) then
                                scan_callback(turtle.inspect())
                            end
                            if defmov.forward() then
                                cVector.x=cVector.x-1
                            elseif candestroy then
                                build.remove("f")
                            else
                                --[[local success, vector = findAlternativeRoute(cVector,"x","-")
                                Utils.logtoFile(selffilename,"goTo",nil,"was stuck true: x",true)
                                addStuckDirection("x")
                                if success then
                                    addVectorGoal(vector)
                                    break
                                else]]
                                    break
                                --end
                            end
                        else
                            if defmov.back() then
                                cVector.x=cVector.x-1
                            elseif candestroy then
                                rotateToFace("-x")
                                build.remove("f")
                            else
                                --[[local success, vector = findAlternativeRoute(cVector,"x","-")
                                Utils.logtoFile(selffilename,"goTo",nil,"was stuck true: x",true)
                                addStuckDirection("x")
                                if success then
                                    addVectorGoal(vector)
                                    break
                                else]]
                                    break
                                --end
                            end
                        end
                    end

                    while cVector.x < gVector.x do
                        if scan_callback and isClose(cVector,gVector) then
                            scan_callback(turtle.inspect())
                        end
                        if defmov.forward() then
                            cVector.x=cVector.x+1
                        elseif candestroy then
                            build.remove("f")
                        else
                            --[[local success, vector = findAlternativeRoute(cVector,"x","+")
                            Utils.logtoFile(selffilename,"goTo",nil,"was stuck true: x",true)
                            addStuckDirection("x")
                            if success then
                                addVectorGoal(vector)
                                break
                            else]]
                                break
                            --end
                        end
                    end

                end
            --end
            -- Z
            --if (not wasStuckPreviously("z")) or (canMoveTo(cVector,cVector:add(vector.new(0,0,1))) or canMoveTo(cVector,cVector:add(vector.new(0,0,-1))))  then
                while (cVector.z ~= gVector.z --[[and (not refresh)]]) do
                    if (lastFacing() ~= "z") and (lastFacing() ~= "-z") then
                        rotateToFace("z")
                    end
                    while cVector.z > gVector.z do
                        if lookFront then
                            rotateToFace("-z")
                            if scan_callback and isClose(cVector,gVector) then
                                scan_callback(turtle.inspect())
                            end
                            if defmov.forward() then
                                cVector.z=cVector.z-1
                            elseif candestroy then
                                build.remove("f")
                            else
                                --[[local success, vector = findAlternativeRoute(cVector,"z","-")
                                Utils.logtoFile(selffilename,"goTo",nil,"was stuck true: z",true)
                                addStuckDirection("z")
                                if success then
                                    addVectorGoal(vector)
                                    break
                                else]]
                                    break
                                --end
                            end
                        else
                            if defmov.back() then
                                cVector.z=cVector.z-1
                            elseif candestroy then
                                build.remove("f")
                            else
                                --[[local success, vector = findAlternativeRoute(cVector,"z","-")
                                Utils.logtoFile(selffilename,"goTo",nil,"was stuck true: z",true)
                                addStuckDirection("z")
                                if success then
                                    addVectorGoal(vector)
                                    break
                                else]]
                                    break
                                --end
                            end
                        end
                    end
                    while cVector.z < gVector.z do
                        if scan_callback and isClose(cVector,gVector) then
                            scan_callback(turtle.inspect())
                        end
                        if defmov.forward() then
                            cVector.z=cVector.z+1
                        elseif candestroy then
                            build.remove("f")
                        else
                            --[[local success, vector = findAlternativeRoute(cVector,"z","+")
                            Utils.logtoFile(selffilename,"goTo",nil,"was stuck true: z",true)
                            addStuckDirection("z")
                            if success then
                                addVectorGoal(vector)
                                break
                            else]]
                                break
                            --end
                        end
                    end
                end
            --end
            -- Y
            while cVector.y ~= gVector.y--[[ and (not refresh)]] do

                while cVector.y > gVector.y do
                    if scan_callback then
                        scan_callback(turtle.inspectDown())
                    end
                    if defmov.down() then
                        cVector.y=cVector.y-1
                    elseif candestroy then
                        build.remove("d")
                    else
                        -- findAlternativeRoute
                        break
                    end
                end
                while cVector.y < gVector.y do
                    if scan_callback then
                        scan_callback(turtle.inspectUp())
                    end
                    if defmov.up() then
                        cVector.y=cVector.y+1
                    elseif candestroy then
                        build.remove("u")
                    else
                        -- findAlternativeRoute
                        break
                    end
                end
            end
        end
        --[[if refresh then
            if successRefresh then
                initCoords(gVector) -- saving new value
                wasStuck[gVector:tostring()] = nil
                Utils.logtoFile(selffilename,"goTo",nil,"Cleared wasStuck.gVector",true)
            end
            Utils.logtoFile(selffilename,"goTo",nil,"REFRESHED",true)
            refresh = false
        else
            table.insert(oldgVectorTable,gVectorTable[1])
            local rem = table.remove(gVectorTable,1)
            Utils.logtoFile(selffilename,"goTo",nil,"REMOVED the following element in gVectorTable: "..textutils.serialise(rem),true)
            refresh = false
            Utils.logtoFile(selffilename,"goTo",nil," sub-finished with: (gVector: "..gVector:tostring()..") in "..startT:getElapsedTime().." milliseconds",true)
            initCoords(gVector) -- saving new value
        end]]
    --end
    Utils.logtoFile(selffilename,"goTo",nil," finished with: (gVector: "..gVector:tostring()..") in "..startT:getElapsedTime().." milliseconds")
    initCoords(gVector) -- saving new value
end
-- moves the turtle to spawn coords and facing direction
local function goToSpawn()
    local startT = Utils.C_ElapsedTime.new()
    Utils.logtoFile(selffilename,"goToSpawn",nil," Going back to spawn coords and facing")
    goTo(getSpawnCoords())
    rotateToFace(getSpawnFacing())
    Utils.logtoFile(selffilename,"goToSpawn",nil," arrived after "..startT:getElapsedTime().." milliseconds")
end
-- for scanning, the turtle goes to all blocks given in a volume
local function checkAllVolume(startVector, endVector,chunkIndex,callbackPerBlockAction,callbackPerLayerAction,callbackPerZLineAction,callbackPerFinishZLineAction)
    local startT = Utils.C_ElapsedTime.new()
    Utils.logtoFile(selffilename,"checkAllVolume()",nil,"starting")
    local yIndex = 1
    for y = startVector.y, endVector.y do
        if callbackPerLayerAction then
            callbackPerLayerAction(chunkIndex,yIndex)
        end
        local FacingOrder = "front"
        local xIndex = 1
        for x = startVector.x, endVector.x do
            if callbackPerZLineAction then
                callbackPerZLineAction(xIndex)
            end
            --local zIndex = 0
            if FacingOrder == "front" then
                for z = startVector.z, endVector.z do
                    callbackPerBlockAction(x,y,z,false)
                    --zIndex = zIndex + 1
                end
                FacingOrder = "back"
            else
                for z = endVector.z, startVector.z, -1 do
                    callbackPerBlockAction(x,y,z,true)
                    --zIndex = zIndex + 1
                end
                FacingOrder = "front"
            end
            if callbackPerFinishZLineAction then
                callbackPerFinishZLineAction(chunkIndex,yIndex)
            end
            xIndex = xIndex+1
        end
        yIndex = yIndex+1
    end
    Utils.logtoFile(selffilename,"checkAllVolume()",nil,"finished in "..startT:getElapsedTime().." milliseconds")
end




return {
    dropoffChest = dropoffChest,
    lastCoordsVector = lastCoordsVector,
    setneedTodropoffChest = setneedTodropoffChest,
    dropoff = dropoff,
    estimate = estimate,

    goTo = goTo,
    --canMoveTo = canMoveTo,
    rotateToFace = rotateToFace,
    goToSpawn = goToSpawn,

    checkAllVolume = checkAllVolume,

    initSpawnCoords = initSpawnCoords,
    initSpawnFacing = initSpawnFacing,
    getSpawnCoords = getSpawnCoords,
    getSpawnFacing = getSpawnFacing,

    initCoords = initCoords,
    initFacing = initFacing,
    lastFacing = lastFacing,
    lastCoords = lastCoords
}