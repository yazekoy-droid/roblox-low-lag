-- Venom Spitter Low Lag+
-- Client-side visual reducer for your own Roblox experience.

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

local enabled = true
local hardHide = true
local globalLowFx = true

local originals = {}
local removedParents = {}

local function notify(text)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "Low Lag+",
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

local function nameMatches(instance)
	local lowerName = string.lower(instance.Name)

	for _, keyword in ipairs(TARGET_KEYWORDS) do
		if string.find(lowerName, keyword, 1, true) then
			return true
		end
	end

	return false
end

local function getTargetRoot(instance)
	local current = instance
	local best = nil

	while current and current ~= Workspace do
		if nameMatches(current) then
			best = current
		end

		current = current.Parent
	end

	return best
end

local function hideVisual(instance)
	if instance:IsA("BasePart") then
		set(instance, "LocalTransparencyModifier", 1)
		set(instance, "CastShadow", false)
	elseif instance:IsA("Decal") or instance:IsA("Texture") then
		set(instance, "Transparency", 1)
	elseif instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Beam") then
		set(instance, "Enabled", false)
	elseif instance:IsA("Smoke") or instance:IsA("Fire") or instance:IsA("Sparkles") then
		set(instance, "Enabled", false)
	elseif instance:IsA("BillboardGui") or instance:IsA("SurfaceGui") then
		set(instance, "Enabled", false)
	elseif instance:IsA("Animator") then
		pcall(function()
			for _, track in ipairs(instance:GetPlayingAnimationTracks()) do
				track:Stop(0)
			end
		end)
	end
end

local function applyGlobalLowFx(instance)
	if not globalLowFx then
		return
	end

	if instance:IsA("BasePart") then
		set(instance, "CastShadow", false)
	elseif instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Beam") then
		set(instance, "Enabled", false)
	elseif instance:IsA("Smoke") or instance:IsA("Fire") or instance:IsA("Sparkles") then
		set(instance, "Enabled", false)
	elseif instance:IsA("PostEffect") then
		set(instance, "Enabled", false)
	end
end

local function hideTarget(instance)
	if not enabled then
		return
	end

	local root = getTargetRoot(instance)
	if not root then
		return
	end

	for _, child in ipairs(root:GetDescendants()) do
		hideVisual(child)
	end

	hideVisual(root)

	if hardHide and root.Parent then
		if removedParents[root] == nil then
			removedParents[root] = root.Parent
		end

		pcall(function()
			root.Parent = nil
		end)
	end
end

local function applyAll()
	set(Lighting, "GlobalShadows", false)
	set(Lighting, "FogEnd", 100000)
	set(Lighting, "EnvironmentDiffuseScale", 0)
	set(Lighting, "EnvironmentSpecularScale", 0)

	for _, instance in ipairs(Workspace:GetDescendants()) do
		applyGlobalLowFx(instance)
		hideTarget(instance)
	end

	for _, instance in ipairs(Lighting:GetDescendants()) do
		applyGlobalLowFx(instance)
	end
end

local function restoreAll()
	for instance, parent in pairs(removedParents) do
		if instance and parent then
			pcall(function()
				instance.Parent = parent
			end)
		end
	end

	removedParents = {}

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

local function makeButton(parent, text, y)
	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(230, 42)
	button.Position = UDim2.new(0, 0, 0, y)
	button.BackgroundColor3 = Color3.fromRGB(35, 120, 80)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 14
	button.ZIndex = 999
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	return button
end

local function makeUI()
	local parent = getGuiParent()

	if not parent then
		notify("Loaded, but UI could not be created.")
		return
	end

	local old = parent:FindFirstChild("VenomLowLagPlusUI")
	if old then
		old:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "VenomLowLagPlusUI"
	gui.ResetOnSpawn = false
	gui.Parent = parent

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(230, 142)
	frame.Position = UDim2.fromScale(0.03, 0.42)
	frame.BackgroundTransparency = 1
	frame.ZIndex = 998
	frame.Parent = gui

	local mainButton = makeButton(frame, "Low Lag+: ON", 0)
	local hardButton = makeButton(frame, "Hard Hide Venom: ON", 50)
	local fxButton = makeButton(frame, "Global VFX: OFF", 100)

	local function refreshButtons()
		mainButton.Text = enabled and "Low Lag+: ON" or "Low Lag+: OFF"
		hardButton.Text = hardHide and "Hard Hide Venom: ON" or "Hard Hide Venom: OFF"
		fxButton.Text = globalLowFx and "Global VFX: OFF" or "Global VFX: ON"

		mainButton.BackgroundColor3 = enabled and Color3.fromRGB(35, 120, 80) or Color3.fromRGB(50, 54, 62)
		hardButton.BackgroundColor3 = hardHide and Color3.fromRGB(80, 95, 180) or Color3.fromRGB(50, 54, 62)
		fxButton.BackgroundColor3 = globalLowFx and Color3.fromRGB(150, 90, 45) or Color3.fromRGB(50, 54, 62)
	end

	mainButton.MouseButton1Click:Connect(function()
		enabled = not enabled

		if enabled then
			applyAll()
		else
			restoreAll()
		end

		refreshButtons()
	end)

	hardButton.MouseButton1Click:Connect(function()
		hardHide = not hardHide
		restoreAll()

		if enabled then
			applyAll()
		end

		refreshButtons()
	end)

	fxButton.MouseButton1Click:Connect(function()
		globalLowFx = not globalLowFx
		restoreAll()

		if enabled then
			applyAll()
		end

		refreshButtons()
	end)

	refreshButtons()
	notify("Low Lag+ loaded. Strong mode is enabled.")
end

Workspace.DescendantAdded:Connect(function(instance)
	task.wait(0.05)

	if enabled then
		applyGlobalLowFx(instance)
		hideTarget(instance)
	end
end)

task.spawn(function()
	while task.wait(0.75) do
		if enabled then
			applyAll()
		end
	end
end)

makeUI()
applyAll()
print("[Low Lag+] Loaded")
