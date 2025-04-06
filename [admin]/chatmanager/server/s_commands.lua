-- Chat Manager: Dynamic Command System
-- Loads and registers commands from commands.xml

-- Storage for command definitions
local commandDefinitions = {}
local commandAliases = {}

-- Storage for commands registered by other resources
local externalCommandHandlers = {}

-- Register a custom command from another resource
function registerCustomCommand(commandName, handlerFunction, requiredPermission)
    if type(commandName) ~= "string" or #commandName == 0 then
        outputDebugString("ChatManager: Failed to register custom command - invalid command name", 1)
        return false
    end

    if type(handlerFunction) ~= "function" then
        outputDebugString("ChatManager: Failed to register custom command - handler must be a function", 1)
        return false
    end

    -- Get the resource that's registering this command
    local sourceResource = getResourceFromName(getResourceName(getThisResource()))

    -- Store the command registration
    externalCommandHandlers[commandName] = {
        handler = handlerFunction,
        permission = requiredPermission or "none",
        resource = sourceResource
    }

    -- Check if this command is already registered
    if commandDefinitions[commandName] then
        outputDebugString("ChatManager: Warning - overriding existing command: " .. commandName, 2)
    end

    -- Register the command
    if not commandAliases[commandName] then
        addCommandHandler(commandName, function(player, cmd, ...)
            -- Handle custom commands from other resources
            local commandData = externalCommandHandlers[cmd]
            if commandData then
                -- Check permissions
                if commandData.permission ~= "none" and
                   not hasObjectPermissionTo(player, commandData.permission, false) then
                    outputChatBox("You don't have permission to use this command.", player, 255, 0, 0)
                    return
                end

                -- Capture arguments
                local args = {...}

                -- Call the custom handler
                local success, error = pcall(function()
                    commandData.handler(player, cmd, unpack(args))
                end)

                if not success then
                    outputDebugString("ChatManager: Error in custom command handler: " .. tostring(error), 1)
                end
            end
        end)
    end

    outputDebugString("ChatManager: Registered custom command: " .. commandName)
    return true
end

-- Unregister a custom command
function unregisterCustomCommand(commandName)
    if externalCommandHandlers[commandName] then
        externalCommandHandlers[commandName] = nil
        outputDebugString("ChatManager: Unregistered custom command: " .. commandName)
        return true
    end
    return false
end

-- Command action handlers
local commandActions = {
    -- Existing command handlers mapped to action names
    privateMessage = function(player, params)
        local targetName = params.target
        local message = params.message

        if not targetName then
            outputChatBox("SYNTAX: /" .. commandName .. " [playername] [message]", player, 255, 255, 0)
            return
        end

        local targetPlayer = getPlayerFromPartialName(targetName)
        if not targetPlayer then
            outputChatBox("Error: Player not found.", player, 255, 0, 0)
            return
        end

        -- Make sure they're not messaging themselves
        if targetPlayer == player then
            outputChatBox("You cannot send a private message to yourself.", player, 255, 0, 0)
            return
        end

        if #message == 0 then
            outputChatBox("SYNTAX: /" .. commandName .. " [playername] [message]", player, 255, 255, 0)
            return
        end

        -- Send the private message
        sendPrivateMessage(player, targetPlayer, message)
    end,

    replyLastMessage = function(player, params)
        local message = params.message
        local lastSender = lastMessageFrom[player]

        if not lastSender or not isElement(lastSender) then
            outputChatBox("You have no one to reply to.", player, 255, 0, 0)
            return
        end

        if #message == 0 then
            outputChatBox("SYNTAX: /reply [message]", player, 255, 255, 0)
            return
        end

        sendPrivateMessage(player, lastSender, message)
    end,

    toggleSetting = function(player, params)
        local setting = params.setting
        local currentValue = getElementData(player, "chatmanager." .. setting) or false
        local newValue = not currentValue

        if setting == "useFilter" then
            toggleChatFilter(player, newValue)
        elseif setting == "chatBlocked" then
            toggleChatBlock(player, newValue)
        end
    end,

    teamAnnounce = function(player, params)
        local message = params.message
        local team = getPlayerTeam(player)

        if not team then
            outputChatBox("You are not in a team.", player, 255, 0, 0)
            return
        end

        if #message == 0 then
            outputChatBox("SYNTAX: /tannounce [message]", player, 255, 255, 0)
            return
        end

        -- Check if player is team leader or admin
        local isAdmin = hasObjectPermissionTo(player, "command.mute", false)
        local isTeamLeader = (getElementData(player, "teamleader") == true)

        if not (isAdmin or isTeamLeader) then
            outputChatBox("You don't have permission to send team announcements.", player, 255, 0, 0)
            return
        end

        -- Send message to team
        sendTeamMessage(message, team, player)

        -- Log the action
        outputServerLog("TEAM ANNOUNCEMENT: " .. getPlayerName(player) .. " to " .. getTeamName(team) .. ": " .. message)
    end,

    mutePlayer = function(player, params)
        local targetName = params.target
        local reason = params.reason

        if not targetName then
            outputChatBox("SYNTAX: /mute [playername] [reason]", player, 255, 255, 0)
            return
        end

        -- Get target player
        local targetPlayer = getPlayerFromPartialName(targetName)
        if not targetPlayer then
            outputChatBox("Error: Player not found.", player, 255, 0, 0)
            return
        end

        -- Mute the player
        if setChatMuted(targetPlayer, true) then
            -- Notify admin
            outputChatBox("You muted " .. getPlayerName(targetPlayer) .. ". Reason: " .. reason, player, 0, 255, 0)

            -- Notify other admins
            local admins = getElementsByType("player")
            for _, admin in ipairs(admins) do
                if admin ~= player and hasObjectPermissionTo(admin, "command.mute", false) then
                    outputChatBox(getPlayerName(player) .. " muted " .. getPlayerName(targetPlayer) .. ". Reason: " .. reason, admin, 255, 126, 0)
                end
            end

            -- Notify target with reason
            outputChatBox("You have been muted by " .. getPlayerName(player) .. ". Reason: " .. reason, targetPlayer, 255, 0, 0)

            -- Log the action
            outputServerLog("ADMIN: " .. getPlayerName(player) .. " muted " .. getPlayerName(targetPlayer) .. ". Reason: " .. reason)
        else
            outputChatBox("Failed to mute " .. getPlayerName(targetPlayer), player, 255, 0, 0)
        end
    end,

    unmutePlayer = function(player, params)
        local targetName = params.target

        if not targetName then
            outputChatBox("SYNTAX: /unmute [playername]", player, 255, 255, 0)
            return
        end

        -- Get target player
        local targetPlayer = getPlayerFromPartialName(targetName)
        if not targetPlayer then
            outputChatBox("Error: Player not found.", player, 255, 0, 0)
            return
        end

        -- Unmute the player
        if setChatMuted(targetPlayer, false) then
            -- Notify admin
            outputChatBox("You unmuted " .. getPlayerName(targetPlayer), player, 0, 255, 0)

            -- Notify other admins
            local admins = getElementsByType("player")
            for _, admin in ipairs(admins) do
                if admin ~= player and hasObjectPermissionTo(admin, "command.mute", false) then
                    outputChatBox(getPlayerName(player) .. " unmuted " .. getPlayerName(targetPlayer), admin, 255, 126, 0)
                end
            end

            -- Notify target
            outputChatBox("You have been unmuted by " .. getPlayerName(player), targetPlayer, 0, 255, 0)

            -- Log the action
            outputServerLog("ADMIN: " .. getPlayerName(player) .. " unmuted " .. getPlayerName(targetPlayer))
        else
            outputChatBox("Failed to unmute " .. getPlayerName(targetPlayer), player, 255, 0, 0)
        end
    end,

    listMutedPlayers = function(player, params)
        -- Get list of all muted players
        local mutedCount = 0
        local players = getElementsByType("player")

        outputChatBox("--- Muted Players ---", player, 255, 255, 0)

        for _, targetPlayer in ipairs(players) do
            if isChatMuted(targetPlayer) then
                mutedCount = mutedCount + 1
                outputChatBox("- " .. getPlayerName(targetPlayer), player, 255, 126, 0)
            end
        end

        if mutedCount == 0 then
            outputChatBox("No muted players", player, 255, 255, 255)
        end

        outputChatBox("--- End of List ---", player, 255, 255, 0)
    end,

    clearChat = function(player, params)
        local target = params.target

        -- Clear chat for specific player or everyone
        if target and target:lower() == "all" then
            -- Clear chat for all players
            for i = 1, 50 do
                outputChatBox(" ", root)
            end
            outputChatBox("Chat has been cleared by " .. getPlayerName(player), root, 255, 126, 0)
            outputServerLog("ADMIN: " .. getPlayerName(player) .. " cleared chat for all players")
        else
            -- Clear chat for the admin only
            for i = 1, 50 do
                outputChatBox(" ", player)
            end
            outputChatBox("You cleared your chat", player, 0, 255, 0)
        end
    end,

    adminAnnounce = function(player, params)
        local message = params.message

        if #message == 0 then
            outputChatBox("SYNTAX: /announce [message]", player, 255, 255, 0)
            return
        end

        -- Send the announcement
        sendAdminAnnouncement(message, player)

        -- Log the action
        outputServerLog("ADMIN: " .. getPlayerName(player) .. " made an announcement: " .. message)
    end,

    systemMessage = function(player, params)
        local message = params.message

        if #message == 0 then
            outputChatBox("SYNTAX: /system [message]", player, 255, 255, 0)
            return
        end

        -- Send the system message
        sendSystemMessage(message)

        -- Log the action
        outputServerLog("ADMIN: " .. getPlayerName(player) .. " sent system message: " .. message)
    end,

    addFilterWord = function(player, params)
        local word = params.word

        if word and #word > 0 then
            if updateCustomFilter(word, false) then
                outputChatBox("Added '" .. word .. "' to the chat filter.", player, 0, 255, 0)
            else
                outputChatBox("Word '" .. word .. "' is already in the filter.", player, 255, 165, 0)
            end
        else
            outputChatBox("SYNTAX: /addfilterword [word]", player, 255, 255, 0)
        end
    end,

    removeFilterWord = function(player, params)
        local word = params.word

        if word and #word > 0 then
            if updateCustomFilter(word, true) then
                outputChatBox("Removed '" .. word .. "' from the chat filter.", player, 0, 255, 0)
            else
                outputChatBox("Word '" .. word .. "' is not in the filter.", player, 255, 165, 0)
            end
        else
            outputChatBox("SYNTAX: /removefilterword [word]", player, 255, 255, 0)
        end
    end,

    listFilterWords = function(player, params)
        -- Get the custom filter word list
        local wordList = getFilterWordList()

        outputChatBox("--- Chat Filter Words ---", player, 255, 255, 0)

        if #wordList == 0 then
            outputChatBox("No custom filter words defined", player, 255, 255, 255)
        else
            for i, word in ipairs(wordList) do
                -- Only show first 20 words to avoid flooding chat
                if i <= 20 then
                    outputChatBox("- " .. word, player, 255, 126, 0)
                end
            end

            if #wordList > 20 then
                outputChatBox("... and " .. (#wordList - 20) .. " more words", player, 255, 126, 0)
            end
        end

        outputChatBox("--- End of List ---", player, 255, 255, 0)
    end,

    reloadFilter = function(player, params)
        -- Reload the filter
        if reloadChatFilter() then
            outputChatBox("Chat filter has been reloaded", player, 0, 255, 0)
            outputServerLog("ADMIN: " .. getPlayerName(player) .. " reloaded the chat filter")
        else
            outputChatBox("Failed to reload chat filter", player, 255, 0, 0)
        end
    end,

    customMessage = function(player, params, command)
        local commandDef = commandDefinitions[command]
        if not commandDef or not commandDef.custom then return end

        -- Skip processing for sendpos command since it's handled separately
        if command == "sendpos" then return end

        -- Process custom messages
        for _, msgDef in ipairs(commandDef.custom) do
            if msgDef.message then
                local message = msgDef.message

                -- Replace placeholders
                message = message:gsub("{PLAYER}", getPlayerName(player))

                -- Get player ID (using getElementID or fallback to data storage)
                local playerID = getElementID(player) or getElementData(player, "playerid") or "N/A"
                message = message:gsub("{PLAYERID}", tostring(playerID))

                -- Get player location (combine zone name and coordinates)
                local x, y, z = getElementPosition(player)
                -- Make sure coordinates are valid before using math.floor
                local locationText = "Unknown"
                if x and y and z then
                    local zoneName = getZoneName(x, y, z) or "Unknown"
                    locationText = zoneName .. " (" .. math.floor(x) .. ", " .. math.floor(y) .. ", " .. math.floor(z) .. ")"
                end
                message = message:gsub("{LOCATION}", locationText)

                -- Process all parameters
                for paramName, paramValue in pairs(params) do
                    message = message:gsub("{PARAM:" .. paramName .. "}", tostring(paramValue))
                end

                -- Support for numeric parameter placeholders (backward compatibility)
                local index = 1
                for _, param in ipairs(commandDef.parameters) do
                    if params[param.name] then
                        message = message:gsub("{PARAM:" .. index .. "}", tostring(params[param.name]))
                        index = index + 1
                    end
                end

                -- Parse color
                local r, g, b = 255, 255, 255
                if msgDef.color then
                    local color = msgDef.color
                    if color:sub(1, 1) == "#" then
                        r = tonumber("0x" .. color:sub(2, 3)) or 255
                        g = tonumber("0x" .. color:sub(4, 5)) or 255
                        b = tonumber("0x" .. color:sub(6, 7)) or 255
                    end
                end

                -- Send to appropriate target
                if msgDef.target == "all" then
                    outputChatBox(message, root, r, g, b, true)
                elseif msgDef.target == "admins" then
                    local admins = getElementsByType("player")
                    for _, admin in ipairs(admins) do
                        if hasObjectPermissionTo(admin, "command.mute", false) then
                            outputChatBox(message, admin, r, g, b, true)
                        end
                    end
                elseif msgDef.target == "team" then
                    local team = getPlayerTeam(player)
                    if team then
                        local teamPlayers = getPlayersInTeam(team)
                        for _, teamPlayer in ipairs(teamPlayers) do
                            outputChatBox(message, teamPlayer, r, g, b, true)
                        end
                    end
                elseif msgDef.target == "sender" then
                    outputChatBox(message, player, r, g, b, true)
                end
            end

            -- Handle location tracking for emergency calls
            if type(commandDef.custom.tracking) == "table" and commandDef.custom.tracking.enabled == "true" then
                local trackingType = commandDef.custom.tracking.type
                if trackingType then
                    -- Replace any parameter placeholders in the tracking type
                    for paramName, paramValue in pairs(params) do
                        trackingType = trackingType:gsub("{PARAM:" .. paramName .. "}", tostring(paramValue))
                    end
                else
                    trackingType = "static" -- Default to static if not specified
                end

                local duration = tonumber(commandDef.custom.tracking.duration) or 300

                -- Generate a unique emergency ID
                local emergencyId = getTickCount() + math.random(10000)

                -- Get player position and handle potential nil values
                local x, y, z = getElementPosition(player)
                if not (x and y and z) then
                    x, y, z = 0, 0, 0 -- Fallback position if coordinates are nil
                end

                -- Send tracking info to admins
                local admins = getElementsByType("player")
                for _, admin in ipairs(admins) do
                    if hasObjectPermissionTo(admin, "command.mute", false) then
                        outputDebugString("ChatManager: Sending blip to admin " .. getPlayerName(admin) .. " with type " .. trackingType)
                        triggerClientEvent(admin, "chatmanager:createEmergencyBlip", admin,
                            emergencyId, trackingType, player, getPlayerName(player), x, y, z)
                    end
                end

                -- Notify server console (with nil checks for logging)
                local zoneName = "Unknown"
                if x and y and z then
                    zoneName = getZoneName(x, y, z) or "Unknown"
                end

                outputServerLog("EMERGENCY: " .. getPlayerName(player) .. " called 911 at " ..
                    zoneName .. " (" .. math.floor(x) .. ", " .. math.floor(y) .. ", " ..
                    math.floor(z) .. "). Tracking type: " .. trackingType)
            end
        end
    end,

    sharePosition = function(player, params)
        local receiver = params.receiver
        local message = params.message or ""

        if not receiver or receiver == "" then
            outputChatBox("SYNTAX: /sendpos [player/team] [optional message]", player, 255, 255, 0)
            return
        end

        local targetType
        if receiver:lower() == "team" then
            targetType = "team"
        else
            targetType = "player"
        end

        sendPositionToTarget(player, targetType, receiver, message)
    end
}

-- Simple utility function to handle position sharing
local function sendPositionToTarget(player, targetType, targetName, message)
    -- Get player's current position
    local x, y, z = getElementPosition(player)
    local zoneName = getZoneName(x, y, z) or "Unknown"
    local locationText = zoneName .. " (" .. math.floor(x) .. ", " .. math.floor(y) .. ", " .. math.floor(z) .. ")"

    -- Format the message to send with prefix based on target type
    local prefixType = ""

    -- Set the appropriate prefix based on target type
    if targetType == "player" then
        prefixType = "PRIVATE"
    elseif targetType == "team" then
        prefixType = "TEAM"
    else
        -- Invalid target type, default to PRIVATE
        prefixType = "PRIVATE"
        targetType = "player" -- Force to player type for safety
    end

    -- Create the final position info message
    local positionInfo = "[" .. prefixType .. "-LOCATION] " .. getPlayerName(player) .. " is at " .. locationText
    if message and message ~= "" then
        positionInfo = positionInfo .. " (" .. message .. ")"
    end

    -- Determine target(s) to send to
    local targets = {}

    if targetType == "player" then
        -- Send to specific player
        local targetPlayer = getPlayerFromPartialName(targetName)
        if targetPlayer then
            table.insert(targets, targetPlayer)
        else
            outputChatBox("Player not found.", player, 255, 0, 0)
            return false
        end
    elseif targetType == "team" then
        -- Send to player's team
        local team = getPlayerTeam(player)
        if team then
            targets = getPlayersInTeam(team)
        else
            outputChatBox("You are not in a team.", player, 255, 0, 0)
            return false
        end
    else
        outputChatBox("Invalid target. Use a player name or 'team'.", player, 255, 0, 0)
        return false
    end

    -- Send the position info to all targets
    for _, target in ipairs(targets) do
        outputChatBox(positionInfo, target, 0, 204, 255, true)
    end

    -- Confirm to sender
    local targetDesc = targetType == "player" and targetName or targetType
    outputChatBox("Location sent to " .. targetDesc .. ".", player, 0, 204, 255)

    -- Log the action
    outputServerLog("POSITION: " .. getPlayerName(player) .. " sent position to " ..
                    targetDesc .. ": " .. locationText)

    return true
end

-- Function to check if player has permission to use a command
local function hasCommandPermission(player, permission)
    if permission == "none" then
        return true
    elseif permission == "teamleader" then
        local isAdmin = hasObjectPermissionTo(player, "command.mute", false)
        local isTeamLeader = (getElementData(player, "teamleader") == true)
        return isAdmin or isTeamLeader
    else
        return hasObjectPermissionTo(player, permission, false)
    end
end

-- Parse parameter values from command arguments
local function parseParameters(commandDef, cmd, ...)
    local args = {...}
    local result = {}

    outputDebugString("ChatManager: Parsing parameters for command: " .. cmd .. ", args: " .. table.concat(args, ", "))

    local argIndex = 1
    for _, param in ipairs(commandDef.parameters or {}) do
        if param.type ~= "hidden" then
            -- Handle different parameter types
            if param.type == "player" then
                -- Player parameter - attempts to find a matching player
                if args[argIndex] then
                    result[param.name] = args[argIndex]
                    argIndex = argIndex + 1
                elseif not param.optional then
                    return false -- Required parameter missing
                end
            elseif param.type == "text" then
                -- Text parameter - consumes all remaining arguments as one string
                if argIndex <= #args then
                    result[param.name] = table.concat(args, " ", argIndex)
                    outputDebugString("ChatManager: Set text parameter '" .. param.name .. "' to: " .. result[param.name])
                    argIndex = #args + 1
                elseif not param.optional then
                    outputDebugString("ChatManager: Missing required text parameter: " .. param.name)
                    return false -- Required parameter missing
                else
                    result[param.name] = param.default or ""
                    outputDebugString("ChatManager: Using default for text parameter: " .. param.name .. " = " .. result[param.name])
                end
            elseif param.type == "number" then
                -- Number parameter - validates that it's a number
                if args[argIndex] then
                    local num = tonumber(args[argIndex])
                    if num then
                        result[param.name] = num
                        argIndex = argIndex + 1
                    else
                        outputChatBox("Error: " .. param.name .. " must be a number", player, 255, 0, 0)
                        return false -- Invalid number format
                    end
                elseif not param.optional then
                    return false -- Required parameter missing
                else
                    result[param.name] = tonumber(param.default) or 0
                end
            elseif param.type == "string" then
                -- String parameter - takes a single word
                if args[argIndex] then
                    result[param.name] = args[argIndex]
                    argIndex = argIndex + 1
                elseif not param.optional then
                    return false -- Required parameter missing
                else
                    result[param.name] = param.default or ""
                end
            elseif param.type == "team" then
                -- Team parameter - attempts to find a matching team
                if args[argIndex] then
                    local teamName = args[argIndex]
                    local foundTeam = false

                    -- Find team by name
                    for _, team in ipairs(getElementsByType("team")) do
                        if string.find(string.lower(getTeamName(team)), string.lower(teamName)) then
                            result[param.name] = getTeamName(team)
                            foundTeam = true
                            break
                        end
                    end

                    if not foundTeam then
                        outputChatBox("Error: Team not found", player, 255, 0, 0)
                        return false
                    end

                    argIndex = argIndex + 1
                elseif not param.optional then
                    return false -- Required parameter missing
                else
                    result[param.name] = param.default or ""
                end
            elseif param.type == "vehicle" then
                -- Vehicle parameter - validates vehicle name/ID
                if args[argIndex] then
                    local vehicleID = tonumber(args[argIndex])
                    if vehicleID and vehicleID >= 400 and vehicleID <= 611 then
                        result[param.name] = vehicleID
                    else
                        -- Could implement vehicle name lookup here
                        result[param.name] = args[argIndex]
                    end
                    argIndex = argIndex + 1
                elseif not param.optional then
                    return false -- Required parameter missing
                else
                    result[param.name] = param.default or ""
                end
            elseif param.type == "weapon" then
                -- Weapon parameter - validates weapon name/ID
                if args[argIndex] then
                    local weaponID = tonumber(args[argIndex])
                    if weaponID and weaponID >= 1 and weaponID <= 46 then
                        result[param.name] = weaponID
                    else
                        -- Could implement weapon name lookup here
                        result[param.name] = args[argIndex]
                    end
                    argIndex = argIndex + 1
                elseif not param.optional then
                    return false -- Required parameter missing
                else
                    result[param.name] = param.default or ""
                end
            else
                -- Default handler for other parameter types
                if args[argIndex] then
                    result[param.name] = args[argIndex]
                    argIndex = argIndex + 1
                elseif not param.optional then
                    return false -- Required parameter missing
                else
                    result[param.name] = param.default or ""
                end
            end
        else
            -- Hidden parameters with default values
            result[param.name] = param.default
        end
    end

    outputDebugString("ChatManager: Parsed parameters result: " .. inspect(result))
    return result
end

-- Simple table inspection function for debugging
function inspect(t)
    if type(t) ~= "table" then return tostring(t) end
    local result = "{"
    for k, v in pairs(t) do
        result = result .. tostring(k) .. "="
        if type(v) == "table" then
            result = result .. inspect(v)
        else
            result = result .. tostring(v)
        end
        result = result .. ", "
    end
    return result .. "}"
end

-- Process a command when executed
local function processCommand(player, cmd, ...)
    -- Check if this is an external command first
    local externalCommand = externalCommandHandlers[cmd]
    if externalCommand then
        -- Check permissions
        if externalCommand.permission ~= "none" and
           not hasObjectPermissionTo(player, externalCommand.permission, false) then
            outputChatBox("You don't have permission to use this command.", player, 255, 0, 0)
            return
        end

        -- Capture arguments
        local args = {...}

        -- Call the custom handler
        local success, error = pcall(function()
            externalCommand.handler(player, cmd, unpack(args))
        end)

        if not success then
            outputDebugString("ChatManager: Error in custom command handler: " .. tostring(error), 1)
        end

        return
    end

    -- Check for command alias
    local commandName = commandAliases[cmd] or cmd
    local commandDef = commandDefinitions[commandName]
    if not commandDef then
        return -- Not our command
    end

    -- Check permission
    if not hasCommandPermission(player, commandDef.permission) then
        outputChatBox("You don't have permission to use this command.", player, 255, 0, 0)
        return
    end

    -- Parse parameters - FIX: Pass the commandDef directly, not params
    local params = parseParameters(commandDef, cmd, ...)
    if params == false then
        outputChatBox("SYNTAX: /" .. cmd .. " " .. (commandDef.syntax or ""), player, 255, 255, 0)
        return
    end

    -- Handle sendpos command specifically to avoid duplicate processing
    if commandName == "sendpos" then
        local receiver = params.receiver
        local message = params.message or ""

        local targetType
        if receiver:lower() == "team" then
            targetType = "team"
        else
            targetType = "player"
        end

        sendPositionToTarget(player, targetType, receiver, message)
        return -- Exit after processing
    end

    -- Execute the command action
    local actionFunc = commandActions[commandDef.action]
    if actionFunc then
        actionFunc(player, params, commandName)
    end
end

-- Load commands from XML file
local function loadCommands()
    local xmlFile = xmlLoadFile("commands.xml")
    if not xmlFile then
        outputDebugString("Failed to load commands.xml", 1)
        return false
    end

    local commands = xmlNodeGetChildren(xmlFile)
    for _, commandNode in ipairs(commands) do
        if xmlNodeGetName(commandNode) == "command" then
            local name = xmlNodeGetAttribute(commandNode, "name")
            if name then
                local command = {
                    name = name,
                    action = xmlNodeGetAttribute(commandNode, "action"),
                    description = xmlNodeGetAttribute(commandNode, "description"),
                    permission = "none",
                    syntax = "",
                    helptext = "",
                    parameters = {},
                    custom = {}
                }

                -- Parse parameters
                local paramNodes = xmlNodeGetChildren(commandNode)
                for _, node in ipairs(paramNodes) do
                    if xmlNodeGetName(node) == "parameter" then
                        table.insert(command.parameters, {
                            name = xmlNodeGetAttribute(node, "name"),
                            type = xmlNodeGetAttribute(node, "type") or "text",
                            description = xmlNodeGetAttribute(node, "description") or "",
                            optional = xmlNodeGetAttribute(node, "optional") == "true",
                            default = xmlNodeGetAttribute(node, "default") or ""
                        })
                    elseif xmlNodeGetName(node) == "permission" then
                        command.permission = xmlNodeGetValue(node) or "none"
                    elseif xmlNodeGetName(node) == "syntax" then
                        command.syntax = xmlNodeGetValue(node) or ""
                    elseif xmlNodeGetName(node) == "helptext" then
                        command.helptext = xmlNodeGetValue(node) or ""
                    elseif xmlNodeGetName(node) == "custom" then
                        -- Parse custom actions
                        local customNodes = xmlNodeGetChildren(node)
                        for _, customNode in ipairs(customNodes) do
                            if xmlNodeGetName(customNode) == "message" then
                                table.insert(command.custom, {
                                    message = xmlNodeGetValue(customNode) or "",
                                    target = xmlNodeGetAttribute(customNode, "target") or "all",
                                    color = xmlNodeGetAttribute(customNode, "color") or "#FFFFFF"
                                })
                            elseif xmlNodeGetName(customNode) == "tracking" then
                                command.custom.tracking = {
                                    enabled = xmlNodeGetAttribute(customNode, "enabled") or "false",
                                    type = xmlNodeGetAttribute(customNode, "type") or "static",
                                    duration = xmlNodeGetAttribute(customNode, "duration") or "300"
                                }
                            end
                        end
                    end
                end

                -- Store command definition
                commandDefinitions[name] = command

                -- Register command handler
                addCommandHandler(name, processCommand)

                -- Handle aliases if any
                local aliases = xmlNodeGetAttribute(commandNode, "alias")
                if aliases then
                    for alias in aliases:gmatch("[^,]+") do
                        alias = alias:match("^%s*(.-)%s*$") -- Trim whitespace
                        commandAliases[alias] = name
                        addCommandHandler(alias, processCommand)
                    end
                end

                outputDebugString("Registered command: " .. name)
            end
        end
    end

    xmlUnloadFile(xmlFile)
    return true
end

-- Track resources that register commands so we can clean up when they stop
addEventHandler("onResourceStop", root, function(resource)
    local resourceName = getResourceName(resource)
    -- Clean up any commands registered by this resource
    for commandName, commandData in pairs(externalCommandHandlers) do
        if commandData.resource == resource then
            externalCommandHandlers[commandName] = nil
            outputDebugString("ChatManager: Cleaned up command " .. commandName .. " from " .. resourceName)
        end
    end
end)

-- Initialize all commands when resource starts
addEventHandler("onResourceStart", resourceRoot, function()
    loadCommands()
end)

-- Helper function to toggle chat filter from command
function toggleChatFilter(player, state)
    triggerClientEvent(player, "chatmanager:filterChanged", player, state)
    setElementData(player, "chatmanager.useFilter", state)
    outputChatBox("Chat filter has been " .. (state and "enabled" or "disabled"), player, 255, 165, 0)
end

-- Helper function to toggle chat blocking from command
function toggleChatBlock(player, state)
    setElementData(player, "chatmanager.chatBlocked", state)
    outputChatBox("Chat messages are now " .. (state and "blocked" or "unblocked"), player, 255, 165, 0)
end

-- Player colors commands
addCommandHandler("playercolors", function(player, cmd, state)
    -- Check admin permissions
    if not hasObjectPermissionTo(player, "command.kick", false) then
        return outputChatBox("You need admin permissions to use this command.", player, 255, 0, 0)
    end

    if not state then
        -- Display current status
        local enabled = getSettingValue("use_player_colors")
        outputChatBox("Player colors are currently " .. (enabled and "ENABLED" or "DISABLED"), player, 255, 255, 0)
        outputChatBox("Usage: /playercolors [on/off]", player, 255, 255, 0)
        return
    end

    -- Process command
    if state == "on" or state == "enable" or state == "1" then
        -- Enable player colors
        setSettingValue("use_player_colors", true)
        randomizeAllPlayerColors()
        outputChatBox("Player colors enabled. All players now have random colors.", player, 0, 255, 0)

        -- Announce to all players
        outputChatBox("Player colors have been enabled on the server.", root, 0, 255, 0)
    elseif state == "off" or state == "disable" or state == "0" then
        -- Disable player colors
        setSettingValue("use_player_colors", false)
        resetAllPlayerColors()
        outputChatBox("Player colors disabled. All players reverted to default white.", player, 255, 100, 100)

        -- Announce to all players
        outputChatBox("Player colors have been disabled on the server.", root, 255, 100, 100)
    else
        outputChatBox("Usage: /playercolors [on/off]", player, 255, 255, 0)
    end
end)

addCommandHandler("randomcolor", function(player, cmd, targetName)
    -- Check admin permissions
    if not hasObjectPermissionTo(player, "command.kick", false) then
        return outputChatBox("You need admin permissions to use this command.", player, 255, 0, 0)
    end

    -- Check if player colors are enabled
    if not getSettingValue("use_player_colors") then
        return outputChatBox("Player colors are currently disabled. Use /playercolors on to enable.", player, 255, 0, 0)
    end

    -- Randomize target player's color or all players
    if not targetName then
        -- Randomize color for all players
        randomizeAllPlayerColors()
        outputChatBox("Randomized colors for all players.", player, 0, 255, 0)
    else
        -- Find target player
        local target = getPlayerFromPartialName(targetName)
        if target then
            randomizePlayerColor(target)
            outputChatBox("Randomized color for player: " .. getPlayerName(target), player, 0, 255, 0)
            outputChatBox("An admin has randomized your name color.", target, 0, 255, 0)
        else
            outputChatBox("Player not found: " .. targetName, player, 255, 0, 0)
        end
    end
end)

-- Add a debug command for testing player colors
addCommandHandler("testcolors", function(player)
    if not hasObjectPermissionTo(player, "command.kick", false) then
        return outputChatBox("You need admin permissions to use this command.", player, 255, 0, 0)
    end

    outputChatBox("===== Player Colors Debug Info =====", player, 255, 255, 0)
    outputChatBox("use_player_colors: " .. tostring(getSettingValue("use_player_colors")), player, 255, 255, 255)
    outputChatBox("use_nametag_colors: " .. tostring(getSettingValue("use_nametag_colors")), player, 255, 255, 255)
    outputChatBox("use_team_colors: " .. tostring(getSettingValue("use_team_colors")), player, 255, 255, 255)
    outputChatBox("team_colors_override: " .. tostring(getSettingValue("team_colors_override")), player, 255, 255, 255)
    outputChatBox("player_colors_override_team: " .. tostring(getSettingValue("player_colors_override_team")), player, 255, 255, 255)
    outputChatBox("player_color_min: " .. tostring(getSettingValue("player_color_min")), player, 255, 255, 255)
    outputChatBox("player_color_max: " .. tostring(getSettingValue("player_color_max")), player, 255, 255, 255)

    -- Show each player's current colors
    outputChatBox("Player Nametag Colors:", player, 255, 255, 0)
    for _, testPlayer in ipairs(getElementsByType("player")) do
        local r, g, b = getPlayerNametagColor(testPlayer)
        outputChatBox(getPlayerName(testPlayer) .. ": RGB(" .. tostring(r) .. "," .. tostring(g) .. "," .. tostring(b) .. ")", player, r, g, b)
    end

    -- Show how getColoredPlayerName renders each player
    outputChatBox("Player Colored Names in Chat:", player, 255, 255, 0)
    for _, testPlayer in ipairs(getElementsByType("player")) do
        local coloredName = getColoredPlayerName(testPlayer)
        outputChatBox(coloredName, player, 255, 255, 255, true)
    end
end)
