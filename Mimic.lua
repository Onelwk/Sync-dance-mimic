-- Sync & Dance Mimic
-- Safe loader + Dance/Emote mimic controller

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local CoreGui = game:GetService("CoreGui")

-- ==========================================
-- SETTINGS
-- ==========================================
local SOUND_URL = "https://raw.githubusercontent.com/Onelwk/Sync-dance-mimic/main/jeje_mimic_intro.mp3"
local SOUND_FILE = "jeje_mimic_intro.mp3"
local SOUND_VOLUME = 0.75
local LOAD_DURATION = 4 -- Seconds (fast & reliable; change if desired)

local localPlayer = Players.LocalPlayer

-- ==========================================
-- SAFE PARENT HELPER
-- ==========================================
local function getUiParent()
	local ok, gui = pcall(function()
		return gethui and gethui()
	end)
	if ok and gui then
		return gui
	end

	local okCore = pcall(function()
		return CoreGui:FindFirstChildOfClass("Folder") or CoreGui
	end)
	if okCore then
		return CoreGui
	end

	return localPlayer:WaitForChild("PlayerGui")
end

-- ==========================================
-- NON-BLOCKING AUDIO LOADER (NEVER HANGS)
-- ==========================================
local function playIntroSoundAsync()
	task.spawn(function()
		local sound = Instance.new("Sound")
		sound.Name = "MimicIntroSound"
		sound.Volume = SOUND_VOLUME
		sound.Parent = SoundService

		local assetId = nil

		if typeof(writefile) == "function" and typeof(getcustomasset) == "function" and typeof(game.HttpGet) == "function" then
			local okFetch, body = pcall(function()
				return game:HttpGet(SOUND_URL)
			end)
			if okFetch and type(body) == "string" and #body > 100 and not body:find("404: Not Found") then
				pcall(function()
					writefile(SOUND_FILE, body)
					assetId = getcustomasset(SOUND_FILE)
				end)
			end
		end

		if assetId then
			sound.SoundId = assetId
			pcall(function()
				sound:Play()
			end)
		end
	end)
end

-- ==========================================
-- LOADING SCREEN (ALWAYS COMPLETES)
-- ==========================================
local function runLoadingScreen()
	local parent = getUiParent()
	local old = parent:FindFirstChild("MimicLoaderGui")
	if old then
		old:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MimicLoaderGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 9999
	screenGui.Parent = parent

	local backdrop = Instance.new("Frame")
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
	backdrop.BorderSizePixel = 0
	backdrop.Parent = screenGui

	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.Size = UDim2.fromOffset(360, 170)
	card.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
	card.BorderSizePixel = 0
	card.Parent = backdrop

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 12)
	cardCorner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 55, 95)
	stroke.Thickness = 1.5
	stroke.Parent = card

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -24, 0, 32)
	title.Position = UDim2.fromOffset(12, 14)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Text = "SYNC & DANCE MIMIC"
	title.Parent = card

	local spinner = Instance.new("Frame")
	spinner.AnchorPoint = Vector2.new(0.5, 0)
	spinner.Position = UDim2.new(0.5, 0, 0, 52)
	spinner.Size = UDim2.fromOffset(26, 26)
	spinner.BackgroundColor3 = Color3.fromRGB(255, 55, 95)
	spinner.BorderSizePixel = 0
	spinner.Parent = card

	local spinnerCorner = Instance.new("UICorner")
	spinnerCorner.CornerRadius = UDim.new(0, 6)
	spinnerCorner.Parent = spinner

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -24, 0, 22)
	statusLabel.Position = UDim2.fromOffset(12, 86)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextSize = 13
	statusLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
	statusLabel.Text = "Loading... 0%"
	statusLabel.Parent = card

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, -32, 0, 12)
	barBg.Position = UDim2.fromOffset(16, 118)
	barBg.BackgroundColor3 = Color3.fromRGB(42, 42, 52)
	barBg.BorderSizePixel = 0
	barBg.Parent = card

	local barBgCorner = Instance.new("UICorner")
	barBgCorner.CornerRadius = UDim.new(1, 0)
	barBgCorner.Parent = barBg

	local barFill = Instance.new("Frame")
	barFill.Size = UDim2.fromScale(0, 1)
	barFill.BackgroundColor3 = Color3.fromRGB(255, 55, 95)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg

	local barFillCorner = Instance.new("UICorner")
	barFillCorner.CornerRadius = UDim.new(1, 0)
	barFillCorner.Parent = barFill

	playIntroSoundAsync()

	local elapsed = 0
	while elapsed < LOAD_DURATION do
		local dt = RunService.RenderStepped:Wait()
		elapsed = math.min(elapsed + dt, LOAD_DURATION)
		local alpha = elapsed / LOAD_DURATION
		local pct = math.floor(alpha * 100)

		spinner.Rotation = (spinner.Rotation + dt * 360) % 360
		barFill.Size = UDim2.fromScale(alpha, 1)
		statusLabel.Text = string.format("Loading... %d%%", pct)
	end

	local fadeTween = TweenService:Create(backdrop, TweenInfo.new(0.35), { BackgroundTransparency = 1 })
	fadeTween:Play()
	fadeTween.Completed:Wait()
	screenGui:Destroy()
end

-- ==========================================
-- DANCE / ANIMATION MIMIC CONTROLLER
-- ==========================================
local mimicEnabled = false
local targetPlayer = nil
local currentMimicTrack = nil
local lastAnimId = nil

local function getAnimator(player)
	local char = player and player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	return hum and hum:FindFirstChildOfClass("Animator")
end

local function stopMimicTrack()
	if currentMimicTrack then
		pcall(function()
			currentMimicTrack:Stop(0.15)
			currentMimicTrack:Destroy()
		end)
		currentMimicTrack = nil
	end
	lastAnimId = nil
end

local function findNearestPlayer()
	local myChar = localPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if not myRoot then
		return nil
	end

	local closest, bestDist = nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= localPlayer and plr.Character then
			local root = plr.Character:FindFirstChild("HumanoidRootPart")
			if root then
				local dist = (root.Position - myRoot.Position).Magnitude
				if dist < bestDist then
					bestDist = dist
					closest = plr
				end
			end
		end
	end
	return closest
end

local function createControlHud()
	local parent = getUiParent()
	local old = parent:FindFirstChild("MimicHudGui")
	if old then
		old:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "MimicHudGui"
	gui.ResetOnSpawn = false
	gui.Parent = parent

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(180, 40)
	btn.Position = UDim2.fromOffset(20, 120)
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.Text = "Mimic: OFF"
	btn.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn

	btn.MouseButton1Click:Connect(function()
		mimicEnabled = not mimicEnabled
		if mimicEnabled then
			targetPlayer = findNearestPlayer()
			btn.Text = targetPlayer and ("Mimic: " .. targetPlayer.Name) or "Mimic: No Target"
			btn.BackgroundColor3 = Color3.fromRGB(255, 55, 95)
		else
			targetPlayer = nil
			stopMimicTrack()
			btn.Text = "Mimic: OFF"
			btn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
		end
	end)
end

RunService.Heartbeat:Connect(function()
	if not mimicEnabled then
		return
	end

	if not targetPlayer or not targetPlayer.Parent then
		targetPlayer = findNearestPlayer()
		if not targetPlayer then
			stopMimicTrack()
			return
		end
	end

	local targetAnimator = getAnimator(targetPlayer)
	local myAnimator = getAnimator(localPlayer)
	if not targetAnimator or not myAnimator then
		return
	end

	local activeTrack = nil
	for _, track in ipairs(targetAnimator:GetPlayingAnimationTracks()) do
		if track.IsPlaying and track.Animation and track.Animation.AnimationId ~= "" then
			activeTrack = track
			break
		end
	end

	if activeTrack then
		local animId = activeTrack.Animation.AnimationId
		if animId ~= lastAnimId then
			stopMimicTrack()
			local anim = Instance.new("Animation")
			anim.AnimationId = animId
			local ok, loaded = pcall(function()
				return myAnimator:LoadAnimation(anim)
			end)
			if ok and loaded then
				loaded.Looped = activeTrack.Looped
				loaded:Play(0.1)
				loaded:AdjustSpeed(activeTrack.Speed)
				currentMimicTrack = loaded
				lastAnimId = animId
			end
		elseif currentMimicTrack then
			currentMimicTrack:AdjustSpeed(activeTrack.Speed)
		end
	else
		stopMimicTrack()
	end
end)

-- ==========================================
-- STARTUP
-- ==========================================
createControlHud()
runLoadingScreen()
