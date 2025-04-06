# Voice & Chat Manager Integration Guide

This document outlines how to implement voice chat integration with ChatManager, specifically allowing you to check if players are voice-muted and potentially block their messages accordingly.

## Overview

The voice resource provides several functions that can be used to check if a player is muted. With our new simplified ChatManager implementation, integrating voice features is even easier:

- Block text messages from voice-muted players
- Show visual indicators for muted players in chat
- Use chat commands to manage voice settings

## Required Components

1. Access to voice resource functions
2. Basic voice status checking

## Implementation Approach

### 1. Checking Mute Status in ChatManager

ChatManager now includes a simple voice mute check:

```lua
-- In ChatManager's s_chat.lua
local function isVoiceMuted(player)
    -- Check if voice resource exists and is running
    if getResourceFromName("voice") and getResourceState(getResourceFromName("voice")) == "running" then
        return exports.voice:isPlayerVoiceMuted(player)
    end

    -- Fallback to element data check
    return getElementData(player, "voice.muted") == true
end

-- Use in message handling
if isVoiceMuted(player) then
    outputChatBox("Your message was not sent because you are voice-muted.", player, 255, 0, 0)
    return false
end
```

### 2. Adding Visual Indicators for Muted Players

```lua
-- In message formatting function
local function formatChatMessage(player, message)
    local playerName = getPlayerName(player)
    local team = getPlayerTeam(player)
    local r, g, b = 255, 100, 100 -- Default FF6464 color for non-teamed players

    if team then
        r, g, b = getTeamColor(team)
    end

    -- Add muted indicator
    if isVoiceMuted(player) then
        playerName = playerName .. " [MUTED]"
    end

    return string.format("#%.2X%.2X%.2X%s:#FFFFFF %s", r, g, b, playerName, message)
}
```

### 3. Mute Level System

```lua
function setPlayerMuteLevel(player, level)
    if level == 1 then -- Voice mute only
        exports.voice:setPlayerVoiceMuted(player, true)
        setElementData(player, "chatmanager.chatMuted", false)
    elseif level == 2 then -- Chat mute only
        exports.voice:setPlayerVoiceMuted(player, false)
        setElementData(player, "chatmanager.chatMuted", true)
    elseif level == 3 then -- Full mute
        exports.voice:setPlayerVoiceMuted(player, true)
        setElementData(player, "chatmanager.chatMuted", true)
    else -- No mute
        exports.voice:setPlayerVoiceMuted(player, false)
        setElementData(player, "chatmanager.chatMuted", false)
    end
end
```

## Example Use Cases

1. **Admin Moderation**: Allow admins to mute disruptive players in both voice and text
2. **Anti-Spam**: Automatically mute players who spam chat or voice
3. **Team Communication**: Block messages from enemy team when using team chat
4. **Channel-based Communication**: Only allow chat between players in the same voice channel

## Compatibility with New ChatManager Implementation

Our new streamlined ChatManager makes voice integration even easier:

1. No special registration needed
2. Works automatically with all gamemodes
3. Mute status displayed consistently for everyone
4. Simple implementation with direct voice exports
5. Consistent team chat appearance with colored "(TEAM)" tag

## Performance Considerations

- Voice status checks are lightweight and performed only when needed
- Element data can be used for quick status checks
- No resource-specific integrations means better performance overall
