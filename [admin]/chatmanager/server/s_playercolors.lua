-- Chat Manager: Player Colors Integration
-- Handles randomizing and applying player nametag colors

-- Default color range (can be overridden in settings)
local defaultLowerBound = 50
local defaultUpperBound = 255

-- Function to get color range from settings
local function getColorRange()
    local lowerBound = tonumber(getSettingValue("player_color_min")) or defaultLowerBound
    local upperBound = tonumber(getSettingValue("player_color_max")) or defaultUpperBound
    return lowerBound, upperBound
end

-- Function to randomize a player's color
function randomizePlayerColor(player)
    if not isElement(player) or getElementType(player) ~= "player" then return false end

    -- Get color range from settings
    local lowerBound, upperBound = getColorRange()

    -- Debug to ensure we're using the correct bounds
    outputDebugString("PlayerColors: Using color range " .. lowerBound .. "-" .. upperBound ..
                     " (player_color_min/max from settings)")

    -- Generate random RGB values
    local r = math.random(lowerBound, upperBound)
    local g = math.random(lowerBound, upperBound)
    local b = math.random(lowerBound, upperBound)

    -- Set the player's nametag color
    setPlayerNametagColor(player, r, g, b)

    -- Store the color for reference
    setElementData(player, "chatmanager.playercolor", {r, g, b})

    -- Debug message
    outputDebugString("PlayerColors: Set " .. getPlayerName(player) .. " color to RGB(" .. r .. "," .. g .. "," .. b .. ")")

    return true
end

-- New function: Get a random color for a chat message
-- This doesn't change the player's actual nametag, just returns a color
function getRandomChatColor()
    -- Get color range from settings
    local lowerBound, upperBound = getColorRange()

    -- Generate random RGB values
    local r = math.random(lowerBound, upperBound)
    local g = math.random(lowerBound, upperBound)
    local b = math.random(lowerBound, upperBound)

    return r, g, b
end

-- Map to store the last chat message color for each player
local playerChatColors = {}

-- Function to get a random chat color for a player
function getChatColorForPlayer(player)
    if not isElement(player) then
        return 255, 255, 255 -- Default white
    end

    -- Check if playercolors is enabled
    if not getSettingValue("use_player_colors") then
        -- When disabled, use the actual nametag color
        return getPlayerNametagColor(player)
    end

    -- Get color range from settings for consistency
    local lowerBound, upperBound = getColorRange()

    -- Generate a new random color for this chat message
    local r = math.random(lowerBound, upperBound)
    local g = math.random(lowerBound, upperBound)
    local b = math.random(lowerBound, upperBound)

    -- Store this color as the player's current chat color
    playerChatColors[player] = {r = r, g = g, b = b}

    return r, g, b
end

-- Cleanup when a player quits
addEventHandler("onPlayerQuit", root, function()
    playerChatColors[source] = nil
end)

-- Cleanup when resource stops
addEventHandler("onResourceStop", resourceRoot, function()
    playerChatColors = {}
end)

-- Function to randomize colors for all players
function randomizeAllPlayerColors()
    for _, player in ipairs(getElementsByType("player")) do
        randomizePlayerColor(player)
    end
    return true
end

-- Function to reset a player's color to default (white)
function resetPlayerColor(player)
    if not isElement(player) or getElementType(player) ~= "player" then return false end

    -- Set to default white (false resets to default)
    setPlayerNametagColor(player, false)

    -- Clear stored color data
    setElementData(player, "chatmanager.playercolor", nil)

    return true
end

-- Function to reset all player colors to default
function resetAllPlayerColors()
    for _, player in ipairs(getElementsByType("player")) do
        resetPlayerColor(player)
    end
    return true
end

-- Event handler for when a player joins
addEventHandler("onPlayerJoin", root, function()
    -- Only apply random color if player colors feature is enabled
    if getSettingValue("use_player_colors") then
        randomizePlayerColor(source)
    end
end)

-- Event handler for map start (mapmanager resets player colors on map change)
addEventHandler("onGamemodeMapStart", root, function()
    -- Only reapply random colors if player colors feature is enabled
    if getSettingValue("use_player_colors") then
        randomizeAllPlayerColors()
    end
end)

-- Export functions for API access
_G.randomizePlayerColor = randomizePlayerColor
_G.randomizeAllPlayerColors = randomizeAllPlayerColors
_G.resetPlayerColor = resetPlayerColor
_G.resetAllPlayerColors = resetAllPlayerColors
_G.getRandomChatColor = getRandomChatColor
_G.getChatColorForPlayer = getChatColorForPlayer
