local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local ItemData = require(ServerScriptService.Modules.Items.Core.ItemData)
local InvenventoryManager = require(ServerScriptService.Modules.Inventory.Core.InventoryManager)
local ModelUtil = require(game:GetService("ReplicatedStorage").Shared.Utils.Models)

local itemModels = ServerStorage.Items
local cachedItems = ServerStorage.CachedItems
local spawnedItems = game.Workspace:WaitForChild("Items"):WaitForChild("SpawnedItems")

local ItemPickupService = {}

-- Pickup Mode is either "Shared", "Instanced" (client) or "Respawning"
local DEFAULT_PICKUP_MODE: string = "Shared" -- All players can see item
local DEFAULT_RESPAWN_TIME: number = 60

local itemRespawnTimers = {}

local function _createCollisionGroup(name)
	if not pcall(function()
			PhysicsService:RegisterCollisionGroup(name)
		end) then
		-- group already exists
	end
end

local function _setModelTransparency(model: Model, hide:boolean)
	if hide == true then
		model.Parent = cachedItems
	else
		model.Parent = spawnedItems
	end
end

function ItemPickupService.Init()
	-- Collision groups
	_createCollisionGroup("Players")
	_createCollisionGroup("Items")
	PhysicsService:CollisionGroupSetCollidable("Items", "Players", false)
	PhysicsService:CollisionGroupSetCollidable("Items", "Default", true)
	game.Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			ModelUtil.setModelCollisionGroup(character, "Players")
		end)
	end)
	
	-- Item setup
	for _, itemModel in pairs(CollectionService:GetTagged("Item")) do
		if itemModel:IsA("Model") then
			if not itemModel.PrimaryPart then
				warn(`No primary part set for {itemModel.Name}`)
				return
			end
			ItemPickupService.SetupItem(itemModel)
		end
	end
	
	CollectionService:GetInstanceAddedSignal("Item"):Connect(function(itemModel)
		if itemModel:IsA("Model") then
			if not itemModel.PrimaryPart then
				warn(`No primary part set for {itemModel.Name}`)
				return
			end
			ItemPickupService.SetupItem(itemModel)
		end
	end)
end

function ItemPickupService.SetupItem(itemModel: Model)
	ModelUtil.setModelCollisionGroup(itemModel, "Items")
	local pickupMode = itemModel:GetAttribute("PickupMode") or DEFAULT_PICKUP_MODE
	
	if pickupMode == "Instanced" then
		-- For Instanced, hide on server and let clients handle
		_setModelTransparency(itemModel, true)
		itemModel:SetAttribute("SpawnPosition", itemModel.PrimaryPart.CFrame)
	else
		-- For Shared and Respawning, create prompt on server
		local id = itemModel:GetAttribute("Id")
		local quantity = itemModel:GetAttribute("Quantity") or 1
		local item = ItemData.GetItem(id)
		
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Pick up"
		prompt.ObjectText = `{item.name} ({quantity})` or "Placeholder Item"
		prompt.HoldDuration = 0.25
		prompt.MaxActivationDistance = 10
		prompt.Parent = itemModel.PrimaryPart
		
		prompt.Triggered:Connect(function(player)
			ItemPickupService.HandlePickup(player, itemModel)
		end)
	end
end

function ItemPickupService.HandlePickup(player: Player, itemModel: Model)
	local itemId = itemModel:GetAttribute("Id")
	local quantity = itemModel:GetAttribute("Quantity") or 1
	local pickupMode = itemModel:GetAttribute("PickupMode") or DEFAULT_PICKUP_MODE
	
	if pickupMode == "Instanced" then
		warn("Instanced items should be handled on client")
		return
	end
	
	if not itemId then
		warn(`No item Id for spawn location {itemModel.Name}`)
		return
	end
	
	local success = InvenventoryManager.AddItem(player, itemId, quantity)
	
	if success then
		if pickupMode == "Shared" then
			-- Destroy permanently
			itemModel:Destroy()
		elseif pickupMode == "Respawning" then
			-- Hide and respawn later
			local respawnTime = itemModel:GetAttribute("RespawnTime") or DEFAULT_RESPAWN_TIME

			_setModelTransparency(itemModel, true)
			local prompt = itemModel.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Enabled = false
			end
			
			-- Set respawn timer
			itemRespawnTimers[itemModel] = true
			task.wait(respawnTime)
			
			_setModelTransparency(itemModel, false)
			local prompt = itemModel.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
			if prompt then
				prompt.Enabled = false
			end
			prompt.Enabled = true
			itemRespawnTimers[itemModel] = nil
		end
	end
	
end

function ItemPickupService.HandleDrop(player: Player, itemId: string, quantity: number)
	local itemTemplate = itemModels:FindFirstChild(itemId)
	if not itemTemplate then
		warn(`No item exists called {itemId}`)
		return
	end
	local character = player.Character or player.CharacterAdded:Wait()
	local root: BasePart = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		warn(`Player {player.Name} has no HumanoidRootPart when trying to drop item {itemId}`)
		return
	end
	InvenventoryManager.RemoveItem(player, itemId, quantity)
	
	local itemModel: Model = itemTemplate:Clone()
	itemModel:SetAttribute("Quantity", quantity)
	itemModel:SetAttribute("PickupMode", "Shared")
	itemModel.Parent = spawnedItems
	-- Temporarily unanchor model
	local saved = ModelUtil.CaptureAnchorState(itemModel)
	ModelUtil.SetModelAnchored(itemModel, false)
	
	local dropCFrame = root.CFrame * CFrame.new(0,0,-3)
	itemModel:PivotTo(dropCFrame)
	
	CollectionService:AddTag(itemModel, "Item")
	task.wait(2)
	ModelUtil.RestoreAnchorState(saved)
end

return ItemPickupService