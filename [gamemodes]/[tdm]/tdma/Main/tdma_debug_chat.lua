--[[
    TDMA Chat Debug - Enhanced
    This file helps identify where chat message duplication occurs
]]

-- Enhanced debugging with message tracking
local processedMessages = {}
local messageCounter = 0
local debugEnabled = true

-- Helper function to get timestamp
local function getTimeString()
    return string.format("[%d]", getTickCount())
end

-- Helper to get calling resource
local function getCallingResource()
    local resource = sourceResource or getThisResource()
    return getResourceName(resource) or "unknown"
end

-- Function to generate a unique message ID
local function getMessageId(player, message)
    -- Create a unique ID based on player, message and timestamp
    local playerId = getPlayerName(player)
    local timestamp = getTickCount()
    return playerId .. "_" .. message .. "_" .. timestamp
end

-- Log full details of an event handler
local function describeHandler(handler)
    if type(handler) ~= "function" then
        return tostring(handler)
    end

    local info = debug.getinfo(handler)
    local resource = "unknown"

    if info then
        resource = info.short_src or "unknown_src"
        local funcName = info.name or "anonymous"
        return string.format("Function: %s (%s:%d)", funcName, resource, info.linedefined)
    end

    return tostring(handler)
end

-- Get and log all event handlers for onPlayerChat
function logAllChatHandlers()
    outputDebugString("TDMA DEBUG: === CHAT HANDLERS LIST " .. getTimeString() .. " ===")

    local allHandlers = getEventHandlers("onPlayerChat", root)
    outputDebugString("TDMA DEBUG: Found " .. #allHandlers .. " handlers for onPlayerChat event")

    for i, handler in ipairs(allHandlers) do
        outputDebugString("TDMA DEBUG: Handler #" .. i .. " - " .. describeHandler(handler))
    end

    -- Also check for team chat handlers
    local teamChatHandlers = getEventHandlers("onPlayerTeamChat", root)
    outputDebugString("TDMA DEBUG: Found " .. #teamChatHandlers .. " handlers for onPlayerTeamChat event")

    outputDebugString("TDMA DEBUG: === END OF HANDLERS LIST ===")
end

-- Debug chat event handler with THREE DIFFERENT PRIORITIES to track when duplication happens
addEventHandler("onPlayerChat", root, function(message, messageType)
    if not debugEnabled then return end

    local msgId = getMessageId(source, message)
    outputDebugString("TDMA DEBUG: [HIGH PRIORITY] onPlayerChat triggered - Source: " .. getPlayerName(source) .. ", Message: " .. message .. ", ID: " .. msgId, 3)
end, true, "high")

addEventHandler("onPlayerChat", root, function(message, messageType)
    if not debugEnabled then return end

    local msgId = getMessageId(source, message)
    outputDebugString("TDMA DEBUG: [NORMAL PRIORITY] onPlayerChat triggered - Source: " .. getPlayerName(source) .. ", Message: " .. message .. ", ID: " .. msgId, 3)

    -- Track this message
    if not processedMessages[msgId] then
        processedMessages[msgId] = 1
    else
        processedMessages[msgId] = processedMessages[msgId] + 1
        outputDebugString("TDMA DEBUG: DUPLICATION DETECTED! Message '" .. message .. "' processed " .. processedMessages[msgId] .. " times", 1)
    end

    -- Check which resources are currently running
    outputDebugString("TDMA DEBUG: ChatManager running: " .. tostring(getResourceFromName("chatmanager") and getResourceState(getResourceFromName("chatmanager")) == "running"))
    outputDebugString("TDMA DEBUG: TDMA running: " .. tostring(getResourceFromName("tdma") and getResourceState(getResourceFromName("tdma")) == "running"))
    outputDebugString("TDMA DEBUG: Called from resource: " .. getCallingResource())

    -- Cleanup older messages to prevent memory leak
    messageCounter = messageCounter + 1
    if messageCounter > 100 then
        processedMessages = {}
        messageCounter = 0
        outputDebugString("TDMA DEBUG: Cleared message tracking cache")
    end
end)

addEventHandler("onPlayerChat", root, function(message, messageType)
    if not debugEnabled then return end

    local msgId = getMessageId(source, message)
    outputDebugString("TDMA DEBUG: [LOW PRIORITY] onPlayerChat triggered - Source: " .. getPlayerName(source) .. ", Message: " .. message .. ", ID: " .. msgId, 3)
end, true, "low")

-- Debug for outputChatBox calls to track if messages are being displayed multiple times
local originalOutputChatBox = outputChatBox
_G.outputChatBox = function(text, ...)
    -- Call original function
    originalOutputChatBox(text, ...)

    if not debugEnabled then return end

    -- Debug info about this outputChatBox call
    local threadInfo = debug.getinfo(2)
    local source = threadInfo.source or "unknown"
    local line = threadInfo.currentline or 0

    outputDebugString("TDMA DEBUG: outputChatBox called from " .. source .. ":" .. line .. " with text: " .. tostring(text), 3)
end

-- Log handlers on resource start
addEventHandler("onResourceStart", resourceRoot, function()
    outputDebugString("TDMA DEBUG: Resource started - checking chat handlers")
    setTimer(logAllChatHandlers, 1000, 1)

    -- Also store original functions for monitoring
    outputDebugString("TDMA DEBUG: Setting up function monitoring")
end)

-- Add command to toggle debug
addCommandHandler("togglechatdebug", function()
    debugEnabled = not debugEnabled
    outputChatBox("Chat debugging " .. (debugEnabled and "enabled" or "disabled"))
    outputDebugString("TDMA DEBUG: Debug " .. (debugEnabled and "enabled" or "disabled"))
end)

-- Add command to check handlers at runtime
addCommandHandler("checkchathandlers", function()
    outputDebugString("TDMA DEBUG: Checking chat handlers via command")
    logAllChatHandlers()
end)

-- Monitor chat manager status changes
if getResourceFromName("chatmanager") then
    -- Check status when this resource loads
    local status = getResourceState(getResourceFromName("chatmanager"))
    outputDebugString("TDMA DEBUG: ChatManager status on debug load: " .. status)

    -- Watch for status changes
    addEventHandler("onResourceStart", root, function(res)
        if getResourceName(res) == "chatmanager" then
            outputDebugString("TDMA DEBUG: ChatManager started")
            setTimer(logAllChatHandlers, 500, 1)
        end
    end)

    addEventHandler("onResourceStop", root, function(res)
        if getResourceName(res) == "chatmanager" then
            outputDebugString("TDMA DEBUG: ChatManager stopped")
            setTimer(logAllChatHandlers, 500, 1)
        end
    end)
end

-- Log when a resource changes event handlers
local originalAddEventHandler = addEventHandler
_G.addEventHandler = function(eventName, attachedTo, handlerFunction, ...)
    originalAddEventHandler(eventName, attachedTo, handlerFunction, ...)

    if not debugEnabled then return end

    if eventName == "onPlayerChat" then
        local info = debug.getinfo(2)
        local resource = info.source or "unknown"
        outputDebugString("TDMA DEBUG: addEventHandler for onPlayerChat called from " .. resource)

        -- Log the new state of handlers
        setTimer(logAllChatHandlers, 50, 1)
    end
end

local originalRemoveEventHandler = removeEventHandler
_G.removeEventHandler = function(eventName, attachedTo, handlerFunction, ...)
    originalRemoveEventHandler(eventName, attachedTo, handlerFunction, ...)

    if not debugEnabled then return end

    if eventName == "onPlayerChat" then
        local info = debug.getinfo(2)
        local resource = info.source or "unknown"
        outputDebugString("TDMA DEBUG: removeEventHandler for onPlayerChat called from " .. resource)

        -- Log the new state of handlers
        setTimer(logAllChatHandlers, 50, 1)
    end
end

-- Call logAllChatHandlers now to see the initial state
logAllChatHandlers()
outputDebugString("TDMA DEBUG: Enhanced debug system loaded")
