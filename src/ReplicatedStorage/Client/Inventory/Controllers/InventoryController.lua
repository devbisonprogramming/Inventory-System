local UserInputService = game:GetService("UserInputService")

local Remotes = require(game.ReplicatedStorage.Shared.Utils.Remotes)

local InventoryUI = require(game.ReplicatedStorage.Client.Inventory.UI.InventoryUI)
local HotbarUI = require(game.ReplicatedStorage.Client.Inventory.UI.HotbarUI)

local InventoryTypes = require(game.ReplicatedStorage.Shared.Types.InventoryTypes)
type ItemData = InventoryTypes.ItemData
type PlayerInventory = InventoryTypes.PlayerInventory
type SortType = InventoryTypes.SortType

local InventoryController = {}

local INVENTORY_KEYBIND = Enum.KeyCode.F

local localInventory:PlayerInventory? = nil

-- Selection state
local isSelectingHotbarSlot = false
local selectedInventorySlot: number? = false

-- Returns the player's inventory
function InventoryController.GetInventory(): PlayerInventory
	local newInventory = Remotes.InvokeServer("GetPlayerInventory")
	localInventory = newInventory
	return newInventory
end

function InventoryController.GetItemQuantity(item: ItemData): number
	local quantity = Remotes.InvokeServer("GetItemQuantity", item)
	return quantity
end

function InventoryController.Init()
	-- Event listeners
	Remotes.OnClientRemoteEvent("InitInventory", function(newInventory: PlayerInventory)
		localInventory = newInventory
		InventoryUI.Init(newInventory)
	end)
	Remotes.OnClientRemoteEvent("UpdateInventory", function(inventoryData)
		-- DEBUGGING PRINT STATEMENTS
		--print("Raw hotbarLinks received:", inventoryData.hotbarLinks)

		-- Check if references are broken
		for i = 1, 8 do
			local link = inventoryData.hotbarLinks[i]
			if link then
				--print(`  hotbarLinks[{i}] = {link}`)
			end
		end

		localInventory = inventoryData
		InventoryUI.UpdateInventory(inventoryData)
		HotbarUI.Refresh(inventoryData)
	end)
	
	-- Set HotbarUI callbacks
	HotbarUI.OnSlotActivated = function(slotIndex: number)
		InventoryController.UseHotbarSlot(slotIndex)
	end
	HotbarUI.ConfirmHotbarSelection = function(slotIndex: number)
		InventoryController.ConfirmHotbarSelection(slotIndex)
	end
	-- Set InventoryUI callbacks
	InventoryUI.OnEquipToHotbar = function(slotIndex: number)
		InventoryController.StartHotbarSelection(slotIndex)
	end
	InventoryUI.DropItem = function(slotIndex: number, quantity: number)
		Remotes.FireServer("DropItem", slotIndex, quantity)
	end
	InventoryUI.SortInventory = function(sortType: SortType, sortOrder)
		InventoryController.SortInventory(sortType, sortOrder)
	end
	
	-- Initialise UIs
	HotbarUI.Init()
	--InventoryUI.Init(localInventory)
	
	-- Inputs
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == INVENTORY_KEYBIND and isSelectingHotbarSlot then
			InventoryController.CancelHotbarSelection()
		end
	end)
end

-- Handles Hotbar usage
function InventoryController.UseHotbarSlot(slotIndex: number)
	if not localInventory then return end
	
	if slotIndex < 1 or slotIndex > 8 then
		warn("Provided hotbar index out of range.")
		return
	end
	
	local inventoryIndex = localInventory.hotbarLinks[slotIndex]
	if not inventoryIndex then
		-- No item in hotbar slot
		return
	end
	local inventorySlot = localInventory.slots[inventoryIndex]
	if not inventorySlot then
		return
	end
	
	local item = inventorySlot.item
	Remotes.FireServer("UseItem", item.id, slotIndex)
end

function InventoryController.StartHotbarSelection(slotIndex: number)
	-- Update inventory for sanity
	localInventory = InventoryController.GetInventory()
	
	local slot = localInventory.slots[slotIndex]
	if not slot or not slot.item then
		warn(`No item in slot {slotIndex}`)
		return
	end
	
	-- Enter selection mode
	isSelectingHotbarSlot = true
	selectedInventorySlot = slotIndex
	
	-- Fire UIs to change
	HotbarUI.EnterSelectionMode()
	InventoryUI.ShowSelectionPrompt("Click a hotbar slot (1-8)")
end

function InventoryController.ConfirmHotbarSelection(hotbarSlot: number)
	-- Check if we are actually selecting
	if not isSelectingHotbarSlot or not selectedInventorySlot then
		warn("Not in selection mode")
		return
	end
	
	-- Send to server
	local success = Remotes.InvokeServer("BindHotbarSlot", hotbarSlot, selectedInventorySlot)
	
	-- Update local until server can confirm
	if localInventory then
		localInventory.hotbarLinks[hotbarSlot] = selectedInventorySlot
	end
	--print(`Bound inventory slot {selectedInventorySlot} to hotbar slot {hotbarSlot}`)
	InventoryController.CancelHotbarSelection()
end

function InventoryController.CancelHotbarSelection()
	isSelectingHotbarSlot = false
	selectedInventorySlot = nil
	
	HotbarUI.ExitSelectionMode()
	InventoryUI.HideSelectionPrompt()
end

function InventoryController.IsSelectingHotbarSlot(): boolean
	return isSelectingHotbarSlot
end

-- Sort inventory based on current sortType
function InventoryController.SortInventory(sortType: SortType, sortOrder)
	local inventory = InventoryController.GetInventory()
	local slots = inventory.slots
	
	if sortType == "None"  then
		return slots
	end
	
	-- Create a temorary copy to avoid mutating original
	local sortedSlots = {}
	for _, slot in ipairs(slots) do
		table.insert(sortedSlots, slot)
	end
	-- Sort based on type
	if sortType == "Name" then
		table.sort(sortedSlots, function(a,b)
			-- Empty slots go to the end
			if not a.item then return false end
			if not b.item then return true end
			
			if sortOrder == "Ascending" then
				return a.item.name < b.item.name
			else
				return a.item.name > b.item.name
			end
		end)
		
	elseif sortType == "Quantity" then
		table.sort(sortedSlots, function(a, b)
			if not a.item then return false end
			if not b.item then return true end
			
			if sortOrder == "Ascending" then
				return a.quantity < b.quantity
			else
				return a.quantity > b.quantity
			end
		end)
			
	elseif sortType == "Rarity" then
		-- Define rarity order
		local rarityOrder = {
			Common = 1,
			Uncommon = 2,
			Rare = 3,
			Epic = 4,
			Legendary = 5,
			Mythic = 6,
			Divine = 7,
			Exalted = 8,
			Developer = 9
		}
		
		table.sort(sortedSlots, function(a, b)
			if not a.item then return false end
			if not b.item then return true end
			
			local aRarity = rarityOrder[a.item.rarity] or 0
			local bRarity = rarityOrder[b.item.rarity] or 0
			
			if sortOrder == "Ascending" then
				return aRarity < bRarity
			else
				return aRarity > bRarity
			end
		end)
			
	elseif sortType == "Type" then
		table.sort(sortedSlots, function(a, b)
			if not a.item then return false end
			if not b.item then return true end

			if sortOrder == "Ascending" then
				return a.item.itemType < b.item.itemType
			else
				return a.item.itemType > b.item.itemType
			end
		end)
	end
	InventoryUI.UpdateInventory(inventory, sortedSlots)
end

return InventoryController