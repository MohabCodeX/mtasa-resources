# ChatManager ACL Permissions Guide

This document outlines all the ACL permissions required for the ChatManager resource to function properly on your MTA:SA server.

## Required Function Permissions

These permissions must be granted to the ChatManager resource:

```xml
<acl name="ChatManagerACL">
    <!-- Essential chat functions -->
    <right name="function.cancelEvent" access="true"></right>
    <right name="function.outputChatBox" access="true"></right>
    <right name="function.outputServerLog" access="true"></right>

    <!-- Player information functions -->
    <right name="function.getPlayerName" access="true"></right>
    <right name="function.getPlayerTeam" access="true"></right>
    <right name="function.getPlayerNametagColor" access="true"></right>
    <right name="function.getElementType" access="true"></right>
    <right name="function.isElement" access="true"></right>

    <!-- Team functions -->
    <right name="function.getTeamColor" access="true"></right>
    <right name="function.getTeamName" access="true"></right>
    <right name="function.getPlayersInTeam" access="true"></right>

    <!-- Element data functions -->
    <right name="function.setElementData" access="true"></right>
    <right name="function.getElementData" access="true"></right>

    <!-- Permission functions -->
    <right name="function.hasObjectPermissionTo" access="true"></right>

    <!-- Command functions -->
    <right name="function.addCommandHandler" access="true"></right>
    <right name="function.removeCommandHandler" access="true"></right>

    <!-- Resource functions -->
    <right name="function.getThisResource" access="true"></right>
    <right name="function.getResourceName" access="true"></right>
    <right name="function.getResourceFromName" access="true"></right>

    <!-- Emergency blip functions -->
    <right name="function.createBlip" access="true"></right>
    <right name="function.destroyElement" access="true"></right>
    <right name="function.setElementPosition" access="true"></right>
    <right name="function.attachElementToDimension" access="true"></right>
    <right name="function.getElementPosition" access="true"></right>
    <right name="function.getZoneName" access="true"></right>
    <right name="function.getElementDimension" access="true"></right>
</acl>
```

You also need to create a group for the resource:

```xml
<group name="ChatManagerGroup">
    <acl name="ChatManagerACL"></acl>
    <object name="resource.chatmanager"></object>
</group>
```

## Required Command Permissions for Users

These permissions should be assigned to appropriate user groups:

```xml
<!-- For Moderators -->
<acl name="Moderator">
    <right name="command.mute" access="true"></right>
    <right name="command.clearchat" access="true"></right>
</acl>

<!-- For Administrators -->
<acl name="Admin">
    <right name="command.mute" access="true"></right>
    <right name="command.kick" access="true"></right>
    <right name="command.clearchat" access="true"></right>
</acl>
```

## How to Apply These Permissions

### Method 1: Edit acl.xml (Requires Server Restart)

Add the rights to the appropriate ACL sections in your server's acl.xml file.

### Method 2: In-Game Commands (No Restart Required)

First, create the ACL and group:

```
/aclcreate ChatManagerACL
/aclgroupcreate ChatManagerGroup
/aclgroupaddacl ChatManagerGroup ChatManagerACL
/aclgroupaddobject ChatManagerGroup resource.chatmanager
```

Then add the specific function rights:

```
/aclsetright ChatManagerACL function.outputChatBox true
/aclsetright ChatManagerACL function.hasObjectPermissionTo true
```

(Repeat for all required permissions)

### Method 3: Add Resource to Admin Group

If you prefer a simpler approach, you can add the ChatManager resource to the Admin group:

```
/aclgroup addobject Admin resource.chatmanager
```

## Troubleshooting

If you encounter "Access denied" errors in the server console:

1. Check which specific function is being denied.
2. Add that function permission to the `ChatManagerACL` ACL.
3. Restart the ChatManager resource with `/refresh chatmanager`.

For command permission issues, make sure the appropriate user groups have the required command permissions.
