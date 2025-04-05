-- Chat Manager: Main Server-Side Chat Event Handler
-- Handles chat interception, spam protection, color application, and message formatting

local lastMessageTime = {}
local lastMessageContent = {}
local lastMessageFrom = {}

-- Function to get player name with appropriate color
local function getColoredPlayerName(player)
    local r, g, b = 255, 255, 255 -- Default white

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

    return getPlayerName(player)
end

-- Check if a message is spam
local function isSpam(player, message)
    -- Get admin bypass setting
    local adminBypass = getSettingValue("admin_bypass_spam")

    -- Check if player can bypass spam protection (admins)
    if adminBypass and (hasObjectPermissionTo(player, "command.kick", false) or
                         hasObjectPermissionTo(player, "command.mute", false)) then
        return false
    end

    local currentTime = getTickCount()
    local minDelay = getSettingValue("chat_message_delay")

    -- Check for repeated messages
    if getSettingValue("block_repeated_messages") and lastMessageContent[player] == message then
        outputChatBox("Stop repeating yourself!", player, 255, 0, 0)
        return true
    end

    -- Check for message delay
    if lastMessageTime[player] and (currentTime - lastMessageTime[player]) < minDelay then
        outputChatBox("Please wait before sending another message!", player, 255, 0, 0)
        return true
    end

    -- Update tracking info
    lastMessageContent[player] = message
    lastMessageTime[player] = currentTime
    return false
end

-- Check if a player is voice-muted
local function isVoiceMuted(player)
    -- Placeholder for voice mute check (integrate with voice resource if available)
    return getElementData(player, "voice.muted") == true
end

-- Function to determine chat format based on player's team and gamemode
function getPlayerChatFormat(player)
    local team = getPlayerTeam(player)
    local gamemode = "default"

    -- Try to get gamemode from team data
    if team then
        local teamGamemode = getElementData(team, "gamemode")
        if teamGamemode then
            gamemode = teamGamemode
        end
    end

    -- Define formats for different gamemodes
    local formats = {
        default = {useTeamColors = true, separator = ": "},
        tdma = {useTeamColors = true, separator = ":#FFFFFF "},
        freeroam = {useTeamColors = false, separator = ": "}
        -- Add more gamemodes as needed
    }

    -- Always return a valid format (use default if gamemode not found)
    return formats[gamemode] or formats.default
end

-- Process and forward chat messages
function handleChatMessage(player, messageType, message, receiver)
    -- Check if chat is blocked for the player
    if getElementData(player, "chatmanager.chatBlocked") then
        outputChatBox("Your chat is currently blocked.", player, 255, 0, 0)
        return false
    end

    -- Check if player is muted
    if isChatMuted(player) then
        outputChatBox("You are muted and cannot send messages.", player, 255, 0, 0)
        return false
    end

    -- Check if player is voice-muted
    if isVoiceMuted(player) then
        outputChatBox("You are voice-muted and cannot send messages.", player, 255, 0, 0)
        return false
    end

    -- Spam protection
    if isSpam(player, message) then
        return false
    end

    -- Apply text filtering if configured
    local useFilter = getElementData(player, "chatmanager.useFilter")
    if useFilter then
        -- Check for bypass attempts first
        local bypassDetected, bypassWord = detectFilterBypass(message)
        if bypassDetected then
            outputChatBox("Your message appears to bypass the language filter.", player, 255, 165, 0)
            -- Give the player a warning but still let the filtered message through
        end

        -- Apply filter - using the function directly
        message = internalFilterText(message)
    end

    -- Strip color codes if configured
    if getSettingValue("strip_color_codes") then
        message = stripColorCodes(message)
    end

    -- Format and send message based on type
    local coloredName = getColoredPlayerName(player)

    if messageType == 0 then -- Public chat
        local team = getPlayerTeam(player)
        local playerName = getPlayerName(player)
        local r, g, b = 255, 255, 255 -- Default white text color

        if team then
            r, g, b = getTeamColor(team) -- Use team color for player name
        end

        -- Get chat format for the player's gamemode
        local format = getPlayerChatFormat(player)
        -- Ensure format is valid (defensive programming)
        if not format then
            format = {separator = ": ", useTeamColors = true}
        end

        local separator = format.separator or ": "
        local useTeamColors = format.useTeamColors

        -- Format message with player name in team color and white message text
        if useTeamColors then
            outputChatBox(string.format("#%.2X%.2X%.2X%s%s%s", r, g, b, playerName, separator, message), root, 255, 255, 255, true)
        else
            outputChatBox(playerName .. separator .. message, root, 255, 255, 255, true)
        end

        outputServerLog("CHAT: " .. playerName .. ": " .. message)
        return false
    end

    if messageType == 1 then -- Team chat
        local team = getPlayerTeam(player)
        if team then
            local teamPlayers = getPlayersInTeam(team)
            outputServerLog("TEAMCHAT: " .. getPlayerName(player) .. ": " .. message)
            for _, teamPlayer in ipairs(teamPlayers) do
                outputChatBox("(TEAM) " .. coloredName .. ": " .. message, teamPlayer, 255, 255, 255, true)
            end
        else
            outputChatBox("You are not in a team.", player, 255, 0, 0)
        end
        return false
    end

    return true
end

-- Helper function to find a player from partial name
function getPlayerFromPartialName(name)
    local name = name and name:gsub("#%x%x%x%x%x%x", ""):lower() or nil
    if name then
        for _, player in ipairs(getElementsByType("player")) do
            local playerName = getPlayerName(player):gsub("#%x%x%x%x%x%x", ""):lower()
            if playerName == name then
                return player
            end
        end

        -- No exact match found, try partial match
        for _, player in ipairs(getElementsByType("player")) do
            local playerName = getPlayerName(player):gsub("#%x%x%x%x%x%x", ""):lower()
            if playerName:find(name, 1, true) then
                return player
            end
        end
    end
    return false
end

-- Event handler for player chat
addEventHandler("onPlayerChat", root, function(message, messageType)
    cancelEvent() -- Cancel default chat display
    handleChatMessage(source, messageType, message)
end, true, "high") -- High priority to ensure we handle before other resources

-- Event handler for player team chat
addEventHandler("onPlayerTeamChat", root, function(message)
    cancelEvent() -- Cancel default chat display
    handleChatMessage(source, 1, message) -- 1 is team chat type
end, true, "high")

-- Event handler for player quit (clean up tables)
addEventHandler("onPlayerQuit", root, function()
    local playerID = getElementData(source, "playerid") or getPlayerName(source)
    lastMessageTime[playerID] = nil
    lastMessageContent[playerID] = nil
    lastMessageFrom[source] = nil
end)

-- Event handler for resource start/stop (to clear spam protection tables)
addEventHandler("onResourceStart", resourceRoot, function()
    lastMessageTime = {}
    lastMessageContent = {}
    lastMessageFrom = {}
end)

-- Handle client setting updates
addEvent("chatmanager:updateClientSetting", true)
addEventHandler("chatmanager:updateClientSetting", root, function(setting, value)
    if setting == "useFilter" then
        setElementData(client, "chatmanager.useFilter", value)
    elseif setting == "chatBlocked" then
        setElementData(client, "chatmanager.chatBlocked", value)
    end
end)

-- Add event for request settings from client
addEvent("chatmanager:requestSettings", true)
addEventHandler("chatmanager:requestSettings", root, function()
    local settings = {
        useNametagColors = getSettingValue("use_nametag_colors"),
        useTeamColors = getSettingValue("use_team_colors"),
        teamColorsOverride = getSettingValue("team_colors_override"),
        chatMessageDelay = getSettingValue("chat_message_delay"),
        blockRepeatedMessages = getSettingValue("block_repeated_messages"),
        stripColorCodes = getSettingValue("strip_color_codes")
    }

    triggerClientEvent(client, "chatmanager:receiveSettings", client, settings)
end)
