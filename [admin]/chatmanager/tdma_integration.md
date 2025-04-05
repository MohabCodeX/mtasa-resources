# ChatManager Resource Integration Guide

## Universal Integration Approach

ChatManager now uses a completely streamlined approach that requires no explicit resource registration or integration code.

### How It Works

1. ChatManager automatically formats messages based on player teams
2. Resources simply remove their chat handlers
3. No registration or special code needed

This approach eliminates all integration complexity and provides a zero-effort solution for all resources.

## Implementation Steps for Any Resource

### 1. Remove Chat Event Handlers

Simply comment out or remove any existing chat event handlers:

```lua
--[[
function onChat(message, messageType)
    -- Remove or comment out this function
    -- ChatManager will handle all chat processing
end
addEventHandler("onPlayerChat", root, onChat)
]]
```

### 2. (Optional) Add ChatManager as a Dependency

If you want to ensure ChatManager loads before your resource:

```xml
<meta>
    <!-- ... existing content ... -->
    <depend>chatmanager</depend>
</meta>
```

## TDMA-Specific Implementation

For the TDMA gamemode, we identified and resolved these issues:

1. **Duplicate Event Handling**: Removed TDMA's onPlayerChat handler
2. **Functionality Overlap**: Eliminated duplicate message formatting code

### Solution Applied to TDMA

1. **Removed Chat Handler**:

   ```lua
   -- Removed all chat handling code from TDMA
   ```

2. **No Integration Code Required**:
   ChatManager automatically detects TDMA teams and formats chat accordingly

### Benefits

This new automatic approach offers several advantages:

1. **Zero Configuration** - No integration code needed for any resource
2. **Automatic Team Detection** - Player team colors applied automatically
3. **White Text Messages** - Chat messages always displayed in white for readability
4. **Consistent Experience** - All gamemodes get the same chat appearance
5. **Simplified Codebase** - No resource-specific code in ChatManager

## Testing and Verification

After removing chat handlers, verify that:

1. Chat messages appear with proper team colors for player names
2. Message text appears in white
3. No chat-related errors appear in the server console

## Rollback Plan

If issues arise, resources can:

1. Re-enable their original chat handling code
