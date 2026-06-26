-- Plant Low Lag Control
-- Client-side visual reducer for your own Roblox experience.
-- Goal: hide heavy Venom Spitter plant visuals while keeping fruit visible.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")

local TARGET_KEYWORDS = {
	"venom spitter",
	"venom",
	"spitter",
}

local FRUIT_KEYWORDS = {
	"fruit",
	"harvest",
	"crop",
	"apple",
	"banana",
	"berry",
	"blueberry",
	"strawberry",
	"grape",
	"mango",
	"coconut",
	"pineapple",
	"dragon fruit",
	"pomegranate",
	"pepper",
	"melon",
	"bean",
	"tomato",
	"carrot",
	"corn",
	"mushroom",
	"bamboo",
	"flower",
	"bloom",
}

local state = {
	enabled = true,
	hidePlantBody = true,
	keepFruit = true,
	stopAnimations = true,
	disableTargetVfx = true,
	disableGlobalVfx = true,
	disableShadows = true,
}

local originals = {}

local function notify(text)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "Plant Low Lag",
			Text = text,
			Duration = 4,
		})
	end)
end

local function save(instance, property)
	originals[instance] = originals[instance] or {}

	if originals[instance][property] == nil then
		local ok, value = pcall(function()
			return instance[property]
		end)

		if ok then
			originals[instance][property] = value
		end
	end
end

local function set(instance, property, value)
	save(instance, property)
	pcall(function()
		instance[property] = value
	end)
end

local function lowerName(instance)
	return string.lower(instance.Name)
end

local function hasKeyword(instance, keywords)
	local name = lowerName(instance)

	for _, keyword in ipairs(keywords) do
		if string.find(name, keyword, 1, true) then
			return true
		end
	end

	return false
end

local function targetRootOf(instance)
	local current = instance
	local best = nil

	while current and current ~= Workspace do
		if hasKeyword(current, TARGET_KEYWORDS) then
			best = current
		end

		current = current.Parent
	end

	return best
end

local function isFruitPart(instance)
	if not state.keepFruit then
		return false
	end

	local current = instance

	while current and current ~= Workspace do
		if hasKeyword(current, FRUIT_KEYWORDS) then
			return true
		end

		if hasKeyword(current, TARGET_KEYWORDS) then
			return false
		end

		current = current.Parent
	end

	return false
end

local function stopAnimationObject(instance)
	if not state.stopAnimations then
		return
	end

	if instance:IsA("Animator") then
		pcall(function()
			for _, track in ipairs(instance:GetPlayingAnimationTracks()) do
				track:Stop(0)
			end
		end)
	elseif instance:IsA("AnimationController") then
		for _, child in ipairs(instance:GetDescendants()) do
			if child:IsA("Animator") then
				stopAnimationObject(child)
			end
		end
	elseif instance:IsA("Motor6D") then
		set(instance, "Transform", CFrame.new())
	end
end

local function hidePlantVisual(instance)
	if isFruitPart(instance) then
		if instance:IsA("BasePart") then
			set(instance, "LocalTransparencyModifier", 0)
			if state.disableShadows then
				set(instance, "CastShadow", false)
			end
		elseif instance:IsA("Decal") or instance:IsA("Texture") then
			set(instance, "Transparency", 0)
		end

		return
	end

	if state.hidePlantBody then
		if instance:IsA("BasePart") then
			set(instance, "LocalTransparencyModifier", 1)
			set(instance, "CastShadow", false)
		elseif instance:IsA("Decal") or instance:IsA("Texture") then
			set(instance, "Transparency", 1)
		elseif instance:IsA("BillboardGui") or instance:IsA("SurfaceGui") then
			set(instance, "Enabled", false)
		end
	end

	if state.disableTargetVfx then
		if instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Beam") then
			set(instance, "Enabled", false)
		elseif instance:IsA("Smoke") or instance:IsA("Fire") or instance:IsA("Sparkles") then
			set(instance, "Enabled", false)
		end
	end

	stopAnimationObject(instance)
end

local function globalLowFx(instance)
	if not state.disableGlobalVfx then
		return
	end

	if instance:IsA("BasePart") and state.disableShadows then
		set(instance, "CastShadow", false)
	elseif instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Beam") then
		set(instance, "Enabled", false)
	elseif instance:IsA("Smoke") or instance:IsA("Fire") or instance:IsA("Sparkles") then
		set(instance, "Enabled", false)
	elseif instance:IsA("PostEffect") then
		set(instance, "Enabled", false)
	end
end

local function processTarget(root)
	for _, item in ipairs(root:GetDescendants()) do
		hidePlantVisual(item)
	end

	hidePlantVisual(root)
end

local function applyAll()
	if not state.enabled then
		return
	end

	if state.disableShadows then
		set(Lighting, "GlobalShadows", false)
		set(Lighting, "EnvironmentDiffuseScale", 0)
		set(Lighting, "EnvironmentSpecularScale", 0)
	end

	for _, instance in ipairs(Workspace:GetDescendants()) do
		globalLowFx(instance)

		local root = targetRootOf(instance)
		if root then
			processTarget(root)
		end
	end

	for _, instance in ipairs(Lighting:GetDescendants()) do
		globalLowFx(instance)
	end
end

local function restoreAll()
	for instance, values in pairs(originals) do
		if instance and instance.Parent then
			for property, value in pairs(values) do
				pcall(function()
					instance[property] = value
				end)
			end
		end
	end

	originals = {}
end

local function getGuiParent()
	if gethui then
		local ok, gui = pcall(gethui)
		if ok and gui then
			return gui
		end
	end

	local ok = pcall(function()
		local _ = CoreGui.Name
	end)

	if ok then
		return CoreGui
	end

	local player = Players.LocalPlayer
	return player and player:WaitForChild("PlayerGui", 5)
end

local function makeButton(parent, y)
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(245, 34)
	button.Position = UDim2.new(0, 0, 0, y)
	button.BackgroundColor3 = Color3.fromRGB(42, 47, 55)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 13
	button.ZIndex = 999
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = button

	return button
end

local function makeUI()
	local parent = getGuiParent()

	if not parent then
		notify("Loaded, but UI could not be created.")
		return
	end

	local old = parent:FindFirstChild("PlantLowLagControlUI")
	if old then
		old:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "PlantLowLagControlUI"
	gui.ResetOnSpawn = false
	gui.Parent = parent

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(245, 250)
	frame.Position = UDim2.fromScale(0.03, 0.32)
	frame.BackgroundColor3 = Color3.fromRGB(20, 23, 28)
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	frame.ZIndex = 998
	frame.Parent = gui

	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 8)
	frameCorner.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 28)
	title.Position = UDim2.fromOffset(10, 8)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "Plant Low Lag Control"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 15
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 999
	title.Parent = frame

	local buttons = {
		enabled = makeButton(frame, 44),
		hidePlantBody = makeButton(frame, 82),
		keepFruit = makeButton(frame, 120),
		stopAnimations = makeButton(frame, 158),
		disableTargetVfx = makeButton(frame, 196),
	}

	local function repaint()
		buttons.enabled.Text = state.enabled and "Main: ON" or "Main: OFF"
		buttons.hidePlantBody.Text = state.hidePlantBody and "Hide Tree Body: ON" or "Hide Tree Body: OFF"
		buttons.keepFruit.Text = state.keepFruit and "Keep Fruit Visible: ON" or "Keep Fruit Visible: OFF"
		buttons.stopAnimations.Text = state.stopAnimations and "Stop Animation: ON" or "Stop Animation: OFF"
		buttons.disableTargetVfx.Text = state.disableTargetVfx and "Target VFX: OFF" or "Target VFX: ON"

		for key, button in pairs(buttons) do
			button.BackgroundColor3 = state[key] and Color3.fromRGB(38, 115, 82) or Color3.fromRGB(58, 62, 70)
		end
	end

	local function toggle(key)
		state[key] = not state[key]
		restoreAll()

		if state.enabled then
			applyAll()
		end

		repaint()
	end

	for key, button in pairs(buttons) do
		button.MouseButton1Click:Connect(function()
			toggle(key)
		end)
	end

	repaint()
	notify("Loaded. Hide tree body + keep fruit mode is enabled.")
end

Workspace.DescendantAdded:Connect(function(instance)
	task.wait(0.05)

	if state.enabled then
		globalLowFx(instance)

		local root = targetRootOf(instance)
		if root then
			processTarget(root)
		end
	end
end)

task.spawn(function()
	while task.wait(0.75) do
		applyAll()
	end
end)

makeUI()
applyAll()
print("[Plant Low Lag Control] Loaded")
