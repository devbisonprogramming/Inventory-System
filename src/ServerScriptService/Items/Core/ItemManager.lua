local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ItemPickupService = require(ServerScriptService.Modules.Items.Services.ItemPickupService)
local InventoryManager = require(ServerScriptService.Modules.Inventory.Core.InventoryManager)
local Remotes = require(game:GetService("ReplicatedStorage").Shared.Utils.Remotes)

local itemsFolder = ServerStorage.Items -- Path to item assets
local spawnedItems = game.Workspace:WaitForChild("Items"):WaitForChild("SpawnedItems")

local ItemManager = {}
local instancedPlayerPickups: {[Player]: {}} = {}

function ItemManager.Init()
	game.Players.PlayerAdded:Connect(function(player: Player)
		instancedPlayerPickups[player] = {}
	end)
	game.Players.PlayerRemoving:Connect(function(player: Player)
		instancedPlayerPickups[player] = nil
	end)
	
	for _, spawnLocation in pairs(CollectionService:GetTagged("ItemSpawn")) do
		if not spawnLocation:IsA("BasePart") then continue end
		
		local itemId = spawnLocation:GetAttribute("Id")
		local itemModel = ItemManager.GetItem(itemId)
		if itemModel then
			ItemManager.SpawnItem(itemModel, spawnLocation)
			-- Hide spawn location
			spawnLocation.Transparency = 1
			spawnLocation.CanCollide = false
		end
	end
	
	-- Event listening and connections
	Remotes.OnServerRemoteEvent("PickupInstancedItem", function(player: Player, item: Model)
		if ItemManager.CheckInstancedItem(player, item) == true then
			warn(`Player {player.Name} has already picked up {item.Name}`)
			return
		end
		local id = item:GetAttribute("Id")
		if not id then
			warn(`No id for Instanced item {item.Name}`)
			return
		end
		local quantity = item:GetAttribute("Quantity") or 1
		ItemManager.AddInstancedItem(player, item)
		local success = InventoryManager.AddItem(player, id, quantity)
	end)
	Remotes.OnServerRemoteEvent("DropItem", function(player: Player, slotIndex: number, quantity: number)
		local playerInventory = InventoryManager.GetInventory(player)
		local slot = playerInventory.slots[slotIndex]
		if not slot or not slot.item then
			return
		end
		local currentQuantity = slot.quantity
		if quantity > currentQuantity then quantity = currentQuantity end
		ItemPickupService.HandleDrop(player, slot.item.id, quantity)
	end)
end

-- Helper function to return item model from ServerStorage
function ItemManager.GetItem(itemId: string): Model?
	for _, item in pairs(itemsFolder:GetChildren()) do
		if item:GetAttribute("Id") and item:GetAttribute("Id") == itemId and item:IsA("Model") then
			return item
		end
	end
	return nil
end
-- Instantiate an object from ServerStorage with same tags and values as spawn location
function ItemManager.SpawnItem(itemModel: Model, spawnLocation: BasePart)
	local itemInstance = itemModel:Clone()
	CollectionService:AddTag(itemInstance, "Item")
	-- Set attributes
	itemInstance:SetAttribute("PickupMode", spawnLocation:GetAttribute("PickupMode") or "Shared")
	itemInstance:SetAttribute("Quantity", spawnLocation:GetAttribute("Quantity") or 1)
	itemInstance:SetAttribute("RespawnTime", spawnLocation:GetAttribute("RespawnTime") or nil) -- Not all are Respawning
	
	if itemInstance:IsA("Model") then
		itemInstance:PivotTo(spawnLocation.CFrame)
	elseif itemInstance:IsA("BasePart") then
		itemInstance.CFrame = spawnLocation.CFrame
	else
		warn("Invalid type for itemModel")
		return
	end
	
	itemInstance.Parent = spawnedItems
	--itemInstance.Anchored = true
end

-- Add an Instanced item (client-only visible) to player's table
function ItemManager.AddInstancedItem(player: Player, item: Model)
	local playerInstances = instancedPlayerPickups[player]
	if playerInstances and not table.find(playerInstances, item) then
		table.insert(playerInstances, item)
	end
end
-- Returns true if player has already picked up Instanced item (for safety)
function ItemManager.CheckInstancedItem(player: Player, item: Model): boolean
	local playerInstances = instancedPlayerPickups[player]
	if playerInstances and table.find(playerInstances, item) then
		return true
	end
	return false
end

return ItemManager