-- EXAMPLE SERVER INIT ALSO COMBINED WITH COMMANDS THAT WERE USED WHILST TESTING, REAL INIT CAN BE DIFFERENT DEPENDING ON IMPLEMENTATION

local Players = game:GetService("Players")
local InventoryManager = require(game.ServerScriptService.Modules.Inventory.Core.InventoryManager)
local ItemManager = require(game.ServerScriptService.Modules.Items.Core.ItemManager)
local ItemPickupService = require(game.ServerScriptService.Modules.Items.Services.ItemPickupService)

InventoryManager.Init()
ItemManager.Init()
ItemPickupService.Init()

-- EXAMPLE COMMANDS FOR TESTING PURPOSES.
local commands = {
	["give"] = function(player, args)
		-- Usage: /give iron_ore 10
		local itemId = args[1]
		local quantity = tonumber(args[2]) or 1
		InventoryManager.AddItem(player, itemId, quantity)
	end,
	
	["inv"] = function(player, args)
		-- Usage: /inv
		InventoryManager.AddItem(player, "wooden_sword", 1)
		InventoryManager.AddItem(player, "wooden_shield", 1)
		InventoryManager.AddItem(player, "iron_ore", 100)
		InventoryManager.AddItem(player, "health_potion", 3)
	end,

	["remove"] = function(player, args)
		-- Usage: /remove iron_ore 5
		local itemId = args[1]
		local quantity = tonumber(args[2]) or 1
		InventoryManager.RemoveItem(player, itemId, quantity)
	end,

	["list"] = function(player, args)
		-- Usage: /list
		local inv = InventoryManager.GetInventory(player)
		print(`\n=== {player.DisplayName}'s Inventory ===`)
		for i, slot in ipairs(inv.slots) do
			if slot.item then
				print(`Slot {i}: {slot.item.name} x{slot.quantity}`)
			end
		end
	end,

	["clear"] = function(player, args)
		-- Usage: /clear
		InventoryManager.RemoveInventory(player)
		InventoryManager.AddInventory(player, 20)
		print("Inventory cleared!")
	end,
}

Players.PlayerAdded:Connect(function(player)
	-- DEFAULT A PLAYER INVENTORY OF SIZE 10
	InventoryManager.AddInventory(player, 10)

	player.Chatted:Connect(function(message)
		if message:sub(1, 1) == "/" then
			local args = message:sub(2):split(" ")
			local cmd = table.remove(args, 1)

			if commands[cmd] then
				commands[cmd](player, args)
			end
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	-- CLEANUP DATA
	InventoryManager.RemoveInventory(player)
end)