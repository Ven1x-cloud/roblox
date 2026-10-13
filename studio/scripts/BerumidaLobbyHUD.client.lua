-- Safe lobby HUD prototype. Party creation, world loading, purchases, and teleports are not wired yet.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("BerumidaPrototypeConfig"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local existingGui = playerGui:FindFirstChild("BerumidaLobbyHUD")
if existingGui then
	existingGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BerumidaLobbyHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.DisplayOrder = 20
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "StatusPanel"
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, 14)
panel.Size = UDim2.new(1, -24, 0, 126)
panel.BackgroundColor3 = Color3.fromRGB(11, 27, 39)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Parent = screenGui

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(280, 126)
sizeConstraint.MaxSize = Vector2.new(560, 126)
sizeConstraint.Parent = panel

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = panel

local outline = Instance.new("UIStroke")
outline.Color = Color3.fromRGB(59, 154, 169)
outline.Thickness = 1.5
outline.Transparency = 0.12
outline.Parent = panel

local function makeLabel(parent, name, text, position, size, fontSize, color, bold)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Position = position
	label.Size = size
	label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	label.Text = text
	label.TextColor3 = color
	label.TextSize = fontSize
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

local leftColumn = UDim2.new(1, -146, 0, 28)
makeLabel(
	panel,
	"Title",
	"BERUMIDA-HAVEN",
	UDim2.new(0, 15, 0, 10),
	leftColumn,
	16,
	Color3.fromRGB(244, 248, 250),
	true
)

local subtitle = makeLabel(
	panel,
	"Subtitle",
	"Party max. " .. tostring(Config.Lobby.MaxPartySize) .. "  •  Wereld max. " .. tostring(Config.Lobby.MaxPlayersPerSavedWorld),
	UDim2.new(0, 16, 0, 41),
	UDim2.new(1, -148, 0, 27),
	12,
	Color3.fromRGB(167, 204, 211),
	false
)
subtitle.TextTruncate = Enum.TextTruncate.AtEnd

local status = makeLabel(
	panel,
	"Status",
	"Lobbyprototype  •  party en opgeslagen werelden volgen",
	UDim2.new(0, 16, 0, 75),
	UDim2.new(1, -148, 0, 37),
	11,
	Color3.fromRGB(238, 190, 112),
	false
)
status.TextTruncate = Enum.TextTruncate.AtEnd

local clockPanel = Instance.new("Frame")
clockPanel.Name = "ClockPanel"
clockPanel.AnchorPoint = Vector2.new(1, 0)
clockPanel.Position = UDim2.new(1, -12, 0, 18)
clockPanel.Size = UDim2.new(0, 118, 0, 90)
clockPanel.BackgroundColor3 = Color3.fromRGB(21, 47, 58)
clockPanel.BackgroundTransparency = 0.05
clockPanel.BorderSizePixel = 0
clockPanel.Parent = panel

local clockCorner = Instance.new("UICorner")
clockCorner.CornerRadius = UDim.new(0, 10)
clockCorner.Parent = clockPanel

local dayLabel = makeLabel(
	clockPanel,
	"DayLabel",
	"DAG 01",
	UDim2.new(0, 6, 0, 8),
	UDim2.new(1, -12, 0, 22),
	12,
	Color3.fromRGB(125, 224, 207),
	true
)
dayLabel.TextXAlignment = Enum.TextXAlignment.Center

local timeLabel = makeLabel(
	clockPanel,
	"TimeLabel",
	"06:00",
	UDim2.new(0, 5, 0, 29),
	UDim2.new(1, -10, 0, 43),
	24,
	Color3.fromRGB(255, 255, 255),
	true
)
timeLabel.TextXAlignment = Enum.TextXAlignment.Center

local phaseLabel = makeLabel(
	clockPanel,
	"PhaseLabel",
	"DAGLICHT",
	UDim2.new(0, 5, 1, -21),
	UDim2.new(1, -10, 0, 15),
	10,
	Color3.fromRGB(185, 202, 211),
	false
)
phaseLabel.TextXAlignment = Enum.TextXAlignment.Center

local function refreshClock()
	local day = tonumber(Lighting:GetAttribute("GameDay")) or 1
	local isNight = Lighting:GetAttribute("IsNight") == true
	local clockTime = Lighting.ClockTime % 24
	local hour = math.floor(clockTime)
	local minute = math.floor((clockTime - hour) * 60 + 0.5) % 60

	dayLabel.Text = string.format("DAG %02d", day)
	timeLabel.Text = string.format("%02d:%02d", hour, minute)
	phaseLabel.Text = isNight and "NACHT" or "DAGLICHT"
end

local function addWorldSign(lobby, partName, title, detail, accent)
	local board = lobby:FindFirstChild(partName, true)
	if not board or not board:IsA("BasePart") or board:FindFirstChild("LobbySignGui") then
		return
	end

	local surface = Instance.new("SurfaceGui")
	surface.Name = "LobbySignGui"
	surface.Face = Enum.NormalId.Front
	surface.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	surface.CanvasSize = Vector2.new(600, 330)
	surface.AlwaysOnTop = true
	surface.LightInfluence = 0
	surface.Parent = board

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(10, 24, 34)
	background.BackgroundTransparency = 0.06
	background.BorderSizePixel = 0
	background.Parent = surface

	local accentBar = Instance.new("Frame")
	accentBar.Name = "Accent"
	accentBar.Size = UDim2.new(1, 0, 0, 12)
	accentBar.BackgroundColor3 = accent
	accentBar.BorderSizePixel = 0
	accentBar.Parent = background

	makeLabel(
		background,
		"SignTitle",
		title,
		UDim2.new(0, 22, 0, 36),
		UDim2.new(1, -44, 0, 120),
		44,
		Color3.fromRGB(246, 249, 250),
		true
	).TextXAlignment = Enum.TextXAlignment.Center

	makeLabel(
		background,
		"SignDetail",
		detail,
		UDim2.new(0, 26, 0, 168),
		UDim2.new(1, -52, 0, 112),
		25,
		Color3.fromRGB(176, 202, 210),
		false
	).TextXAlignment = Enum.TextXAlignment.Center
end

task.spawn(function()
	local lobby = workspace:WaitForChild("BerumidaLobbyPrototype", 15)
	if not lobby then
		return
	end

	addWorldSign(lobby, "PartyBoardPanel", "PARTY", "Start met maximaal 5 spelers", Color3.fromRGB(51, 181, 174))
	addWorldSign(lobby, "SavedWorldBoardPanel", "WERELDEN", "Join na de eerste vaartocht • max. 10 tegelijk", Color3.fromRGB(58, 140, 202))
	addWorldSign(lobby, "BoatShopBoardPanel", "BOTENSHOP", "Gewone boten • showroom", Color3.fromRGB(224, 161, 67))
	addWorldSign(lobby, "VIPBoardPanel", "VIP", "Exclusieve boot • starter kit", Color3.fromRGB(158, 93, 226))
	addWorldSign(lobby, "ResearchMapBoardPanel", "BERUMIDA-DRIEHOEK", "Oceaanonderzoeksgebied", Color3.fromRGB(92, 211, 193))
end)

Lighting:GetAttributeChangedSignal("GameDay"):Connect(refreshClock)
Lighting:GetAttributeChangedSignal("IsNight"):Connect(refreshClock)
Lighting:GetPropertyChangedSignal("ClockTime"):Connect(refreshClock)
refreshClock()
