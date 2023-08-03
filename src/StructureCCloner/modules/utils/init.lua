
local filenameDefault = "logFileDefault"
local logsDir = "StructureCCloner/logs/"
local fileIndex = 0
local selffilename = "utils"

local showDetailedLogs = Config.detailedLogging
local noLogging = Config.config.noLogging

local function ternary(condition, value_if_true, value_if_false)
    if condition then
        return value_if_true
    else
        return value_if_false
    end
end

local function ternary4Bool(bool)
    return ternary(bool,"True","False")
end

--[[ Time ]]--
local ElapsedTime = {}

function ElapsedTime.new()
    local self= {
      startTime = os.epoch("utc")
    }
    setmetatable(self, ElapsedTime)
    ElapsedTime.__index = ElapsedTime
    return self
end

function ElapsedTime:getElapsedTime()
    return (os.epoch("utc")-self.startTime)
end
local function formatTime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    seconds = math.ceil(seconds % 60)

    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end


local function logtoFile(source,functionCalled,params,content,detailed)
    if not noLogging then
        if (not detailed) or (detailed and showDetailedLogs) then
           detailed = detailed or false
           if not content then content = functionCalled; functionCalled = nil end
           local path = logsDir..filenameDefault.."."..fileIndex..".md"
           local file = fs.open(path,"a")
           file.writeLine("["..os.date("%Y-%m-%d %H:%M:%S").."] ".." **[ "..(source and source or "Source not given").." ]**  "..(functionCalled and "["..functionCalled.."]" or "")..(params and (" - ".."__@param(s): ["..params.."]__") or "").." - "..(content and content or "Nil"))
           file.close()
           if fs.getSize(path) >= 200000 then
               fileIndex = fileIndex + 1
           end
       end
    end
end

local function clearLogs()
    local startT = ElapsedTime.new()
    local files = fs.list(logsDir)
    for i = 1, #files do
        if not (string.find(files[i],"_")) then
            fs.delete(logsDir..files[i])
        end
    end
    logtoFile(selffilename,"# logs cleared in "..startT:getElapsedTime().." milliseconds")
end

-- [[ Table ]]--
local function tablecopy(tbl)
    local new = {}
    for k,v in pairs(tbl) do
        new[k] = v
    end
    return new
end
local function tabledeepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[tabledeepcopy(orig_key)] = tabledeepcopy(orig_value)
        end
        setmetatable(copy, tabledeepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end




return {
    ternary = ternary,
    tern4Bool = ternary4Bool,

    tablecopy = tablecopy,
    tabledeepcopy = tabledeepcopy,

    C_ElapsedTime = ElapsedTime,
    formatTime = formatTime,

    logtoFile = logtoFile,
    clearLogs = clearLogs,
}