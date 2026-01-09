-- EXAMPLE INIT, PRECICE IMPLEMENTATION DEPENDS ON GAME STRUCTURE AND MODULE LOADING

-- Require controllers
local InventoryController = require(game.ReplicatedStorage.Client.Inventory.Controllers.InventoryController)
local InventoryUI = require(game.ReplicatedStorage.Client.Inventory.UI.InventoryUI)
local HotbarUI = require(game.ReplicatedStorage.Client.Inventory.UI.HotbarUI)

local InstancedItemController = require(game.ReplicatedStorage.Client.Items.Controllers.InstancedItemController)

-- Initialize systems

InventoryController.Init()
task.wait()
InstancedItemController.Init()