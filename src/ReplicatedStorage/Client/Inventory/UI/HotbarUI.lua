local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local InventoryTypes = require(game:GetService("ReplicatedStorage").Shared.Types.InventoryTypes)
type ItemData = InventoryTypes.ItemData
type PlayerInventory = InventoryTypes.PlayerInventory

local HotbarUI = {}

local player = game.Players.LocalPlayer
local hotbar: Frame = player:FindFirstChild("PlayerGui"):FindFirstChild("Inventory"):FindFirstChild("Hotbar")

local selectedHighlight: UIStroke = script.SelectedHighlight
local selectedSlot: number? = nil

local isInSelectionMode = false

local NORMAL_SCALE = 1
local SELECTION_SCALE = 1.05
local TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- Callback gets set in InventoryController
HotbarUI.OnSlotActivated = nil :: ((slotIndex: number) -> ())?
HotbarUI.ConfirmHotbarSelection = nil :: ((slotIndex: number) -> ())?

HotbarUI.Keybinds = {
	[1] = Enum.KeyCode.One,
	[2] = Enum.KeyCode.Two,
	[3] = Enum.KeyCode.Three,
	[4] = Enum.KeyCode.Four,
	[5] = Enum.KeyCode.Five,
	[6] = Enum.KeyCode.Six,
	[7] = Enum.KeyCode.Seven,
	[8] = Enum.KeyCode.Eight,
}

function HotbarUI.SelectSlot(slotIndex: number)
	local slotButton = hotbar:FindFirstChild(tostring(slotIndex))
	if not slotButton then
		warn(`No hotbar slot {slotIndex}`)
		return
	end
	-- Deselect previous slot
	if selectedSlot then
		local prevSlotButton = hotbar:FindFirstChild(tostring(selectedSlot))
		if prevSlotButton then
			local highlight = prevSlotButton:FindFirstChild("SelectedHighlight")
			if highlight then
				highlight:Destroy()
			end
		end
	end
	-- If clicking same slot then deselect
	if selectedSlot == slotIndex then
		selectedSlot = nil
		return
	end

	-- Select new slot
	selectedSlot = slotIndex
	local highlight = selectedHighlight:Clone()
	highlight.Parent = slotButton

end

-- Set a slot to empty
function HotbarUI.SetEmpty(slotIndex: number)
	local slotButton = hotbar:FindFirstChild(tostring(slotIndex))
	if slotButton then
		slotButton:FindFirstChild("Icon").Image = ""
		slotButton:FindFirstChild("Quantity").Text = ""
	end
end

-- Set hotbar info based on ItemData
function HotbarUI.UpdateSlot(slotIndex: number, item: ItemData?, quantity: number)
	if item == nil then
		-- No item provided, empty slot
		HotbarUI.SetEmpty(slotIndex)
		return
	end
	-- Item provided, update slot accordingly
	local slotButton = hotbar:FindFirstChild(tostring(slotIndex))
	if slotButton then
		slotButton:FindFirstChild("Icon").Image = item.icon
		slotButton:FindFirstChild("Quantity").Text = tostring(quantity)
	end
end

function HotbarUI.Init()
	-- Set original size (for tweens)
	hotbar:SetAttribute("OriginalSize", hotbar.Size)
	
	-- Connect button clicks
	for _, v in pairs(hotbar:GetChildren()) do
		if not v:IsA("TextButton") then continue end
		
		local slotIndex = tonumber(v.Name)
		if slotIndex then
			v.Activated:Connect(function()
				if isInSelectionMode then
					-- Confirms the selection
					if HotbarUI.ConfirmHotbarSelection then
						HotbarUI.ConfirmHotbarSelection(slotIndex)
					end
				else
					-- Normal behaviour
					HotbarUI.SelectSlot(slotIndex)
				end
			end)
		end
	end
	
	-- Connect keyboard input
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if not selectedSlot then
				return
			end
			HotbarUI.OnSlotActivated(selectedSlot)
		end
		
		for slot, keybind in pairs(HotbarUI.Keybinds) do
			if input.KeyCode == keybind then
				HotbarUI.SelectSlot(slot)
				break
			end
		end
	end)
end

-- Visually indicate the hotbar to be selected
function HotbarUI.EnterSelectionMode()
	local originalSize:UDim2 = hotbar:GetAttribute("OriginalSize") or UDim2.new(0.5, 0,0.1, 0)
	isInSelectionMode = true
	local scaleTween = TweenService:Create(hotbar, TWEEN_INFO, {
		Size = UDim2.new(
			originalSize.X.Scale * SELECTION_SCALE,
			0,
			originalSize.Y.Scale * SELECTION_SCALE,
			0
		),
	})
	scaleTween:Play()
	
	for i = 1, 8 do
		local slotButton = hotbar:FindFirstChild(tostring(i))
		if slotButton then
			local tween = TweenService:Create(slotButton, TWEEN_INFO, {
				BackgroundColor3 = Color3.fromRGB(140, 205, 255), -- Blue glow
			})
			tween:Play()
		end
	end
end

function HotbarUI.ExitSelectionMode()
	local originalSize:UDim2 = hotbar:GetAttribute("OriginalSize") or UDim2.new(0.5, 0,0.1, 0)
	local scaleTween = TweenService:Create(hotbar, TWEEN_INFO, {
		Size = originalSize,
	})
	scaleTween:Play()

	for i = 1, 8 do
		local slotButton = hotbar:FindFirstChild(tostring(i))
		if slotButton then
			local tween = TweenService:Create(slotButton, TWEEN_INFO, {
				BackgroundColor3 = Color3.fromRGB(185, 185, 185), -- Revert to normal
			})
			tween:Play()
		end
	end
	isInSelectionMode = false
end

-- Updates Hotbar based on inventory data
function HotbarUI.Refresh(inventoryData: PlayerInventory)
	-- Iterate through positions like this as pairs doesn't guarantee order
	for hotbarIndex = 1, 8 do
		local button = hotbar:FindFirstChild(tostring(hotbarIndex))

		if not button or not button:IsA("TextButton") then 
			warn(`Hotbar slot {hotbarIndex} not found or not a TextButton`)
			continue 
		end

		local inventorySlotIndex = inventoryData.hotbarLinks[hotbarIndex]

		if inventorySlotIndex and inventorySlotIndex > 0 then
			print(`Hotbar {hotbarIndex} → Inv slot {inventorySlotIndex}`)
			local inventorySlot = inventoryData.slots[inventorySlotIndex]

			if inventorySlot and inventorySlot.item then
				print(`  Displaying: {inventorySlot.item.name} x{inventorySlot.quantity}`)
				button.Icon.Image = inventorySlot.item.icon
				button.Quantity.Text = tostring(inventorySlot.quantity)
			else
				print(`  ERROR: Inv slot {inventorySlotIndex} is empty/invalid`)
				button.Icon.Image = ""
				button.Quantity.Text = ""
			end
		else
			-- Empty slot
			button.Icon.Image = ""
			button.Quantity.Text = ""
		end
	end
end

return HotbarUI