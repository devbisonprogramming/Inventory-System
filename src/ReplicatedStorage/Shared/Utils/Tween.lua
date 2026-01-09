-- EXAMPLE BASIC TWEEN MODULE; MORE EFFECTS CAN EASILY BE ADDED

local TweenService = game:GetService("TweenService")

local Tween = {}

-- Tween info: duration, easing style, easing direction
local hoverTweenInfo = TweenInfo.new(
	0.15, -- Duration (seconds)
	Enum.EasingStyle.Quad, -- Smooth acceleration
	Enum.EasingDirection.Out -- Ease out
)

local unhoverTweenInfo = TweenInfo.new(
	0.2, -- Slightly slower return
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.Out
)

-- Hover effect: slight scale up and color change
local function _playHoverEffect(frame: GuiObject)
	local lighterColor = frame.BackgroundColor3:Lerp(Color3.fromRGB(255, 255, 255), 0.3)
	local hoverTween = TweenService:Create(frame, hoverTweenInfo, {
		BackgroundColor3 = lighterColor
	})
	hoverTween:Play()
	--hoverTween.Completed:Wait()
end

-- Unhover effect: return to normal
local function _playUnhoverEffect(frame: GuiObject, originalColor: Color3)
	local unhoverTween = TweenService:Create(frame, unhoverTweenInfo, {
		--Size = originalSize,
		BackgroundColor3 = originalColor,
	})
	unhoverTween:Play()
end

function Tween.Hover(frame: GuiObject)
	frame:SetAttribute("OriginalColour", frame.BackgroundColor3)
	_playHoverEffect(frame)
end
function Tween.UnHover(frame:GuiObject)
	local originalColour = frame:GetAttribute("OriginalColour")
	_playUnhoverEffect(frame, originalColour)
end

return Tween