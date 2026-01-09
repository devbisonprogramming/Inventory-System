local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local Remotes = require(game.ReplicatedStorage.Shared.Utils.Remotes)
local Tween = require(game.ReplicatedStorage.Shared.Utils.Tween)

local InventoryTypes = require(game.ReplicatedStorage.Shared.Types.InventoryTypes)
type ItemData = InventoryTypes.ItemData
type PlayerInventory = InventoryTypes.PlayerInventory
type SortType = InventoryTypes.SortType

local SlotFrame = require(script.Parent.SlotFrame)
local InfoPanel = require(script.Parent.InfoPanel)

local InventoryUI = {}
local slots = {}
local selectedSlot

local player = game.Players.LocalPlayer
local inventoryGui = player:FindFirstChild("PlayerGui"):FindFirstChild("Inventory")
local inventoryFrame: Frame = inventoryGui:FindFirstChild("Main")
local inventoryGrid: ScrollingFrame = inventoryFrame:FindFirstChild("InventoryGrid")
local infoPanelFrame: Frame = inventoryFrame:FindFirstChild("ItemInfoPanel")
local storageLabel: TextLabel = inventoryFrame:FindFirstChild("Storage")
local prompt: TextLabel = inventoryGui:FindFirstChild("Prompt")

local infoPanel = InfoPanel.new(infoPanelFrame)

local sortType:SortType = "None"
local sortOrder: "Ascending" | "Descending" = "Ascending"

-- All available sort types in order
local SORT_TYPES: {SortType} = {"None", "Name","Name", "Quantity","Quantity", "Rarity","Rarity", "Type","Type"}

-- Display names
local SORT_DISPLAY_NAMES = {
	None = "Sort: None",
	Name = "Sort: Name ↑",
	Quantity = "Sort: Quantity ↑",
	Rarity = "Sort: Rarity ↑",
	Type = "Sort: Type ↑"
}

local SORT_DISPLAY_NAMES_DESC = {
	None = "Sort: None",
	Name = "Sort: Name ↓",
	Quantity = "Sort: Quantity ↓",
	Rarity = "Sort: Rarity ↓",
	Type = "Sort: Type ↓"
}

local INVENTORY_KEYBIND:Enum.KeyCode = Enum.KeyCode.F

local UNSELECTED_COLOUR = Color3.fromRGB(185, 185, 185)
local SELECTED_COLOUR = Color3.fromRGB(163, 255, 114)

local onEquipCooldown:boolean = false
local COOLDOWN_DURATION = 0.5

-- Connections
local currentEquipButtonConnection: RBXScriptConnection? = nil
local currentDeleteButtonConnection: RBXScriptConnection? = nil

-- Callbacks (set in InventoryController)
InventoryUI.OnEquipToHotbar = nil :: ((slotIndex: number) -> ())?
InventoryUI.DropItem = nil :: ((slotIndex: number) -> ())?
InventoryUI.SortInventory = nil :: ((currentSortType: SortType, currentSortOrder:"Ascending" | "Descending") -> ())?

local function _handleSlotClick(slotIndex: number)
	-- Show item info panel
	-- Handle selection logic
	if selectedSlot then
		selectedSlot.frame.BackgroundColor3 = UNSELECTED_COLOUR
		selectedSlot.frame:SetAttribute("Selected", nil)
		selectedSlot = nil
	end
	
	selectedSlot = slots[slotIndex]
	selectedSlot.frame.BackgroundColor3 = SELECTED_COLOUR
	selectedSlot.frame:SetAttribute("Selected", true)
	
	-- Display info panel
	if selectedSlot.currentItem == nil then
		infoPanel:SetEmpty()
	else
		local quantity = InventoryUI.GetItemQuantity(selectedSlot.currentItem)
		infoPanel:UpdateItem(selectedSlot.currentItem, quantity)
		-- Connect info panel equip to hotbar functionality
		local equip:TextButton = infoPanelFrame:FindFirstChild("EquipButton")
		if equip then
			if currentEquipButtonConnection then
				currentEquipButtonConnection:Disconnect()
			end
			currentEquipButtonConnection = equip.Activated:Connect(function()
				if onEquipCooldown == true then
					-- Cannot equip if player is on cooldown to prevent spam
					return
				end
				onEquipCooldown = true
				task.delay(COOLDOWN_DURATION, function()
					onEquipCooldown = false
				end)
				--print("Started equipping something")
				if InventoryUI.OnEquipToHotbar then
					InventoryUI.OnEquipToHotbar(slotIndex)
				end
			end)
		end
		-- Connect drop button to drop functionality
		local drop:TextButton = infoPanelFrame:FindFirstChild("DropButton")
		local dropQuantity:TextBox = infoPanelFrame:FindFirstChild("DropQuantity")
		if drop then
			if currentDeleteButtonConnection then
				currentDeleteButtonConnection:Disconnect()
			end
			currentDeleteButtonConnection = drop.Activated:Connect(function()
				if InventoryUI.DropItem then
					local quantity = tonumber(dropQuantity.Text)
					InventoryUI.DropItem(slotIndex, quantity)
				end
			end)
		end
	end
end

local function _handleSlotHover(slotIndex: number, tweenIn:boolean)
	local slot = slots[slotIndex]
	-- Show tooltip, play hover anim
	if slot.frame:GetAttribute("Selected") then
		return
	end
	if tweenIn == true then
		Tween.Hover(slot.frame)
	elseif tweenIn == false then
		Tween.UnHover(slot.frame)
	end
end

-- Sets up slots in player's inventory
function InventoryUI.Init(inventory: PlayerInventory)
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == INVENTORY_KEYBIND then
			if inventoryFrame.Visible then
				InventoryUI.CloseInventory()
			else
				InventoryUI.OpenInventory()
			end
		end
	end)
	if not inventory then return end
	local maxSpace = inventory.maxSlots or 10
	-- Change to get max size of player's inventory
	for i = 1, maxSpace do
		local slot = SlotFrame.new(inventoryGrid, i, _handleSlotClick, _handleSlotHover)
		table.insert(slots, slot)
	end
	-- Init the info panel
	infoPanel:SetEmpty()
	-- Init the drop quantity text box
	infoPanel:InitTextBox()
	
	-- Link sort button
	local sortButton = inventoryFrame:FindFirstChild("SortType")
	if sortButton and sortButton:IsA("TextButton") then
		sortButton.Text = SORT_DISPLAY_NAMES[sortType]
		-- Cycle sort mode on click
		sortButton.Activated:Connect(function()
			InventoryUI.CycleSortType()
		end)
	else
		warn("Sort button not found")
	end
end

function InventoryUI.CycleSortType()
	local currentIndex = table.find(SORT_TYPES, sortType) or 1
	local nextIndex = currentIndex + 1
	
	-- If clicking the same sort type, toggle order
	if nextIndex <= #SORT_TYPES and SORT_TYPES[nextIndex] == sortType then
		if sortOrder == "Ascending" then
			sortOrder = "Descending"
		else
			sortOrder = "Ascending"
			-- Move to next sort type
			nextIndex = nextIndex + 1
		end
	end
	-- Loop back to start
	if nextIndex > #SORT_TYPES then
		nextIndex = 1
	end
	
	sortType = SORT_TYPES[nextIndex]
	
	-- Update button
	local sortButton = inventoryFrame:FindFirstChild("SortType")
	if sortButton then
		if sortOrder == "Ascending" then
			sortButton.Text = SORT_DISPLAY_NAMES[sortType]
		else
			sortButton.Text = SORT_DISPLAY_NAMES_DESC[sortType]
		end
	end
	-- Deselect any item selected
	if selectedSlot then
		selectedSlot.frame.BackgroundColor3 = UNSELECTED_COLOUR
		selectedSlot.frame:SetAttribute("Selected", nil)
		selectedSlot = nil
		infoPanel:SetEmpty()
	end

	-- Re-sort and refresh inventory
	InventoryUI.SortInventory(sortType, sortOrder)
end

function InventoryUI.OpenInventory()
	infoPanel:SetEmpty()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
	inventoryFrame.Visible = true
end

function InventoryUI.CloseInventory()
	inventoryFrame.Visible = false
	if selectedSlot then
		selectedSlot.frame.BackgroundColor3 = UNSELECTED_COLOUR
		selectedSlot = nil
	end
	infoPanel:SetEmpty()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
end

function InventoryUI.UpdateInventory(inventory: PlayerInventory, sortedSlots)
	if not inventory then return end
	
	for i, slot in ipairs(slots) do
		local inventorySlot
		if sortedSlots then
			inventorySlot = sortedSlots[i]
		else
			inventorySlot = inventory.slots[i]
		end
		if inventorySlot then
			slot:UpdateVisuals(inventorySlot.item, inventorySlot.quantity)
		else
			slot:SetEmpty()
		end
	end
	if selectedSlot then
		local quantity = InventoryUI.GetItemQuantity(selectedSlot.currentItem)
		infoPanel:UpdateItem(selectedSlot.currentItem, quantity)
	end
	local usedStorage = #inventory.slots
	local maxStorage = inventory.maxSlots
	storageLabel.Text = `Storage: {usedStorage}/{maxStorage}`
end

function InventoryUI.ShowSelectionPrompt(message: string)
	-- Easy to add Tweens if desired
	prompt.Text = message
	prompt.Visible = true
end

function InventoryUI.HideSelectionPrompt()
	-- Again, easy to add Tweens
	prompt.Visible = false
end

function InventoryUI.GetItemQuantity(item: ItemData): number
	local quantity = Remotes.InvokeServer("GetItemQuantity", item)
	return quantity
end

return InventoryUI