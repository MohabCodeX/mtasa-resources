--[[
    TDMA Chat Bridge
    This file connects TDMA with the ChatManager resource
    and ensures that team colors are properly applied
]]

-- Store existing event handlers so we can completely disable them
local originalChatHandlers = {}

local function setupChatBridge()
    -- Check if ChatManager is running
    if not getResourceFromName("chatmanager") or getResourceState(getResourceFromName("chatmanager")) ~= "running" then
        outputDebugString("TDMA: ChatManager not found or not running - using fallback chat handler", 2)
        -- Enable fallback chat handler
        enableFallbackChatHandler()
        return false
    end

    outputDebugString("TDMA: Setting up chat bridge with ChatManager")

    -- Disable ALL chat handlers in TDMA to prevent duplication
    disableAllChatHandlers()

    -- Register with ChatManager
    if exports.chatmanager then
        if exports.chatmanager.registerChatResource then
            local options = {
                formatPlayerName = true,
                useTeamColors = true,
                stripColorCodes = true,
                teamColorsOverride = true
            }
            exports.chatmanager:registerChatResource(getResourceName(getThisResource()), options)
            outputDebugString("TDMA: Successfully registered with ChatManager")
        end

        -- Notify new players
        addEventHandler("onPlayerJoin", root, function()
            if isElement(source) then
                setTimer(function()
                    if isElement(source) then
                        outputChatBox("This server uses TDMA with a centralized chat system.", source, 255, 255, 0)
                        outputChatBox("Type /help for available commands.", source, 255, 255, 0)
                    end
                end, 5000, 1)
            end
        end)
    end

    return true
end

-- Function to completely disable ALL chat handlers in TDMA
function disableAllChatHandlers()
    -- Store the original handlers first
    local allHandlers = getEventHandlers("onPlayerChat", root)
    if allHandlers then
        for i, handler in ipairs(allHandlers) do
            originalChatHandlers[i] = handler
            removeEventHandler("onPlayerChat", root, handler)
            outputDebugString("TDMA: Removed chat handler #" .. i)
        end
    end

    -- Also specifically remove our fallback handler
    removeEventHandler("onPlayerChat", root, onPlayerChat_Fallback)

    -- Use cancelEvent with high priority to prevent other resources from handling chat
    addEventHandler("onPlayerChat", root, function()
        -- Do nothing, just let ChatManager handle it
        return
    end, true, "high+1")

    outputDebugString("TDMA: All chat handlers disabled to prevent duplication")
end

-- Function to restore all original chat handlers
function restoreOriginalChatHandlers()
    -- Remove our placeholder handler
    for i, handler in pairs(getEventHandlers("onPlayerChat", root)) do
        removeEventHandler("onPlayerChat", root, handler)
    end

    -- Restore the original handlers
    for i, handler in pairs(originalChatHandlers) do
        addEventHandler("onPlayerChat", root, handler)
        outputDebugString("TDMA: Restored original chat handler #" .. i)
    end

    outputDebugString("TDMA: Original chat handlers restored")
    originalChatHandlers = {}
end

-- Fallback chat handler for when ChatManager is not available
function onPlayerChat_Fallback(message, messageType)
    -- Only for normal chat
    if messageType == 0 then
        cancelEvent()
        message = string.gsub(message, "#%x%x%x%x%x%x", "")
        local team = getPlayerTeam(source)
        local playerName = getPlayerName(source)
        if (team) then
            local r, g, b = getTeamColor(team)
            outputChatBox(playerName..":#FFFFFF "..message, root, r, g, b, true)
        else
            outputChatBox(playerName..": "..message)
        end
        outputServerLog("CHAT: " .. playerName .. ": " .. message)
    end
end

-- Enable the fallback chat handler
function enableFallbackChatHandler()
    -- First remove any existing handlers to avoid duplicates
    removeEventHandler("onPlayerChat", root, onPlayerChat_Fallback)

    -- Add our fallback handler with high priority
    addEventHandler("onPlayerChat", root, onPlayerChat_Fallback, true, "high")
    outputDebugString("TDMA: Fallback chat handler enabled")
end

-- Initialize on resource start
addEventHandler("onResourceStart", resourceRoot, function()
    -- Check ChatManager status and set up accordingly
    if getResourceFromName("chatmanager") and getResourceState(getResourceFromName("chatmanager")) == "running" then
        setupChatBridge()
    else
        enableFallbackChatHandler()
    end
end)

-- If ChatManager starts after TDMA, set up the bridge
addEventHandler("onResourceStart", root, function(res)
    if getResourceName(res) == "chatmanager" then
        outputDebugString("TDMA: ChatManager started - setting up chat bridge")
        setupChatBridge()
    end
end)

-- If ChatManager stops, restore original handlers
addEventHandler("onResourceStop", root, function(res)
    if getResourceName(res) == "chatmanager" then
        outputDebugString("TDMA: ChatManager stopped - restoring original chat handlers")
        restoreOriginalChatHandlers()
        enableFallbackChatHandler()
    end
end)

-- Make sure to clean up when TDMA itself stops
addEventHandler("onResourceStop", resourceRoot, function()
    -- Only restore handlers if we modified them
    if #originalChatHandlers > 0 then
        restoreOriginalChatHandlers()
    end
end)
