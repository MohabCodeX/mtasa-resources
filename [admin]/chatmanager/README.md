# Chat Manager

A centralized chat management system for MTA:SA servers.

## Overview

Chat Manager provides a unified solution for handling in-game chat, resolving conflicts between multiple resources that handle chat events independently. It implements consistent chat formatting, color options, and spam protection.

## Features

- **Centralized Chat Handling**: Single point of control for all chat events
- **Color Options**:
  - Player nametag colors in chat
  - Team colors in chat
  - Configurable priority (team colors can override nametag colors)
- **Spam Protection**:
  - Configurable delay between messages
  - Option to block repeated messages
  - Admin exemptions
- **Admin Integration**:
  - Respects admin mutes
  - API for other resources to check mute status or mute/unmute players
- **Message Formatting**:
  - Optional color code stripping
  - Consistent message display
  - Server-side logging

## Configuration

All settings can be adjusted in the `meta.xml` file:

| Setting                   | Description                                               | Default |
| ------------------------- | --------------------------------------------------------- | ------- |
| `use_nametag_colors`      | Use player's nametag color in chat                        | `true`  |
| `use_team_colors`         | Use player's team color in chat                           | `true`  |
| `team_colors_override`    | Team colors override nametag colors when both are enabled | `true`  |
| `chat_message_delay`      | Minimum delay between messages in milliseconds            | `1000`  |
| `block_repeated_messages` | Block repeated messages from players                      | `true`  |
| `strip_color_codes`       | Strip color codes from messages                           | `true`  |

## Message Types

Chat Manager supports various types of messages:

### Public Chat

Regular chat messages visible to all players. Used through normal chat input.

### Team Chat

Messages visible only to players in the same team. Used through team chat input.

### Private Messages

Direct messages between two players. Used with `/pm`, `/msg`, or `/whisper` commands.

### System Messages

Important server notifications. Can be sent using:

```lua
exports.chatmanager:sendSystemMessage("Server will restart in 5 minutes")
```

### Admin Announcements

Highlighted messages from administrators. Can be sent using:

```lua
exports.chatmanager:sendAdminAnnouncement("Please follow the server rules", adminPlayer)
```

### Team Announcements

Important messages for a specific team. Can be sent using:

```lua
exports.chatmanager:sendTeamMessage("Capture the flag!", teamElement, senderPlayer)
```

### Gamemode Messages

Context-specific messages for gamemodes (objectives, announcements, etc.). Can be sent using:

```lua
exports.chatmanager:sendGamemodeMessage("Capture the enemy flag!", "objective")
```

## API for Other Resources

Chat Manager exports the following functions that can be used by other resources:

### `sendChatMessage(player, message, messageType, receiver)`

Sends a chat message from a player or system.

- **Parameters**:
  - `player`: The player element or a string for system messages
  - `message`: The message text
  - `messageType`: 0 for public chat, 1 for team chat (default: 0)
  - `receiver`: Optional player element to send the message to (default: all players)
- **Returns**: `true` if successful, `false` otherwise

### `sendPrivateMessage(sender, receiver, message)`

Sends a private message from one player to another.

- **Parameters**:
  - `sender`: The player element sending the message
  - `receiver`: The player element receiving the message
  - `message`: The message text
- **Returns**: `true` if successful, `false` otherwise

### `sendTeamMessage(message, team, fromPlayer)`

Sends a message to all players in a team.

- **Parameters**:
  - `message`: The message text
  - `team`: The team element
  - `fromPlayer`: Optional player element to attribute the message to
- **Returns**: `true` if successful, `false` otherwise

### `sendAdminMessage(message, fromPlayer)`

Sends a message to all admin players.

- **Parameters**:
  - `message`: The message text
  - `fromPlayer`: Optional player element to attribute the message to
- **Returns**: `true` if successful, `false` otherwise

### `isChatMuted(player)`

Checks if a player is muted.

- **Parameters**:
  - `player`: The player element
- **Returns**: `true` if muted, `false` otherwise

### `setChatMuted(player, state)`

Mutes or unmutes a player.

- **Parameters**:
  - `player`: The player element
  - `state`: `true` to mute, `false` to unmute
- **Returns**: `true` if successful, `false` otherwise

### `getColoredPlayerName(player)`

Gets a player's name with appropriate color formatting.

- **Parameters**:
  - `player`: The player element
- **Returns**: Colored player name string

### `filterText(text)`

Filters text by replacing profanity with asterisks.

- **Parameters**:
  - `text`: The text to filter
- **Returns**: Filtered text

### `updateCustomFilter(word, remove)`

Adds or removes words from the custom filter.

- **Parameters**:
  - `word`: The word to add or remove
  - `remove`: `true` to remove, `false` to add
- **Returns**: `true` if successful, `false` otherwise

## External Command Registration

Chat Manager allows other resources to register custom commands using the API:

```lua
-- Register a custom command
exports.chatmanager:registerCustomCommand(commandName, handlerFunction, requiredPermission)

-- Example: Register a simple announcement command
function broadcastMessage(player, cmd, ...)
    local message = table.concat({...}, " ")
    if #message > 0 then
        outputChatBox("[Broadcast] " .. message, root, 255, 200, 0, true)
        return true
    else
        outputChatBox("SYNTAX: /broadcast [message]", player, 255, 255, 0)
        return false
    end
end

exports.chatmanager:registerCustomCommand("broadcast", broadcastMessage, "command.mute")
```

### Parameters

- `commandName`: String - The name of the command (without the slash)
- `handlerFunction`: Function - The function to execute when the command is used
- `requiredPermission`: String (optional) - ACL permission required to use the command (default: "none")

### Handler Function Format

The handler function should accept these parameters:

```lua
function handlerFunction(player, cmd, ...)
    -- player: The player who executed the command
    -- cmd: The command that was executed
    -- ...: All arguments passed to the command

    -- Return true if successful, false otherwise
    return true
end
```

### Unregistering Commands

To remove a command when your resource stops or when you no longer need it:

```lua
exports.chatmanager:unregisterCustomCommand("broadcast")
```

### Automatic Cleanup

Commands are automatically unregistered when the resource that registered them stops.

## Admin Commands

Chat Manager provides the following commands for server administrators:

### Chat Moderation

| Command                   | Description                            | Required Permission |
| ------------------------- | -------------------------------------- | ------------------- |
| `/mute [player] [reason]` | Mute a player                          | command.mute        |
| `/unmute [player]`        | Unmute a player                        | command.mute        |
| `/clearchat [all]`        | Clear chat for yourself or all players | command.mute        |
| `/mutelist`               | View list of muted players             | command.mute        |

### Filter Management

| Command                    | Description                        | Required Permission |
| -------------------------- | ---------------------------------- | ------------------- |
| `/addfilterword [word]`    | Add a word to the chat filter      | command.kick        |
| `/removefilterword [word]` | Remove a word from the chat filter | command.kick        |
| `/filterlist`              | View list of filtered words        | command.mute        |
| `/reloadfilter`            | Reload the chat filter             | command.mute        |

### Client Commands

| Command                       | Description                    | Required Permission |
| ----------------------------- | ------------------------------ | ------------------- |
| `/togglechat`                 | Toggle chat blocking           | None                |
| `/togglefilter`               | Toggle chat filter             | None                |
| `/pm [player] [message]`      | Send a private message         | None                |
| `/msg [player] [message]`     | Send a private message (alias) | None                |
| `/whisper [player] [message]` | Send a private message (alias) | None                |
| `/reply [message]`            | Reply to last private message  | None                |

## Command Configuration

Chat Manager commands are configurable through the `commands.xml` file. You can:

- Modify existing commands
- Add new commands
- Change command aliases
- Set custom permissions
- Create custom message commands

### Command XML Structure

```xml
<command name="commandname" alias="alias1,alias2" action="actionType" description="Command description">
    <parameter name="param1" type="player" description="Target player" />
    <parameter name="param2" type="text" description="Message text" optional="true" default="Default value" />
    <permission>command.permission</permission>
    <syntax>[param1] [param2]</syntax>
    <helptext>Help text shown to players</helptext>
    <custom>
        <!-- Custom actions for specialized commands -->
        <message target="all" color="#FFFF00">Message to display</message>
    </custom>
</command>
```

### Available Action Types

| Action             | Description                                         |
| ------------------ | --------------------------------------------------- |
| `privateMessage`   | Send a private message to another player            |
| `replyLastMessage` | Reply to the last private message                   |
| `toggleSetting`    | Toggle a client setting (requires hidden parameter) |
| `teamAnnounce`     | Send an announcement to a team                      |
| `mutePlayer`       | Mute a player                                       |
| `unmutePlayer`     | Unmute a player                                     |
| `listMutedPlayers` | Show list of muted players                          |
| `clearChat`        | Clear chat messages                                 |
| `adminAnnounce`    | Send an admin announcement                          |
| `systemMessage`    | Send a system message                               |
| `addFilterWord`    | Add a word to the chat filter                       |
| `removeFilterWord` | Remove a word from the chat filter                  |
| `listFilterWords`  | Show list of filtered words                         |
| `reloadFilter`     | Reload the chat filter                              |
| `customMessage`    | Execute custom message actions                      |

### Parameter Types

| Type     | Description                                                  |
| -------- | ------------------------------------------------------------ |
| `player` | A player name (will be resolved using partial name matching) |
| `text`   | Text input (consumes all remaining arguments)                |
| `hidden` | Hidden parameter with a default value                        |

### Custom Message Targets

For `customMessage` actions, you can specify different message targets:

| Target   | Description                             |
| -------- | --------------------------------------- |
| `all`    | Send to all players                     |
| `admins` | Send to players with admin permissions  |
| `team`   | Send to player's team members           |
| `sender` | Send to the player who used the command |

### Example: Adding a Custom Command

To add a custom command to broadcast player status:

```xml
<command name="status" action="customMessage" description="Share your status">
    <parameter name="message" type="text" description="Status message" />
    <permission>none</permission>
    <syntax>[message]</syntax>
    <helptext>Share your status with other players</helptext>
    <custom>
        <message target="all" color="#00FFFF">[STATUS] {PLAYER}: {PARAM:message}</message>
    </custom>
</command>
```

### Tips for Modifying Commands

1. Always keep a backup of the original `commands.xml`
2. Test changes on a development server first
3. Ensure permissions are appropriate (avoid giving powerful commands to all players)
4. Custom message placeholders: `{PLAYER}` (player name), `{PARAM:name}` (parameter value)

## Usage Examples

### Using the API from another resource

```lua
-- Check if a player is muted
local isMuted = exports.chatmanager:isChatMuted(thePlayer)
if isMuted then
    outputChatBox("You are currently muted!", thePlayer, 255, 0, 0)
end

-- Mute a player
exports.chatmanager:setChatMuted(thePlayer, true)

-- Send a chat message as a player
exports.chatmanager:sendChatMessage(thePlayer, "Hello everyone!", 0)

-- Send a system message
exports.chatmanager:sendChatMessage("[Server]", "Server will restart in 5 minutes")
```

## Troubleshooting

If you encounter issues with Chat Manager:

1. Ensure that no other resources are handling `onPlayerChat` events. Chat Manager should be the only resource handling these events.
2. Check the server console for any error messages.
3. Verify that Chat Manager has the necessary ACL permissions as defined in `meta.xml`.

## Support

For support, bug reports, or feature requests, please create an issue on the MTA:SA Community GitHub repository.

## License

This resource is part of the MTA:SA Community resources and is provided under the same license.
