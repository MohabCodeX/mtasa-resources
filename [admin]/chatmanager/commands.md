# Chat Manager - Command Reference

This document lists all available commands in the Chat Manager resource, categorized by user type and functionality.

## Regular Player Commands

These commands are available to all players on the server.

| Command         | Description                                             | Usage                         | Example                        |
| --------------- | ------------------------------------------------------- | ----------------------------- | ------------------------------ |
| `/pm`           | Send a private message to another player                | `/pm [player] [message]`      | `/pm John Hello there!`        |
| `/msg`          | Alias for `/pm`                                         | `/msg [player] [message]`     | `/msg John How are you?`       |
| `/whisper`      | Alias for `/pm`                                         | `/whisper [player] [message]` | `/whisper John Are you there?` |
| `/reply`        | Reply to the last person who sent you a private message | `/reply [message]`            | `/reply Yes, I'm here`         |
| `/togglefilter` | Toggle the chat filter on/off for yourself              | `/togglefilter`               | `/togglefilter`                |
| `/togglechat`   | Toggle chat blocking on/off for yourself                | `/togglechat`                 | `/togglechat`                  |

## Team Leader Commands

These commands are available to team leaders or players with the "teamleader" element data.

| Command      | Description                       | Usage                  | Example                                    |
| ------------ | --------------------------------- | ---------------------- | ------------------------------------------ |
| `/tannounce` | Send an announcement to your team | `/tannounce [message]` | `/tannounce Meet at the base in 5 minutes` |

## Admin Commands - Chat Moderation

These commands require the "command.mute" permission.

| Command      | Description                                              | Usage                     | Example                                  |
| ------------ | -------------------------------------------------------- | ------------------------- | ---------------------------------------- |
| `/mute`      | Mute a player (prevents them from sending chat messages) | `/mute [player] [reason]` | `/mute John Spamming chat`               |
| `/unmute`    | Unmute a previously muted player                         | `/unmute [player]`        | `/unmute John`                           |
| `/mutelist`  | Show a list of all currently muted players               | `/mutelist`               | `/mutelist`                              |
| `/clearchat` | Clear chat messages for yourself or all players          | `/clearchat [all]`        | `/clearchat all`                         |
| `/announce`  | Send a server-wide admin announcement                    | `/announce [message]`     | `/announce Server restart in 10 minutes` |
| `/system`    | Send a system message to all players                     | `/system [message]`       | `/system Welcome to our server!`         |

## Admin Commands - Filter Management

These commands require the "command.kick" permission.

| Command             | Description                                  | Usage                      | Example                     |
| ------------------- | -------------------------------------------- | -------------------------- | --------------------------- |
| `/addfilterword`    | Add a word to the chat filter                | `/addfilterword [word]`    | `/addfilterword badword`    |
| `/removefilterword` | Remove a word from the chat filter           | `/removefilterword [word]` | `/removefilterword badword` |
| `/filterlist`       | Show a list of custom filtered words         | `/filterlist`              | `/filterlist`               |
| `/reloadfilter`     | Reload the chat filter (clears custom words) | `/reloadfilter`            | `/reloadfilter`             |

## Permission Requirements

The Chat Manager uses MTA's built-in ACL system for command permissions:

1. **Regular Player Commands**

   - No special permissions required

2. **Team Leader Commands**

   - Must be in a team
   - Must have elementData "teamleader" set to true OR have admin permissions

3. **Admin Chat Moderation Commands**

   - Requires "command.mute" permission

4. **Admin Filter Management Commands**
   - Requires "command.kick" permission

## Command Configuration

All commands are hardcoded in the Chat Manager resource and cannot be changed without modifying the code. However, you can use ACL to control which groups have access to the administrative commands.

Example ACL configuration:

```xml
<acl>
    <group name="Moderator">
        <object name="resource.chatmanager" />
        <right name="command.mute" access="true" />
    </group>
    <group name="Admin">
        <object name="resource.chatmanager" />
        <right name="command.mute" access="true" />
        <right name="command.kick" access="true" />
    </group>
</acl>
```

## Troubleshooting

If you're having trouble with commands:

1. Check if you have the required permissions in the server's ACL
2. Ensure you're using the correct syntax for the command
3. Check the server console for any error messages
4. Make sure the Chat Manager resource is running

For further assistance, please contact your server administrator.
