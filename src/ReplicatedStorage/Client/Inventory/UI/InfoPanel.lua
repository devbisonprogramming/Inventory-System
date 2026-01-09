local Remotes = require(game.ReplicatedStorage.Shared.Utils.Remotes)

local InventoryTypes = require(game.ReplicatedStorage.Shared.Types.InventoryTypes)
type ItemData = InventoryTypes.ItemData

local InfoPanel = {}
InfoPanel.__index = InfoPanel

InfoPanel.Colours = {
	Common = Color3.fromRGB(255, 255, 255),
	Uncommon = Color3.fromRGB(163, 255, 129),
	Rare = Color3.fromRGB(37, 197, 255),
	Epic = Color3.fromRGB(97, 35, 255),
	Legendary = Color3.fromRGB(255, 237, 42),
	Mythic = Color3.fromRGB(255, 12, 255),
	Divine = Color3.fromRGB(255, 21, 25),
	Exalted = Color3.fromRGB(68, 255, 0),
	Developer = Color3.fromRGB(0, 0, 0),
}

function InfoPanel.new(frame: Frame)
	local self = setmetatable({}, InfoPanel)
	
	self.frame = frame
	self.equipButton = frame:FindFirstChild("EquipButton")
	self.dropButton = frame:FindFirstChild("DropButton")
	self.dropQuantity = frame:FindFirstChild("DropQuantity")
	self.image = frame:FindFirstChild("Image")
	self.description = frame:FindFirstChild("Description")
	self.itemSpecifics = frame:FindFirstChild("ItemSpecifics")
	self.quantity = frame:FindFirstChild("Quantity")
	self.rarity = frame:FindFirstChild("Rarity")
	self.rarityTitle = frame:FindFirstChild("RarityTitle")
	self.title = frame:FindFirstChild("Title")
	self.type = frame:FindFirstChild("Type")
	self.item = nil
	
	return self
end

function InfoPanel:SetEmpty()
	self.equipButton.Visible = false
	self.dropButton.Visible = false
	self.dropQuantity.Visible = false
	self.dropQuantity.Text = ""
	self.image.Image = ""
	self.description.Text = ""
	self.itemSpecifics.Text = ""
	self.quantity.Text = ""
	self.rarity.Text = ""
	self.rarityTitle.Visible = false
	self.title.Text = ""
	self.type.Text = ""
	self.item = nil
end

function InfoPanel:UpdateItem(newItem: ItemData, quantity: number)
	self.item = newItem
	self.equipButton.Visible = true
	self.dropButton.Visible = true
	self.dropQuantity.Visible = true
	self.dropQuantity.Text = 1
	self.image.Image = newItem.icon
	self.description.Text = newItem.description
	--self.itemSpecifics.Text = newItem
	self.quantity.Text = `Quantity: {quantity}`
	self.rarity.Text = newItem.rarity
	self.rarityTitle.Visible = true
	self.title.Text = newItem.name
	self.type.Text = newItem.itemType
	self:SetRarityColour(newItem.rarity)
end

function InfoPanel:InitTextBox()
	self.dropQuantity.FocusLost:Connect(function(enterPressed)
		local textBox = self.dropQuantity
		local inputtedValue = tonumber(textBox.Text)
		local text = self.quantity.Text
		local currentMaxQuantity = tonumber(text:match("%d+")) or 1
		if not inputtedValue then
			textBox.Text = tostring(0)
			return
		end
		-- Clamp to range
		inputtedValue = math.clamp(inputtedValue, 0, tonumber(currentMaxQuantity))
		textBox.Text = tostring(inputtedValue)
	end)
end

function InfoPanel:SetRarityColour(rarity: string)
	local colour = InfoPanel.Colours[rarity]
	self.rarity.TextColor3 = colour
	self.title.TextColor3 = colour
end

return InfoPanel