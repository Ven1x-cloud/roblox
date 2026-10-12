-- Roblox Studio Git Bridge
-- Install this file in the Studio Plugins folder, then restart Studio.
-- The companion server and the JSON format are documented in README.md.

local HttpService = game:GetService("HttpService")
local Selection = game:GetService("Selection")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ScriptEditorService = game:GetService("ScriptEditorService")

local PLUGIN_ID = "RobloxGitBridgeDockWidget_v1"
local MAX_INSTANCES = 3000
local MAX_SOURCE_LENGTH = 256000
local MAX_SNAPSHOT_BYTES = 7 * 1024 * 1024
local MAX_OPERATIONS = 500

local toolbar = plugin:CreateToolbar("Roblox Git Bridge")
local openButton = toolbar:CreateButton(
	"Roblox Git Bridge",
	"Open the local Git bridge for snapshots and reviewed changes",
	""
)
openButton.ClickableWhenViewportHidden = true

local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Right,
	false,
	false,
	430,
	650,
	350,
	420
)
local widget = plugin:CreateDockWidgetPluginGui(PLUGIN_ID, widgetInfo)
widget.Title = "Roblox Git Bridge"

local function make(className, properties, parent)
	local object = Instance.new(className)
	for key, value in pairs(properties or {}) do
		object[key] = value
	end
	object.Parent = parent
	return object
end

local background = make("Frame", {
	Name = "Background",
	BackgroundColor3 = Color3.fromRGB(25, 28, 35),
	BorderSizePixel = 0,
	Size = UDim2.fromScale(1, 1),
}, widget)

local scroll = make("ScrollingFrame", {
	Name = "Content",
	Active = true,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	ScrollBarImageColor3 = Color3.fromRGB(105, 116, 137),
	ScrollBarThickness = 7,
	Size = UDim2.new(1, 0, 1, 0),
}, background)
make("UIPadding", {
	PaddingBottom = UDim.new(0, 16),
	PaddingLeft = UDim.new(0, 14),
	PaddingRight = UDim.new(0, 14),
	PaddingTop = UDim.new(0, 14),
}, scroll)
make("UIListLayout", {
	Padding = UDim.new(0, 7),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, scroll)

local layoutOrder = 0
local function nextOrder()
	layoutOrder += 1
	return layoutOrder
end

local function addLabel(text, height, color, fontSize)
	return make("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		LayoutOrder = nextOrder(),
		Size = UDim2.new(1, -4, 0, height),
		Text = text,
		TextColor3 = color or Color3.fromRGB(226, 231, 241),
		TextSize = fontSize or 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, scroll)
end

local function addTextBox(placeholder, initialText)
	return make("TextBox", {
		BackgroundColor3 = Color3.fromRGB(39, 44, 54),
		BorderColor3 = Color3.fromRGB(67, 76, 92),
		ClearTextOnFocus = false,
		Font = Enum.Font.Code,
		LayoutOrder = nextOrder(),
		PlaceholderColor3 = Color3.fromRGB(145, 155, 171),
		PlaceholderText = placeholder,
		Size = UDim2.new(1, -4, 0, 34),
		Text = initialText or "",
		TextColor3 = Color3.fromRGB(244, 246, 250),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, scroll)
end

local function addButton(text, color)
	return make("TextButton", {
		AutoButtonColor = true,
		BackgroundColor3 = color or Color3.fromRGB(51, 101, 174),
		BorderSizePixel = 0,
		Font = Enum.Font.GothamSemibold,
		LayoutOrder = nextOrder(),
		Size = UDim2.new(1, -4, 0, 38),
		Text = text,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 13,
	}, scroll)
end

addLabel("Roblox Git Bridge", 28, Color3.fromRGB(255, 255, 255), 20)
addLabel(
	"Exporteer je wereld naar de repo. Bekijk een patch eerst; toepassen is altijd handmatig.",
	42,
	Color3.fromRGB(175, 187, 205),
	12
)
addLabel("Lokale bridge-URL", 18, Color3.fromRGB(195, 204, 219), 12)
local urlBox = addTextBox("http://127.0.0.1:47831", "http://127.0.0.1:47831")
addLabel("Tijdelijke bridge-token", 18, Color3.fromRGB(195, 204, 219), 12)
local tokenBox = addTextBox("Plak de token uit de terminal", "")

local row = make("Frame", {
	BackgroundTransparency = 1,
	LayoutOrder = nextOrder(),
	Size = UDim2.new(1, -4, 0, 38),
}, scroll)
local saveTestButton = make("TextButton", {
	AutoButtonColor = true,
	BackgroundColor3 = Color3.fromRGB(52, 119, 91),
	BorderSizePixel = 0,
	Font = Enum.Font.GothamSemibold,
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(0.58, -4, 1, 0),
	Text = "Opslaan + testverbinding",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 12,
}, row)
local toggleScriptsButton = make("TextButton", {
	AutoButtonColor = true,
	BackgroundColor3 = Color3.fromRGB(70, 76, 91),
	BorderSizePixel = 0,
	Font = Enum.Font.GothamSemibold,
	Position = UDim2.new(0.58, 4, 0, 0),
	Size = UDim2.new(0.42, -4, 1, 0),
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 11,
}, row)

local statusLabel = addLabel("Status: start de lokale bridge en test de verbinding.", 170, Color3.fromRGB(174, 205, 190), 12)
statusLabel.TextYAlignment = Enum.TextYAlignment.Top

local exportWorkspaceButton = addButton("Workspace exporteren")
local exportSelectionButton = addButton("Selectie exporteren")
local previewButton = addButton("Wijzigingen bekijken", Color3.fromRGB(111, 83, 169))
local applyButton = addButton("Voorbeeld toepassen", Color3.fromRGB(183, 104, 45))
applyButton.Visible = false
addLabel(
	"Export maakt een JSON-snapshot in studio/snapshots. De bridge doet geen Git-commit of push. " ..
	"Lees scriptwijzigingen na voordat je ze toepast.",
	52,
	Color3.fromRGB(155, 169, 190),
	11
)

local storedUrl = plugin:GetSetting("RobloxGitBridgeUrl")
if type(storedUrl) == "string" and storedUrl ~= "" then
	urlBox.Text = storedUrl
end
local storedToken = plugin:GetSetting("RobloxGitBridgeToken")
if type(storedToken) == "string" then
	tokenBox.Text = storedToken
end
local includeScripts = plugin:GetSetting("RobloxGitBridgeIncludeScripts") ~= false
local pendingChangeSet = nil
local busy = false

local function refreshScriptsButton()
	toggleScriptsButton.Text = includeScripts and "Scripts: AAN" or "Scripts: UIT"
end
refreshScriptsButton()

local function setStatus(message, isError)
	statusLabel.Text = "Status: " .. tostring(message)
	statusLabel.TextColor3 = isError and Color3.fromRGB(255, 157, 151) or Color3.fromRGB(174, 205, 190)
end

local function normalizedBaseUrl()
	local base = string.gsub(urlBox.Text or "", "%s", "")
	base = string.gsub(base, "/+$", "")
	local authority = string.match(base, "^http://([^/]+)$")
	if not authority then
		error("Gebruik alleen een lokale URL zoals http://127.0.0.1:47831")
	end
	local hostName, portText = string.match(authority, "^([%w%.%-]+):(%d+)$")
	if not hostName or (hostName ~= "127.0.0.1" and hostName ~= "localhost") then
		error("De URL moet naar 127.0.0.1 of localhost verwijzen; stuur de token nooit naar een externe host.")
	end
	local portNumber = tonumber(portText)
	if not portNumber or portNumber < 1 or portNumber > 65535 then
		error("De URL bevat geen geldige poort.")
	end
	return base
end

local function saveSettings()
	plugin:SetSetting("RobloxGitBridgeUrl", urlBox.Text)
	plugin:SetSetting("RobloxGitBridgeToken", tokenBox.Text)
	plugin:SetSetting("RobloxGitBridgeIncludeScripts", includeScripts)
end

local function request(method, route, payload, useToken)
	local base = normalizedBaseUrl()
	local headers = { ["Content-Type"] = "application/json" }
	if useToken ~= false then
		local token = string.gsub(tokenBox.Text or "", "^%s*(.-)%s*$", "%1")
		if token == "" then
			error("Plak eerst de bridge-token uit de terminal.")
		end
		headers.Authorization = "Bearer " .. token
	end

	local requestOptions = {
		Url = base .. route,
		Method = method,
		Headers = headers,
	}
	if payload ~= nil then
		requestOptions.Body = HttpService:JSONEncode(payload)
	end

	local response = HttpService:RequestAsync(requestOptions)
	local decoded = nil
	if response.Body and response.Body ~= "" then
		local decodeOk, decodeResult = pcall(function()
			return HttpService:JSONDecode(response.Body)
		end)
		if decodeOk then
			decoded = decodeResult
		end
	end
	if not response.Success then
		local message = type(decoded) == "table" and decoded.error or nil
		error(message or ("HTTP " .. tostring(response.StatusCode) .. ": " .. tostring(response.StatusMessage)))
	end
	return decoded
end

local function vectorArray(vector)
	return { vector.X, vector.Y, vector.Z }
end

local function getPath(instance)
	local reversed = {}
	local current = instance
	while current and current ~= game do
		local parent = current.Parent
		if not parent then
			break
		end
		local ordinal = 0
		for _, sibling in ipairs(parent:GetChildren()) do
			if sibling.Name == current.Name and sibling.ClassName == current.ClassName then
				ordinal += 1
				if sibling == current then
					break
				end
			end
		end
		table.insert(reversed, {
			name = current.Name,
			className = current.ClassName,
			ordinal = math.max(ordinal, 1),
		})
		current = parent
	end
	local path = {}
	for index = #reversed, 1, -1 do
		table.insert(path, reversed[index])
	end
	return path
end

local function serializeInstance(instance, depth, counters)
	if depth > 80 then
		error("De objecthiërarchie is dieper dan 80 niveaus; exporteer een kleinere selectie.")
	end
	counters.instances += 1
	if counters.instances > MAX_INSTANCES then
		error("De export bevat meer dan " .. tostring(MAX_INSTANCES) .. " objecten; exporteer een kleinere selectie.")
	end

	local node = {
		name = instance.Name,
		className = instance.ClassName,
		path = getPath(instance),
		properties = {},
		children = {},
	}
	local properties = node.properties

	if instance:IsA("BasePart") then
		properties.Size = vectorArray(instance.Size)
		properties.Position = vectorArray(instance.Position)
		properties.Orientation = vectorArray(instance.Orientation)
		properties.Anchored = instance.Anchored
		properties.CanCollide = instance.CanCollide
		properties.CanTouch = instance.CanTouch
		properties.CanQuery = instance.CanQuery
		properties.CastShadow = instance.CastShadow
		properties.Transparency = instance.Transparency
		properties.Reflectance = instance.Reflectance
		properties.Color = { instance.Color.R, instance.Color.G, instance.Color.B }
		properties.Material = instance.Material.Name
		if instance:IsA("Part") then
			properties.Shape = instance.Shape.Name
		end
	end
	if instance:IsA("SpawnLocation") then
		properties.Neutral = instance.Neutral
		properties.Duration = instance.Duration
	end
	if instance:IsA("PointLight") or instance:IsA("SpotLight") then
		properties.Enabled = instance.Enabled
		properties.Brightness = instance.Brightness
		properties.Range = instance.Range
		properties.Color = { instance.Color.R, instance.Color.G, instance.Color.B }
		properties.Shadows = instance.Shadows
		if instance:IsA("SpotLight") then
			properties.Angle = instance.Angle
			properties.Face = instance.Face.Name
		end
	end
	if instance:IsA("Attachment") then
		properties.Position = vectorArray(instance.Position)
		properties.Orientation = vectorArray(instance.Orientation)
	end
	if instance:IsA("Decal") or instance:IsA("Texture") then
		properties.Texture = instance.Texture
		properties.Transparency = instance.Transparency
		properties.Face = instance.Face.Name
		properties.Color3 = { instance.Color3.R, instance.Color3.G, instance.Color3.B }
	end
	if instance:IsA("LuaSourceContainer") then
		counters.scripts += 1
		if instance:IsA("Script") or instance:IsA("LocalScript") then
			properties.Disabled = instance.Disabled
		end
		if includeScripts then
			local sourceOk, source = pcall(function()
				return instance.Source
			end)
			if sourceOk and type(source) == "string" then
				if #source > MAX_SOURCE_LENGTH then
					error("Script '" .. instance.Name .. "' is groter dan de exportlimiet.")
				end
				node.source = source
			else
				node.sourceUnavailable = true
			end
		end
	end
	if next(properties) == nil then
		node.properties = nil
	end

	for _, child in ipairs(instance:GetChildren()) do
		table.insert(node.children, serializeInstance(child, depth + 1, counters))
	end
	return node
end

local function rootSelection(selection)
	local roots = {}
	for _, instance in ipairs(selection) do
		local nested = false
		for _, other in ipairs(selection) do
			if instance ~= other and instance:IsDescendantOf(other) then
				nested = true
				break
			end
		end
		if not nested then
			table.insert(roots, instance)
		end
	end
	return roots
end

local function exportInstances(instances, selectedOnly)
	if #instances == 0 then
		error("Er zijn geen objecten om te exporteren.")
	end
	local counters = { instances = 0, scripts = 0 }
	local roots = {}
	for _, instance in ipairs(instances) do
		table.insert(roots, serializeInstance(instance, 1, counters))
	end

	local snapshot = {
		schemaVersion = 1,
		exportedAt = os.date("!%Y-%m-%dT%H:%M:%SZ"),
		placeName = game.Name,
		placeId = game.PlaceId,
		selectedOnly = selectedOnly,
		includeScripts = includeScripts,
		roots = roots,
	}
	local encoded = HttpService:JSONEncode(snapshot)
	if #encoded > MAX_SNAPSHOT_BYTES then
		error("De snapshot is groter dan de pluginlimiet; exporteer minder objecten of zet Scripts uit.")
	end
	local result = request("POST", "/v1/snapshot", snapshot, true)
	return result, counters
end

local function validatePath(path, label)
	if type(path) ~= "table" or #path == 0 or #path > 80 then
		error(label .. " moet een pad-array met minstens één segment zijn.")
	end
	for index, segment in ipairs(path) do
		if type(segment) ~= "table" or type(segment.name) ~= "string" or type(segment.className) ~= "string" then
			error(label .. " bevat een ongeldig padsegment.")
		end
		if type(segment.ordinal) ~= "number" or segment.ordinal < 1 or segment.ordinal % 1 ~= 0 then
			error(label .. " bevat een ongeldige ordinal.")
		end
		if index > 80 then
			error(label .. " is te diep.")
		end
	end
end

local knownProperties = {
	Anchored = true, CanCollide = true, CanTouch = true, CanQuery = true, CastShadow = true,
	Disabled = true, Enabled = true, Neutral = true, Shadows = true,
	Transparency = true, Reflectance = true, Brightness = true, Range = true, Angle = true, Duration = true,
	Size = true, Position = true, Orientation = true,
	Color = true, Color3 = true, Material = true, Shape = true, Face = true, Texture = true,
}
local allowedClasses = {
	Model = true, Folder = true, Part = true, SpawnLocation = true,
	Script = true, LocalScript = true, ModuleScript = true,
	PointLight = true, SpotLight = true, Attachment = true, Decal = true, Texture = true,
}

local function validateProperties(properties, label)
	if type(properties) ~= "table" then
		error(label .. " moet een object zijn.")
	end
	local count = 0
	for key, value in pairs(properties) do
		count += 1
		if count > 40 or not knownProperties[key] then
			error(label .. " bevat een niet-ondersteunde property: " .. tostring(key))
		end
		if type(value) == "number" and (value ~= value or math.abs(value) == math.huge) then
			error(label .. "." .. key .. " moet een eindig getal zijn.")
		end
	end
end

local function validateCreateNode(node, depth)
	if depth > 40 or type(node) ~= "table" then
		error("Een aangemaakt object is ongeldig of te diep genest.")
	end
	if type(node.name) ~= "string" or node.name == "" or #node.name > 100 then
		error("Een aangemaakt object heeft een ongeldige naam.")
	end
	if type(node.className) ~= "string" or not allowedClasses[node.className] then
		error("Aanmaken van klasse '" .. tostring(node.className) .. "' is niet toegestaan.")
	end
	validateProperties(node.properties or {}, "properties voor " .. node.name)
	if node.source ~= nil and (type(node.source) ~= "string" or #node.source > MAX_SOURCE_LENGTH) then
		error("De scriptbron voor " .. node.name .. " is ongeldig of te groot.")
	end
	if node.children ~= nil and type(node.children) ~= "table" then
		error("children van " .. node.name .. " moet een array zijn.")
	end
	for _, child in ipairs(node.children or {}) do
		validateCreateNode(child, depth + 1)
	end
end

local function validateChangeSet(changeSet)
	if type(changeSet) ~= "table" or changeSet.schemaVersion ~= 1 then
		error("De patch heeft geen ondersteunde schemaVersion.")
	end
	if type(changeSet.id) ~= "string" or changeSet.id == "" or #changeSet.id > 100 or not string.match(changeSet.id, "^[%w%._%-]+$") then
		error("De patch heeft een ongeldige id.")
	end
	if type(changeSet.summary) ~= "string" or #changeSet.summary > 500 then
		error("De patch heeft geen geldige samenvatting.")
	end
	if type(changeSet.operations) ~= "table" or #changeSet.operations > MAX_OPERATIONS then
		error("De patch bevat te veel of ongeldige operaties.")
	end
	for _, operation in ipairs(changeSet.operations) do
		if type(operation) ~= "table" then
			error("De patch bevat een ongeldige operatie.")
		elseif operation.op == "create" then
			validatePath(operation.parent, "create.parent")
			validateCreateNode(operation.node, 1)
		elseif operation.op == "set" then
			validatePath(operation.path, "set.path")
			validateProperties(operation.properties, "set.properties")
		elseif operation.op == "setSource" then
			validatePath(operation.path, "setSource.path")
			if type(operation.source) ~= "string" or #operation.source > MAX_SOURCE_LENGTH then
				error("De patch bevat ongeldige of te grote scriptbroncode.")
			end
		elseif operation.op == "delete" then
			validatePath(operation.path, "delete.path")
		else
			error("Onbekende patchoperatie: " .. tostring(operation.op))
		end
	end
	return true
end

local function resolvePath(path)
	validatePath(path, "object path")
	local current = game
	local startIndex = 1
	if path[1].name == "Workspace" and path[1].className == "Workspace" then
		current = workspace
		startIndex = 2
	end
	for index = startIndex, #path do
		local segment = path[index]
		local matches = {}
		for _, child in ipairs(current:GetChildren()) do
			if child.Name == segment.name and child.ClassName == segment.className then
				table.insert(matches, child)
			end
		end
		current = matches[segment.ordinal]
		if not current then
			error("Object niet gevonden op padsegment '" .. segment.name .. "' (ordinal " .. tostring(segment.ordinal) .. ").")
		end
	end
	return current
end

local basePartProperties = {
	Anchored = true, CanCollide = true, CanTouch = true, CanQuery = true, CastShadow = true,
	Transparency = true, Reflectance = true, Size = true, Position = true, Orientation = true,
	Color = true, Material = true,
}
local specificProperties = {
	Part = { Shape = true },
	SpawnLocation = { Neutral = true, Duration = true },
	Script = { Disabled = true },
	LocalScript = { Disabled = true },
	PointLight = { Enabled = true, Brightness = true, Range = true, Color = true, Shadows = true },
	SpotLight = { Enabled = true, Brightness = true, Range = true, Color = true, Shadows = true, Angle = true, Face = true },
	Attachment = { Position = true, Orientation = true },
	Decal = { Texture = true, Transparency = true, Face = true, Color3 = true },
	Texture = { Texture = true, Transparency = true, Face = true, Color3 = true },
}

local function isAllowedProperty(instance, key)
	if instance:IsA("BasePart") and basePartProperties[key] then
		return true
	end
	local classRules = specificProperties[instance.ClassName]
	return classRules ~= nil and classRules[key] == true
end

local function finiteNumber(value, label)
	if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
		error(label .. " moet een eindig getal zijn.")
	end
	return value
end

local function toVector3(value, label)
	if type(value) ~= "table" or #value ~= 3 then
		error(label .. " moet [x, y, z] zijn.")
	end
	return Vector3.new(
		finiteNumber(value[1], label),
		finiteNumber(value[2], label),
		finiteNumber(value[3], label)
	)
end

local function toColor3(value, label)
	if type(value) ~= "table" or #value ~= 3 then
		error(label .. " moet [r, g, b] zijn.")
	end
	local r = finiteNumber(value[1], label)
	local g = finiteNumber(value[2], label)
	local b = finiteNumber(value[3], label)
	if r < 0 or r > 1 or g < 0 or g > 1 or b < 0 or b > 1 then
		error(label .. " moet RGB-waarden tussen 0 en 1 gebruiken.")
	end
	return Color3.new(r, g, b)
end

local function enumValue(enumType, value, label)
	if type(value) ~= "string" then
		error(label .. " moet een Enum-naam zijn.")
	end
	local ok, item = pcall(function()
		return enumType[value]
	end)
	if not ok or item == nil then
		error("Ongeldige Enum-waarde voor " .. label .. ": " .. value)
	end
	return item
end

local function setProperty(instance, key, value)
	if not isAllowedProperty(instance, key) then
		error("Property '" .. tostring(key) .. "' is niet toegestaan op " .. instance.ClassName .. ".")
	end

	local converted = value
	if key == "Size" or key == "Position" or key == "Orientation" then
		converted = toVector3(value, key)
	elseif key == "Color" or key == "Color3" then
		converted = toColor3(value, key)
	elseif key == "Material" then
		converted = enumValue(Enum.Material, value, key)
	elseif key == "Shape" then
		converted = enumValue(Enum.PartType, value, key)
	elseif key == "Face" then
		converted = enumValue(Enum.NormalId, value, key)
	elseif key == "Transparency" or key == "Reflectance" then
		converted = finiteNumber(value, key)
		if converted < 0 or converted > 1 then
			error(key .. " moet tussen 0 en 1 liggen.")
		end
	elseif key == "Brightness" or key == "Range" or key == "Angle" or key == "Duration" then
		converted = finiteNumber(value, key)
	elseif key == "Texture" then
		if type(value) ~= "string" then
			error("Texture moet een string zijn.")
		end
	elseif type(value) ~= "boolean" then
		error(key .. " moet een boolean zijn.")
	end

	local ok, assignmentError = pcall(function()
		instance[key] = converted
	end)
	if not ok then
		error("Kon " .. key .. " niet instellen: " .. tostring(assignmentError))
	end
end

local function setScriptSource(instance, source)
	if not instance:IsA("LuaSourceContainer") then
		error("setSource werkt alleen op Script, LocalScript of ModuleScript.")
	end
	if type(source) ~= "string" or #source > MAX_SOURCE_LENGTH then
		error("Scriptbroncode is ongeldig of te groot.")
	end

	local updateOk, updateError = pcall(function()
		ScriptEditorService:UpdateSourceAsync(instance, function()
			return source
		end)
	end)
	if not updateOk then
		local directOk, directError = pcall(function()
			instance.Source = source
		end)
		if not directOk then
			error("Kon scriptbron niet bijwerken: " .. tostring(updateError) .. " / " .. tostring(directError))
		end
	end
end

local function createNode(parent, node)
	for _, child in ipairs(parent:GetChildren()) do
		if child.Name == node.name then
			error("Er bestaat al een child met de naam '" .. node.name .. "' onder " .. parent:GetFullName() .. ".")
		end
	end
	local instance = Instance.new(node.className)
	instance.Name = node.name
	if instance:IsA("BasePart") then
		instance.Anchored = true
	end
	for key, value in pairs(node.properties or {}) do
		setProperty(instance, key, value)
	end
	if node.source ~= nil then
		setScriptSource(instance, node.source)
	end
	instance.Parent = parent
	for _, childNode in ipairs(node.children or {}) do
		createNode(instance, childNode)
	end
	return instance
end

local function applyOperation(operation)
	if operation.op == "create" then
		local parent = resolvePath(operation.parent)
		if parent == game then
			error("Aanmaken direct onder game is niet toegestaan.")
		end
		createNode(parent, operation.node)
	elseif operation.op == "set" then
		local target = resolvePath(operation.path)
		for key, value in pairs(operation.properties) do
			setProperty(target, key, value)
		end
	elseif operation.op == "setSource" then
		setScriptSource(resolvePath(operation.path), operation.source)
	elseif operation.op == "delete" then
		local target = resolvePath(operation.path)
		if target == game or target.Parent == game then
			error("Een service of het DataModel zelf kan niet worden verwijderd.")
		end
		target:Destroy()
	else
		error("Onbekende patchoperatie.")
	end
end

local function operationDescription(operation)
	if operation.op == "create" then
		return "+ " .. operation.node.className .. " " .. operation.node.name
	elseif operation.op == "delete" then
		local last = operation.path[#operation.path]
		return "− " .. last.name
	elseif operation.op == "setSource" then
		local last = operation.path[#operation.path]
		return "code bijwerken: " .. last.name
	elseif operation.op == "set" then
		local last = operation.path[#operation.path]
		local count = 0
		for _ in pairs(operation.properties) do
			count += 1
		end
		return "~ " .. last.name .. " (" .. tostring(count) .. " properties)"
	end
	return "? onbekende operatie"
end

local function run(action)
	if busy then
		return
	end
	busy = true
	local ok, result = pcall(action)
	busy = false
	if not ok then
		setStatus(tostring(result), true)
	end
end

openButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

saveTestButton.Activated:Connect(function()
	run(function()
		saveSettings()
		local result = request("GET", "/health", nil, false)
		if type(result) ~= "table" or result.ok ~= true then
			error("De lokale bridge gaf geen geldige health-response terug.")
		end
		setStatus("Verbinding werkt met " .. tostring(result.service) .. ". De token is lokaal opgeslagen.", false)
	end)
end)

toggleScriptsButton.Activated:Connect(function()
	includeScripts = not includeScripts
	refreshScriptsButton()
	saveSettings()
	setStatus(includeScripts and "Scriptbroncode wordt meegenomen in nieuwe snapshots." or "Scriptbroncode wordt overgeslagen in nieuwe snapshots.", false)
end)

exportWorkspaceButton.Activated:Connect(function()
	run(function()
		saveSettings()
		setStatus("Workspace wordt geëxporteerd…", false)
		local result, counters = exportInstances({ workspace }, false)
		setStatus(
			"Snapshot opgeslagen: " .. tostring(result.file) .. "\n" ..
			tostring(counters.instances) .. " objecten, " .. tostring(counters.scripts) .. " scripts. " ..
			"Commit/push de snapshot zelf als je hem in GitHub wilt bewaren.",
			false
		)
	end)
end)

exportSelectionButton.Activated:Connect(function()
	run(function()
		saveSettings()
		local selectedRoots = rootSelection(Selection:Get())
		setStatus("Selectie wordt geëxporteerd…", false)
		local result, counters = exportInstances(selectedRoots, true)
		setStatus(
			"Snapshot opgeslagen: " .. tostring(result.file) .. "\n" ..
			tostring(counters.instances) .. " objecten, " .. tostring(counters.scripts) .. " scripts.",
			false
		)
	end)
end)

previewButton.Activated:Connect(function()
	run(function()
		saveSettings()
		setStatus("Laatste wijzigingsbestand wordt opgehaald…", false)
		local changeSet = request("GET", "/v1/changes", nil, true)
		validateChangeSet(changeSet)
		local lastApplied = plugin:GetSetting("RobloxGitBridgeLastAppliedId")
		if lastApplied == changeSet.id then
			pendingChangeSet = nil
			applyButton.Visible = false
			error("Deze patch-id is al toegepast. Geef een nieuwe patch een nieuwe id.")
		end
		pendingChangeSet = changeSet
		applyButton.Visible = true
		local lines = {
			"Preview: " .. changeSet.summary,
			"Patch-id: " .. changeSet.id .. " | operaties: " .. tostring(#changeSet.operations),
		}
		for index, operation in ipairs(changeSet.operations) do
			if index > 8 then
				table.insert(lines, "… en " .. tostring(#changeSet.operations - 8) .. " meer")
				break
			end
			table.insert(lines, operationDescription(operation))
		end
		setStatus(table.concat(lines, "\n") .. "\nKlik Voorbeeld toepassen pas nadat je de patch hebt gecontroleerd.", false)
	end)
end)

applyButton.Activated:Connect(function()
	run(function()
		local changeSet = pendingChangeSet
		if not changeSet then
			error("Haal eerst een patch op met Wijzigingen bekijken.")
		end
		validateChangeSet(changeSet)
		if plugin:GetSetting("RobloxGitBridgeLastAppliedId") == changeSet.id then
			error("Deze patch-id is al toegepast.")
		end

		pcall(function()
			ChangeHistoryService:SetWaypoint("Before Roblox Git Bridge: " .. changeSet.id)
		end)
		local completed = 0
		for index, operation in ipairs(changeSet.operations) do
			local operationOk, operationError = pcall(function()
				applyOperation(operation)
			end)
			if not operationOk then
				pcall(function()
					ChangeHistoryService:SetWaypoint("Partial Roblox Git Bridge: " .. changeSet.id)
				end)
				pendingChangeSet = nil
				applyButton.Visible = false
				error(
					"Toepassen stopte bij operatie " .. tostring(index) .. ". " .. tostring(completed) ..
					" eerdere operatie(s) kunnen al zijn toegepast. Gebruik Studio Ctrl+Z om terug te draaien.\n" ..
					tostring(operationError)
				)
			end
			completed += 1
		end
		pcall(function()
			ChangeHistoryService:SetWaypoint("After Roblox Git Bridge: " .. changeSet.id)
		end)
		plugin:SetSetting("RobloxGitBridgeLastAppliedId", changeSet.id)
		pendingChangeSet = nil
		applyButton.Visible = false
		setStatus("Patch toegepast (" .. tostring(completed) .. " operaties). De code is niet door de plugin uitgevoerd.", false)
	end)
end)

setStatus("Start npm start in de repo, plak de token en test de verbinding.", false)
