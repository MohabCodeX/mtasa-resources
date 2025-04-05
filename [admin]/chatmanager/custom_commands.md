# Custom Command System Documentation

The ChatManager includes a powerful system for creating custom commands through XML, without requiring Lua scripting. This document explains how to create and use custom commands in the ChatManager.

## Basic Command Structure

Custom commands are defined in the `commands.xml` file using the following structure:

```xml
<command name="commandname" action="customMessage" description="Command description">
    <parameter name="param1" type="text" description="Parameter description" />
    <permission>none</permission>
    <syntax>[parameter]</syntax>
    <helptext>Help text shown to players</helptext>
    <custom>
        <message target="all" color="#FFFF00">{PLAYER} says: {PARAM:param1}</message>
    </custom>
</command>
```

## Key Components

1. **Command Definition**

   - `name`: The command name used after the slash (e.g., `/commandname`)
   - `alias`: Optional comma-separated list of alternative command names
   - `action`: Must be "customMessage" for custom message commands
   - `description`: Brief description of what the command does

2. **Parameters**

   - Define the parameters your command accepts
   - Each parameter has a name, type, and description
   - Parameters can be optional with default values
   - The command will automatically validate these parameters

3. **Permission**

   - Controls who can use this command
   - Use "none" for everyone, or an ACL permission like "command.mute"

4. **Custom Section**
   - Contains the message definitions that determine what happens when the command runs
   - Multiple messages can be defined with different targets

## Parameter Types

When defining parameters for custom commands, you can use the following types:

| Type      | Description                                                                                                  | Example Usage                                                    |
| --------- | ------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------- |
| `text`    | Captures all remaining text as a single parameter. Used for messages, descriptions, or any multi-word input. | `<parameter name="message" type="text" />`                       |
| `player`  | Expects a player name. The system will attempt to find a matching player using partial name matching.        | `<parameter name="target" type="player" />`                      |
| `number`  | Expects a numeric value. Will validate that the input is a valid number.                                     | `<parameter name="amount" type="number" />`                      |
| `string`  | Captures a single word. Unlike text, it only captures one argument.                                          | `<parameter name="option" type="string" />`                      |
| `team`    | Expects a team name. The system will attempt to find a matching team.                                        | `<parameter name="team" type="team" />`                          |
| `vehicle` | Expects a vehicle ID or name. Will translate to the appropriate vehicle.                                     | `<parameter name="vehicle" type="vehicle" />`                    |
| `weapon`  | Expects a weapon ID or name. Will translate to the appropriate weapon.                                       | `<parameter name="weapon" type="weapon" />`                      |
| `hidden`  | Not provided by the user but defined with a default value in the command.                                    | `<parameter name="setting" type="hidden" default="useFilter" />` |

### Optional Parameters and Default Values

Parameters can be defined as optional using the `optional` attribute. When a parameter is optional, you can also set a default value:

```xml
<parameter name="reason" type="text" description="Reason" optional="true" default="No reason specified" />
```

### Parameter Order

Parameters are processed in the order they appear in the command definition. Non-hidden parameters are consumed from the user's input in sequence, so the order matters.

### Special Case: Text Parameters

When using a `text` type parameter, it should generally be the last parameter in your command, as it will consume all remaining arguments.

## Message Format

The message definition uses these attributes:

- `target`: Who receives the message (options: "all", "admins", "team", "sender")
- `color`: Text color in hex format (#RRGGBB)
- Message content: The text with placeholders

### Available Placeholders

- `{PLAYER}`: Replaced with the name of the player using the command
- `{PARAM:name}`: Replaced with the value of the parameter with the given name
- `{PARAM:1}`, `{PARAM:2}`, etc.: Replaced with the parameters in order (for backward compatibility)

## Target Options

- `all`: Send to all players on the server
- `admins`: Send only to players with admin permissions (command.mute)
- `team`: Send only to players in the same team as the command user
- `sender`: Send only to the player who used the command

## Examples

### Help Request Command

```xml
<command name="helpme" action="customMessage" description="Request help from admins">
    <parameter name="message" type="text" description="Help request" />
    <permission>none</permission>
    <syntax>[message]</syntax>
    <helptext>Send a help request to online admins</helptext>
    <custom>
        <message target="admins" color="#FFFF00">[HELP] {PLAYER} needs assistance: {PARAM:message}</message>
        <message target="sender" color="#FFFF00">Your help request was sent to admins</message>
    </custom>
</command>
```

### Team Status Command

```xml
<command name="status" action="customMessage" description="Share your status with your team">
    <parameter name="message" type="text" description="Status message" />
    <permission>none</permission>
    <syntax>[message]</syntax>
    <helptext>Share your status with your team</helptext>
    <custom>
        <message target="team" color="#00FFFF">[STATUS] {PLAYER}: {PARAM:message}</message>
        <message target="sender" color="#00FFFF">Status shared with your team</message>
    </custom>
</command>
```

### Admin Broadcast Command

```xml
<command name="broadcast" action="customMessage" description="Broadcast an important message">
    <parameter name="message" type="text" description="Message to broadcast" />
    <permission>command.mute</permission>
    <syntax>[message]</syntax>
    <helptext>Send an important message to all players</helptext>
    <custom>
        <message target="all" color="#FF0000">[BROADCAST] {PARAM:message}</message>
    </custom>
</command>
```

### Multiple Parameter Example

```xml
<command name="report" action="customMessage" description="Report a player">
    <parameter name="target" type="player" description="Player to report" />
    <parameter name="reason" type="text" description="Reason for report" />
    <permission>none</permission>
    <syntax>[player] [reason]</syntax>
    <helptext>Report a player to admins</helptext>
    <custom>
        <message target="admins" color="#FF9900">[REPORT] {PLAYER} reported {PARAM:target}: {PARAM:reason}</message>
        <message target="sender" color="#FF9900">Your report has been sent to online admins</message>
    </custom>
</command>
```

## Adding Your Own Commands

To add your own custom commands:

1. Edit the `commands.xml` file
2. Follow the format shown in the examples above
3. Restart the ChatManager resource or use `/refresh chatmanager`

## Tips and Best Practices

- Always provide feedback to the command user with a "sender" targeted message
- Use different colors for different types of messages to help players distinguish them
- Keep command names short and intuitive
- Include clear syntax and helptext to guide players
- Use appropriate permissions to restrict access to powerful commands
