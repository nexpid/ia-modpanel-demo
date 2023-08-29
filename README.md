<h1 align="center">
    IA Modpanel Demo
</h1>

> **Note**
> The `modpanel-game` folder doesn't contain any scripts yet

This is a demo to showcase how a theoretical modpanel for Item Asylum could look like, the `base-game` and `modpanel-game` folders contain scripts that should be synced to Roblox using [Rojo](https://rojo.space)  
The two games communicate using a DataStore and MessagingService

# MessagingService Schema

## `modpanel` topic

Arguments:

- `id` — string, represents the unique ID of the message (conversation), used for acking
- `serverID` — string, the target server ID
- `action` — the modpanel action
- `args` — array, an array of arguments for the specific action

### `shutdown` action

No args needed

### `kickPlr` action

- `plr` — string, the player's username
- `reason` — string, why the player got kicked

## `modpanel-ack`

Arguments:

- `id` — string, the unique ID of a message (conversation)
