local files = {
  "StructureCCloner/modules/building/init.lua",
  "StructureCCloner/modules/inventory/init.lua",
  "StructureCCloner/modules/mapping/build.lua",
  "StructureCCloner/modules/mapping/scan.lua",
  "StructureCCloner/modules/movement/init.lua",
  "StructureCCloner/modules/term/init.lua",
  "StructureCCloner/modules/utils/init.lua",
  "StructureCCloner/modules/utils/input.lua",
  "StructureCCloner/modules/external/init.lua",
  "StructureCCloner/modules/external/DiscordHook/init.lua",
  "StructureCCloner/config.lua",
  "StructureCCloner/init.lua"
}
local dirs = {
  "StructureCCloner/logs",
  "StructureCCloner/userData"
}


local starttext = "downloading "
local endtext = "/"..#files
local function init()
  print(starttext.."0"..endtext)
end
local x,y = term.getCursorPos()
init()
local function update(i)
    term.setCursorPos(x,y)
    print(starttext..i..endtext)
end

local function ternary(condition, value_if_true, value_if_false)
  if condition then
      return value_if_true
  else
      return value_if_false
  end
end
local function resetColor()
  term.setTextColor(colors.white)
end
local function changeColor(v)
  term.setTextColor(v)
end
local function splitWrite(tbltext,tblcolors,skipline)
  skipline = ternary(skipline == nil, true, skipline)
  for i, text in ipairs(tbltext) do
      local color = tblcolors[i]
      if color then
          changeColor(color)
      else
          changeColor(colors.white)
      end
      write(text)
  end
  if skipline then
      print()
  end
  resetColor()
end
local function askInput()
  Term.resetColor()
  write("> ")
end


local url = "https://raw.githubusercontent.com/hzFishy/StructureCCloner/main/src/"
local tasks = {}
for i, path in ipairs(files) do
  tasks[i] = function()
    local req, err = http.get(url.. path)
    if not req then error("Failed to download " .. url..path .. ": " .. err, 0) end

    update(i)
    local file = fs.open(path, "w")
    file.write(req.readAll())
    file.close()

    req.close()
    end
end
for _, path in ipairs(dirs) do
  tasks[#tasks+1] = function()
    fs.makeDir(path)
  end
end

print("")
print("=== Starting instalation ===")
parallel.waitForAll(table.unpack(tasks))


local completion = require "cc.completion"

changeColor(colors.red)
shell.run("set motd.enable false")
changeColor(colors.orange)
print("Disabled motd, do 'set motd.enable true' to set back to enable")


io.open("StructureCCloner.lua", "w"):write('shell.run("StructureCCloner/init.lua")'):close()
print("StructureCCloner successfully installed!")
splitWrite({"Run ","/StructureCCloner.lua"," to start."},{nil,colors.blue,nil})


changeColor(colors.orange)
print("Create a startup file for StructureCCloner ?")
askInput()
local ans = select(1,(string.gsub(read(nil, {}, function(text) return completion.choice(text, {"yes","no"}) end)," ","")))
if ans == "yes" then
    io.open("startup.lua", "w"):write('shell.run("StructureCCloner.lua")'):close()
end

changeColor(colors.green)
print("=== Instalation complete ===")
