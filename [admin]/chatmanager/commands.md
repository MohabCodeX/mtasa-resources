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
| `/sendpos`      | Share your current position with others                 | `/sendpos [target] [message]` | `/sendpos John Meet me here`   |

For the `/sendpos` command, the target can be:

- A player name - Sends to that specific player
- "team" - Sends to all players in your team

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
| `/system`    | Send a system message to all players                     | `/system [message]`       | `/system Welcome to our server!"         |

## Admin Commands - Player Colors

These commands require the "command.kick" permission and are used to control player name colors.

| Command                           | Description                                       | Usage                             | Example                       |
| --------------------------------- | ------------------------------------------------- | --------------------------------- | ----------------------------- |
| `/playercolors`                   | Show player colors status                         | `/playercolors`                   | `/playercolors`               |
| `/playercolors on/off`            | Enable/disable player colors                      | `/playercolors [on/off]`          | `/playercolors on`            |
| `/playercolors static`            | Set player colors to fixed per player             | `/playercolors static`            | `/playercolors static`        |
| `/playercolors dynamic`           | Set player colors to change with each message     | `/playercolors dynamic`           | `/playercolors dynamic`       |
| `/randomcolor`                    | Randomize all player colors                       | `/randomcolor`                    | `/randomcolor`                |
| `/randomcolor [player]`           | Randomize a specific player's color               | `/randomcolor [player]`           | `/randomcolor John`           |
| `/colorsetting`                   | List all color settings                           | `/colorsetting`                   | `/colorsetting`               |
| `/colorsetting [setting]`         | Show current value of a color setting             | `/colorsetting [setting]`         | `/colorsetting override`      |
| `/colorsetting [setting] [value]` | Change a color setting                            | `/colorsetting [setting] [value]` | `/colorsetting override true` |
| `/coloroverride [value]`          | Toggle whether player colors override team colors | `/coloroverride [true/false]`     | `/coloroverride true`         |

When player colors are disabled, non-teamed players will have a default color of FF6464 (light red).

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

## Examples of Using /sendpos

1. **Sending location to specific player:**

   - `/sendpos John I'm waiting here for you`
   - Result for John: "[PRIVATE-LOCATION] YourName is at Downtown (123, 456, 789) (I'm waiting here for you)"

2. **Sending location to team:**
   - `/sendpos team Found a vehicle here`
   - Result for team: "[TEAM-LOCATION] YourName is at Beach (234, 567, 890) (Found a vehicle here)"
