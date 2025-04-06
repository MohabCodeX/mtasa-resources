# Chat Manager Functionality

## 1. Event Handling

- Intercept all `onPlayerChat` events.
- Cancel the default chat event to prevent duplication.
- Handle public chat (type 0) and team chat (type 1) appropriately.
- Ensure compatibility with other resources by providing an API for sending messages.

## 2. Color Options

- Support **nametag colors** using `getPlayerNametagColor()`.
- Support **team colors** using `getTeamColor()`.
- Implement a configurable priority system:
  - Use team colors if enabled and the player is in a team.
  - Use player colors if enabled (static or dynamic mode).
  - Fallback to nametag colors if team colors are disabled or unavailable.
- Handle players with no team gracefully (default to FF6464 - light red).
- Ensure team chat messages have consistent coloring (same color for tag and name).

## 3. Spam Protection

- Implement a configurable delay between messages (`chat_message_delay`).
- Add an option to block repeated messages (`block_repeated_messages`).
- Allow admins with specific permissions (e.g., `command.kick`, `command.mute`) to bypass spam restrictions.
- Provide feedback to players when their messages are blocked due to spam rules.

## 4. Message Formatting

- Strip color codes from messages when configured (`strip_color_codes`).
- Format chat messages consistently:
  - Example: `<PlayerName>: <Message>` with appropriate colors.
  - Team chat: `<TeamColored>(TEAM)</TeamColored> <TeamColoredPlayerName>: <Message>`
- Log all chat messages to the server log for auditing purposes.

## 5. Admin Integration

- Respect admin mutes and ensure muted players cannot send messages.
- Check if a player has voice chat muted and block their messages if applicable.
- Provide an API for admin tools to mute/unmute players programmatically.

## 6. Extensibility

- Design the chat manager to be extensible for future needs:
  - Allow other resources to hook into chat events or modify behavior.
  - Provide settings for server admins to customize all aspects of chat handling.
- Ensure compatibility with existing resources like `freeroam`, `playercolors`, `tdma`, `ctv`, and `assault`.

## 7. API for Other Resources

- Create a function (`sendChatMessage`) for other resources to send messages through the chat manager.
- Ensure messages sent via the API respect the same formatting and color rules.

## 8. Testing Requirements

- Verify that color options (nametag and team colors) work as expected.
- Test spam protection features thoroughly:
  - Ensure delays and repeated message blocking function correctly.
  - Verify admin exemptions.
- Confirm that chat messages are logged correctly.
- Ensure compatibility with admin systems and other resources.

---
