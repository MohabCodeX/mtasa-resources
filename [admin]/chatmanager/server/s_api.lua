-- Chat Manager: API for other resources
-- Provides functions for other resources to interact with the chat manager

-- Player mute status tracking
local mutedPlayers = {}

-- Store resources that have registered for chat integration
local registeredResources = {}

-- API Documentation
--[[
Functions exported by this resource:
- sendChatMessage(player, message, messageType, receiver)
- isChatMuted(player)
- setChatMuted(player, state)
- getColoredPlayerName(player)
- sendPrivateMessage(sender, receiver, message)
- filterText(text)
- updateCustomFilter(word, remove)
- getFilterWordList()
- reloadChatFilter()
- sendSystemMessage(message, receiver, messageColor)
- sendAdminAnnouncement(message, fromAdmin, receiver)
- sendGamemodeMessage(message, messageType, receiver)
- registerCompatibleResource(resourceName)
- registerChatResource(resourceName, options)
- isResourceRegistered(resourceName)
- getResourceChatOptions(resourceName)
]]--

-- Send a chat message from a player or system
-- player: Player element or string for system messages
-- message: The message text
-- messageType: 0 for public chat, 1 for team chat (default: 0)
-- receiver: Optional player element to send the message to (default: all players)
-- Returns: true if successful, false otherwise
function sendChatMessage(player, message, messageType, receiver)
    messageType = messageType or 0 -- Default to public chat

    if type(player) == "string" then
        -- System message
        outputServerLog("SYSTEM: " .. message)
        outputChatBox(player .. ": " .. message, receiver or root, 255, 255, 255, true)
        return true
    elseif not isElement(player) or getElementType(player) ~= "player" then
        return false
    end

    -- Check if player is muted
    if isChatMuted(player) then
        return false
    end

    -- Apply text filtering for player messages
    if isElement(player) and getElementType(player) == "player" then
        local useFilter = getElementData(player, "chatmanager.useFilter")
        if useFilter then
            message = filterText(message)
        end
    end

    -- Format message like in s_chat.lua
    local playerName = getPlayerName(player)
    local team = getPlayerTeam(player)
    local r, g, b = 211, 174, 154 -- Default D3AE9A for non-teamed players

    if team then
        r, g, b = getTeamColor(team) -- Use team color for player name
    end

    if messageType == 0 then -- Public chat
        outputServerLog("CHAT: " .. playerName .. ": " .. message)
        -- Always use white color for message text
        outputChatBox(string.format("#%.2X%.2X%.2X%s:#FFFFFF %s", r, g, b, playerName, message), receiver or root, 255, 255, 255, true)
        return true
    elseif messageType == 1 then -- Team chat
        local team = getPlayerTeam(player)
        if team then
            local teamPlayers = getPlayersInTeam(team)
            outputServerLog("TEAMCHAT: " .. getPlayerName(player) .. ": " .. message)

            local targetPlayers = receiver and {receiver} or teamPlayers
            for _, teamPlayer in ipairs(targetPlayers) do
                if not receiver or (getPlayerTeam(receiver) == team) then
                    outputChatBox("(TEAM) " .. getColoredPlayerName(player) .. ": " .. message, teamPlayer, 255, 255, 255, true)
                end
            end
            return true
        end
        return false
    end

    return false
end

-- Check if a player is muted
-- player: The player element
-- Returns: true if muted, false otherwise
function isChatMuted(player)
    if not isElement(player) then return false end

    local playerID = getElementData(player, "playerid") or getPlayerName(player)
    return mutedPlayers[playerID] == true
end

-- Mute or unmute a player
-- player: The player element
-- state: true to mute, false to unmute
-- Returns: true if successful, false otherwise
function setChatMuted(player, state)
    if not isElement(player) then return false end

    local playerID = getElementData(player, "playerid") or getPlayerName(player)
    mutedPlayers[playerID] = state

    -- Notify the player
    if state then
        outputChatBox("You have been muted and cannot send messages.", player, 255, 0, 0)
    else
        outputChatBox("You have been unmuted and can now send messages.", player, 0, 255, 0)
    end

    return true
end

-- Helper function to get colored player name
-- player: The player element
-- Returns: Player name with color formatting
function getColoredPlayerName(player)
    local r, g, b = 211, 174, 154 -- Default D3AE9A for non-teamed players

    local useNametagColors = getSettingValue("use_nametag_colors")
    local useTeamColors = getSettingValue("use_team_colors")
    local teamColorsOverride = getSettingValue("team_colors_override")

    if useTeamColors then
        local team = getPlayerTeam(player)
        if team then
            r, g, b = getTeamColor(team)
            if not useNametagColors or teamColorsOverride then
                return string.format("#%.2X%.2X%.2X%s", r, g, b, getPlayerName(player))
            end
        end
    end

    if useNametagColors then
        r, g, b = getPlayerNametagColor(player)
        return string.format("#%.2X%.2X%.2X%s", r, g, b, getPlayerName(player))
    end

    -- Return with default color for non-teamed players
    return string.format("#%.2X%.2X%.2X%s", r, g, b, getPlayerName(player))
end

-- Send a private message from one player to another
-- sender: The player element sending the message
-- receiver: The player element receiving the message
-- message: The message text
-- Returns: true if successful, false otherwise
function sendPrivateMessage(sender, receiver, message)
    if not isElement(sender) or not isElement(receiver) or
       getElementType(sender) ~= "player" or getElementType(receiver) ~= "player" then
        return false
    end

    -- Check if sender is muted
    if isChatMuted(sender) then
        outputChatBox("You are muted and cannot send messages.", sender, 255, 0, 0)
        return false
    end

    -- Apply text filtering if configured
    local useFilter = getElementData(sender, "chatmanager.useFilter")
    if useFilter then
        message = filterText(message)
    end

    -- Strip color codes if configured
    if getSettingValue("strip_color_codes") then
        message = stripColorCodes(message)
    end

    -- Log the message
    outputServerLog("PM: " .. getPlayerName(sender) .. " to " .. getPlayerName(receiver) .. ": " .. message)

    -- Get colors dynamically
    local fromR, fromG, fromB = getMessageColor("private_from", false)
    local toR, toG, toB = getMessageColor("private_to", false)

    -- Tag color for consistency
    local tagColor = getColorHex("tag_pm", true)

    -- Format message with proper colors
    local fromPrefix = tagColor .. "[PM From] "
    local toPrefix = tagColor .. "[PM To] "

    -- Send to sender and receiver with appropriate colors
    triggerClientEvent(sender, "chatmanager:onPrivateMessage", sender, message, getPlayerName(receiver), false)
    triggerClientEvent(receiver, "chatmanager:onPrivateMessage", receiver, message, getPlayerName(sender), true)

    return true
end

-- Filter text to replace profanity with asterisks
-- text: The text to filter
-- Returns: Filtered text
function filterText(text)
    -- Call the internal function directly
    return internalFilterText(text)
end

-- Add or remove words from the custom filter
-- word: The word to add or remove
-- remove: true to remove, false to add
-- Returns: true if successful, false otherwise
function updateCustomFilter(word, remove)
    -- Call the internal function directly
    return internalUpdateCustomFilter(word, remove)
end

-- Get list of filter words
-- Returns: Table of filter words
function getFilterWordList()
    -- Call the internal function directly
    return internalGetFilterWordList()
end

-- Reload the chat filter
-- Returns: true if successful
function reloadChatFilter()
    -- Call the internal function directly
    return internalReloadChatFilter()
end

-- Send a system announcement to all players or a specific player
-- message: The message text
-- receiver: Optional player to send the message to (default: all players)
-- messageColor: Optional color table {r, g, b} (default: {255, 255, 255})
-- Returns: true if successful
function sendSystemMessage(message, receiver, messageColor)
    local r, g, b = 255, 255, 255
    if messageColor and type(messageColor) == "table" then
        r, g, b = messageColor[1] or 255, messageColor[2] or 255, messageColor[3] or 255
    end

    outputServerLog("SYSTEM: " .. message)
    outputChatBox("[System]: " .. message, receiver or root, r, g, b, true)

    -- Trigger client event for system messages
    triggerClientEvent(receiver or root, "chatmanager:onSystemMessage", receiver or root, message)
    return true
end

-- Register a resource as compatible with ChatManager
function registerCompatibleResource(resourceName)
    outputDebugString("ChatManager: Registered compatible resource: " .. resourceName)
    -- Placeholder for tracking compatible resources
end

-- Register a resource to use the chat system
function registerChatResource(resourceName, options)
    if not resourceName then
        resourceName = getResourceName(sourceResource or getThisResource())
    end

    local resource = getResourceFromName(resourceName)
    if not resource then
        outputDebugString("ChatManager: Failed to register resource '" .. resourceName .. "' - resource not found", 2)
        return false
    end

    -- Default options
    options = options or {}
    options.formatPlayerName = options.formatPlayerName ~= false -- Default to true
    options.useTeamColors = options.useTeamColors ~= false -- Default to true
    options.stripColorCodes = options.stripColorCodes ~= false -- Default to true

    registeredResources[resourceName] = {
        resource = resource,
        options = options
    }

    outputDebugString("ChatManager: Resource '" .. resourceName .. "' registered for chat integration")
    return true
end

-- Check if a resource is registered for chat integration
function isResourceRegistered(resourceName)
    if not resourceName then
        resourceName = getResourceName(sourceResource or getThisResource())
    end

    return registeredResources[resourceName] ~= nil
end

-- Get options for a registered resource
function getResourceChatOptions(resourceName)
    if not resourceName then
        resourceName = getResourceName(sourceResource or getThisResource())
    end

    return registeredResources[resourceName] and registeredResources[resourceName].options or nil
end

-- Send an admin announcement to all players or a specific player
-- message: The message text
-- fromAdmin: Optional admin player who sent the message
-- receiver: Optional player to send the message to (default: all players)
-- Returns: true if successful
function sendAdminAnnouncement(message, fromAdmin, receiver)
    local sender = "Admin"
    if fromAdmin and isElement(fromAdmin) and getElementType(fromAdmin) == "player" then
        sender = getPlayerName(fromAdmin)
        -- Log the admin who sent the message
        outputServerLog("ADMIN ANNOUNCEMENT: " .. sender .. ": " .. message)
    else
        -- Log generic admin announcement
        outputServerLog("ADMIN ANNOUNCEMENT: " .. message)
    end

    outputChatBox("[Admin] " .. sender .. ": " .. message, receiver or root, 255, 100, 100, true)

    return true
end

-- Send a gamemode-specific message to all players or a specific player
-- message: The message text
-- messageType: Type of message ("objective", "announcement", "warning", etc.)
-- receiver: Optional player to send the message to (default: all players)
-- Returns: true if successful
function sendGamemodeMessage(message, messageType, receiver)
    outputServerLog("GAMEMODE (" .. (messageType or "info") .. "): " .. message)

    -- Handle different types of gamemode messages
    if messageType == "objective" then
        outputChatBox("[Objective] " .. message, receiver or root, 0, 255, 0, true)
    elseif messageType == "announcement" then
        outputChatBox("[Announcement] " .. message, receiver or root, 255, 165, 0, true)
    elseif messageType == "warning" then
        outputChatBox("[Warning] " .. message, receiver or root, 255, 100, 0, true)
    else
        -- Default gamemode message
        outputChatBox("[Info] " .. message, receiver or root, 200, 200, 200, true)
    end

    -- Trigger client event for handling gamemode messages (sounds, UI effects, etc.)
    if receiver then
        triggerClientEvent(receiver, "chatmanager:onGamemodeMessage", receiver, message, messageType)
    else
        triggerClientEvent(root, "chatmanager:onGamemodeMessage", root, message, messageType)
    end

    return true
end

-- Clear mutes when the resource starts
addEventHandler("onResourceStart", resourceRoot, function()
    mutedPlayers = {}
end)

-- Clean up when players leave
addEventHandler("onPlayerQuit", root, function()
    local playerID = getElementData(source, "playerid") or getPlayerName(source)
    mutedPlayers[playerID] = nil
end)

-- Clean up when resources stop
addEventHandler("onResourceStop", root, function(resource)
    local resourceName = getResourceName(resource)
    if registeredResources[resourceName] then
        registeredResources[resourceName] = nil
        outputDebugString("ChatManager: Resource '" .. resourceName .. "' unregistered from chat integration")
    end
end)
