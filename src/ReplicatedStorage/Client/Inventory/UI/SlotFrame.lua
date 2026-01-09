local InventoryTypes = require(game.ReplicatedStorage.Shared.Types.InventoryTypes)
type ItemData = InventoryTypes.ItemData

local SlotFrame = {}
SlotFrame.__index = SlotFrame

local slotTemplate = script.SlotFrame

function SlotFrame.new(parent: Instance, slotIndex: number, onClicked: ((slotIndex:number)->())?, onHover: ((slotIndex:number)->()))
	local self = setmetatable({}, SlotFrame)
	
	self.frame = slotTemplate:Clone()
	self.frame.Parent = parent
	self.frame.Name = "empty_slot"
	self.slotIndex = slotIndex
	self.currentItem = nil
	self.frame.Quantity.Text = ""
	self.frame.Icon.Image = ""
	
	-- Click event
	if onClicked then
		self.frame.MouseButton1Click:Connect(function()
			onClicked(self.slotIndex)
		end)
	end
	-- Hover event
	if onHover then
		self.frame.MouseEnter:Connect(function()
			onHover(self.slotIndex, true)
		end)
		self.frame.MouseLeave:Connect(function()
			onHover(self.slotIndex, false)
		end)
	end
	
	return self
end

-- Updates the quantity and icon of the slot
function SlotFrame:UpdateVisuals(itemData: ItemData, quantity: number)
	self.currentItem = itemData
	self.frame.Name = itemData.id
	local quantityFrame: TextLabel = self.frame:FindFirstChild("Quantity")
	local icon: ImageLabel = self.frame:FindFirstChild("Icon")
	if quantityFrame then
		quantityFrame.Text = quantity
	end
	local imageId = itemData.icon
	if icon then
		icon.Image = imageId
	end
end
-- Sets slot to default (not highlighted)
function SlotFrame:SetEmpty()
	self.currentItem = nil
	self.frame.Name = "empty_slot"
	self.frame.Quantity.Text = ""
	self.frame.Icon.Image = ""
	self.frame.BackgroundColor3 = Color3.fromRGB(185,185,185)
end

-- Destroys slot
function SlotFrame:Destroy()
	self.frame:Destroy()
end

return SlotFrame