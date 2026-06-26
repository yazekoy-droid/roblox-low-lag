	return false
end

local function stopAnimator(animator)
	if not config.StopAnimations then
		return
	end

	local ok, tracks = pcall(function()
		return animator:GetPlayingAnimationTracks()
	end)

	if not ok then
		return
	end

	for _, track in ipairs(tracks) do
		pcall(function()
			track:Stop(0)
		end)
	end
end

local function hideInstance(instance)
	if not isInsideTarget(instance) then
		return
	end

	if instance:IsA("BasePart") then
		trackedParts[instance] = true
		setProperty(instance, "LocalTransparencyModifier", 1)

		if config.DisableShadows then
			setProperty(instance, "CastShadow", false)
		end
	elseif config.HideTextures and (instance:IsA("Decal") or instance:IsA("Texture")) then
		setProperty(instance, "Transparency", 1)
	elseif config.HideEffects and (instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Beam")) then
		setProperty(instance, "Enabled", false)
	elseif config.HideEffects and (instance:IsA("Smoke") or instance:IsA("Fire") or instance:IsA("Sparkles")) then
		setProperty(instance, "Enabled", false)
	elseif instance:IsA("BillboardGui") or instance:IsA("SurfaceGui") then
		setProperty(instance, "Enabled", false)
	elseif instance:IsA("Animator") then
		stopAnimator(instance)
	end
end

local function applyLowLag()
	if not config.Enabled then
		return
	end

	setProperty(Lighting, "GlobalShadows", false)

	for _, instance in ipairs(Workspace:GetDescendants()) do
		hideInstance(instance)
	end
end

local function makeUI()
	if not config.ShowUI then
		return
	end

	if not localPlayer then
		warn("[Venom Low Lag] LocalPlayer not found.")
		return
	end

	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local oldGui = playerGui:FindFirstChild("VenomSpitterLowLagUI")

	if oldGui then
		oldGui:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "VenomSpitterLowLagUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local button = Instance.new("TextButton")
	button.Name = "Toggle"
	button.AnchorPoint = Vector2.new(1, 0)
	button.Position = UDim2.fromScale(0.985, 0.32)
	button.Size = UDim2.fromOffset(180, 42)
	button.BackgroundColor3 = config.Enabled and Color3.fromRGB(35, 120, 80) or Color3.fromRGB(44, 48, 56)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = config.Enabled and "Venom Low Lag: ON" or "Venom Low Lag: OFF"
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 14
	button.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	button.MouseButton1Click:Connect(function()
		config.Enabled = not config.Enabled

		if config.Enabled then
			button.Text = "Venom Low Lag: ON"
			button.BackgroundColor3 = Color3.fromRGB(35, 120, 80)
			applyLowLag()
		else
			button.Text = "Venom Low Lag: OFF"
			button.BackgroundColor3 = Color3.fromRGB(44, 48, 56)
			restoreAll()
		end
	end)
end

Workspace.DescendantAdded:Connect(function(instance)
	if not config.Enabled then
		return
	end

	task.defer(function()
		hideInstance(instance)
	end)
end)

RunService.RenderStepped:Connect(function()
	if not config.Enabled then
		return
	end

	for part in pairs(trackedParts) do
		if not part.Parent then
			trackedParts[part] = nil
		else
			part.LocalTransparencyModifier = 1
		end
	end
end)

makeUI()
applyLowLag()

print("[Venom Low Lag] Loaded. Target: Venom Spitter")
