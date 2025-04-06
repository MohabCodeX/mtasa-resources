-- Chat Manager: Main Server-Side Chat Event Handler
-- Handles chat interception, spam protection, color application, and message formatting

local lastMessageTime = {}
local lastMessageContent = {}
local lastMessageFrom = {}

-- Function to get player name with appropriate color
local function getColoredPlayerName(player)
    local r, g, b = 211, 174, 154 -- Default color D3AE9A for non-teamed players

    -- Get all relevant settings
    local usePlayerColors = getSettingValue("use_player_colors")
    local useNametagColors = getSettingValue("use_nametag_colors")
    local useTeamColors = getSettingValue("use_team_colors")
    local teamColorsOverride = getSettingValue("team_colors_override")
    local playerColorsOverrideTeam = getSettingValue("player_colors_override_team")

    -- Priority 1: Player colors with override
    if usePlayerColors and playerColorsOverrideTeam then
        r, g, b = getChatColorForPlayer(player)
        return string.format("#%.2X%.2X%.2X%s", r, g, b, getPlayerName(player))
    end

    -- Priority 2: Team colors
    if useTeamColors then
        local team = getPlayerTeam(player)
        if team then
            r, g, b = getTeamColor(team)
            if not useNametagColors or teamColorsOverride then
                return string.format("#%.2X%.2X%.2X%s", r, g, b, getPlayerName(player))
            end
        end
    end

    -- Priority 3: Player colors without override
    if usePlayerColors and not playerColorsOverrideTeam then
        r, g, b = getChatColorForPlayer(player)
        return string.format("#%.2X%.2X%.2X%s", r, g, b, getPlayerName(player))
    end

    -- Priority 4: Nametag colors
    if useNametagColors then
        r, g, b = getPlayerNametagColor(player)
        return string.format("#%.2X%.2X%.2X%s", r, g, b, getPlayerName(player))
    end

    -- Default fallback color for non-teamed players
    return string.format("#%.2X%.2X%.2X%s", r, g, b, getPlayerName(player))
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
    local playerName = getPlayerName(player)

    -- Handle different message types according to MTA documentation:
    -- 0: normal message, 1: action message (/me), 2: team message,
    -- 3: private message, 4: internal message
    if messageType == 0 then -- Normal message
        -- Always use a separator that enforces white text for the message
        local separator = ":#FFFFFF "

        -- Use the pre-colored player name with dynamic color (if enabled)
        outputChatBox(coloredName .. separator .. message, root, 255, 255, 255, true)

        outputServerLog("CHAT: " .. playerName .. ": " .. message)
        return false

    elseif messageType == 1 then -- Action message (/me)
        -- Format action messages with dynamic colors as well
        outputChatBox("* " .. coloredName .. "#FFFFFF " .. message .. " *", root, 255, 255, 255, true)
        outputServerLog("ACTION: * " .. playerName .. " " .. message .. " *")
        return false

    elseif messageType == 2 then -- Team message
        local team = getPlayerTeam(player)
        if team then
            local teamPlayers = getPlayersInTeam(team)
            outputServerLog("TEAMCHAT: " .. playerName .. ": " .. message)

            -- MODIFIED: Always use team color for team chat regardless of player colors setting
            local r, g, b = getTeamColor(team)
            local teamColoredName = string.format("#%.2X%.2X%.2X%s", r, g, b, playerName)

            for _, teamPlayer in ipairs(teamPlayers) do
                outputChatBox("(TEAM) " .. teamColoredName .. ":#FFFFFF " .. message, teamPlayer, 255, 255, 255, true)
            end
        else
            outputChatBox("You are not in a team.", player, 255, 0, 0)
        end
        return false

    elseif messageType == 3 then -- Private message
        if receiver and isElement(receiver) and getElementType(receiver) == "player" then
            local r, g, b = 200, 150, 255 -- Purple-ish color for private messages

            -- Send to receiver - ensure message is white
            outputChatBox(string.format("#%.2X%.2X%.2X(PM from %s): #FFFFFF%s", r, g, b, playerName, message), receiver, 255, 255, 255, true)

            -- Send confirmation to sender - ensure message is white
            outputChatBox(string.format("#%.2X%.2X%.2X(PM to %s): #FFFFFF%s", r, g, b, getPlayerName(receiver), message), player, 255, 255, 255, true)

            outputServerLog("PM: " .. playerName .. " to " .. getPlayerName(receiver) .. ": " .. message)
        else
            outputChatBox("Invalid message recipient.", player, 255, 0, 0)
        end
        return false

    elseif messageType == 4 then -- Internal message (system messages, server notifications)
        -- System messages should also have white text for consistency
        outputChatBox("#FFFF64[SYSTEM]: #FFFFFF" .. message, root, 255, 255, 255, true)
        outputServerLog("INTERNAL: " .. message)
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

    -- Handle the message based on its type
    if messageType == 3 then -- Private message
        -- For private messages, we need to find the target player
        -- This assumes the message format is "/pm playername message"
        local targetName, privateMessage = string.match(message, "^(%S+)%s+(.+)$")
        if targetName and privateMessage then
            local targetPlayer = getPlayerFromPartialName(targetName)
            if targetPlayer then
                handleChatMessage(source, 3, privateMessage, targetPlayer)
            else
                outputChatBox("Player not found: " .. targetName, source, 255, 0, 0)
            end
        else
            outputChatBox("Usage: /pm playername message", source, 255, 0, 0)
        end
    else
        -- For all other message types, pass directly to handler
        handleChatMessage(source, messageType, message)
    end
end, true, "high") -- High priority to ensure we handle before other resources

-- Keep the onPlayerTeamChat handler for backward compatibility
-- but now we handle team chat through messageType 2 in onPlayerChat as well
addEventHandler("onPlayerTeamChat", root, function(message)
    cancelEvent() -- Cancel default chat display
    handleChatMessage(source, 2, message) -- 2 is team chat type according to wiki
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
