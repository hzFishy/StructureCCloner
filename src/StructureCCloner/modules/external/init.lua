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



return {
    checkUp = checkUp,

    DH_sendmsg = DiscordHook_sendmsg,
    DH_updatemsg = DiscordHook_updatemsg
}