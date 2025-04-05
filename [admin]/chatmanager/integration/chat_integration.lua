--[[
    ChatManager - Universal Integration Module

    This file can be included in any resource to integrate with ChatManager

    How to use:
    1. Add ChatManager as a dependency in your resource's meta.xml:
       <depend>chatmanager</depend>

    2. Include this file in your resource:
       <include resource="chatmanager" />

    3. Remove your onPlayerChat event handlers to avoid conflicts
]]

-- Function to check if ChatManager is handling chat for this resource
function isChatManagerActive()
    if not getResourceFromName("chatmanager") or getResourceState(getResourceFromName("chatmanager")) ~= "running" then
        return false
    end

    local resourceName = getResourceName(getThisResource())
    if exports.chatmanager and exports.chatmanager.isResourceRegistered then
        return exports.chatmanager:isResourceRegistered(resourceName)
    end

    return false
end

-- Attempt registration if ChatManager starts after this resource
addEventHandler("onResourceStart", root, function(resource)
    if getResourceName(resource) == "chatmanager" then
        -- Give ChatManager a moment to initialize fully
        setTimer(function()
            -- Removed resource registration logic as ChatManager now uses a global formatting function.
        end, 1000, 1)
    end
end)
