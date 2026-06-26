-- Venom Spitter Low Lag
-- Client-side visual reducer for your own Roblox experience.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")

local TARGET_NAME = "venom spitter"
local enabled = true
local originals = {}

local function notify(text)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "Venom Low Lag",
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

local function isTarget(instance)
	local current = instance

	while current and current ~= Workspace do
		if string.find(string.lower(current.Name), TARGET_NAME, 1, true) then
			return true
		end

		current = current.Parent
	end

	return false
end

local function hide(instance)
	if not enabled or not isTarget(instance) then
		return
	end

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

local function applyAll()
	set(Lighting, "GlobalShadows", false)

	for _, instance in ipairs(Workspace:GetDescendants()) do
		hide(instance)
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

local function makeUI()
	local parent = getGuiParent()

	if not parent then
		notify("Loaded, but UI could not be created.")
		return
	end

	local old = parent:FindFirstChild("VenomLowLagUI")
	if old then
		old:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "VenomLowLagUI"
	gui.ResetOnSpawn = false
	gui.Parent = parent

	local button = Instance.new("TextButton")
	button.Size = UDim2.fromOffset(220, 48)
	button.Position = UDim2.fromScale(0.03, 0.5)
	button.AnchorPoint = Vector2.new(0, 0.5)
	button.BackgroundColor3 = Color3.fromRGB(35, 120, 80)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = "Venom Low Lag: ON"
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 16
	button.ZIndex = 999
	button.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	button.MouseButton1Click:Connect(function()
		enabled = not enabled
		button.Text = enabled and "Venom Low Lag: ON" or "Venom Low Lag: OFF"
		button.BackgroundColor3 = enabled and Color3.fromRGB(35, 120, 80) or Color3.fromRGB(50, 54, 62)

		if enabled then
			applyAll()
		else
			restoreAll()
		end
	end)

	notify("Loaded. Button is on the left side.")
end

Workspace.DescendantAdded:Connect(function(instance)
	task.wait(0.05)
	hide(instance)
end)

task.spawn(function()
	while task.wait(0.5) do
		if enabled then
			applyAll()
		end
	end
end)

makeUI()
applyAll()
print("[Venom Low Lag] Loaded")
