local PhysicsService = game:GetService("PhysicsService")

local Models = {}

function Models.SetModelAnchored(model: Model, anchored: boolean)
	assert(typeof(model) == "Instance" and model:IsA("Model"), "Expected model")
	
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = anchored
		end
	end
end

function Models.CaptureAnchorState(model: Model)
	local state = {}

	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			state[d] = d.Anchored
		end
	end

	return state
end

function Models.RestoreAnchorState(state)
	for part, anchored in pairs(state) do
		if part and part.Parent then
			part.Anchored = anchored
		end
	end
end

function Models.setModelCollisionGroup(model: Model, collisionGroup: string)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = collisionGroup
		end
	end
end

return Models