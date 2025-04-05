# Voice & Chat Manager Integration Guide

This document outlines how to implement voice chat integration with a chat manager system, specifically allowing you to check if players are voice-muted and potentially block their messages accordingly.

## Overview

The voice resource provides several functions that can be used to check if a player is muted. These can be integrated with your chat manager to add features like:

- Blocking text messages from voice-muted players
- Showing visual indicators for muted players in chat
- Providing chat commands to manage voice settings

## Required Components

1. Access to voice resource functions
2. Chat event handlers to intercept messages
3. Proper permissions checking

## Implementation Approach

### 1. Checking Mute Status

To check if a player is muted, use the following exports:

```lua
-- Client-side: Check if a specific player is muted locally
local isMuted = exports.voice:isPlayerVoiceMuted(playerToCheck)

-- Server-side: Check if a player is globally muted
local isGloballyMuted = exports.voice:isPlayerVoiceMuted(playerToCheck)

-- Server-side: Get the list of players who muted a specific player
local mutedByList = exports.voice:getPlayerVoiceMutedByList(playerToCheck)
```

### 2. Chat Manager Integration

#### Intercepting Chat Messages

Add an event handler for chat messages and check mute status:

```lua
addEventHandler("onPlayerChat", root, function(message, messageType)
    -- Cancel the default event
    cancelEvent()

    -- Check if the player is muted
    if exports.voice:isPlayerVoiceMuted(source) then
        -- Option 1: Block the message completely
        outputChatBox("Your message was not sent because you are muted.", source, 255, 0, 0)
        return

        -- Option 2: Only show the message to the sender
        -- outputChatBox("You (muted): " .. message, source, 150, 150, 150)
        -- return
    end

    -- If not muted, process and display the message normally
    -- Your regular chat processing code here
end)
```

#### Adding Commands for Voice Control

Implement chat commands to control voice settings:

```lua
function mutePlayerCommand(player, cmd, targetPlayerName)
    if not targetPlayerName then
        outputChatBox("Usage: /mutevoice [playerName]", player, 255, 255, 0)
        return
    end

    local targetPlayer = getPlayerFromName(targetPlayerName)
    if not targetPlayer then
        outputChatBox("Player not found.", player, 255, 0, 0)
        return
    end

    exports.voice:setPlayerVoiceMuted(targetPlayer, true)
    outputChatBox("You muted " .. targetPlayerName, player, 255, 255, 0)
end
addCommandHandler("mutevoice", mutePlayerCommand)

-- Similar implementation for unmutevoice command
```

### 3. Advanced Implementation

#### Mute Levels

Consider implementing different levels of muting:

1. **Voice Mute Only**: Player can't speak but can send chat messages
2. **Chat Mute Only**: Player can speak but can't send chat messages
3. **Full Mute**: Player can neither speak nor send chat messages

```lua
function setPlayerMuteLevel(player, level)
    if level == 1 then -- Voice mute only
        exports.voice:setPlayerVoiceMuted(player, true)
        setElementData(player, "chatMuted", false)
    elseif level == 2 then -- Chat mute only
        exports.voice:setPlayerVoiceMuted(player, false)
        setElementData(player, "chatMuted", true)
    elseif level == 3 then -- Full mute
        exports.voice:setPlayerVoiceMuted(player, true)
        setElementData(player, "chatMuted", true)
    else -- No mute
        exports.voice:setPlayerVoiceMuted(player, false)
        setElementData(player, "chatMuted", false)
    end
end
```

#### Visual Indicators

Add visual indicators in chat for muted players:

```lua
function formatChatMessage(player, message)
    local formattedMessage = message
    local playerName = getPlayerName(player)

    if exports.voice:isPlayerVoiceMuted(player) then
        -- Add muted icon or text
        playerName = playerName .. " [MUTED]"
    end

    return playerName, formattedMessage
end
```

## Example Use Cases

1. **Admin Moderation**: Allow admins to mute disruptive players in both voice and text
2. **Anti-Spam**: Automatically mute players who spam chat or voice
3. **Team Communication**: Block messages from enemy team when using team chat
4. **Channel-based Communication**: Only allow chat between players in the same voice channel

## Compatibility Considerations

- Check if your server uses legacy voice functions and adapt accordingly
- Consider resource load order to ensure voice resource is loaded before your chat manager
- Test thoroughly to ensure voice states are preserved correctly across resource restarts

## Performance Impact

The mute status checks are relatively lightweight, but consider:

- Caching mute status for frequently checked players
- Limiting complex operations (like getting the full mute list) to when necessary
- Using element data for quick checks rather than exports when appropriate
