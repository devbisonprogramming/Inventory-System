export type ItemType = "Weapon"|"Consumable"|"Material"|"Armour"|"QuestItem"

export type Rarity = "Common"|"Uncommon"|"Rare"|"Epic"|"Legendary"|"Mythic"|"Divine"|"Exalted"|"Developer"

export type EquipSlot = "Head"|"Chest"|"Legs"|"Feet"|"MainHand"|"OffHand"

export type SortType = "Name"|"Quantity"|"Rarity"|"Type"|"None"

export type ItemData = {
	id: string,
	name: string,
	description: string,
	icon: string, -- asset ID
	itemType: ItemType,
	rarity: Rarity,
	stackLimit: number,
	weight: number?,
	
	-- Equipment specific (optional)
	equipSlot: EquipSlot?,
	damage: number?,
	defense: number?,
	
	-- Consumable specific (optional)
	healAmount: number?,
	buffDuration: number?,
}

export type InventorySlot = {
	item: ItemData?,
	quantity: number,
	slotIndex: number,
}

export type PlayerInventory = {
	slots: {InventorySlot},
	hotbarLinks: {number?},
	equipped: {[EquipSlot]: InventorySlot?},
	maxSlots: number,
	gold: number,
}

return {}