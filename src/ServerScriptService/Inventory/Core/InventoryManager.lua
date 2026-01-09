local HttpService = game:GetService("HttpService")

local InventoryService = require(game.ServerScriptService.Modules.Inventory.Services.InventoryService)
local Remotes = require(game.ReplicatedStorage.Shared.Utils.Remotes)

local InventoryTypes = require(game.ReplicatedStorage.Shared.Types.InventoryTypes)
type ItemData = InventoryTypes.ItemData
type InventorySlot = InventoryTypes.InventorySlot
type PlayerInventory = InventoryTypes.PlayerInventory

local ItemData = require(game.ServerScriptService.Modules.Items.Core.ItemData)

local InventoryManager = {}
local playerInventories: {[Player]: PlayerInventory} = {}

-- Helper function to create clean copy of table for sending to client for safety
local function cloneInventory(original)
	local copy = {}
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = cloneInventory(value)
		else
			copy[key] = value
		end
	end
	return copy
end

-- Create new PlayerInventory to playerInventories
function InventoryManager.AddInventory(player: Player, maxSlots: number)
	local inventory: PlayerInventory = {
		slots = {},
		hotbarLinks = {0, 0, 0, 0, 0, 0, 0, 0}, -- 8 hotbar slots
		equipped = {},
		maxSlots = maxSlots,
		gold = 0,
	}
	playerInventories[player] = inventory
	Remotes.FireClient(player, "InitInventory", cloneInventory(inventory))
end
-- Remove PlayerInventory from playerInventories
function InventoryManager.RemoveInventory(player: Player)
	playerInventories[player] = nil
end
-- Get an existing PlayerInventory
function InventoryManager.GetInventory(player: Player): PlayerInventory
	return playerInventories[player]
end

-- Helper function to check if player can take in any more items. Returns result
function InventoryManager.HasInventorySpace(player: Player, inventory: PlayerInventory): boolean
	if #inventory.slots >= inventory.maxSlots then
		print(`Max inventory space for {player.DisplayName}`)
		return false
	end
	return true
end

-- Add an item to a player's inventory. Returns true for successful item addition
function InventoryManager.AddItem(player: Player, itemId: string, quantity: number): boolean
	local inventory = InventoryManager.GetInventory(player)
	local newItem = ItemData.Items[itemId]
	
	if not newItem then
		warn(`Item of ID {itemId} not found in ItemData`)
		return false
	end
	
	-- Check through inventory to see if item is already present, and try to stack with existing items
	local remainingQuantity = quantity
	for _, slot in ipairs(inventory.slots) do
		if remainingQuantity <= 0 then break end
		
		if slot.item and slot.item.id == newItem.id then
			local availableSpace = newItem.stackLimit - slot.quantity
			if availableSpace > 0 then
				local amountToAdd = math.min(remainingQuantity, availableSpace)
				slot.quantity += amountToAdd
				remainingQuantity -= amountToAdd
			end
		end
	end
	
	-- Create new slots for remaining quantity
	while remainingQuantity > 0 do
		-- Check the player still has space
		if not InventoryManager.HasInventorySpace(player, inventory) then
			warn(`Inventory full for {player.DisplayName}. Could only add {quantity - remainingQuantity}/{quantity} items.`)
			return false
		end
		
		local amountForNewSlot = math.min(remainingQuantity, newItem.stackLimit)
		local newSlot: InventorySlot = {
			item = newItem,
			quantity = amountForNewSlot,
			slotIndex = #inventory.slots + 1
		}
		table.insert(inventory.slots, newSlot)
		remainingQuantity -= amountForNewSlot
	end
	
	-- Reindex slots
	for i, slot in ipairs(inventory.slots) do
		slot.slotIndex = i
	end
	
	print(`Successfully added {quantity} {newItem.name} to {player.DisplayName}'s inventory.`)
	Remotes.FireClient(player, "UpdateInventory", cloneInventory(inventory))
	return true
end
-- Remove an item from a player's inventory. 
function InventoryManager.RemoveItem(player: Player, itemId: string, quantity: number)
	local inventory = InventoryManager.GetInventory(player)
	local itemToRemove = ItemData.Items[itemId]
	
	if not itemToRemove then
		warn(`Item of ID {itemId} not found in ItemData`)
		return false
	end
	
	-- First loop to find total quantity
	local currentQuantity = 0
	for _, inventorySlot in ipairs(inventory.slots) do
		local slotItem = inventorySlot.item
		if slotItem and slotItem.id == itemToRemove.id then
			currentQuantity += inventorySlot.quantity
		end
	end
	-- Check if the requested quantity can be removed
	if currentQuantity < quantity then
		warn(`Not enough {itemToRemove.name} to remove. Has {currentQuantity}, needs {quantity}`)
		return false
	end
	-- Remove from slots, starting from the end (to avoid index shifting issues)
	local remainingToRemove = quantity
	for i = #inventory.slots, 1, -1 do
		if remainingToRemove <= 0 then break end
		
		local slot = inventory.slots[i]
		if slot.item and slot.item.id == itemId then
			if slot.quantity <= remainingToRemove then
				-- Remove entire slot
				remainingToRemove -= slot.quantity
				table.remove(inventory.slots, i)
			else
				-- Partially remove from this slot
				slot.quantity -= remainingToRemove
				remainingToRemove = 0
			end
		end
	end
	
	-- Reindex slots
	for i, slot in ipairs(inventory.slots) do
		slot.slotIndex = i
	end
	
	print(`Successfully removed {quantity} {itemToRemove.name} from {player.DisplayName}'s inventory.`)
	Remotes.FireClient(player, "UpdateInventory", cloneInventory(inventory))
	return true
end

function InventoryManager.GetItemQuantity(player: Player, item: ItemData)
	local inventory = InventoryManager.GetInventory(player)
	local totalQuantity = 0
	for _, slot in ipairs(inventory.slots) do
		if slot.item and slot.item.id == item.id then
			totalQuantity += slot.quantity
		end
	end
	return totalQuantity
end

-- Link inventory slot to hotbar. Returns success
function InventoryManager.SetHotbarLink(player: Player, hotbarSlot: number, inventorySlot: number?):boolean
	local inventory = InventoryManager.GetInventory(player)
	if not inventory then return false end
	
	-- Validate hotbar slot
	if hotbarSlot < 1 or hotbarSlot > 8 then
		warn(`False hotbar slot provided. Must be in range 1-8, got {hotbarSlot}`)
		return false
	end
	-- Clear hotbar slot if no inventorySlot provided
	if inventorySlot == nil then
		inventory.hotbarLinks[hotbarSlot] = 0
		return true
	end
	-- Validate inventorySlot
	if inventorySlot < 1 or inventorySlot > #inventory.slots then
		warn(`False inventory slot provided. Must be in range 1-{#inventory.slots}, got {inventorySlot}`)
		return false
	end
	
	local slot = inventory.slots[inventorySlot]
	if not slot then
		warn(`No item in slot {inventorySlot}`)
		return false
	end
	-- Stop same item being put into multiple hotbar slots
	for hotbarIndex, slot in inventory.hotbarLinks do
		if slot == inventorySlot then
			inventory.hotbarLinks[hotbarIndex] = 0
		end
	end
	
	inventory.hotbarLinks[hotbarSlot] = inventorySlot
	Remotes.FireClient(player, "UpdateInventory", cloneInventory(inventory))
	return true
end

-- Get item from hotbar slot
function InventoryManager.GetHotbarItem(player: Player, hotbarSlot: number): InventorySlot
	local inventory = InventoryManager.GetInventory(player)
	if not inventory then return false end

	-- Validate hotbar slot
	if hotbarSlot < 1 or hotbarSlot > 8 then
		warn(`False hotbar slot provided. Must be in range 1-8, got {hotbarSlot}`)
		return false
	end
	
	local itemIndex = inventory.hotbarLinks[hotbarSlot]
	if itemIndex < 1 or itemIndex > #inventory.slots then
		warn(`False inventory slot provided. Must be in range 1-{#inventory.slots}, got {itemIndex}`)
		return false
	end
	
	local item = inventory.slots[itemIndex]
	return item
end

-- Init
function InventoryManager.Init()
	-- Create remotes
	Remotes.NewRemoteEvent("UpdateInventory")
	Remotes.NewRemoteEvent("UseItem")

	-- Set up event listeners
	Remotes.OnServerRemoteFunction("GetPlayerInventory", function(player: Player)
		return InventoryManager.GetInventory(player)
	end)
	Remotes.OnServerRemoteFunction("GetItemQuantity", function(player: Player, item: ItemData)
		return InventoryManager.GetItemQuantity(player, item)
	end)
	Remotes.OnServerRemoteFunction("GetItem", function(player: Player, itemId: string)
		return ItemData.GetItem(itemId)
	end)
	Remotes.OnServerRemoteFunction("GetHotbarItem", function(player: Player, hotbarSlot: number)
		return InventoryManager.GetHotbarItem(player, hotbarSlot)
	end)
	Remotes.OnServerRemoteFunction("BindHotbarSlot", function(player: Player, hotbarSlot: number, inventorySlot: number)
		return InventoryManager.SetHotbarLink(player, hotbarSlot, inventorySlot)
	end)
	Remotes.OnServerRemoteEvent("UseItem", function(player: Player, itemId: string, itemIndex: number)
		local inventory = InventoryManager.GetInventory(player)
		InventoryService.UseItem(player, inventory, itemId, itemIndex)
	end)
end

return InventoryManager