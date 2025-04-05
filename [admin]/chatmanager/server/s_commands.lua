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

        -- Process custom messages
        for _, msgDef in ipairs(commandDef.custom) do
            if msgDef.message then
                local message = msgDef.message

                -- Replace placeholders
                message = message:gsub("{PLAYER}", getPlayerName(player))
                for i, param in pairs(params) do
                    message = message:gsub("{PARAM:" .. i .. "}", param)
                end

                -- Parse color
                local r, g, b = 255, 255, 255
                if msgDef.color then
                    local color = msgDef.color
                    if color:sub(1,1) == "#" then
                        r = tonumber("0x"..color:sub(2,3)) or 255
                        g = tonumber("0x"..color:sub(4,5)) or 255
                        b = tonumber("0x"..color:sub(6,7)) or 255
                    end
                end

                -- Send to appropriate target
                if msgDef.target == "all" then
                    outputChatBox(message, root, r, g, b, true)
                elseif msgDef.target == "admins" then
                    -- Send to all admins
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
        end
    end
}

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
local function parseParameters(params, commandDef, cmd, ...)
    local args = {...}
    local result = {}

    local argIndex = 1
    for _, param in ipairs(commandDef.parameters or {}) do
        if param.type ~= "hidden" then
            if param.type == "player" then
                -- For player parameters
                if args[argIndex] then
                    result[param.name] = args[argIndex]
                    argIndex = argIndex + 1
                elseif not param.optional then
                    return false -- Required parameter missing
                end
            elseif param.type == "text" then
                -- For text parameters (consumes all remaining arguments)
                if argIndex <= #args then
                    result[param.name] = table.concat(args, " ", argIndex)
                    argIndex = #args + 1
                elseif not param.optional then
                    return false -- Required parameter missing
                else
                    result[param.name] = param.default or ""
                end
            else
                -- For other parameter types
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

    return result
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

    -- Parse parameters
    local params = parseParameters(commandDef, cmd, ...)
    if params == false then
        outputChatBox("SYNTAX: /" .. cmd .. " " .. (commandDef.syntax or ""), player, 255, 255, 0)
        return
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
