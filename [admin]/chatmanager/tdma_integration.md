# TDMA and ChatManager Integration Plan

## Current Problem

After analyzing the TDMA gamemode, I've found it directly handles the `onPlayerChat` event which conflicts with ChatManager's centralized approach.

### Specific Issues:

1. **Duplicate Event Handling**:
   The `tdma_core.lua` handles `onPlayerChat` around line 342-353:

   ```lua
   function onChat(message, theType)
       if theType == 0 then
           cancelEvent()
           message = string.gsub(message, "#%x%x%x%x%x%x", "")
           local team = getPlayerTeam(source)
           local bastidName = getPlayerName(source)
           if (team) then
               local r, g, b = getTeamColor(team)
               outputChatBox(bastidName..":#FFFFFF "..message, root, r, g, b, true)
           else
               outputChatBox(bastidName..": "..message)
           end
           outputServerLog("CHAT: " .. bastidName .. ": " .. message)
       end
   end
   addEventHandler("onPlayerChat", root, onChat)
   ```

2. **Functionality Overlap**:

   - Both TDMA and ChatManager cancel the default chat event
   - Both handle team colors for chat messages
   - Both format player names with appropriate team colors
   - Both log chat messages to the server log

3. **Current Behavior**:
   - TDMA formats player names with their team color, and makes the message text white
   - TDMA strips color codes from messages
   - TDMA doesn't handle other message types like admin announcements, system messages, or position sharing

## Integration Approach

### 1. Modify TDMA Resource

1. **Remove Conflicting Handler**:

   - Comment out or remove the `onChat` function in `tdma_core.lua`
   - Remove the `addEventHandler("onPlayerChat", root, onChat)` line

2. **Add Dependency**:
   - Update TDMA's meta.xml to include a dependency on ChatManager:
   ```xml
   <depend>chatmanager</depend>
   ```

### 2. Configure ChatManager

1. **Ensure Team Color Support**:

   - Verify that ChatManager's settings include:

   ```xml
   <setting name="*use_team_colors" value="true" />
   <setting name="*team_colors_override" value="true" />
   ```

2. **Verify Message Formatting**:
   - Ensure ChatManager's output format is consistent with TDMA's expectations
   - ChatManager should format messages with team colors similar to TDMA's approach

### 3. Implementation Plan

#### Step 1: Back Up Original Files

- Create backup copies of `tdma_core.lua` and `meta.xml` from the TDMA resource

#### Step 2: Modify TDMA Code

- Comment out the `onChat` function and its event handler
- The code to be commented out is:

```lua
function onChat(message, theType)
    if theType == 0 then
        cancelEvent()
        message = string.gsub(message, "#%x%x%x%x%x%x", "")
        local team = getPlayerTeam(source)
        local bastidName = getPlayerName(source)
        if (team) then
            local r, g, b = getTeamColor(team)
            outputChatBox(bastidName..":#FFFFFF "..message, root, r, g, b, true)
        else
            outputChatBox(bastidName..": "..message)
        end
        outputServerLog("CHAT: " .. bastidName .. ": " .. message)
    end
end
addEventHandler("onPlayerChat", root, onChat)
```

#### Step 3: Update TDMA Meta.xml

- Add the dependency on ChatManager:

```xml
<depend>chatmanager</depend>
```

#### Step 4: Testing

1. Test regular chat messages - ensure they appear with proper team colors
2. Test team chat messages - ensure they only appear to team members
3. Test ChatManager commands - ensure they work properly with TDMA
4. Verify no chat-related errors appear in the server console

## Expected Benefits

1. **Centralized Chat Handling**:

   - All chat-related functionality managed by ChatManager
   - Consistent message formatting across the server

2. **Enhanced Features**:

   - TDMA players gain access to ChatManager's commands:
     - `/pm`, `/reply` for private messaging
     - `/sendpos` for position sharing
     - Team announcements and custom commands

3. **Improved Admin Controls**:

   - Mute functionality
   - Chat filtering
   - Chat moderation tools

4. **Better Resource Organization**:
   - TDMA focuses on gamemode logic
   - ChatManager handles all chat-related functionality

## Potential Issues

1. **Format Inconsistency**:

   - ChatManager might format messages differently than TDMA
   - Solution: Configure ChatManager settings to match TDMA's format

2. **Missing Custom Logic**:

   - If TDMA had any custom chat logic, it might need to be reimplemented
   - Solution: Review TDMA code for any special chat handling

3. **Resource Load Order**:
   - ChatManager must load before TDMA
   - Solution: TDMA's dependency on ChatManager should enforce this

## Rollback Plan

If issues arise during integration:

1. Restore the original TDMA files from backups
2. Remove the dependency on ChatManager
3. Re-enable TDMA's chat handling code
