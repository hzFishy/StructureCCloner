local input = require "modules.utils.input"
local movement = require "modules.movement"
local inventory = require "modules.inventory"
local build = require "modules.building"
local pretty = require "modules.term.pretty"
local selffilename = "mapping/build"

local mappingDir = "StructureCCloner/userData/"
local selectedFileName
local selectedSubMode

local startvector
local endvector
local filedata
local layers
local names
local ressourceChestModem = Config.build.ressourceChestModem
local replace_patterns = Config.build.replace_patterns
local ignored_blocks = Config.build.ignored_blocks

local length
local height
local width

local firstIndexRemoved = false
local extraRemovedIndexs = 0

local cLayer = 1
local cLine = 1
local cZ = 1

--[[ File handling ]]--
-- checks if the selectedFileName is a valide format
local function checkFile()
    Utils.logtoFile(selffilename,"checkFile",selectedFileName,"starting check",true)
    Term.changeColor(colors.orange)
    print("Checking file integrity")
    local selectedFile = fs.open(selectedFileName,"r")
    filedata = textutils.unserialise(selectedFile.readAll())
    selectedFile.close()
    if not (filedata and (filedata.chunks and (filedata.names and filedata.chunks))) then
        Term.errorr("Given file doesn't respect integrity criteria")
        Utils.logtoFile(selffilename,"checkFile",selectedFileName,"fail")
        Term.press2Continue()
        return false
    else
        Term.changeColor(colors.green)
        print("File check integrity successful")
        Utils.logtoFile(selffilename,"checkFile",selectedFileName,"success")
        Term.press2Continue()
        return true
    end
end
-- get selectedFileName
local function getFile()
    Utils.logtoFile(selffilename,"getFile",nil,"")
    Term.changeColor(colors.orange)
    print("From where do you want to get your scan file ?")
    local allmethods = {
        locally = "Use a file already stored in the turtle inside '"..mappingDir.."'",
        dragAndDrop = "Drag and drop one file or multiple files from your file explorer",
        web = "Use a file hosted on the web"
    }

    local function method()
        Utils.logtoFile(selffilename,"getFile,method",nil,"",true)
        local methodsnames = {}
        local selectedMethod
        Term.clear()
        local selected = false
        while not selected do
            Term.changeColor(colors.orange)
            print("Select a method from the list below:")
            print("=======")

            for k, value in pairs(allmethods) do
                table.insert(methodsnames, k)
                Term.splitWrite({"- ",k," | Desc: ",value},{colors.lightGray,colors.purple,colors.lightGray,colors.lightBlue})
            end

            Term.changeColor(colors.orange)
            print("=======")
            Term.askInput()

            local ans = select(1,(string.gsub(read(nil, {}, function(text) return Completion.choice(text, methodsnames) end),"","")))
            print(ans)
            for _, value in pairs(methodsnames) do
                if value == ans then
                    term.clear()
                    Term.resetCursor()
                    Term.changeColor(colors.green)
                    selectedMethod = value
                    selected = true
                end
            end
            if not selected then
                Term.clear()
                Term.changeColor(colors.red)
                print("Please enter an existing method")
            end
        end
        Term.clear()

        local function chooseFile()
            Utils.logtoFile(selffilename,"getFile,method,chooseFile",nil,"",true)

            local allfiles = fs.list(mappingDir)
            Term.clear()
            selected = false
            while not selected do
                Term.changeColor(colors.orange)
                print("Select a file from the list below:")
                print("=======")

                Term.changeColor(colors.white)
                local filesnames = {}
                for _, value in ipairs(allfiles) do
                    table.insert(filesnames,value)
                    print(value)
                end

                Term.changeColor(colors.orange)
                print("=======")
                Term.askInput()

                local ans = select(1,(string.gsub(read(nil, {}, function(text) return Completion.choice(text, filesnames) end),"","")))

                for _, value in ipairs(filesnames) do
                    if value == ans then
                        selectedFileName = mappingDir..value
                        selected = true
                    end
                end
                if not selected then
                    Term.clear()
                    Term.changeColor(colors.red)
                    print("Please enter an existing file")
                end
            end
        end

        if selectedMethod == "locally" then
            chooseFile()
        elseif selectedMethod == "dragAndDrop" then
            Term.changeColor(colors.blue)
            print("Waiting for files...")
            Term.resetColor()

            local event, droppedfiles
            parallel.waitForAny(function ()
                event, droppedfiles = os.pullEvent("file_transfer")
                end,function ()
                    read()
            end)

            if event == "file_transfer" then
                local count = 0
                local filepath
                for _, file in ipairs(droppedfiles.getFiles()) do
                    filepath = mappingDir..file.getName()
                    local handle = fs.open(filepath, "wb")
                    handle.write(file.readAll())
                    handle.close()
                    file.close()
                    count = count +1
                end
                if count > 1 then
                    local allfiles = {}
                    for _, file in ipairs(droppedfiles.getFiles()) do
                        table.insert(allfiles,file.getName())
                    end
                    selected = false
                    while not selected do
                        Term.changeColor(colors.orange)
                        print("Multiple files were saved, choose one from the list below")
                        print("=======")

                        local filesnames = {}
                        Term.changeColor(colors.white)
                        for _, value in ipairs(allfiles) do
                            table.insert(filesnames,value)
                            print(value)
                        end

                        Term.changeColor(colors.orange)
                        print("=======")
                        Term.askInput()

                        local ans = select(1,(string.gsub(read(nil, {}, function(text) return Completion.choice(text, filesnames) end),"","")))

                        for _, value in ipairs(filesnames) do
                            if value == ans then
                                selectedFileName = mappingDir..value
                                selected = true
                            end
                        end
                        if not selected then
                            Term.clear()
                            Term.changeColor(colors.red)
                            print("Please enter an existing file")
                        end
                    end
                else
                    selectedFileName = filepath
                end
            else
                Term.errorr("Drag and drop canceled")
                Term.press2Continue()
                Term.clear()
                method()
            end
        
        elseif selectedMethod == "web" then
            local webmethods = {
                StructureCCloner = "StructureCCloner web storage",
                pastebin = "Use a pastebin",
                custom = "Enter a url that points to a file (has to be raw)"
            }
            Term.clear()
            selected = false
            local selectedWebMethod
            while not selected do
                Term.changeColor(colors.orange)
                print("Select a web method from the list below:")
                print("=======")

                Term.changeColor(colors.white)
                local webmethodsnames = {}
                for k, value in pairs(webmethods) do
                    table.insert(webmethodsnames,k)
                    Term.splitWrite({"- ",k," | Desc: ",value},{colors.lightGray,colors.purple,colors.lightGray,colors.lightBlue})
                end

                Term.changeColor(colors.orange)
                print("=======")
                Term.askInput()

                local ans = select(1,(string.gsub(read(nil, {}, function(text) return Completion.choice(text, webmethodsnames) end),"","")))

                for _, value in ipairs(webmethodsnames) do
                    if value == ans then
                        selectedWebMethod = value
                        selected = true
                    end
                end
                if not selected then
                    Term.clear()
                    Term.changeColor(colors.red)
                    print("Please enter an existing web method ")
                end
            end
            Term.clear()
            if selectedWebMethod == "StructureCCloner" then
                while not selectedFileName do
                    Term.clear()
                    Term.changeColor(colors.orange)
                    print("Enter the name of the hosted file")
                    Term.askInput()
                    local ans = read()
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
                    Z="o%2"local et="&srt"local tt="bolbscans/"..ans
                    Utils.logtoFile(selffilename,"getFile",nil,"Executing the http request")

                    local resp = http.get((s..t..d..q..f..p..l..y..i..b..e..m..k..n..x..o..u..r..v..h..c..g..w..a..j..z)..tt.."?"..(E..C..K..et..D..L..U..M..F..W..X..I..S..V..B..A..N..Z..H..P..O..Q..R..G..J..Y..T))
                    Utils.logtoFile(selffilename,"getFile",nil,"Waiting the http result")

                    if resp and (resp.getResponseCode()) then
                        Utils.logtoFile(selffilename,"getFile",nil,"File received successful"); Term.changeColor(colors.green)
                        print("File found");
                        local newfile = fs.open(mappingDir..ans,"w")
                        newfile.write(resp.readAll())
                        newfile.close()
                        print("File saved locally")
                        selectedFileName = mappingDir..ans
                    else
                        Utils.logtoFile(selffilename,"getFile",nil,"Error encountered, error details: "..Utils.ternary(resp==nil,"Nil",resp))
                        Term.errorr("File not found")
                    end
                    Term.press2Continue()
                end
            elseif selectedWebMethod == "pastebin" then
                local filename
                local function checkCreateFile(filenamee)
                    return fs.exists(filenamee)
                end
                local function getPastebin()
                    Term.changeColor(colors.orange)
                    Term.splitWrite({"Web method ",selectedWebMethod, " selected"},{nil,colors.orange,nil})
                    Term.changeColor(colors.orange)
                    print("Enter the name of this file")
                    Term.askInput()
                    local ans = read()
                    print("Without spaces, enter the id of the pastebin")
                    Term.changeColor(colors.lightGray)
                    print("(For e.g, if your url is 'pastebin.com/YXR8YAH4', the ID is 'YXR8YAH4')")
                    local pastebinID = read()
                    filename = mappingDir..ans..math.random(9999)
                    Term.resetColor()
                    shell.run("pastebin get "..pastebinID.." "..filename)
                    if not checkCreateFile(filename) then
                        Term.errorr("Please try again with an existing pastebin ID")
                        Term.press2Continue()
                        Term.clear()
                        getPastebin()
                    end
                end

                if not selectedFileName then
                    getPastebin()
                end

                selectedFileName = filename
            elseif selectedWebMethod == "custom" then
                --code
                while not selectedFileName do
                    Term.clear()
                    Term.changeColor(colors.orange)
                    print("Enter the url of the hosted file")
                    Term.askInput()
                    local ans = read()
                    Utils.logtoFile(selffilename,"getFile",nil,"Executing the http request")

                    local resp = http.get(ans)
                    Utils.logtoFile(selffilename,"getFile",nil,"Waiting the http result")

                    if resp and (resp.getResponseCode()) then
                        Utils.logtoFile(selffilename,"getFile",nil,"File received successful"); Term.changeColor(colors.green)
                        print("File found");
                        Term.changeColor(colors.orange)
                        print("Enter the name of this file")
                        Term.askInput()
                        ans = read()
                        local newfile = fs.open(mappingDir..ans,"w")
                        newfile.write(resp.readAll())
                        newfile.close()
                        Term.changeColor(colors.green)
                        print("File saved locally")
                        selectedFileName = mappingDir..ans
                    else
                        Utils.logtoFile(selffilename,"getFile",nil,"Error encountered, error details: "..Utils.ternary(resp==nil,"Nil",resp))
                        Term.errorr("File not found")
                    end
                    Term.press2Continue()
                end
            end
        end
    end
    method()
    Term.clear()
    Term.changeColor(colors.blue)
    print("If you want to rename your selected file:")
    Term.resetColor()
    print(selectedFileName)
    Term.changeColor(colors.orange)
    print("please enter below its new name.")
    Term.resetColor()
    print("If you don't want to rename just skip by leaving your answer empty and press enter")
    Term.askInput()
    local ans = read()
    if #ans > 0 then
        local function try()
            local suc = pcall(fs.move,selectedFileName,mappingDir..ans)
            if suc then
                selectedFileName = mappingDir..ans
            end
            return suc
        end
        while not try() do
            Term.clear()
            Term.errorr("An error occured while trying to rename your file, please try again")
            Term.resetColor()
            print("If you don't want to rename just skip by leaving your answer empty and press enter")
            Term.askInput()
            ans = read()
            if #ans < 1 then
                break
            end
        end
    end
end


--[[ Overview ]]
local function presummary()
    Term.changeColor(colors.cyan)
    print("List of block you will need: ")
    Term.resetColor()
    names = filedata.names
    --local block_count = {}
    if names[1].id == "air" then
        table.remove(names,1)
        firstIndexRemoved = true
    end
    for _, blocktbl in ipairs(names) do
        --block_count[blocktbl.id] = blocktbl.count
        Term.splitWrite({blocktbl.id," ",blocktbl.count},{colors.lightBlue,nil,colors.blue})        
    end

    Utils.logtoFile(selffilename,"presummary",nil,textutils.serialise(names),true)

    if #names < 1 then
        Term.errorr("None")
        return "None"
    else
        return textutils.serialise(names)
    end

end

--[[ Utils ]]--
local function fixNamesId(id)
    local oldid = id
    if firstIndexRemoved then
        id = id-1
    end
    id = id-extraRemovedIndexs
    Utils.logtoFile(selffilename,"fixNamesId","(id: "..oldid..")","returned: "..id,true)
    return id
end


--[[ Blocks ]]--
-- get closest block to turtle
local function getCloseBlocks()
    local closeblocks = {}
    -- format {{name = "", count = 0}}

    local function check()
        return #closeblocks < #inventory.blockSlots
    end
    for iLayer = cLayer, height do
        for iLine = cLine, length do
            for iZ = cZ, width do
                local blockId = fixNamesId(layers[iLayer][iLine][iZ])
                if (not firstIndexRemoved) or (firstIndexRemoved and blockId > 0) then
                    local blockName = names[blockId].id
                    local found = false
                    for i, value in pairs(closeblocks) do
                        if value.name == blockName then
                            closeblocks[i].count = closeblocks[i].count + 1
                            found = true
                            break
                        end
                    end
                    if not found then
                        table.insert(closeblocks,{name = blockName, count = 1})
                    end
                end
            end
            if not check() then break end
        end
        if not check() then break end
    end
    Utils.logtoFile(selffilename,"getCloseBlocks",nil,textutils.serialise(closeblocks,{ allow_repetitions = true }),true)
    return closeblocks
end
local function getBlocks()
    Utils.logtoFile(selffilename,"getBlocks",nil,"",true)
    local closeBlocks
    parallel.waitForAll(function ()
        movement.goTo(ressourceChestModem)
    end,function ()
        closeBlocks = getCloseBlocks()
    end)
    inventory.getBlocks(closeBlocks)
end


--[ Actions ]--
local function actionPerLayer(_,i)
    Utils.logtoFile(selffilename,"actionPerLayer",nil,"",true)
    cLayer = i
end
local function actionPerLine(i)
    Utils.logtoFile(selffilename,"actionPerLine",nil,"",true)
    cLine = i
end
local function actionPerFinishLine()
    Utils.logtoFile(selffilename,"actionPerFinishLine",nil,"",true)
    cZ = 0
end


--[[ Build ]]
-- Executed a each new block
local function perBlockScanAction(x,y,z,backwards)
    Utils.logtoFile(selffilename,"perBlockScanAction","("..x..", "..y..", "..z..")","")
    cZ = cZ + 1
    local id = fixNamesId(layers[cLayer][cLine][Utils.ternary(backwards,width-cZ+1,cZ)])
    local block = names[id]
    -- the selectedSubMode isnt check since there is only one submode
    if block then -- skip if "air")
        local blockSlot = inventory.getBlock(block.id)
        while not blockSlot do
            getBlocks()
        end
        movement.goTo(vector.new(x,y+1,z))
        if build.placeDown(blockSlot) then
            block.count = block.count - 1
        else
            Term.errorr("Block couldn't be placed")
        end
    end

    Utils.logtoFile(selffilename,"perBlockScanAction","("..x..","..y..","..z..")","block: "..textutils.serialise(block, {compact = true}).." names: "..textutils.serialise(names),true)
end
-- start building
local function startBuilding()
    local startT = Utils.C_ElapsedTime.new()
    Utils.logtoFile(selffilename,"startBuilding","(startvector: "..startvector:tostring()..")","")
    Term.changeColor(colors.green)
    print("Started building")
    Depend.DH_sendmsg("# Started building")

    getBlocks()
    cLayer = 0
    cLine = 0
    cZ = 0
    Term.resetColor()
    print("Progress:")
    pretty.initBar(colors.green,colors.red)
    Depend.DH_sendmsg("**Progress:**")
    local _,msgid = Depend.DH_initBar(0)
    local function updatebars(p)
        pretty.updateBar(p)
        Depend.DH_updateBar(p,msgid)
    end

    movement.goTo(startvector:add(vector.new(0,1,-1))) -- prevent from being blocked
    movement.checkAllVolume(
        updatebars,
        startvector,
        endvector,
        1,
        perBlockScanAction,
        actionPerLayer,
        actionPerLine,
        actionPerFinishLine)

    updatebars(100)
    Term.changeColor(colors.green)
    print("Finished building")
    Depend.DH_sendmsg("# Finished building \n In `"..(Utils.formatTime((startT:getElapsedTime()/1000))).."`")
    movement.goToSpawn()
end


--[[ Init ]]--
-- init required variables
local function initVariables()
    Utils.logtoFile(selffilename,"initVariables",nil,"",true)
    layers = filedata.chunks[1].layers
    names = filedata.names

    --use ignored_blocks (if any)
    if #ignored_blocks > 0 then
        for _, value in ipairs(ignored_blocks) do
            for i, valuenames in ipairs(names) do
                local t = inventory.addMCNameSpace(valuenames.id)
                if value == t then
                    table.remove(names,i)
                    extraRemovedIndexs = extraRemovedIndexs + 1
                end
            end
        end
    end

    if #replace_patterns > 0 then
        for _, valuerepa in ipairs(replace_patterns) do
            for _, valuenames in ipairs(names) do
                local t = inventory.addMCNameSpace(valuenames.id)
                if t == valuerepa[1] then
                    valuenames.id = inventory.removeMCNameSpace(valuerepa[2])
                end
            end
        end
    end
    height = #layers
    length = #layers[1]
    width = #layers[1][1]

    local x = startvector.x+#layers[1]-1
    local y = startvector.y+#layers-1
    local z = startvector.z+width-1
    endvector = vector.new(x,y,z)
end
local function initCheckRessources()
    Utils.logtoFile(selffilename,"initCheckRessources",nil,"",true)
    movement.goTo(ressourceChestModem)
    return inventory.checkItemsCount(Utils.tabledeepcopy(names))
end
local function init()
    Utils.logtoFile(selffilename,"init",nil,"")
    Term.splitWrite({"Entered"," build ","mode"},{nil,colors.orange,nil})

    inventory.setFuelSlots("build")

    getFile()
    Term.clear()
    if not checkFile() then
        init()
    else
        Term.changeColor(colors.orange)
        print("[[ Gathering User Input ]]")

        startvector = input.vectorgetInput("Start")
        Term.press2Continue()

        local allsubModes = {
            Default = "Do nothing special, can be stuck if inside the build zone there is blocks"
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
        initVariables()
        Depend.DH_sendmsg("# Build mode initialized with: \n __Submode:__ `"..selectedSubMode.."` \n __Begin coordinate:__ `"..startvector:tostring().."` \nFile: `"..selectedFileName.."`\n**Blocks summary:**\n```lua\n"..presummary().."\n```")
        Term.clear()
        local function subcheck()
            Term.changeColor(colors.orange)
            print("Checking if all required blocks are in chest")

            local checktable = initCheckRessources()
            if #checktable == 0 then
                Term.splitWrite({"Starting scan with ",selectedSubMode," submode in 1 second"},{nil,colors.orange,nil})
                sleep(1)
                startBuilding()
            else
                Term.errorr("Blocks are missing")
                local missing = textutils.serialise(checktable)
                print(missing)
                Depend.DH_sendmsg("**The following blocks and count are missing :warning::**\n ```lua\n"..missing.."\n```\n Press any key to execute a new scan")
                Term.press2Continue("to execute a new scan")
                subcheck()
            end
        end
        subcheck()
    end
end



return {
    init = init,
    firstIndexRemoved = firstIndexRemoved,
}
