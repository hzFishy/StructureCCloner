local selffilename = "inventory"

local fuelSlots
local fuelChest
local blockSlots = {}
local fuelItems = {
    "minecraft:coal",
    "minecraft:charcoal"
}
local modem

local currentSelectedSlot -- no usage for now
local inventoryisFull = false
local doinventoryEvents

local ressourceChestType = Config.build.ressourceChestType


--[[ Utils ]]--
local function removeMCNameSpace(str)
    return string.gsub(str,"minecraft:","")
end

local function addMCNameSpace(str)
    if not string.find(str,":") then
        str = "minecraft:"..str
    end
    return str
end

local function connectModem()
    return peripheral.find("modem") or error("No modem", 0)
end


--[ Inventory Global ]--
local function turtlemakelist()
    local slots = {}
    local function ree(i) return function() slots[i] = turtle.getItemDetail(i) end end
    parallel.waitForAll(ree(1),ree(2),ree(3),ree(4),ree(5),ree(6),ree(7),ree(8),ree(9),ree(10),ree(11),ree(12),ree(13),ree(14),ree(15),ree(16))
    return slots
end
-- sucks stacks in the inventory under of the turtle
local function suckX(stacks)
    for _ = 1, stacks do
        turtle.suckDown()
    end
end
-- drops  in the inventory under of the turtle
local function drop()
    for i,details in pairs(turtlemakelist()) do
        if i >= blockSlots[1] then
            if details.count > 0 then
                turtle.select(i)
                currentSelectedSlot = i
                turtle.dropDown()
            end
        end
    end
end


--[[ Fuel ]]--
-- returns if given slot item is a fuel type item
local function isFuelItem(slot)
    for _, value in ipairs(fuelItems) do
        local d = turtle.getItemDetail(slot)
        if d and d.name == value then
            return true
        end
    end
    return false
end
-- return a fuelslot that isn't empty
local function getFuelSlot()
    for _, slot in ipairs(fuelSlots) do
        if isFuelItem(slot) then
            if turtle.getItemCount(slot) > 0 then
                Utils.logtoFile(selffilename,"selectSlotBlock",nil,"(slot: "..slot..")",true)
                return slot
            end
        end
    end
    Utils.logtoFile(selffilename,"selectSlotBlock",nil,"No not-empty-slot/fuel-item  found",true)
    return nil
end
local function getFuelChestposition()
    return fuelChest
end
-- set 'fuelSlots' and 'blockSlots'
local function setFuelSlots(mode)
    Utils.logtoFile(selffilename,"setFuelSlots","(mode: "..mode..")","",true)
    if mode == "scan" then
        fuelSlots = Config.scan.fuelSlots
        fuelChest = Config.scan.fuelChest
        for i = #fuelSlots+1, 16 do
            table.insert(blockSlots,i)
        end
    elseif mode == "build" then
        fuelSlots = Config.build.fuelSlots
        fuelChest = Config.build.fuelChest
        for i = #fuelSlots+1, 16 do
            table.insert(blockSlots,i)
        end
    end
end
local function refillFuel()
    suckX(#fuelSlots)
end


--[[ Block ]]--
local function getBlock(name)
    name = addMCNameSpace(name)
    for slot, _ in ipairs(blockSlots) do
        local info = turtle.getItemDetail(slot)
        if info and info.name == name then
            return slot
        end
    end
    return nil
end
local function getAllSlotsWithBlock(name)
    name = addMCNameSpace(name)
    local allslots = {}
    for slot, _ in ipairs(blockSlots) do
        local info = turtle.getItemDetail(slot)
        if info and info.name == name then
            table.insert(allslots,slot)
        end
    end
    return allslots
end
-- return  blockslot
local function getBlockSlots()
    return blockSlots
end
-- return a table, containing all slots (empty or not) where a block can be placed
local function getEmptyBlockSlot(name,count)
    Utils.logtoFile(selffilename,"name: "..name.." want to add: "..count)
    -- format: {{slot = <slotnumber>, count = <spaceisnide>},...}
    local function makeSlot(slot,slotcount)
        return {slot = slot, count = slotcount}
    end
    local function emptySlot()
        for _, slot in ipairs(blockSlots) do
            if turtle.getItemCount(slot) == 0 then
                return slot
            end
        end
        return nil
    end

    if name and count then
        local countLeft = count
        local slots = {}
        local function addSlot(intable)
            table.insert(slots,intable)
        end
        local slotsblock = getAllSlotsWithBlock(name)
        Utils.logtoFile(selffilename,"getAllSlotsWithBlock: "..textutils.serialise(slotsblock))
        while countLeft > 0 do
            if #slotsblock > 0 then
                for _, slot in ipairs(slotsblock) do
                    local space = turtle.getItemSpace(slot)
                    if space > 0 then
                        local neededspace
                        if space <= countLeft then
                            neededspace = space
                        else
                            neededspace = countLeft
                        end
                        addSlot(makeSlot(slot,neededspace))
                        countLeft = countLeft - neededspace
                    end
                end
                slotsblock = {}
            else
                for _ = 1, math.ceil(countLeft/64) do
                    local empty = emptySlot()
                    if empty then
                        table.insert(slots,makeSlot(empty,count))
                    else
                        Term.errorr("Inventory full ! User did a mistake ?")
                        break
                    end
                end
                return slots
            end
        end
        return slots
    else
        local empty = emptySlot()
        if empty then
            return {makeSlot(empty,count)}
        else
            Term.errorr("Inventory full ! User did a mistake ?")
        end
    end
end
-- select a blockslot that isn't empty
local function selectSlotBlock()
    for _, slot in ipairs(blockSlots) do
        if turtle.getItemCount(slot) > 0 then
            turtle.select(slot)
            currentSelectedSlot = slot
            Utils.logtoFile(selffilename,"selectSlotBlock",nil,"(slot: "..slot..")",true)
            return true, slot
        end
    end
    Utils.logtoFile(selffilename,"selectSlotBlock",nil," didn't found any block slot with items",true)
    return false
end


--[ Inventory Global ]--
local function push(periph,slot,count)

    local da = getEmptyBlockSlot(periph.getItemDetail(slot).name,count)

    Utils.logtoFile(selffilename,"push from slot "..slot..", turtle slots will be used: ".. textutils.serialise(da))

    for _, value in ipairs(da) do
        periph.pushItems(modem.getNameLocal(), slot,value.count,value.slot)
    end
end

--[ Inventory ]--
-- returns inventoryisFull
local function getinventoryisFull()
    return inventoryisFull
end
-- set inventoryisFull
local function setinventoryisFull(bool)
    inventoryisFull = bool
end
-- sort inventory between blockSlots and fuelSlots
local function sortInventory()
    for _, slot in ipairs(fuelSlots) do
        if (turtle.getItemCount(slot) > 0) and (not isFuelItem(slot)) then
            turtle.select(slot)
            currentSelectedSlot = slot
            local blockS = blockSlots[1]
            while not turtle.transferTo(blockS) do
                blockS = blockS +1
                if blockS > #blockSlots+#fuelSlots then
                    turtle.drop()
                    setinventoryisFull(true)
                    break
                end
            end
        end
    end
end
-- checks if the all blockSlots are taken
local function checkInventoryFull()
    local full
    if not getinventoryisFull() then
        for _, slot in ipairs(blockSlots) do
            if turtle.getItemCount(slot) > 0 then
                full = true
            else
                full = false
                break
            end
        end
        setinventoryisFull(full)
    end
end
-- function is running in another thread next to the current module execution
local function inventoryEvents()
    Utils.logtoFile(selffilename,"inventoryEvents","listening to 'turtle_inventory' events")
    doinventoryEvents = true
    while doinventoryEvents do
        if fuelSlots and blockSlots then
            checkInventoryFull()
            os.pullEvent("turtle_inventory")
            sortInventory()
        end
    end
    Utils.logtoFile(selffilename,"inventoryEvents","stoped listening to 'turtle_inventory' events")
end
-- stops 'inventoryEvents()'
local function stopinventoryEvents()
    doinventoryEvents = false
end
--check if required item and count is present in inventory
local function checkItemsCount(missing)

    local chest = peripheral.find(ressourceChestType)
    while not chest do
        Term.errorr("No '"..ressourceChestType.."' connected to modem")
        Term.manualretry()
    end

    for _, chestitem in pairs(chest.list()) do
        for i, neededitem in pairs(missing) do
            if neededitem.count <= 0 then
                table.remove(missing,i)
            end
            local id = neededitem.id
            local count = neededitem.count
            id = addMCNameSpace(id)

            if chestitem.name == id then
                local newcount
                newcount = count - chestitem.count
                if newcount <= 0 then
                    table.remove(missing,i)
                else
                    missing[i].count = newcount
                end
            end
        end
    end
    return missing
end
-- get needed block
local function getBlocks(blocks)
    -- format {{name = "", count = 0}}
    local chest = peripheral.find(ressourceChestType)
    while not chest do
        Term.errorr("No '"..ressourceChestType.."' connected to modem")
        Term.manualretry()
    end

    local chestItems = chest.list()
    modem = connectModem()
    Utils.logtoFile(selffilename,"origin blocks: "..textutils.serialise(blocks))

    Utils.logtoFile(selffilename,"getBlocks",nil,"blocks: "..textutils.serialise(blocks),true)

    local chestSlotsData = {}
    --[[ format:
    {
        <itemname> = {
            {
                slot = <slotnb>,
                count = <count>
            },
            ...
        },
        ...
    }
    ]]
    local function additemname(name)
        chestSlotsData[name] = {}
    end
    local function addSlotAndCount(name,slotnb,countnb)
        table.insert(chestSlotsData[name],{slot = slotnb,count = countnb})
    end

    Term.resetColor()
    print("Scanning chest")
    for slot, chestitem in pairs(chestItems) do
        for _, value in pairs(blocks) do
            local name = value.name
            local neededcount = value.count
            name = addMCNameSpace(name)
            if neededcount > 0 and chestitem.name == name then
                if not chestSlotsData[name] then
                    additemname(name)
                end
                local newcount
                if chestitem.count >= neededcount then
                    newcount = neededcount
                else
                    newcount = chestitem.count
                end
                value.count = value.count-newcount
                addSlotAndCount(name,slot,newcount)
            end
        end
    end
    Utils.logtoFile(selffilename,"chestSlotsData:" ..textutils.serialise(chestSlotsData))
    print("Gathering requested items")

    for _, info in pairs(chestSlotsData) do
        for _, slotinfo in pairs(info) do
            push(chest,slotinfo.slot,slotinfo.count)
        end
    end
end



return {
    fuelSlots = fuelSlots,
    blockSlots = blockSlots,
    addMCNameSpace = addMCNameSpace,
    removeMCNameSpace = removeMCNameSpace,

    getFuelSlot = getFuelSlot,
    getFuelChestposition = getFuelChestposition,
    setFuelSlots = setFuelSlots,
    isFuelItem = isFuelItem,
    refillFuel = refillFuel,
    getinventoryisFull = getinventoryisFull,
    setinventoryisFull = setinventoryisFull,

    getBlockSlots = getBlockSlots,
    getBlock = getBlock,
    selectSlotBlock = selectSlotBlock,

    sortInventory = sortInventory,
    checkItemsCount = checkItemsCount,
    inventoryEvents = inventoryEvents,
    stopinventoryEvents = stopinventoryEvents,

    suckX = suckX,
    drop = drop,
    getBlocks = getBlocks
}