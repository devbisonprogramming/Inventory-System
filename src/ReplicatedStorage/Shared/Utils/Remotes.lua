-- SIMPLE NETWORKING UTILITY CREATED TO DECLUTTER REMOTE HANDLING

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local RemotesFolder = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Remotes")

local Remotes = {}

local function _checkRunContext(server: boolean)
	if server then
		return RunService:IsServer()
	else
		return RunService:IsClient()
	end
end

-- Create a new RemoteEvent (default parent is ReplicatedStorage.Events.Remotes)
function Remotes.NewRemoteEvent(name: string, parent: Instance?): RemoteEvent
	local parent = parent or RemotesFolder
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = parent
	return remote
end
-- Create a new RemoteFunction (default parent is ReplicatedStorage.Events.Remotes)
function Remotes.NewRemoteFunction(name: string, parent: Instance?): RemoteFunction
	local parent = parent or RemotesFolder
	local remote = Instance.new("RemoteFunction")
	remote.Name = name
	remote.Parent = parent
	return remote
end
-- Get an existing RemoteEvent or create a new one if it doesn't exist (default parent is ReplicatedStorage.Events.Remotes)
function Remotes.GetRemoteEvent(name: string, parent: Instance?): RemoteEvent
	local parent = parent or RemotesFolder
	return parent:FindFirstChild(name) or Remotes.NewRemoteEvent(name, parent)
end
-- Get an existing RemoteFunction or create a new one if it doesn't exist (default parent is ReplicatedStorage.Events.Remotes)
function Remotes.GetRemoteFunction(name: string, parent: Instance?): RemoteFunction
	local parent = parent or RemotesFolder
	return parent:FindFirstChild(name) or Remotes.NewRemoteFunction(name, parent)
end

-- BASIC EVENT HANDLING

-- Link a RemoteEvent to a handler function (Server-side)
function Remotes.OnServerRemoteEvent(remoteName: string, handler: (player: Player, ...any) -> ())
	if not _checkRunContext(true) then warn("Cannot call OnServerEvent from client") return end
	local remote = Remotes.GetRemoteEvent(remoteName, RemotesFolder)
	remote.OnServerEvent:Connect(handler)
end
-- Link a RemoteFunction to a handler function (Client-side)
function Remotes.OnClientRemoteEvent(remoteName: string, handler: (...any) -> ())
	if not _checkRunContext(false) then warn("Cannot call OnClientEvent from server") return end
	local remote = Remotes.GetRemoteEvent(remoteName, RemotesFolder)
	--remote.OnClientEvent:Connect(handler)
	remote.OnClientEvent:Connect(handler)
end

-- Link a RemoteFunction to a handler function (Server-side)
function Remotes.OnServerRemoteFunction(remoteName: string, handler: (player: Player, ...any) -> ...any)
	if not _checkRunContext(true) then warn("Cannot call OnServerInvoke from client") return end
	local remote = Remotes.GetRemoteFunction(remoteName, RemotesFolder)
	remote.OnServerInvoke = handler
end
-- Link a RemoteFunction to a handler function (Client-side)
function Remotes.OnClientRemoteFunction(remoteName: string, handler: (...any) -> ...any)
	if not _checkRunContext(false) then warn("Cannot call OnClientInvoke from server") return end
	local remote = Remotes.GetRemoteFunction(remoteName, RemotesFolder)
	remote.OnClientInvoke = handler
end

-- EVENT FIRING

-- Fire a RemoteEvent to all clients (Server-side)
function Remotes.FireAllClients(remoteName: string, ...)
	if not _checkRunContext(true) then warn("Cannot call FireAllClients from client") return end
	local remote = Remotes.GetRemoteEvent(remoteName, RemotesFolder)
	remote:FireAllClients(...)
end
-- Fire a RemoteFunction to all clients and get their return values eg. {player1 = "data1", player2 = "data2"}
function Remotes.InvokeAllClients(remoteName: string, ...)
	if not _checkRunContext(true) then warn("Cannot call InvokeAllClients from client") return end
	local remote = Remotes.GetRemoteFunction(remoteName, RemotesFolder)
	local returnData = {}
	for _, player in Players:GetPlayers() do
		local playerData = remote:InvokeClient(player, ...)
		returnData[player] = playerData
	end
	return returnData
end

-- Fire a RemoteEvent to a specific player (Server-side)
function Remotes.FireClient(player: Player, remoteName: string, ...)
	if not _checkRunContext(true) then warn("Cannot call FireClient from client") return end
	local remote = Remotes.GetRemoteEvent(remoteName, RemotesFolder)
	remote:FireClient(player, ...)
	--print(`Fired {remote.Name} in {remote.Parent.Name} to {player.DisplayName}`)
end
-- Fire a RemoteEvent to the server (Client-side)
function Remotes.FireServer(remoteName: string, ...)
	if not _checkRunContext(false) then warn("Cannot call FireServer from server") return end
	local remote = Remotes.GetRemoteEvent(remoteName, RemotesFolder)
	remote:FireServer(...)
end

-- Fire a RemoteFunction to a specific player (Server-side)
function Remotes.InvokeClient(player: Player, remoteName: string, ...)
	if not _checkRunContext(true) then warn("Cannot call InvokeClient from client") return end
	local remote = Remotes.GetRemoteFunction(remoteName, RemotesFolder)
	return remote:InvokeClient(player, ...)
end
-- Fire a RemoteFunction to the server (Client-side)
function Remotes.InvokeServer(remoteName: string, ...)
	if not _checkRunContext(false) then warn("Cannot call InvokeServer from server") return end
	local remote = Remotes.GetRemoteFunction(remoteName, RemotesFolder)
	return remote:InvokeServer(...)
end

return Remotes