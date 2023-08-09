local DiscordHook
local hook


--[[ Config ]]--
if Config.dependencies.DiscordHook.enable then
    DiscordHook = require "modules.external.DiscordHook"
end


--[[ Check ]]--
local function checkUp()
    local errormessage
    local function checkDiscordHook()
        local success
        success, hook = DiscordHook.createWebhook(Config.dependencies.DiscordHook.webhook)
        if not success then
            errormessage = "Webhook connection failed! Reason: " .. hook
        end
    end
    if DiscordHook then
        checkDiscordHook()
    end

    return errormessage
end


--[[ Discord ]]--
local logourl = "https://raw.githubusercontent.com/hzFishy/StructureCCloner/39cf04ec5daf97207b5ce3ba34711eea79f4ad1e/_wiki/assets/BaseLogo_small.png"

local function DiscordHook_sendmsg(msg)
    if DiscordHook then
        -- return: success, messageid
        return hook.send(msg,"StructureCCloner",logourl)
    end
end

local function DiscordHook_updatemsg(msg,messageid)
    if DiscordHook then
        hook.update(msg,"StructureCCloner",logourl,messageid)
    end
end
local function Discord_makeBar(percent)
    local max=20
    local finalmsg = ""
    percent = math.floor(percent)
    if percent < 0 then
        percent = 0
    elseif percent > 100 then
        percent = 100
    end

    for _=1, ((percent/100)*max) do
        finalmsg = finalmsg .. ":green_square:"
    end
    for _=1, max-((percent/100)*max) do
    finalmsg = finalmsg .. ":red_square:"
    end

    return finalmsg
end
local function Discord_initBar(percent)
    return DiscordHook_sendmsg(Discord_makeBar(percent))
end
local function Discord_updateBar(percent,messageid)
    DiscordHook_updatemsg(Discord_makeBar(percent),messageid)
end


return {
    checkUp = checkUp,

    DH_sendmsg = DiscordHook_sendmsg,
    DH_updatemsg = DiscordHook_updatemsg,
    DH_initBar = Discord_initBar,
    DH_updateBar = Discord_updateBar,
}