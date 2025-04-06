-- Chat Manager: Shared settings and utility functions

-- Default settings if not defined in meta.xml
local defaultSettings = {
    use_nametag_colors = true,
    use_team_colors = true,
    team_colors_override = true,
    chat_message_delay = 1000,
    block_repeated_messages = true,
    strip_color_codes = true,
    admin_bypass_spam = true,

    -- Player colors settings (default off)
    use_player_colors = false,
    player_color_min = 50,
    player_color_max = 255,
    player_colors_override_team = false,
    player_colors_dynamic = false
}

-- Default color settings for different message types
local defaultMessageColors = {
    normal = {255, 255, 255},    -- White for normal chat
    team = {0, 255, 0},          -- Green for team chat
    admin = {255, 0, 0},         -- Red for admin messages
    system = {255, 255, 255},    -- White for system messages
    private_from = {255, 255, 0},-- Yellow for incoming PMs
    private_to = {255, 255, 0},  -- Yellow for outgoing PMs
    objective = {0, 255, 0},     -- Green for objectives
    warning = {255, 165, 0},     -- Orange for warnings
    announcement = {255, 165, 0},-- Orange for announcements
    tag_normal = {255, 255, 255},-- Tags/labels color for normal
    tag_pm = {255, 255, 0},      -- Tags color for PMs
    tag_system = {255, 255, 255},-- Tags color for system messages
    tag_admin = {255, 0, 0}      -- Tags color for admin messages
}

-- Cache for settings to avoid repeated calls to get setting
local settingsCache = {}

-- Clear cached settings
function clearSettingsCache()
    settingsCache = {}
end

-- Function to get a setting value
function getSettingValue(settingName)
    -- Check if we have this value cached
    if settingsCache[settingName] ~= nil then
        return settingsCache[settingName]
    end

    -- Try to get the setting from meta.xml
    local resourceName = getResourceName(getThisResource())
    local settingValue = get(resourceName .. "." .. settingName)

    -- If setting doesn't exist, use default
    if settingValue == nil then
        settingValue = defaultSettings[settingName]
    elseif type(defaultSettings[settingName]) == "boolean" then
        settingValue = settingValue == "true"
    elseif type(defaultSettings[settingName]) == "number" then
        settingValue = tonumber(settingValue) or defaultSettings[settingName]
    end

    -- Cache the result
    settingsCache[settingName] = settingValue

    return settingValue
end

-- Function to set a setting value (for admin commands)
function setSettingValue(settingName, value)
    -- Update cache
    settingsCache[settingName] = value

    -- Try to update in meta.xml if possible
    local resourceName = getResourceName(getThisResource())
    local settingKey = resourceName .. "." .. settingName

    -- If setting change fails, we still keep it in cache
    if not set(settingKey, tostring(value)) then
        outputDebugString("Warning: Couldn't save setting " .. settingName .. " to meta.xml", 2)
    end

    return true
end

-- Function to get message color by type
function getMessageColor(messageType, isTag)
    local tagPrefix = isTag and "tag_" or ""
    local colorKey = tagPrefix .. messageType

    -- Check for overridden settings in meta.xml first
    local resourceName = getResourceName(getThisResource())
    local r = tonumber(get(resourceName .. ".color_" .. colorKey .. "_r"))
    local g = tonumber(get(resourceName .. ".color_" .. colorKey .. "_g"))
    local b = tonumber(get(resourceName .. ".color_" .. colorKey .. "_b"))

    -- Use defaults if not specified in meta.xml
    if not (r and g and b) then
        local defaultColor = defaultMessageColors[colorKey] or defaultMessageColors.normal
        r, g, b = defaultColor[1], defaultColor[2], defaultColor[3]
    end

    return r, g, b
end

-- Function to get color as hex string for chat
function getColorHex(messageType, isTag)
    local r, g, b = getMessageColor(messageType, isTag)
    return string.format("#%.2X%.2X%.2X", r, g, b)
end

-- Function to strip color codes from messages
function stripColorCodes(message)
    if not message then return "" end

    -- Remove MTA color codes (#RRGGBB)
    message = message:gsub("#%x%x%x%x%x%x", "")

    -- Remove legacy color codes (^R, ^G, ^B, etc.)
    message = message:gsub("%^%a", "")

    return message
end

-- Text filtering system
local defaultFilterWords = {
    -- Common profanity list (abbreviated for code example)
    "badword1", "badword2", "badword3",
    -- Add more default filtered words here
}

local customFilterWords = {}

-- Function to check if text contains filtered words
function containsFilteredWord(text)
    if not text or text == "" then return false end

    -- Convert to lowercase for case-insensitive matching
    text = string.lower(text)

    -- Check default filter words
    for _, word in ipairs(defaultFilterWords) do
        if string.find(text, "%f[%a]" .. word .. "%f[%A]") then
            return true, word
        end
    end

    -- Check custom filter words
    for _, word in ipairs(customFilterWords) do
        if string.find(text, "%f[%a]" .. word .. "%f[%A]") then
            return true, word
        end
    end

    return false
end

-- Function to filter text (replace filtered words with asterisks)
function filterText(text)
    if not text or text == "" then return text end

    local filtered = text
    local textLower = string.lower(text)

    -- Process default filter words
    for _, word in ipairs(defaultFilterWords) do
        local pattern = "%f[%a](" .. word .. ")%f[%A]"
        local replacement = string.rep("*", string.len(word))
        filtered = string.gsub(filtered, pattern, replacement)
    end

    -- Process custom filter words
    for _, word in ipairs(customFilterWords) do
        local pattern = "%f[%a](" .. word .. ")%f[%A]"
        local replacement = string.rep("*", string.len(word))
        filtered = string.gsub(filtered, pattern, replacement)
    end

    return filtered
end

-- Function to detect filter bypass attempts
function detectFilterBypass(text)
    if not text or text == "" then return false end

    -- Convert to lowercase
    text = string.lower(text)

    -- Check for common bypass techniques
    -- 1. Character substitution (e.g., @ for a, 0 for o)
    local substitutionMap = {
        ["@"] = "a", ["4"] = "a", ["8"] = "b", ["("] = "c", ["3"] = "e",
        ["6"] = "g", ["1"] = "i", ["!"] = "i", ["0"] = "o", ["5"] = "s",
        ["$"] = "s", ["7"] = "t", ["+"] = "t", ["2"] = "z"
    }

    local normalizedText = text
    for symbol, letter in pairs(substitutionMap) do
        normalizedText = normalizedText:gsub(symbol, letter)
    end

    -- 2. Check if normalized text contains any filtered words
    local containsFiltered, word = containsFilteredWord(normalizedText)
    if containsFiltered then
        return true, word
    end

    -- 3. Check for deliberate spacing (e.g., "b a d w o r d")
    local noSpaceText = normalizedText:gsub("%s+", "")
    containsFiltered, word = containsFilteredWord(noSpaceText)
    if containsFiltered then
        return true, word
    end

    return false
end

-- Add or remove words from the custom filter
function updateCustomFilter(word, remove)
    if not word or word == "" then return false end

    word = string.lower(word)

    if remove then
        for i, existingWord in ipairs(customFilterWords) do
            if existingWord == word then
                table.remove(customFilterWords, i)
                return true
            end
        end
        return false
    else
        -- Check if word already exists in filter
        for _, existingWord in ipairs(customFilterWords) do
            if existingWord == word then
                return false
            end
        end

        table.insert(customFilterWords, word)
        return true
    end
end

-- Get list of custom filter words for admin display
function getFilterWordList()
    return customFilterWords
end

-- Reload the chat filter (could load from external source in the future)
function reloadChatFilter()
    -- For now, just clear the custom words and return true
    customFilterWords = {}
    return true
end

-- Make these functions accessible to other files in the resource
_G.internalFilterText = filterText
_G.internalUpdateCustomFilter = updateCustomFilter
_G.internalGetFilterWordList = getFilterWordList
_G.internalReloadChatFilter = reloadChatFilter

-- Clear settings cache when resource starts or settings change
function clearSettingsCache()
    settingsCache = {}
end

-- Set up event handlers
if triggerServerEvent then
    -- Client-side
    addEventHandler("onClientResourceStart", resourceRoot, clearSettingsCache)
else
    -- Server-side
    addEventHandler("onResourceStart", resourceRoot, clearSettingsCache)

    -- Refresh settings if they change
    addEventHandler("onSettingChange", root, function(setting)
        local resourceName = getResourceName(getThisResource())
        if string.find(setting, resourceName .. ".") then
            clearSettingsCache()
        end
    end)
end
