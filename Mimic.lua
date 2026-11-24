-- Sync & Dance Mimic
-- made by jeje

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

-- ==========================================
-- AUDIO & LOADING SETTINGS
-- ==========================================
local SOUND_URL = "https://raw.githubusercontent.com/Onelwk/Jeje-6767/main/lv_0_20261125023048.mp3"
local SOUND_FILE = "jeje_mimic_intro.mp3"
local SOUND_VOLUME = 0.75
local LOAD_DURATION = 16 -- Seconds

local localPlayer = Players.LocalPlayer

-- State
local state = {
	enabled = false,
	targetQuery = "",
	side = "Right", -- "Left" or "Right"
	distance = 3.5,
	uiVisible = true,
	isAnimating = false,
	loadingDone = false,
}

local activeTracks = {}
local lastTargetPlayer = nil

-- Cleanup existing UI & Blur if re-executed
local uiParent = (gethui and gethui()) or CoreGui
local oldGui = uiParent:FindFirstChild("MimicDanceGUI_JEJE")
if oldGui then
	oldGui:Destroy()
end
local oldBlur = Lighting:FindFirstChild("JejeMimicBlur")
if oldBlur then
	oldBlur:Destroy()
end

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MimicDanceGUI_JEJE"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = uiParent

-- ==========================================
-- FULL-SCREEN 16-SECOND LOADING SCREEN
-- ==========================================
local blurEffect = Instance.new("BlurEffect")
blurEffect.Name = "JejeMimicBlur"
blurEffect.Size = 0
blurEffect.Parent = Lighting

TweenService:Create(
	blurEffect,
	TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	{ Size = 14 }
):Play()

local loadingOverlay = Instance.new("Frame")
loadingOverlay.Name = "FullScreenLoading"
loadingOverlay.Size = UDim2.new(1, 0, 1, 0)
loadingOverlay.Position = UDim2.new(0, 0, 0, 0)
loadingOverlay.BackgroundColor3 = Color3.fromRGB(14, 4, 6)
loadingOverlay.BackgroundTransparency = 0.52
loadingOverlay.BorderSizePixel = 0
loadingOverlay.ZIndex = 30
loadingOverlay.Parent = screenGui

local bgVignette = Instance.new("UIGradient")
bgVignette.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 5, 10)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(12, 6, 8)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(55, 6, 12)),
})
bgVignette.Rotation = 90
bgVignette.Parent = loadingOverlay

-- Center Badge: Normal Red Border + Dark Red Inside + Drifting Particles
local centerGroup = Instance.new("Frame")
centerGroup.Name = "CenterBadge"
centerGroup.Size = UDim2.new(0, 420, 0, 150)
centerGroup.Position = UDim2.new(0.5, 0, 0.42, 0)
centerGroup.AnchorPoint = Vector2.new(0.5, 0.5)
centerGroup.BackgroundColor3 = Color3.fromRGB(45, 6, 10)
centerGroup.BackgroundTransparency = 0.08
centerGroup.BorderSizePixel = 0
centerGroup.ClipsDescendants = true
centerGroup.ZIndex = 32
centerGroup.Parent = loadingOverlay

local badgeCorner = Instance.new("UICorner")
badgeCorner.CornerRadius = UDim.new(0, 20)
badgeCorner.Parent = centerGroup

-- Clean normal red border around the badge
local badgeStroke = Instance.new("UIStroke")
badgeStroke.Color = Color3.fromRGB(215, 24, 42)
badgeStroke.Thickness = 2.5
badgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
badgeStroke.Parent = centerGroup

-- Subtle dark red gradient inside
local innerDarkRedGrad = Instance.new("UIGradient")
innerDarkRedGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(58, 7, 13)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(32, 4, 7)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(66, 8, 15)),
})
innerDarkRedGrad.Rotation = 35
innerDarkRedGrad.Parent = centerGroup

-- Soft drifting particles inside the dark red badge (no fixed shape)
local particlesHolder = Instance.new("Frame")
particlesHolder.Name = "BadgeParticles"
particlesHolder.Size = UDim2.new(1, 0, 1, 0)
particlesHolder.BackgroundTransparency = 1
particlesHolder.ZIndex = 32
particlesHolder.Parent = centerGroup

local rng = Random.new(2026)
local badgeParticles = {}
for i = 1, 18 do
	local sizePx = rng:NextInteger(4, 9)
	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, sizePx, 0, sizePx)
	dot.Position = UDim2.new(rng:NextNumber(0.05, 0.95), 0, rng:NextNumber(0.1, 0.9), 0)
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.BackgroundColor3 = Color3.fromRGB(rng:NextInteger(210, 255), rng:NextInteger(25, 75), rng:NextInteger(40, 90))
	dot.BackgroundTransparency = rng:NextNumber(0.35, 0.75)
	dot.BorderSizePixel = 0
	dot.ZIndex = 32
	dot.Parent = particlesHolder

	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = dot

	table.insert(badgeParticles, {
		frame = dot,
		x = dot.Position.X.Scale,
		y = dot.Position.Y.Scale,
		vx = rng:NextNumber(-0.045, 0.045),
		vy = rng:NextNumber(-0.055, -0.015),
		phase = rng:NextNumber(0, math.pi * 2),
		speed = rng:NextNumber(1.5, 3.5),
		baseAlpha = dot.BackgroundTransparency,
	})
end

local redIconBox = Instance.new("Frame")
redIconBox.Size = UDim2.new(0, 64, 0, 64)
redIconBox.Position = UDim2.new(0, 22, 0.5, 0)
redIconBox.AnchorPoint = Vector2.new(0, 0.5)
redIconBox.BackgroundColor3 = Color3.fromRGB(215, 24, 42)
redIconBox.BorderSizePixel = 0
redIconBox.ClipsDescendants = true
redIconBox.ZIndex = 33
redIconBox.Parent = centerGroup

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(0, 14)
iconCorner.Parent = redIconBox

local iconStroke = Instance.new("UIStroke")
iconStroke.Color = Color3.fromRGB(255, 110, 125)
iconStroke.Thickness = 1.5
iconStroke.Parent = redIconBox

-- Animated Music Note ("♪")
local iconSymbol = Instance.new("TextLabel")
iconSymbol.Size = UDim2.new(1, 0, 1, 0)
iconSymbol.Position = UDim2.new(0, 0, 0.5, 0)
iconSymbol.AnchorPoint = Vector2.new(0, 0.5)
iconSymbol.BackgroundTransparency = 1
iconSymbol.Text = "♪"
iconSymbol.TextColor3 = Color3.fromRGB(255, 255, 255)
iconSymbol.Font = Enum.Font.GothamBlack
iconSymbol.TextSize = 36
iconSymbol.ZIndex = 34
iconSymbol.Parent = redIconBox

local badgeTitle = Instance.new("TextLabel")
badgeTitle.Size = UDim2.new(1, -110, 0, 38)
badgeTitle.Position = UDim2.new(0, 98, 0, 34)
badgeTitle.BackgroundTransparency = 1
badgeTitle.Text = "SYNC & DANCE MIMIC"
badgeTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
badgeTitle.Font = Enum.Font.GothamBlack
badgeTitle.TextSize = 22
badgeTitle.TextXAlignment = Enum.TextXAlignment.Left
badgeTitle.ZIndex = 33
badgeTitle.Parent = centerGroup

local badgeSub = Instance.new("TextLabel")
badgeSub.Size = UDim2.new(1, -110, 0, 24)
badgeSub.Position = UDim2.new(0, 98, 0, 72)
badgeSub.BackgroundTransparency = 1
badgeSub.Text = "Copy Emote • Follow Emote • Full Sync"
badgeSub.TextColor3 = Color3.fromRGB(255, 185, 195)
badgeSub.Font = Enum.Font.GothamBold
badgeSub.TextSize = 13
badgeSub.TextXAlignment = Enum.TextXAlignment.Left
badgeSub.ZIndex = 33
badgeSub.Parent = centerGroup

-- Bottom Loading Area (16s Bar + Effect + Stylized "made by jeje")
local bottomSection = Instance.new("Frame")
bottomSection.Name = "BottomLoadingSection"
bottomSection.Size = UDim2.new(0.75, 0, 0, 155)
bottomSection.Position = UDim2.new(0.5, 0, 0.84, 0)
bottomSection.AnchorPoint = Vector2.new(0.5, 0.5)
bottomSection.BackgroundTransparency = 1
bottomSection.ZIndex = 32
bottomSection.Parent = loadingOverlay

local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, 0, 0, 24)
statusText.Position = UDim2.new(0, 0, 0, 0)
statusText.BackgroundTransparency = 1
statusText.Text = "INITIALIZING... 0%"
statusText.TextColor3 = Color3.fromRGB(255, 80, 98)
statusText.Font = Enum.Font.GothamBlack
statusText.TextSize = 15
statusText.ZIndex = 33
statusText.Parent = bottomSection

local loadTrackFrame = Instance.new("Frame")
loadTrackFrame.Size = UDim2.new(1, 0, 0, 18)
loadTrackFrame.Position = UDim2.new(0, 0, 0, 30)
loadTrackFrame.BackgroundColor3 = Color3.fromRGB(22, 8, 12)
loadTrackFrame.BackgroundTransparency = 0.2
loadTrackFrame.BorderSizePixel = 0
loadTrackFrame.ClipsDescendants = true
loadTrackFrame.ZIndex = 33
loadTrackFrame.Parent = bottomSection

local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(1, 0)
trackCorner.Parent = loadTrackFrame

local trackStroke = Instance.new("UIStroke")
trackStroke.Color = Color3.fromRGB(210, 25, 45)
trackStroke.Thickness = 1.8
trackStroke.Parent = loadTrackFrame

local loadFillBar = Instance.new("Frame")
loadFillBar.Size = UDim2.new(0, 0, 1, 0)
loadFillBar.Position = UDim2.new(0, 0, 0, 0)
loadFillBar.BackgroundColor3 = Color3.fromRGB(235, 25, 45)
loadFillBar.BorderSizePixel = 0
loadFillBar.ClipsDescendants = true
loadFillBar.ZIndex = 34
loadFillBar.Parent = loadTrackFrame

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = loadFillBar

local barShimmer = Instance.new("Frame")
barShimmer.Size = UDim2.new(0.25, 0, 1, 0)
barShimmer.Position = UDim2.new(-0.25, 0, 0, 0)
barShimmer.BackgroundColor3 = Color3.fromRGB(255, 150, 160)
barShimmer.BackgroundTransparency = 0.35
barShimmer.BorderSizePixel = 0
barShimmer.ZIndex = 35
barShimmer.Parent = loadFillBar

local shimmerGrad = Instance.new("UIGradient")
shimmerGrad.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.5, 0.2),
	NumberSequenceKeypoint.new(1, 1),
})
shimmerGrad.Parent = barShimmer

-- Stylized "made by jeje" Signature at the Bottom of Loading Screen
local bigCreatorLabel = Instance.new("TextLabel")
bigCreatorLabel.Size = UDim2.new(1, 0, 0, 50)
bigCreatorLabel.Position = UDim2.new(0, 0, 0, 62)
bigCreatorLabel.BackgroundTransparency = 1
bigCreatorLabel.Text = "『  m a d e   b y   j e j e  』"
bigCreatorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
bigCreatorLabel.Font = Enum.Font.Michroma
bigCreatorLabel.TextSize = 26
bigCreatorLabel.ZIndex = 34
bigCreatorLabel.Parent = bottomSection

local creatorStroke = Instance.new("UIStroke")
creatorStroke.Color = Color3.fromRGB(165, 12, 28)
creatorStroke.Thickness = 2.2
creatorStroke.Parent = bigCreatorLabel

local creatorGradient = Instance.new("UIGradient")
creatorGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 45, 68)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 215, 220)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 45, 68)),
})
creatorGradient.Rotation = 0
creatorGradient.Parent = bigCreatorLabel

-- ==========================================
-- MAIN UI (Clean Rotating Red/Black Border)
-- ==========================================
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 275, 0, 265)
mainFrame.Position = UDim2.new(0.5, 0, 0.4, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ClipsDescendants = true
mainFrame.Visible = false
mainFrame.Parent = screenGui

local uiScale = Instance.new("UIScale")
uiScale.Scale = 0.7
uiScale.Parent = mainFrame

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Black & Red Glowing Rotating Border
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(255, 255, 255)
mainStroke.Thickness = 2
mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
mainStroke.Parent = mainFrame

local borderGradient = Instance.new("UIGradient")
borderGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(235, 25, 45)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(25, 10, 14)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(235, 25, 45)),
})
borderGradient.Rotation = 45
borderGradient.Parent = mainStroke

-- Header Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -24, 0, 28)
titleLabel.Position = UDim2.new(0, 14, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "SYNC & DANCE MIMIC"
titleLabel.TextColor3 = Color3.fromRGB(240, 35, 55)
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 15
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = mainFrame

-- Keybind Hint Badge
local hintLabel = Instance.new("TextLabel")
hintLabel.Size = UDim2.new(0, 65, 0, 20)
hintLabel.Position = UDim2.new(1, -78, 0, 14)
hintLabel.BackgroundColor3 = Color3.fromRGB(24, 14, 16)
hintLabel.Text = "[T] Hide"
hintLabel.TextColor3 = Color3.fromRGB(210, 60, 75)
hintLabel.Font = Enum.Font.GothamBold
hintLabel.TextSize = 11
hintLabel.Parent = mainFrame

local hintCorner = Instance.new("UICorner")
hintCorner.CornerRadius = UDim.new(0, 5)
hintCorner.Parent = hintLabel

local hintStroke = Instance.new("UIStroke")
hintStroke.Color = Color3.fromRGB(130, 20, 35)
hintStroke.Thickness = 1
hintStroke.Parent = hintLabel

-- Status Label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -28, 0, 18)
statusLabel.Position = UDim2.new(0, 14, 0, 37)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Ready"
statusLabel.TextColor3 = Color3.fromRGB(165, 165, 175)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = mainFrame

local function styleBox(box)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = box

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(140, 20, 35)
	stroke.Thickness = 1.2
	stroke.Parent = box
	return stroke
end

-- Target Name Input
local nameBox = Instance.new("TextBox")
nameBox.Size = UDim2.new(1, -28, 0, 34)
nameBox.Position = UDim2.new(0, 14, 0, 62)
nameBox.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
nameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
nameBox.PlaceholderText = "Enter target username..."
nameBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
nameBox.Text = ""
nameBox.Font = Enum.Font.GothamSemibold
nameBox.TextSize = 13
nameBox.ClearTextOnFocus = false
nameBox.Parent = mainFrame
styleBox(nameBox)

-- Distance Row
local distLabel = Instance.new("TextLabel")
distLabel.Size = UDim2.new(0.58, 0, 0, 32)
distLabel.Position = UDim2.new(0, 14, 0, 104)
distLabel.BackgroundTransparency = 1
distLabel.Text = "Side Distance (studs):"
distLabel.TextColor3 = Color3.fromRGB(220, 220, 225)
distLabel.Font = Enum.Font.GothamSemibold
distLabel.TextSize = 12
distLabel.TextXAlignment = Enum.TextXAlignment.Left
distLabel.Parent = mainFrame

local distBox = Instance.new("TextBox")
distBox.Size = UDim2.new(0.32, 0, 0, 32)
distBox.Position = UDim2.new(0.68, -14, 0, 104)
distBox.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
distBox.TextColor3 = Color3.fromRGB(245, 50, 70)
distBox.Text = tostring(state.distance)
distBox.Font = Enum.Font.GothamBold
distBox.TextSize = 13
distBox.Parent = mainFrame
styleBox(distBox)

-- Side Toggle Button
local sideButton = Instance.new("TextButton")
sideButton.Size = UDim2.new(1, -28, 0, 34)
sideButton.Position = UDim2.new(0, 14, 0, 145)
sideButton.BackgroundColor3 = Color3.fromRGB(24, 16, 18)
sideButton.TextColor3 = Color3.fromRGB(245, 245, 250)
sideButton.Text = "SIDE: RIGHT"
sideButton.Font = Enum.Font.GothamBold
sideButton.TextSize = 13
sideButton.AutoButtonColor = false
sideButton.Parent = mainFrame
styleBox(sideButton)

-- Start / Stop Button
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, -28, 0, 38)
toggleButton.Position = UDim2.new(0, 14, 0, 188)
toggleButton.BackgroundColor3 = Color3.fromRGB(205, 24, 44)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Text = "START MIMIC"
toggleButton.Font = Enum.Font.GothamBlack
toggleButton.TextSize = 14
toggleButton.AutoButtonColor = false
toggleButton.Parent = mainFrame

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 7)
toggleCorner.Parent = toggleButton

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(255, 85, 100)
toggleStroke.Thickness = 1.2
toggleStroke.Parent = toggleButton

-- Footer Credit ("made by jeje")
local creditLabel = Instance.new("TextLabel")
creditLabel.Size = UDim2.new(1, -28, 0, 20)
creditLabel.Position = UDim2.new(0, 14, 1, -25)
creditLabel.BackgroundTransparency = 1
creditLabel.Text = "made by jeje"
creditLabel.TextColor3 = Color3.fromRGB(210, 40, 58)
creditLabel.Font = Enum.Font.GothamBold
creditLabel.TextSize = 12
creditLabel.TextXAlignment = Enum.TextXAlignment.Center
creditLabel.Parent = mainFrame

-- ==========================================
-- ONE-TIME INTRO SOUND
-- ==========================================
local function playOneTimeIntroSound()
	if not SOUND_URL or SOUND_URL == "" then return end
	task.spawn(function()
		pcall(function()
			if not isfile or not writefile or not getcustomasset then return end

			if not isfile(SOUND_FILE) then
				local audioData = game:HttpGet(SOUND_URL)
				if audioData and #audioData > 0 then
					writefile(SOUND_FILE, audioData)
				end
			end

			if isfile(SOUND_FILE) then
				local sound = Instance.new("Sound")
				sound.Name = "JejeIntroSound"
				sound.SoundId = getcustomasset(SOUND_FILE)
				sound.Volume = SOUND_VOLUME
				sound.Looped = false
				sound.Parent = SoundService

				sound.Ended:Connect(function()
					sound:Destroy()
				end)

				sound:Play()
			end
		end)
	end)
end

-- ==========================================
-- POP-IN / POP-OUT ANIMATION (T KEY)
-- ==========================================
local function popInMainUI()
	state.isAnimating = true
	state.uiVisible = true
	mainFrame.Visible = true
	uiScale.Scale = 0.72
	mainFrame.BackgroundTransparency = 1
	mainStroke.Transparency = 1

	local openTween = TweenService:Create(
		uiScale,
		TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = 1 }
	)
	local fadeIn = TweenService:Create(
		mainFrame,
		TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 0 }
	)
	local strokeIn = TweenService:Create(
		mainStroke,
		TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Transparency = 0 }
	)

	openTween:Play()
	fadeIn:Play()
	strokeIn:Play()
	openTween.Completed:Wait()
	state.isAnimating = false
end

local function setMenuVisible(visible)
	if not state.loadingDone or state.isAnimating or state.uiVisible == visible then return end
	state.isAnimating = true
	state.uiVisible = visible

	if visible then
		mainFrame.Visible = true
		uiScale.Scale = 0.75
		mainFrame.BackgroundTransparency = 1
		mainStroke.Transparency = 1

		local openTween = TweenService:Create(
			uiScale,
			TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1 }
		)
		local fadeIn = TweenService:Create(
			mainFrame,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 0 }
		)
		local strokeIn = TweenService:Create(
			mainStroke,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Transparency = 0 }
		)

		openTween:Play()
		fadeIn:Play()
		strokeIn:Play()
		openTween.Completed:Wait()
	else
		local closeTween = TweenService:Create(
			uiScale,
			TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In),
			{ Scale = 0.72 }
		)
		local fadeOut = TweenService:Create(
			mainFrame,
			TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ BackgroundTransparency = 1 }
		)
		local strokeOut = TweenService:Create(
			mainStroke,
			TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Transparency = 1 }
		)

		closeTween:Play()
		fadeOut:Play()
		strokeOut:Play()
		closeTween.Completed:Wait()
		mainFrame.Visible = false
	end

	state.isAnimating = false
end

-- Run 16-Second Full-Screen Loading Sequence 
