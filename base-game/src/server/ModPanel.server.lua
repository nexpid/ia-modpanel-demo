-- types --
type PlayerData = {
	id: number,
	name: string,
	joinedPlayer: number?,
	joinedAt: number,
	leftAt: number?,
}
type ServerData = {
	players: { PlayerData },
	round: {
		ingame: boolean,
		map: string,
		mode: string,
		loadedAt: boolean,
	},
}

-- top level stuff --
local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")

local DB = DataStoreService:GetDataStore("modpanel")
local serverID = game.JobId

-- ignore private servers
if game.PrivateServerOwnerId ~= 0 then
	return
end

local players: { [Player]: PlayerData } = {}

-- important --
local function grabData(): ServerData
	local data: ServerData = {
		players = {},
		round = {
			ingame = false,
			map = "cool_map",
			mode = "lobby",
			loadedAt = 0,
		},
	}
	for _, x in pairs(players) do
		data.players[#data.players + 1] = x
	end

	return data
end

local queueID
local function queueUpdate()
	local now = tick()
	queueID = now

	task.delay(10, function()
		if queueID == now then
			DB:SetAsync(serverID, grabData())
		end
	end)
end

local function ackModpanelMessage(id: string, success: boolean)
	MessagingService:PublishAsync("modpanel-ack", { id, success })
end

-- runners --
game:BindToClose(function()
	DB:UpdateAsync("list", function(list)
		list = list or {}
		if table.find(list, serverID) then
			table.remove(list, table.find(list, serverID))
		end

		return list
	end)
	queueID = nil
	DB:SetAsync(serverID, nil)
end)

game.Players.PlayerAdded:Connect(function(plr)
	players[plr] = {
		id = plr.UserId,
		name = plr.Name,
		joinedPlayer = plr.FollowUserId,
		joinedAt = DateTime.now().UnixTimestampMillis,
	}
	queueUpdate()
end)
game.Players.PlayerRemoving:Connect(function(plr)
	players[plr] = players[plr]
		or {
			id = plr.UserId,
			name = plr.Name,
			joinedPlayer = plr.FollowUserId,
			joinedAt = 0,
		}

	players[plr].leftAt = DateTime.now().UnixTimestampMillis
	queueUpdate()

	task.wait(60)

	players[plr] = nil
	queueUpdate()
end)

MessagingService:SubscribeAsync("modpanel", function(msg)
	local data = msg.Data

	if data[2] ~= serverID then
		return
	end

	if data[3] == "shutdown" then
		for _, x in pairs(Players:GetPlayers()) do
			x:Kick("Shutting down server...")
		end
		ackModpanelMessage(data[1], true)
	elseif data[3] == "kickPlr" then
		local plr: Player? = Players:FindFirstChild(data[4][1])
		if not plr then
			return ackModpanelMessage(data[1], false)
		end

		plr:Kick(data[4][1])
		ackModpanelMessage(data[1], true)
	end
end)

-- init --
DB:UpdateAsync("list", function(list)
	list = list or {}
	list[#list + 1] = serverID

	return list
end)
