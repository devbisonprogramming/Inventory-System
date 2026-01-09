local InventoryTypes = require(game.ReplicatedStorage.Shared.Types.InventoryTypes)
type ItemData = InventoryTypes.ItemData

local ItemData = {}

-- Items (type checked as ItemData in format keyName = {ItemData})
ItemData.Items = {
	["wooden_sword"] = {
		id = "wooden_sword",
		name = "Wooden Sword",
		description = "A basic sword made of wood. Better than nothing.",
		icon = "rbxassetid://104979873854197",
		itemType = "Weapon",
		rarity = "Divine",
		stackLimit = 1,
		weight = 2.5,
		-- Weapon specifics
		equipSlot = "MainHand",
		damage = 10,
	}::ItemData,
	
	["wooden_shield"] = {
		id = "wooden_shield",
		name = "Wooden Shield",
		description = "A basic shield made of wood. It provides some defense.",
		icon = "rbxassetid://123420033360960",
		itemType = "Shield",
		rarity = "Developer",
		stackLimit = 1,
		weight = 5,
		-- Weapon specifics
		equipSlot = "OffHand",
		defense = 10,
	}::ItemData,
	
	["health_potion"] = {
		id = "health_potion",
		name = "Health Potion",
		description = "A potion that heals 20 HP when consumed.",
		icon = "rbxassetid://105365164765601",
		itemType = "Potion",
		rarity = "Exalted",
		stackLimit = 10,
		weight = 0.5,
		-- Consumable specifics
		healAmount = 20,
	}::ItemData,
	
	["iron_ore"] = {
		id = "iron_ore",
		name = "Iron Ore",
		description = "A piece of iron ore.",
		icon = "rbxassetid://129776201855040",
		itemType = "Ore",
		rarity = "Mythic",
		stackLimit = 64,
		weight = 1,
	}::ItemData,
}

-- Helper function to get item
function ItemData.GetItem(itemId: string): ItemData?
	return ItemData.Items[itemId]
end

-- Validate an item exists
function ItemData.ValidateItem(itemId: string): boolean
	return ItemData.Items[itemId] ~= nil
end

return ItemData