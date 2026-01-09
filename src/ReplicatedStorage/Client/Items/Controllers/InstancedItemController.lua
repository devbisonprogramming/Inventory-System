local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local InventoryTypes = require(game:GetService("ReplicatedStorage").Shared.Types.InventoryTypes)
type ItemData = InventoryTypes.ItemData

local Remotes = require(game:GetService("ReplicatedStorage").Shared.Utils.Remotes)

local player = Players.LocalPlayer
local spawnedItems = game.Workspace:WaitForChild("Items"):WaitForChild("ClientSpawnedItems")

local InstancedItemController = {}

local pickedUpItems = {} -- Keep track of which Instanced items the client has picked up

local function _setModelTransparency(model: Model, hide:boolean)
	for _, child in pairs(model:GetChildren()) do
		if child:IsA("BasePart") then
			if hide == true then
				child.Transparency = 1
				child.CanCollide = false
			else
				child.Transparency = 0
			end
		end
	end
end

function InstancedItemController.Init()
	-- Find all instanced items
	for _, itemModel in pairs(CollectionService:GetTagged("Item")) do
		if not itemModel:IsA("Model") then continue end
		local pickupMode = itemModel:GetAttribute("PickupMode")
		if pickupMode == "Instanced" then
			InstancedItemController.CreateClientInstance(itemModel)
		end
	end
	CollectionService:GetInstanceAddedSignal("Item"):Connect(function(itemModel)
		if not itemModel:IsA("Model") then return end
		local pickupMode = itemModel:GetAttribute("PickupMode")
		if pickupMode == "Instanced" then
			InstancedItemController.CreateClientInstance(itemModel)
		end
	end)
end

function InstancedItemController.CreateClientInstance(serverModel: Model)
	-- Clone the item for this client only
	local clientModel = serverModel:Clone()
	_setModelTransparency(clientModel, false)
	clientModel.Parent = spawnedItems
	
	-- Add proximity prompt
	local serverItem: ItemData? = Remotes.InvokeServer("GetItem", serverModel:GetAttribute("Id"))
	local quantity = serverModel:GetAttribute("Quantity") or 1
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pick up"
	prompt.ObjectText = `{serverItem.name} ({quantity})` or "Placeholder Item"
	prompt.MaxActivationDistance = 10
	prompt.HoldDuration = 0.25
	prompt.Parent = clientModel
	
	prompt.Triggered:Connect(function()
		-- Tell server to pick up
		Remotes.FireServer("PickupInstancedItem", serverModel)
		-- Hide locally
		clientModel:Destroy()
		-- Track locally as well as on server
		pickedUpItems[serverModel] = true
	end)
	
	if pickedUpItems[serverModel] then
		clientModel:Destroy()
	end
end

return InstancedItemController