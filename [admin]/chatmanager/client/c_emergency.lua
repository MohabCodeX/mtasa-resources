-- Chat Manager: Emergency Tracking System
-- Handles displaying emergency blips on admin maps

-- Table to track active emergency blips
local emergencyBlips = {}

-- Track if a notification has been shown for an emergency ID to prevent duplicates
local shownNotifications = {}
-- Store location info for emergency calls to use in expiration messages
local emergencyLocations = {}

-- Blip settings
local blipSettings = {
    icon = 41, -- Red marker
    size = 2,
    color = {255, 0, 0}
}

-- Debug function to output messages with timestamp
local function debugOutput(message)
    local timestamp = string.format("[%s]", tostring(getTickCount()))
    outputDebugString("Emergency System " .. timestamp .. ": " .. tostring(message))
end

-- Create a fallback function for blip tooltips if the function doesn't exist
if not setBlipTooltip then
    function setBlipTooltip(blip, text)
        -- Store tooltip text as element data if the function doesn't exist natively
        if isElement(blip) then
            setElementData(blip, "emergencyTooltip", text, false)
            debugOutput("Using fallback tooltip method for blip")
            return true
        end
        return false
    end

    -- Also add a function to get the tooltip data
    function getBlipTooltip(blip)
        if isElement(blip) then
            return getElementData(blip, "emergencyTooltip") or ""
        end
        return ""
    end
end

-- Emergency notification system - simplified approach
local function notifyEmergencyStatus(emergencyId, playerName, notificationType, customMessage)
    -- Use a global notificationLock to prevent duplicates during the same frame
    if _G.notificationLock then return false end

    -- Lock notifications temporarily
    _G.notificationLock = true

    -- Clear lock after short delay
    setTimer(function() _G.notificationLock = false end, 500, 1)

    -- Process different notification types
    if notificationType == "expired" then
        -- Get location info if available
        local locationText = ""
        if emergencyLocations[emergencyId] then
            locationText = emergencyLocations[emergencyId]
        end

        -- Send notification with consistent formatting
        outputChatBox("[911 LIVE] Live tracking for " .. playerName .. " has ended.", 255, 0, 0, true)
        if locationText ~= "" then
            outputChatBox("Last Position was at: " .. locationText, 255, 165, 0, true)
        end
        return true
    elseif notificationType == "offline" then
        -- Similar handling for offline notifications
        local locationText = ""
        if emergencyLocations[emergencyId] then
            locationText = emergencyLocations[emergencyId]
        end

        outputChatBox("[911 EMERGENCY] " .. playerName .. " has disconnected. Live tracking ended.", 255, 0, 0, true)
        if locationText ~= "" then
            outputChatBox("Last known position: " .. locationText, 255, 165, 0, true)
        end
        return true
    elseif notificationType == "created" then
        outputChatBox("Emergency tracking started for " .. playerName .. ".", 255, 165, 0)
        return true
    elseif notificationType == "cleared" then
        outputChatBox("Emergency from " .. playerName .. " has been cleared.", 255, 165, 0)
        return true
    elseif customMessage then
        outputChatBox(customMessage, 255, 165, 0)
        return true
    end

    return false
end

-- Create/update a blip element
local function createBlipElement(x, y, z, isRealtime)
    local blip = createBlip(x, y, z, blipSettings.icon, blipSettings.size,
                           blipSettings.color[1], blipSettings.color[2], blipSettings.color[3], 255)

    if not blip then
        debugOutput("FAILED to create blip element")
        return nil
    end

    return blip
end

-- Clean up a specific emergency blip
local function cleanupEmergencyBlip(blipData)
    debugOutput("Cleaning up emergency blip...")

    if blipData then
        -- Destroy the blip element
        if isElement(blipData.blip) then
            debugOutput("Destroying blip element")
            destroyElement(blipData.blip)
        else
            debugOutput("Blip element is not valid - cannot destroy")
        end

        -- Cancel timer if it exists
        if blipData.timer and isTimer(blipData.timer) then
            debugOutput("Killing blip timer")
            killTimer(blipData.timer)
        else
            debugOutput("No valid timer to kill")
        end

        -- Cancel update timer if it exists
        if blipData.updateTimer and isTimer(blipData.updateTimer) then
            debugOutput("Killing update timer")
            killTimer(blipData.updateTimer)
        else
            debugOutput("No valid update timer to kill")
        end

        debugOutput("Cleanup complete")
    else
        debugOutput("No blip data provided for cleanup")
    end
end

-- Clean up all emergency blips
local function cleanupAllEmergencyBlips()
    debugOutput("Cleaning up ALL emergency blips...")
    local count = 0
    for id, blipData in pairs(emergencyBlips) do
        count = count + 1
        cleanupEmergencyBlip(blipData)
        emergencyBlips[id] = nil
    end
    debugOutput("Cleaned up " .. count .. " blips")
    -- Also clear the notification tracking table
    shownNotifications = {}
    emergencyLocations = {}
end

-- Set up a timer to automatically expire a blip
local function setupExpirationTimer(emergencyId, duration, isRealtime)
    local expiryTime = isRealtime and (duration or 60000) or (duration or 300000)
    debugOutput("Setting expiration timer for " .. (expiryTime/1000) .. " seconds")

    local timerFunc = function()
        if not emergencyBlips[emergencyId] then return end

        debugOutput((isRealtime and "REALTIME" or "STATIC") .. " EXPIRATION TIMER TRIGGERED for blip #" .. tostring(emergencyId))

        if isRealtime then
            -- Handle realtime expiration
            if isElement(emergencyBlips[emergencyId].blip) then
                local playerElement = emergencyBlips[emergencyId].senderElement
                local playerName = emergencyBlips[emergencyId].sender

                -- Get last position and store location info for notification
                local px, py, pz
                if isElement(playerElement) then
                    px, py, pz = getElementPosition(playerElement)
                    -- Store formatted location for notification
                    local zoneName = getZoneName(px, py, pz) or "Unknown"
                    emergencyLocations[emergencyId] = zoneName .. " (" .. math.floor(px) .. ", " .. math.floor(py) .. ", " .. math.floor(pz) .. ")"
                else
                    px, py, pz = getElementPosition(emergencyBlips[emergencyId].blip)
                end

                -- Remove the realtime blip completely
                cleanupEmergencyBlip(emergencyBlips[emergencyId])
                emergencyBlips[emergencyId] = nil

                -- No need to create a static replacement blip
                -- Just notify admin about expiration with location
                notifyEmergencyStatus(emergencyId, playerName, "expired")
            end
        else
            -- Handle static expiration - just remove it
            if emergencyBlips[emergencyId] and isElement(emergencyBlips[emergencyId].blip) then
                destroyElement(emergencyBlips[emergencyId].blip)
                emergencyBlips[emergencyId] = nil
                debugOutput("Static blip removed from tracking")
            end
        end
    end

    return setTimer(timerFunc, expiryTime, 1)
end

-- Set up a timer to update position of a realtime blip
local function setupPositionUpdateTimer(emergencyId, playerElement, blip, updateInterval)
    local interval = updateInterval or 1000 -- Default to 1 second updates

    local updateFunc = function()
        if not isElement(playerElement) then
            -- Player left the server
            debugOutput("PLAYER ELEMENT INVALID - player left server")

            -- Get last position and store for notification
            local lastX, lastY, lastZ = getElementPosition(blip)
            local playerName = emergencyBlips[emergencyId].sender

            -- Store formatted location for notification
            local zoneName = getZoneName(lastX, lastY, lastZ) or "Unknown"
            emergencyLocations[emergencyId] = zoneName .. " (" .. math.floor(lastX) .. ", " .. math.floor(lastY) .. ", " .. math.floor(lastZ) .. ")"

            -- Clean up realtime blip
            cleanupEmergencyBlip(emergencyBlips[emergencyId])
            emergencyBlips[emergencyId] = nil

            -- No need for static replacement anymore
            -- Just notify about player leaving with location
            notifyEmergencyStatus(emergencyId, playerName, "offline")
            return
        end

        -- Update position
        local px, py, pz = getElementPosition(playerElement)
        setElementPosition(blip, px, py, pz)
    end

    return setTimer(updateFunc, interval, 0) -- 0 = infinite repetitions
end

-- Create a static emergency blip
function createStaticEmergencyBlip(emergencyId, playerName, x, y, z)
    debugOutput("Creating STATIC emergency blip #" .. tostring(emergencyId) .. " for " .. playerName)
    debugOutput("Position: " .. x .. ", " .. y .. ", " .. z)

    -- Clean up any existing blip with the same ID
    if emergencyBlips[emergencyId] then
        debugOutput("Found existing blip with same ID - cleaning up first")
        cleanupEmergencyBlip(emergencyBlips[emergencyId])
    end

    -- Create the blip element
    local blip = createBlipElement(x, y, z, false)
    if not blip then return false end

    -- Set up expiration timer
    local timer = setupExpirationTimer(emergencyId, 5000, false) -- 5 seconds for testing (change to 300000 for 5 minutes)

    -- Store the blip data
    emergencyBlips[emergencyId] = {
        blip = blip,
        timer = timer,
        type = "static",
        sender = playerName
    }

    debugOutput("Stored blip data in tracking table")

    -- Set blip tooltip
    setBlipTooltip(blip, "911 Emergency: " .. playerName)
    debugOutput("Static blip setup complete")

    return true
end

-- Create a real-time emergency blip that follows the player
function createRealtimeEmergencyBlip(emergencyId, playerElement, playerName)
    debugOutput("Creating REALTIME emergency blip #" .. tostring(emergencyId) .. " for " .. playerName)

    -- Clean up any existing blip with the same ID
    if emergencyBlips[emergencyId] then
        debugOutput("Found existing blip with same ID - cleaning up first")
        cleanupEmergencyBlip(emergencyBlips[emergencyId])
    end

    -- Check player element validity
    if not isElement(playerElement) then
        debugOutput("ERROR: Player element is invalid")
        return false
    end

    -- Get initial position and store location info for later notifications
    local x, y, z = getElementPosition(playerElement)
    local zoneName = getZoneName(x, y, z) or "Unknown"
    emergencyLocations[emergencyId] = zoneName .. " (" .. math.floor(x) .. ", " .. math.floor(y) .. ", " .. math.floor(z) .. ")"

    debugOutput("Initial position: " .. x .. ", " .. y .. ", " .. z)
    debugOutput("Stored location info: " .. emergencyLocations[emergencyId])

    -- Create the blip element
    local blip = createBlipElement(x, y, z, true)
    if not blip then return false end

    -- Set up timers
    local updateTimer = setupPositionUpdateTimer(emergencyId, playerElement, blip, 1000)
    local expirationTimer = setupExpirationTimer(emergencyId, 10000, true) -- 10 seconds for testing (change to 60000 for 1 minute)

    -- Store the blip data
    emergencyBlips[emergencyId] = {
        blip = blip,
        timer = expirationTimer,
        updateTimer = updateTimer,
        type = "realtime",
        sender = playerName,
        senderElement = playerElement
    }

    debugOutput("Stored realtime blip data in tracking table")

    -- Set blip tooltip
    setBlipTooltip(blip, "LIVE 911 Emergency: " .. playerName .. " (expires in 1 min)")
    debugOutput("Realtime blip setup complete")

    return true
end

-- Process a new emergency tracking request
local function processEmergencyTracking(emergencyId, trackingType, playerElement, playerName, x, y, z)
    debugOutput("Processing emergency tracking request - ID: " .. tostring(emergencyId) .. ", Type: " .. trackingType)

    -- Reset notification status for this emergency ID only if it's a new emergency
    if not shownNotifications[emergencyId] then
        shownNotifications[emergencyId] = {}
    else
        -- If we already have this emergency ID, it might be a duplicate event trigger
        -- We'll leave existing notification records but allow creation of the new blip
        debugOutput("Warning: Emergency ID already exists - might be duplicate event trigger")
    end

    -- Create appropriate blip type
    local result
    if trackingType == "realtime" then
        result = createRealtimeEmergencyBlip(emergencyId, playerElement, playerName)
    else
        result = createStaticEmergencyBlip(emergencyId, playerName, x, y, z)
    end

    -- Notify admin about new emergency if successful
    if result then
        notifyEmergencyStatus(emergencyId, playerName, "created")
    end

    return result
end

-- Clear a specific emergency blip
local function clearEmergencyBlip(emergencyId)
    debugOutput("Attempting to clear emergency #" .. tostring(emergencyId))

    if not emergencyBlips[emergencyId] then
        debugOutput("Could not find emergency with ID #" .. emergencyId)
        return false, "Emergency ID not found"
    end

    local senderName = emergencyBlips[emergencyId].sender
    debugOutput("Found emergency #" .. emergencyId .. " from " .. senderName .. " - clearing")

    cleanupEmergencyBlip(emergencyBlips[emergencyId])
    emergencyBlips[emergencyId] = nil

    notifyEmergencyStatus(emergencyId, senderName, "cleared")

    return true, "Emergency cleared"
end

-- Get list of all active emergencies
local function listActiveEmergencies()
    local emergencyList = {}
    local count = 0

    for id, data in pairs(emergencyBlips) do
        table.insert(emergencyList, {
            id = id,
            sender = data.sender,
            type = data.type
        })
        count = count + 1
    end

    return emergencyList, count
end

-- Event handler for creating emergency blips
addEvent("chatmanager:createEmergencyBlip", true)
addEventHandler("chatmanager:createEmergencyBlip", root, function(emergencyId, trackingType, playerElement, playerName, x, y, z)
    -- Simple deduplication using hash of parameters
    local requestHash = tostring(emergencyId) .. trackingType .. tostring(x) .. tostring(y) .. tostring(z)

    -- Check if this exact request was recently processed (in the last 2 seconds)
    if _G.lastEmergencyHash == requestHash and getTickCount() - (_G.lastEmergencyTime or 0) < 2000 then
        debugOutput("Duplicate emergency request detected and ignored")
        return
    end

    -- Store current request details
    _G.lastEmergencyHash = requestHash
    _G.lastEmergencyTime = getTickCount()

    -- Process the request
    processEmergencyTracking(emergencyId, trackingType, playerElement, playerName, x, y, z)
end)

-- Provide a command to remove a specific emergency blip
addCommandHandler("clearemergency", function(cmd, emergencyId)
    debugOutput("COMMAND: clearemergency " .. tostring(emergencyId or "no ID provided"))

    -- Check if player has admin rights
    if not hasObjectPermissionTo(localPlayer, "command.mute", false) then
        outputChatBox("You don't have permission to clear emergency markers.", 255, 0, 0)
        debugOutput("Permission denied - not an admin")
        return
    end

    if not emergencyId then
        -- List all active emergencies
        debugOutput("No ID provided - listing all active emergencies")
        outputChatBox("Active emergencies:", 255, 165, 0)

        local emergencyList, count = listActiveEmergencies()

        if count == 0 then
            outputChatBox("No active emergencies.", 255, 165, 0)
            debugOutput("No active emergencies to list")
        else
            for _, emergency in ipairs(emergencyList) do
                outputChatBox("ID: " .. emergency.id .. " - " .. emergency.sender .. " (" .. emergency.type .. ")", 255, 165, 0)
            end

            outputChatBox("Use /clearemergency [id] to clear a specific emergency.", 255, 165, 0)
            outputChatBox("Use /clearallemergencies to clear all emergencies.", 255, 165, 0)
            debugOutput("Listed " .. count .. " active emergencies")
        end
        return
    end

    emergencyId = tonumber(emergencyId)
    local success, message = clearEmergencyBlip(emergencyId)

    if success then
        outputChatBox(message, 0, 255, 0)
        debugOutput("Successfully cleared emergency")
    else
        outputChatBox(message, 255, 0, 0)
        debugOutput("Failed to clear emergency: " .. message)
    end
end)

-- Provide a command to clear all emergency blips
addCommandHandler("clearallemergencies", function()
    debugOutput("COMMAND: clearallemergencies")

    -- Check if player has admin rights
    if not hasObjectPermissionTo(localPlayer, "command.mute", false) then
        outputChatBox("You don't have permission to clear emergency markers.", 255, 0, 0)
        debugOutput("Permission denied - not an admin")
        return
    end

    local _, count = listActiveEmergencies()

    debugOutput("Clearing all emergencies (" .. count .. " found)")
    cleanupAllEmergencyBlips()

    if count > 0 then
        outputChatBox("Cleared " .. count .. " emergency markers.", 0, 255, 0)
        debugOutput("Successfully cleared all emergencies")
    else
        outputChatBox("No active emergencies to clear.", 255, 165, 0)
        debugOutput("No emergencies to clear")
    end
end)

-- Clean up on resource stop
addEventHandler("onClientResourceStop", resourceRoot, function()
    debugOutput("RESOURCE STOPPING - cleaning up all emergencies")
    cleanupAllEmergencyBlips()
end)

-- Initialize on resource start
addEventHandler("onClientResourceStart", resourceRoot, function()
    debugOutput("RESOURCE STARTED - emergency system initialized")
    shownNotifications = {}
    emergencyLocations = {}

    -- Make sure we clean up any orphaned events
    addEventHandler("onClientPlayerQuit", root, function(reason)
        debugOutput("Player quit: " .. getPlayerName(source) .. ", reason: " .. reason)

        -- Find any emergencies tied to this player and clean them up
        for id, data in pairs(emergencyBlips) do
            if data.senderElement == source then
                debugOutput("Found emergency for disconnected player: " .. id)

                -- Convert to static
                local lastX, lastY, lastZ = getElementPosition(data.blip)
                local playerName = data.sender

                -- Clean up the realtime blip
                cleanupEmergencyBlip(data)
                emergencyBlips[id] = nil

                -- No need to create a static replacement, just notify
                local zoneName = getZoneName(lastX, lastY, lastZ) or "Unknown"
                emergencyLocations[id] = zoneName .. " (" .. math.floor(lastX) .. ", " .. math.floor(lastY) .. ", " .. math.floor(lastZ) .. ")"

                notifyEmergencyStatus(id, playerName, "offline")
            end
        end
    end)
end)
