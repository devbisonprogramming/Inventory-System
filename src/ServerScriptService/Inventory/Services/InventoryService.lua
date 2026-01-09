local ItemData = require(game:GetService("ServerScriptService").Modules.Items.Core.ItemData)
local InventoryTypes = require(game:GetService("ReplicatedStorage").Shared.Types.InventoryTypes)
type PlayerInventory = InventoryTypes.PlayerInventory
type ItemData = InventoryTypes.ItemData
type ItemType = InventoryTypes.ItemType

local InventoryService = {}

function InventoryService.UseItem(player: Player, inventory: PlayerInventory, itemId: string, itemIndex: number)
	-- Todo: Add functionality and link to other systems in game
	local item = ItemData.Items[itemId]
	if not item then
		warn(`No item named {itemId} in ItemData for {player.DisplayName}`)
	end
	print(`{player.DisplayName} used {item.name} of type {item.itemType}`)
	
	-- Example functionality of how to link in to other in game systems
	if item.itemType == "Weapon" then
		-- EquipmentService.EquipWeapon(item)
	elseif item.itemType == "Armour" then
		-- EquipmentService.EquipArmour(item)
	elseif item.itemType == "Consumable" then
		-- ConsumableService.ConsumeItem(item)
	elseif item.itemType == "Material" then
		-- CraftingService.CraftItem(item)
	elseif item.itemType == "QuestItem" then
		-- QuestService.IncrementQuest(item)
	else
		-- Item has no item type, add handling here
	end
end

return InventoryService