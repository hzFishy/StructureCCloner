local movement = require "modules.movement"
local inventory = require "modules.inventory"
local input = require "modules.utils.input"
local pretty = require "modules.term.pretty"
local selffilename = "mapping/scan"

local mappingDir = "StructureCCloner/userData/"
local mappingFileName = "scan"
local currentScanFilename
local scanFilePrefix = Config.scan.scanfilepreffix

local selectedSubMode
local vector_start
local vector_end
local chunks = {}
--local chunkSize = 16
local tableOutput
local ZLineTable = {}
local items = {}


local placeholderBlockIfEmpty = Config.scan.placeholderBlockIfEmpty
local upload = Config.scan.autoupload
local removeMCNamespace = Config.scan.removeMCNamespace
local showIndexs = Config.scan.showIndexs
local replace_patterns = Config.scan.replace_patterns
local ignored_blocks = Config.scan.ignored_blocks

-- convert int to string for layer/chunk indexing
local function convertIndex(int)
    if showIndexs then
        int = tostring(int)
    end
    return int
end

--[[ Scan Output actions while scanning ]]--
-- Upload scanresultfile to web
local function scanOutput_Upload(type)
    Utils.logtoFile(selffilename,"scanOutput_Upload","(type: "..type..")","Starting")
    if type == "StructureCCloner" then
        local e="er"local t="tp"local a=".n"local o="ob"local i="cl"local n="s."local
        s="ht"local h="wi"local r="or"local d="s:/"local l="ur"local u=".c"local
        c="nd"local m="sc"local f="ru"local w="s"local y="ec"local p="ct"local
        v="e."local b="on"local g="ow"local k="an"local q="/st"local j="et"local
        x="bl"local z="/"local E="sv=2022-"local T="1Y%3D"local A="tps,http"local
        O="TlWKl"local I="&st=202"local N="&sig="local S="3-07-22T1"local
        H="FqgvS"local R="cdOotb2s"local D="=o"local L="&sp=rw"local U="lactf"local
        C="11-02"local M="&se=2024-"local F="01-01T"local W="20:53:"local
        Y="PUmVf"local P="YAg9nV"local V="1:53:35Z"local B="&spr=ht"local
        G="prAPL"local K="&ss=bf"local Q="DPYx"local J="q%2B"local X="35Z"local
        Z="o%2"local et="&srt"local tt="bolbscans/"..currentScanFilename local
        at=fs.open(mappingDir..currentScanFilename,"r")local
        ot=at.readAll()at.close()local
        it={["x-ms-blob-type"]="BlockBlob",["Content-Length"]=#ot,["x-ms-version"]="2022-11-02",}Utils.logtoFile(selffilename,"scanOutput_Upload",nil,"Executing the http request")http.request{method="PUT",url=(s..t..d..q..f..p..l..y..i..b..e..m..k..n..x..o..u..r..v..h..c..g..w..a..j..z)..tt.."?"..(E..C..K..et..D..L..U..M..F..W..X..I..S..V..B..A..N..Z..H..P..O..Q..R..G..J..Y..T),headers=it,body=ot}local
        nt,st
        Utils.logtoFile(selffilename,"scanOutput_Upload",nil,"Waiting the http result")while
        true do nt,_,st=os.pullEvent()if string.find(nt,"http")~=nil then break end end
        Utils.logtoFile(selffilename,"scanOutput_Upload",nil,"Event: "..nt.." ResponseCode: "..st.getResponseCode())if
        string.find((st.getResponseCode()),"201")then
        Utils.logtoFile(selffilename,"scanOutput_Upload",nil,"File created successful"); Term.changeColor(colors.green)
        print("File uploaded to StructureCCloner web storage"); Depend.DH_sendmsg("File uploaded to StructureCCloner web storage") else
        Utils.logtoFile(selffilename,"scanOutput_Upload",nil,"Error encountered, error details: "..Utils.ternary(st==nil,"Nil",st));Term.errorr("File upload failed")end
    elseif type == "pastebin" then
        Term.changeColor(colors.orange)
        print("Uploading to pastebin...")
        Term.resetColor()
        shell.run("pastebin put "..mappingDir..currentScanFilename)
    end
end

-- replace the tableOutput with new table stat
local function scanOutput_Save(table)
    tableOutput = table
end
-- Save the current scan table to the scanfile
local function scanOutput_SaveFile()
    Utils.logtoFile(selffilename,"scanOutput_SaveFile",nil,"")
    local file = fs.open(mappingDir..currentScanFilename,"w")
    file.write(textutils.serialise(tableOutput))
    file.close()
end
-- Adds a new chunk
local function scanOutput_NewChunk(chunkIndex)
    Utils.logtoFile(selffilename,"scanOutput_NewChunk","(chunkIndex: "..chunkIndex..")","")
    chunkIndex = convertIndex(chunkIndex)
    tableOutput.chunks[chunkIndex] = {
        --order = tonumber(chunkIndex),
        layers = {}
    }
    scanOutput_SaveFile()
end
-- Adds a new layer to the current chunk
local function scanOutput_NewLayer(chunkIndex,layerIndex)
    Utils.logtoFile(selffilename,"scanOutput_NewLayer","(chunkIndex: "..chunkIndex.." layerIndex: "..layerIndex..")","")
    chunkIndex = convertIndex(chunkIndex)
    tableOutput.chunks[chunkIndex].layers[layerIndex] = {}
    scanOutput_SaveFile()
end
-- Adds a new Z line table to the current layer
local function scanOutput_NewZLine()
    Utils.logtoFile(selffilename,"scanOutput_NewZLine")
    ZLineTable = {}
end
-- Save the current Z line to the table and add it to the file
local function scanOutput_SaveZLine(chunkIndex,layerIndex)
    Utils.logtoFile(selffilename,"scanOutput_SaveZLine","(chunkIndex: "..chunkIndex.." layerIndex: "..layerIndex..")","")
    chunkIndex = convertIndex(chunkIndex)
    layerIndex = convertIndex(layerIndex)
    table.insert(tableOutput.chunks[chunkIndex].layers[layerIndex], ZLineTable)
    Utils.logtoFile(selffilename,"scanOutput_SaveZLine",nil," inserted (ZLineTable: "..textutils.serialise(ZLineTable)..")")
    scanOutput_SaveFile()
end


--[[ Actions while scanning ]]--
-- Executed a each new layer
local function perLayerScanAction(chunkIndex,layerIndex)
    Utils.logtoFile(selffilename,"perLayerScanAction","(chunkIndex: "..chunkIndex.." layerIndex: "..layerIndex..")","")
    layerIndex = convertIndex(layerIndex)
    scanOutput_NewLayer(chunkIndex,layerIndex)
end
-- Executed a each new Z line
local function perZLineAction()
    Utils.logtoFile(selffilename,"perZLineAction")
    scanOutput_NewZLine()
end
-- Executed a each end of Z linesd
local function perFinishZLineAction(chunkIndex,layerIndex)
    Utils.logtoFile(selffilename,"perFinishZLineAction"," (layerIndex: "..layerIndex..")","")
    layerIndex = convertIndex(layerIndex)
    scanOutput_SaveZLine(chunkIndex,layerIndex)
end

--use ignored_blocks (if any)
local function IgnoredBlockCheck(block)
    if #ignored_blocks < 1 then
        return block
    end
    for _, value in ipairs(ignored_blocks) do
        if value == block then
            return "minecraft:air"
        end
    end
    return block
end

-- use replace_patterns (if any)
local function replaceWithPatterns(block)
    if #replace_patterns < 1 then
        return block
    end
    for _, value in ipairs(replace_patterns) do
        if value[1] == block then
            return value[2]
        end
    end
    return block
end

-- add item (or block) to 'names' table
local function addBlock(block,setempty)
    setempty = Utils.ternary(setempty == nil, false, setempty)
    block = IgnoredBlockCheck(block)
    block = replaceWithPatterns(block)
    Utils.logtoFile(selffilename,"addBlock","( item: "..block.." setempty: "..(Utils.tern4Bool(setempty))..")","")
    local function lookupify_ids(tbl)
        local lookup = {}
        for i,v in ipairs(tbl) do
            lookup[v.id] = {i,v}
        end
        return lookup
    end
    local function addNames()
        tableOutput.names = items
    end

    if removeMCNamespace then
        block = block:gsub("minecraft:", "")
    end
    local id = 1
    local res = lookupify_ids(items)
    if not res[block] then
        Utils.logtoFile(selffilename,"addBlock",nil,"item doesnt exist in 'items' table, adding it")
        table.insert(items,{id = block, count = Utils.ternary(setempty,0,1)})
        id = #items
        addNames()
    else
        Utils.logtoFile(selffilename,"addBlock",nil,"Item exists in 'items' table, adding 1 for 'count'")
        id = res[block][1]
        res[block][2]["count"] = res[block][2]["count"] + 1
    end
    return id
end
-- Executed a each new block
local function perBlockScanAction(x,y,z,backwards)
    Utils.logtoFile(selffilename,"perBlockScanAction","("..x..", "..y..", "..z..")","")
    local scanned = false
    local function save(inspectSuccess, blockInfo)
        if not scanned then
            Utils.logtoFile(selffilename,"perBlockScanAction",nil,Utils.ternary(inspectSuccess,"Block found","Block not found"),true)
            local block = Utils.ternary(inspectSuccess,blockInfo.name,placeholderBlockIfEmpty)
            local id = addBlock(block,false)
            table.insert(ZLineTable,Utils.ternary(backwards,1,#ZLineTable+1),id)
            scanned = true
        end
    end

    if selectedSubMode == "Full" then
        movement.goTo(vector.new(x,y,z),movement.getFacingOrder() == "back",true,save)
    end
end


--[[ Initializing parameters before scan ]]--
-- creates starting and ending points coords, gets xyz begin bottom left corner and xyz end top right corner
local function initVectors(vectorStart,vectorEnd)
    vector_start = vectorStart
    vector_end = vectorEnd
    Utils.logtoFile(selffilename,"initVectors","(vector_start: "..vector_start:tostring().." vector_end: "..vector_end:tostring()..")","")
end
-- split the volume into as many 16x16 (x,z) sub-volumes (chunks)
local function initChunks(vectorStart,vectorEnd)

    --[[
    local startChunkX = math.floor(vectorStart.x / chunkSize)
    local startChunkZ = math.floor(vectorStart.z / chunkSize)
    local endChunkX = math.floor(vectorEnd.x / chunkSize)
    local endChunkZ = math.floor(vectorEnd.z / chunkSize)

    local i = 1
    for x = startChunkX, endChunkX do
        for z = startChunkZ, endChunkZ do
            local chunkStartX = x * chunkSize
            local chunkStartZ = z * chunkSize
            local chunkEndX = chunkStartX + chunkSize - 1
            local chunkEndZ = chunkStartZ + chunkSize - 1

            if x == endChunkX and vectorEnd.x % chunkSize ~= 0 then
                chunkEndX = vectorEnd.x
            end

            if z == endChunkZ and vectorEnd.z % chunkSize ~= 0 then
                chunkEndZ = vectorEnd.z
            end

            local chunk = {
                index = i,
                start = vector.new(chunkStartX, vectorStart.y, chunkStartZ),
                finish = vector.new(chunkEndX, vectorEnd.y, chunkEndZ)
            }
            chunks[i] = chunk
            i = i + 1
        end
    end
    ]]
    local chunk = {
        index = 1,
        start = vectorStart,
        finish = vectorEnd
    }
    chunks[1] = chunk
    Utils.logtoFile(selffilename,"initChunks","(vectorStart: "..vectorStart:tostring().." vectorEnd: "..vectorEnd:tostring()..")"," ended with (total chunk count: "..#chunks..", chunks table : "..(textutils.serialise(chunks))..")")
end
-- Creates the file
local function initOutput(customname)
    currentScanFilename = mappingFileName.."_"..scanFilePrefix.."_"..customname.."_"..(os.date("%Y-%m-%d_%H-%M-%S")).."_"..math.random(9999)
    local initTable = {
        names = {},
        chunks = {}
    }
    scanOutput_Save(initTable)
    addBlock(placeholderBlockIfEmpty,true)
    scanOutput_SaveFile()
    Utils.logtoFile(selffilename,"initOutput",nil,"Finished with filename: '"..currentScanFilename.."'")
end
-- Inits the whole init scan process
local function initScan(vectorStart,vectorEnd,customname)
    Term.changeColor(colors.orange)
    print()
    print("Initializing...")
    local startT = Utils.C_ElapsedTime.new()
    Utils.logtoFile(selffilename,"===initScan===",nil,"initializing scanning variables")


    initVectors(vectorStart,vectorEnd)
    Utils.logtoFile(selffilename,"initScan",nil," finished initVectors in "..startT:getElapsedTime().." milliseconds")
    initChunks(vectorStart,vectorEnd)
    Utils.logtoFile(selffilename,"initScan",nil,"finished initChunks in "..startT:getElapsedTime().." milliseconds")
    initOutput(customname)
    Utils.logtoFile(selffilename,"initScan",nil," finished initOutput in "..startT:getElapsedTime().." milliseconds")

    Utils.logtoFile(selffilename,"===initScan===",nil," finished initializing in "..startT:getElapsedTime().." milliseconds")
    Term.changeColor(colors.green)
    print("Initialized")
    Depend.DH_sendmsg("# Scan mode initialized with:")
    Depend.DH_sendmsg("__Begin coordinate:__ `"..vector_start:tostring().."`")
    Depend.DH_sendmsg("__End coordinate:__ `"..vector_end:tostring().."`")
end


--[[ Scan ]]--
local function startScanning()
    local startT = Utils.C_ElapsedTime.new()
    Utils.logtoFile(selffilename,"===startScanning===",nil," starting scanning")
    Term.changeColor(colors.orange)
    print("Started scanning")
    Depend.DH_sendmsg("# Started scanning")
    Term.resetColor()
    print("Progress:")
    pretty.initBar(colors.green,colors.red)
    Depend.DH_sendmsg("**Progress:**")
    local _,msgid = Depend.DH_initBar(0)
    local function updatebars(p)
        pretty.updateBar(p)
        Depend.DH_updateBar(p,msgid)
    end

    movement.goTo(vector_start:add(vector.new(0,0,-1)))
    for chunkIndex, value in ipairs(chunks) do -- for each chunk go to bottom left corner TO top right corner
        scanOutput_NewChunk(chunkIndex)
        movement.checkAllVolume(
            updatebars,
            value.start,
            value.finish,
            chunkIndex,
            perBlockScanAction,
            perLayerScanAction,
            perZLineAction,
            perFinishZLineAction)
    end
    updatebars(100)
    Utils.logtoFile(selffilename,"startScanning",nil," scan finished in "..startT:getElapsedTime().." milliseconds")
    Term.changeColor(colors.green)
    print("Finished Scanning")
    Depend.DH_sendmsg("# Finished Scanning \n In `"..(Utils.formatTime((startT:getElapsedTime()/1000))).."`")

    if movement.dropoff then
        movement.setneedTodropoffChest(true)
    end
    movement.goToSpawn()

    Term.changeColor(colors.white)
    print("Scanfile name: "..currentScanFilename)
    Depend.DH_sendmsg("Scanfile name: `"..currentScanFilename.."`")

    if upload then
        scanOutput_Upload("StructureCCloner")
    else
        Term.changeColor(colors.cyan)
        print("Do you want to upload your file to StructureCCloner web storage or pastebin ?")
        Term.askInput()
        local ans = select(1,(string.gsub(read(nil, {}, function(text) return Completion.choice(text, {"StructureCCloner","pastebin","nothing"}) end)," ","")))
        if ans == "StructureCCloner" or ans == "pastebin" then
            scanOutput_Upload(ans)
        end
    end

    Utils.logtoFile(selffilename,"===startScanning===",nil," finished in "..(Utils.formatTime((startT:getElapsedTime()/1000))))
end
-- User inputs menu
local function init()
    Utils.logtoFile(selffilename,"scanInit",nil,"Starting scan mode")
    Term.splitWrite({"Entered"," scan ","mode"},{nil,colors.orange,nil})

    inventory.setFuelSlots("scan")

    Term.changeColor(colors.orange)
    print("[[ Gathering User Input ]]")
    Utils.logtoFile(selffilename,"scanInit",nil,"Gathering user input")

    local input_vector_start = input.vectorgetInput("Start")
    local input_vector_end = input.vectorgetInput("End")

    Term.changeColor(colors.blue)
    print("Enter a custom name for your scan file")
    Term.askInput()
    local customfilename = read()

    Utils.logtoFile(selffilename,"scanInit",nil,"User inputs gathered")

    Term.press2Continue()
    local estimate = movement.estimate(input_vector_start,input_vector_end)
    Term.splitWrite({"Estimated time ","(minimum)",": ",estimate.time},{colors.lightBlue,colors.lightGray,colors.lightBlue,nil})
    Term.splitWrite({"Estimated coal ","(minimum)",": ",estimate.fuel},{colors.lightBlue,colors.lightGray,colors.lightBlue,nil})

    Term.press2Continue()
    print("")
    local allsubModes = {
        Full = "Destroy the blocks as it goes"
    }
    local submodenames = {}
    Term.clear()
    local selected = false
    while not selected do
        Term.changeColor(colors.orange)
        print("Select a submode from the list below:")
        print("=======")

        for k, value in pairs(allsubModes) do
            table.insert(submodenames, k)
            Term.splitWrite({"- ",k," | Desc: ",value},{colors.lightGray,colors.purple,colors.lightGray,colors.lightBlue})
        end

        Term.changeColor(colors.orange)
        print("=======")
        Term.askInput()

        local ans = select(1,(string.gsub(read(nil, {}, function(text) return Completion.choice(text, submodenames) end)," ","")))

        for _, value in pairs(submodenames) do
            if value == ans then
                term.clear()
                Term.resetCursor()
                Term.changeColor(colors.green)
                selectedSubMode = value
                selected = true
            end
        end
        if not selected then
            Term.clear()
            Term.changeColor(colors.red)
            print("Please enter an existing Module")
        end
    end

    Term.splitWrite({"Starting scan with ",selectedSubMode," submode in 1 second"},{nil,colors.orange,nil})

    sleep(1)
    Utils.logtoFile(selffilename,"scanInit",nil,"finished with: (selectedSubMode: "..selectedSubMode.."), now initializing and starting scan")
    initScan(input_vector_start,input_vector_end,customfilename)
    startScanning()
end



return {
    init = init,
    initScan = initScan,

    startScanning = startScanning
}