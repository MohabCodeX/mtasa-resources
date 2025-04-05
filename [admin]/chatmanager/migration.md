# Migrating to ChatManager

This guide explains how to modify existing resources to work with the centralized ChatManager system.

## For playercolors

1. Remove the `onPlayerChat` event handler:

   ```lua
   -- Remove this entire handler
   addEventHandler("onPlayerChat", root, function(message, messageType)
       -- chat color handling code...
   end)
   ```

2. If you need colored player names, use the ChatManager API instead:
   ```lua
   -- Instead of handling colors yourself
   local coloredName = exports.chatmanager:getColoredPlayerName(player)
   ```

## For freeroam

1. Remove the `onPlayerChat` and `onPlayerPrivateMessage` event handlers:

   ```lua
   -- Remove these event handlers
   addEventHandler("onPlayerChat", root, function(message, messageType)
       -- chat handling code...
   end)

   addEventHandler("onPlayerPrivateMessage", root, function(message, recipient)
       -- private message handling code...
   end)
   ```

2. Remove any spam protection code (ChatManager handles this)

3. For sending chat messages, use the ChatManager API:

   ```lua
   -- Instead of using outputChatBox directly
   exports.chatmanager:sendChatMessage(player, message, messageType)

   -- For private messages
   exports.chatmanager:sendPrivateMessage(player, recipient, message)
   ```

## For tdma, ctv, and assault

1. Remove any team-colored chat handling code:

   ```lua
   -- Remove team chat color code like this
   addEventHandler("onPlayerChat", root, function(message, messageType)
       if messageType == 1 then -- team chat
           -- team color handling...
       end
   end)
   ```

2. For team-specific messages, use the ChatManager API:

   ```lua
   -- Instead of manually formatting team messages
   exports.chatmanager:sendTeamMessage(message, teamElement, fromPlayer)
   ```

3. For gamemode-specific messages (objectives, announcements):
   ```lua
   -- Instead of custom formatting for gamemode messages
   exports.chatmanager:sendGamemodeMessage("Capture the flag!", "objective")
   ```

## For admin resources

1. Remove code that handles muting players:

   ```lua
   -- Remove functions like these
   function mutePlayer(player, target)
       -- muting code...
   end
   ```

2. Use the ChatManager API for mute functionality:

   ```lua
   -- To mute a player
   exports.chatmanager:setChatMuted(player, true)

   -- To check if a player is muted
   local isMuted = exports.chatmanager:isChatMuted(player)

   -- To send admin messages
   exports.chatmanager:sendAdminAnnouncement(message, adminPlayer)
   ```

## Common Changes for All Resources

1. Remove any `outputChatBox` calls that format player messages
2. Remove custom spam protection systems
3. Remove any code that handles chat colors or formatting
4. Check for any features that rely on capturing chat messages and adapt them to use ChatManager

## Testing

After migration, test to ensure:

1. Players can chat normally
2. Team chat works correctly
3. Admin commands function properly
4. Muting system works
5. No console errors appear related to chat

## Troubleshooting

If you encounter issues after migration:

1. Make sure ChatManager is running and loaded before other resources
2. Check if the resource was properly migrated using the steps above
3. Verify the ChatManager has the necessary permissions in ACL
4. Look for console errors that might indicate missing function calls
