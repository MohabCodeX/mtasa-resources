-- Chat Manager: Client-side chat handling
-- Handles client-side chat display and related functionality

-- Client-side settings cache
local chatSettings = {
    useNametagColors = true,
    useTeamColors = true,
    teamColorsOverride = true,
    enableSounds = true,
    useFilter = false,
    chatBlocked = false
}

-- Initialize sound settings
local messageSounds = {
    normal = 13,       -- Normal chat sound
    team = 14,         -- Team chat sound
    admin = 16,        -- Admin announcement sound
    system = 17,       -- System message sound
    private = 18,      -- Private message sound
    objective = 19,    -- Objective sound
    warning = 20       -- Warning sound
}

-- Play sound for message type
function playChatSound(messageType)
    if not chatSettings.enableSounds then return end

    local soundId = messageSounds.normal -- Default sound

    if messageType == "team" then
        soundId = messageSounds.team
    elseif messageType == "admin" then
        soundId = messageSounds.admin
    elseif messageType == "system" then
        soundId = messageSounds.system
    elseif messageType == "private" then
        soundId = messageSounds.private
    elseif messageType == "objective" then
        soundId = messageSounds.objective
    elseif messageType == "warning" then
        soundId = messageSounds.warning
    end

    playSoundFrontEnd(soundId)
end

-- Function to request settings from server or load from XML
function loadChatSettings()
    -- Request settings from server
    triggerServerEvent("chatmanager:requestSettings", localPlayer)
end

-- Receive settings from server
addEvent("chatmanager:receiveSettings", true)
addEventHandler("chatmanager:receiveSettings", root, function(settings)
    for key, value in pairs(settings) do
        chatSettings[key] = value
    end
    outputDebugString("Chat Manager: Settings updated")
end)

-- Basic event handlers for different message types
-- Each resource can add their own implementation later

-- Handle incoming chat messages (general notification)
addEvent("chatmanager:onChatMessage", true)
addEventHandler("chatmanager:onChatMessage", root, function(message, messageType)
    -- This is a minimal implementation, primarily as a notification
    -- A more complex chat UI would handle this differently
    playChatSound("normal")
end)

-- Event handler for team chat messages
addEvent("chatmanager:onTeamChatMessage", true)
addEventHandler("chatmanager:onTeamChatMessage", root, function(message, sender)
    if not chatSettings.useTeamColors then return end
    -- Additional team chat handling logic can go here
    playChatSound("team")
end)

-- Event handler for admin chat messages
addEvent("chatmanager:onAdminChatMessage", true)
addEventHandler("chatmanager:onAdminChatMessage", root, function(message, sender)
    -- Admin chat handling logic can go here
    playChatSound("admin")
end)

-- Event handler for private messages
addEvent("chatmanager:onPrivateMessage", true)
addEventHandler("chatmanager:onPrivateMessage", root, function(message, sender, isIncoming)
    playChatSound("private")

    local msgType = isIncoming and "private_from" or "private_to"
    local tagColor = getColorHex("tag_pm", true)
    local msgColor = getColorHex(msgType, false)

    local prefix = isIncoming and tagColor.."[PM From] " or tagColor.."[PM To] "
    local formattedMessage = prefix .. sender .. "#FFFFFF: " .. message

    local r, g, b = getMessageColor(msgType, false)
    outputChatBox(formattedMessage, r, g, b, true)
end)

-- Event for gamemode-specific messages
addEvent("chatmanager:onGamemodeMessage", true)
addEventHandler("chatmanager:onGamemodeMessage", root, function(message, messageType)
    playChatSound(messageType or "normal")

    local r, g, b = getMessageColor(messageType or "normal", false)
    local tagColor = getColorHex("tag_" .. (messageType or "normal"), true)

    outputChatBox(tagColor .. "[" .. (messageType:gsub("^%l", string.upper) or "Message") .. "]: " .. message, r, g, b, true)
end)

-- Event handler for system messages
addEvent("chatmanager:onSystemMessage", true)
addEventHandler("chatmanager:onSystemMessage", root, function(message)
    playChatSound("system")

    local tagColor = getColorHex("tag_system", true)
    local r, g, b = getMessageColor("system", false)

    outputChatBox(tagColor .. "[System]: " .. message, r, g, b, true)
end)

-- Event handler for admin announcements
addEvent("chatmanager:onAdminAnnouncement", true)
addEventHandler("chatmanager:onAdminAnnouncement", root, function(message, sender)
    playChatSound("admin")
    -- Additional client-side handling can be added here
end)

-- Toggle chat filter
function toggleChatFilter(state)
    chatSettings.useFilter = state
    triggerServerEvent("chatmanager:updateClientSetting", localPlayer, "useFilter", state)
    outputChatBox("Chat filter has been " .. (state and "enabled" or "disabled"), 255, 165, 0)

    -- Save preference to client
    setElementData(localPlayer, "chatmanager.useFilter", state)
end

-- Command to toggle chat filter
addCommandHandler("togglefilter", function()
    toggleChatFilter(not chatSettings.useFilter)
end)

-- Event for chat filter changes
addEvent("chatmanager:filterChanged", true)
addEventHandler("chatmanager:filterChanged", root, function(state)
    chatSettings.useFilter = state
    outputChatBox("Chat filter has been " .. (state and "enabled" or "disabled"), 255, 165, 0)
end)

-- Toggle chat block
function toggleChatBlock(state)
    chatSettings.chatBlocked = state
    triggerServerEvent("chatmanager:updateClientSetting", localPlayer, "chatBlocked", state)
    outputChatBox("Chat messages are now " .. (state and "blocked" or "unblocked"), 255, 165, 0)
end

-- Command to toggle chat blocking
addCommandHandler("togglechat", function()
    toggleChatBlock(not chatSettings.chatBlocked)
end)

-- Initialize client-side chat settings
addEventHandler("onClientResourceStart", resourceRoot, function()
    loadChatSettings()
    outputChatBox("Chat Manager loaded successfully", 0, 255, 0)
end)