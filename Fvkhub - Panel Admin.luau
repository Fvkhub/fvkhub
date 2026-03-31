

-- FVKHUB Admin Panel Script --
-- 1. Fly + Noclip
-- 2. Fullbright
-- 3. Noclip
-- 4. WalkSpeed control
-- 5. FlySpeed control
-- 6. ESP (Team/Enemy/All/NPC)
-- 7. Dash (Q key)
-- 8. No Shadow (K key)
-- 9. Visible All Parts (Y key)
-- 10. No Touch (L key)
-- 11. Server List (Join/Hop/Rejoin)
-- 12. Building Tools (BTools)
-- 13. Local Script Loader (Scripts folder)

-- Services & Core (Bypass-aware initialization)
local S = {}
local E = {}
local localPlayer = game:GetService("Players").LocalPlayer or game:GetService("Players").PlayerAdded:Wait()

-- -- [STABILITY] UNIQUE EXECUTION GUARD
-- Cleaning up previous execution's UI and Background Loops
-- Core Tables (Declared early for all functions)
local U = {}
local G_Connections = (getgenv and getgenv().FVK_Connections) or {}
local G_States = (getgenv and getgenv().FVK_States) or {}
local States = G_States
local UI = { 
	buttons = {}, 
	inputs = { wpPointName = nil, walkSpeedInput = nil }, 
	pages = {}, 
	sidebarButtons = {}, 
	keybindInputs = {},
	notificationContainer = nil,
	screenGui = nil,
	mainFrame = nil
}

-- Shared references for executor across different scopes
if getgenv then 
	-- [CRITICALLY IMPORTANT] Cleanup previous execution BEFORE initializing new one
	if getgenv().FVKHUB_Cleanup and type(getgenv().FVKHUB_Cleanup) == "function" then
		pcall(getgenv().FVKHUB_Cleanup)
	end
	
	getgenv().FVK_Connections = G_Connections 
	getgenv().FVK_States = G_States
end

-- Reset destruction flag for NEW execution session
States.isDestroyed = false

-- [[ 1. IMMEDIATE BOOTSTRAP BYPASS ]]
-- This runs BEFORE anything else to prevent kicking at startup
local function bootstrap()
	
	-- Executor Globals
	E = {
		writefile = writefile or (getgenv and getgenv().writefile),
		readfile = readfile or (getgenv and getgenv().readfile),
		isfile = isfile or (getgenv and getgenv().isfile),
		listfiles = listfiles or (getgenv and getgenv().listfiles),
		makefolder = makefolder or (getgenv and getgenv().makefolder),
		isfolder = isfolder or (getgenv and getgenv().isfolder),
		delfile = delfile or (getgenv and getgenv().delfile),
		sethiddenproperty = sethiddenproperty or (getgenv and getgenv().sethiddenproperty),
		gethiddenproperty = gethiddenproperty or (getgenv and getgenv().gethiddenproperty),
		getnetworkowner = getnetworkowner or (getgenv and getgenv().getnetworkowner),
		newcclosure = newcclosure or (getgenv and getgenv().newcclosure) or function(f) return f end,
		setreadonly = setreadonly or (getgenv and getgenv().setreadonly) or function() end,
		getrawmetatable = getrawmetatable or (getgenv and getgenv().getrawmetatable),
		getnamecallmethod = getnamecallmethod or (getgenv and getgenv().getnamecallmethod),
		checkcaller = checkcaller or (getgenv and getgenv().checkcaller) or function() return true end,
		gethui = gethui or (getgenv and getgenv().gethui),
		loadstring = loadstring or (getgenv and getgenv().loadstring),
		getconnections = getconnections or (getgenv and getgenv().getconnections),
		fireproximityprompt = fireproximityprompt or (getgenv and getgenv().fireproximityprompt),
		firetouchinterest = firetouchinterest or (getgenv and getgenv().firetouchinterest),
	}

	-- Admin Injection
	pcall(function()
		local rs = game:GetService("ReplicatedStorage")
		local adminModule = rs:FindFirstChild("Admins", true)
		if adminModule and adminModule:IsA("ModuleScript") then
			local admins = require(adminModule)
			if typeof(admins) == "table" then
				admins[localPlayer.Name] = true
				admins[tostring(localPlayer.UserId)] = true
				admins[localPlayer.UserId] = true
			end
		end
	end)

	-- Apply Metatable Bypass early (Consolidated)
	pcall(function()
		local gmt = E.getrawmetatable and E.getrawmetatable(game)
		if not gmt then return end
		local oldNm = gmt.__namecall
		local oldIdx = gmt.__index
		local oldNewIdx = gmt.__newindex
		E.setreadonly(gmt, false)

		gmt.__namecall = E.newcclosure(function(self, ...)
			local method = E.getnamecallmethod()
			local args = {...}
			
			if not E.checkcaller() then
				-- 1. Anti-Cheat & Service Hiding
				local sName = (method == "GetService" or method == "FindService") and args[1]
				if sName then
					local sensitive = {
						"HttpService", "VirtualInputManager", "LogService", "GuiService", "CoreGui",
						"InsertService", "AssetService", "ScriptContext", "Stats", "Selection", "UserInputService"
					}
					for _, s in ipairs(sensitive) do
						if sName == s then return nil end
					end
				end
				
				-- 2. Anti-Kick
				if method == "Kick" then return nil end

				-- 3. Anti-Cheat & Service Hiding Remotes
				-- (No damage blocking needed here)
			end
			return oldNm(self, ...)
		end)

		gmt.__index = E.newcclosure(function(self, key)
			if not E.checkcaller() then
				-- Property Spoofing
				if typeof(self) == "Instance" then
					if self == workspace and key == "Gravity" then return 196.2 end
					
					local isHum = false
					pcall(function() isHum = self:IsA("Humanoid") end)
					if isHum then
						if key == "WalkSpeed" then return 16 end
						if key == "JumpPower" then return 50 end
						if key == "JumpHeight" then return 7.2 end
						if key == "CameraOffset" then return Vector3.new(0,0,0) end
					end

					if self == localPlayer and (key == "SimulationRadius" or key == "MaximumSimulationRadius") then
						return (key == "SimulationRadius" and 100 or 1000)
					end
				end
			end
			return oldIdx(self, key)
		end)

		gmt.__newindex = E.newcclosure(function(self, key, value)
			if not E.checkcaller() then
				if typeof(self) == "Instance" then
					local isHum = false
					pcall(function() isHum = self:IsA("Humanoid") end)
					if isHum then
						if key == "CameraOffset" then return end
					end
				end
			end
			return oldNewIdx(self, key, value)
		end)

		E.setreadonly(gmt, true)
	end)
end
bootstrap()

-- Use safe service getter (Bypass __namecall hooks)
local function getService(name)
	local s
	pcall(function() s = game.GetService(game, name) end)
	return s or game:GetService(name)
end

S = {
	Players = getService("Players"),
	UserInputService = getService("UserInputService"),
	RunService = getService("RunService"),
	Lighting = getService("Lighting"),
	ReplicatedStorage = getService("ReplicatedStorage"),
	MarketplaceService = getService("MarketplaceService"),
	TweenService = getService("TweenService"),
	ContextActionService = getService("ContextActionService"),
	StarterGui = getService("StarterGui"),
	HttpService = getService("HttpService"),
	GuiService = getService("GuiService"),
	TeleportService = getService("TeleportService"),
	ProximityPromptService = getService("ProximityPromptService"),
}

-- Global variables
local mouse = localPlayer:GetMouse()

-- Detection variables (Declared early for Config)
local initialCharacter = localPlayer and localPlayer.Character
local initialHumanoid = initialCharacter and initialCharacter:FindFirstChildOfClass("Humanoid")
local actualGameWalkSpeed = 16
pcall(function()
	if initialHumanoid then
		actualGameWalkSpeed = initialHumanoid.WalkSpeed
	else
		local dummy = Instance.new("Humanoid")
		actualGameWalkSpeed = dummy.WalkSpeed
		dummy:Destroy()
	end
end)

local actualGameVehicleMultiplier = 1
pcall(function()
	local m = workspace:GetAttribute("VehicleMultiplier") or S.ReplicatedStorage:GetAttribute("VehicleMultiplier")
	if not m then
		local mv = S.ReplicatedStorage:FindFirstChild("VehicleMultiplier", true)
		if mv and mv:IsA("ValueBase") then m = mv.Value end
	end
	if typeof(m) == "number" and m > 0 then
		actualGameVehicleMultiplier = m
	end
end)


-- Core Tables

local Config = {
	DEFAULT_AUTO_E_DOWN_DELAY = 0.03,
	DEFAULT_AUTO_E_UP_DELAY = 0.12,
	DEFAULT_BRIGHTNESS = 1,
	DEFAULT_EXPOSURE_COMPENSATION = 0,
	DEFAULT_FREECAM_BASE_SPEED = 0.20,
	DEFAULT_ZOOM_AMOUNT = 5,
	DEFAULT_CLOCKTIME = 12,
	DEFAULT_GRAVITY = 196.2,
	walkSpeed = actualGameWalkSpeed,
	defaultWalkSpeedFromCharacter = actualGameWalkSpeed,
	lastKnownDefault = actualGameWalkSpeed,
	flySpeed = 80,
	vehicleFlySpeed = 80,
	walkBoostMultiplier = 2,
	baseJumpPower = 50,
	jumpBoostMultiplier = 1.5,
	bringRadius = 100,
	autoEDownDelay = 0.03,
	autoEUpDelay = 0.12,
	brightnessValue = 2,
	exposureCompensationValue = 1,
	freecamBaseSpeed = 0.2,
	vehicleBoostMultiplier = actualGameVehicleMultiplier * 2,
	vehicleBoostAcceleration = 25,
	vehicleBrakeForce = 150,
	skyboxId = "",
	flashSpeedAmount = 1,
	scrollAmount = 100,
	zoomAmount = 5,
	networkClaimRadius = 1000,
	iyflyspeed = 1,
	vehicleflyspeed = 1,
	partFlingRadius = 30, -- Adjustable Radius
	partFlingStrength = 500000, -- Power of the fling
	partFlingMode = "Spin", -- Modes: Spin, Push, Pull, Vortex, Jitter
	partPullGap = 8, -- Distance gap for Pull mode
	keybinds = {},
	isAssigningKey = nil,
	assigningStartTime = 0,
}
local Refs = {
	connections = G_Connections,
	removedNonCollideParts = {},
	visiblePartsCache = {},
	npcCache = {},
	originalJointC0 = nil,
	cachedJoint = nil,
	spinAngle = 0,
	itemCache = {}, -- { [BasePart]: true }
	espConnections = {},
	originalTransparency = {},
	originalLighting = nil,
	realisticEffects = {},
	disabledVehicleScripts = {},
	originalCharacterParent = nil,
	vehicleLastPos = nil,
	boostBV = nil,
	originalGlobalShadows = nil,
	originalFogStart = nil,
	originalFogEnd = nil,
	originalAtmospheres = nil,
	originalMaxZoom = nil,
	originalMinZoom = nil,
	originalVolumes = {},
	
	Active = nil, -- MouseLock loop
	crosshairGui = nil,
	Noclipping = nil,
	flyKeyDown = nil,
	flyKeyUp = nil,
	jumpSpamJumpConn = nil,
	clickTpConn = nil,
	floatPart = nil,
	floatHeight = 0,
	floatConnection = nil,
	spectateTarget = nil,
	selectedTeleportPlayer = nil,
	cameraControlGui = nil,
	crosshairPart = nil, -- Cached crosshair DOT part
	flyBG = nil,
	flyBV = nil,
	realMousePos = S.UserInputService:GetMouseLocation(),
	
	-- Connection slots for destruction
	characterAddedConn = nil,
	playerAddedConn = nil,
	characterRemovingConn = nil,
	npcDescendantConn = nil,
	npcDescendantRemovingConn = nil,
	activeESP = {}, -- { [Billboard]: TargetPart }
	mainInputConn = nil,
	crosshairLoopConn = nil,
	teleportMenuConn = nil,
	lastRightClickTime = 0,
	originalSkybox = {},
	customSky = nil,
	invisSeat = nil,
	ropeCache = {},
	mainInputEndedConn = nil,
	clockTimeLockConnection = nil,
	airWalkPart = nil,
	
	trafficProps = {},
	originalNamecall = nil,
	originalIndex = nil,
	originalNewIndex = nil,
	ncStorage = {},
	_timeLockPropConn = nil,
}

-- Forward declaration for cleanup function
local destroyPanel 
local updateClipState -- Forward declaration for noclip management
local ensureNoclipConnection -- Forward declaration for noclip management
local toggleSpectate -- Forward declaration for spectate logic
local updateStartInfo -- Forward declaration for Waypoint info logic

local function cleanup()
	if destroyPanel then
		pcall(function() destroyPanel() end)
	end
	-- Mark as destroyed so loops stop
	States.isDestroyed = true
end

_G.FVKHUB_Cleanup = cleanup
if getgenv then getgenv().FVKHUB_Cleanup = cleanup end

local _VirtualInputManager = nil
local function getVIM()
	if not _VirtualInputManager then
		pcall(function() _VirtualInputManager = S.ContextActionService:GetService("VirtualInputManager") end)
		if not _VirtualInputManager then
			pcall(function() _VirtualInputManager = game:GetService("VirtualInputManager") end)
		end
	end
	return _VirtualInputManager
end

local function getCharacter()
	return localPlayer.Character or localPlayer.CharacterAdded:Wait()
end

if not localPlayer then
	warn("panel-admin.client: LocalPlayer not found")
	return
end

---------------------------------------------------------------------
-- UTILITIES & HELPERS
---------------------------------------------------------------------


function U.stopAutoTeleport()
	States.isAutoTeleporting = false
	States.autoTeleportIndex = 1
	U.notify("Waypoints", "Auto Teleport Stopped", 2)
	if UI.buttons and UI.buttons.autoTp then U.setButtonState(UI.buttons.autoTp, false) end
	if UI.buttons and UI.buttons.pauseAutoTp then 
		U.setButtonState(UI.buttons.pauseAutoTp, false)
		UI.buttons.pauseAutoTp.Text = "|| Pause"
	end
end

function U.requestRespawn()
	pcall(function()
		local rs = S.ReplicatedStorage
		local remotes = {"Respawn", "Reset", "LoadCharacter", "RequestRespawn", "PlayerReady"}
		for _, rName in ipairs(remotes) do
			local r = rs:FindFirstChild(rName, true)
			if r and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) then
				if r:IsA("RemoteEvent") then r:FireServer() else r:InvokeServer() end
			end
		end
		
		local char = localPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then hum.Health = 0 end
	end)
end

function U.loadWaypointsFromSpecificFile(fileName)
	if not fileName:match("%.json$") then fileName = fileName .. ".json" end
	local fullPath = "FVKHUB_Data/Waypoints/" .. fileName
	
	if not E.readfile or not E.isfile(fullPath) then
		U.notify("Error", "File not found!", 2)
		return
	end
	
	local success, result = pcall(function()
		local json = E.readfile(fullPath)
		local data = S.HttpService:JSONDecode(json)
		local newWps = {}
		for _, wp in ipairs(data) do
			table.insert(newWps, {name = wp.name, cf = CFrame.new(unpack(wp.cf)), delay = wp.delay})
		end
		
		States.waypoints = newWps
		if U.refreshWaypointListUI then U.refreshWaypointListUI() end
		if U.refreshWaypointFileList then U.refreshWaypointFileList() end
		U.notify("Success", "Loaded " .. #newWps .. " waypoints from " .. fileName, 3)
	end)
	
	if not success then
		U.notify("Error", "Failed to load waypoints: " .. tostring(result), 4)
	end
end

function U.getCharacter()
	local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	return character
end

function U.getHumanoidAndRoot()
	local character = U.getCharacter()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not root then
		return nil, nil
	end

	return humanoid, root
end

-- Improved utility to find the root part of any vehicle (Cars, Boats, Planes, etc.)
function U.getSeatedVehicleRoot()
	local char = localPlayer.Character
	if not char then return nil end
	
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end

	-- 1. Check standard seating (VehicleSeat or regular Seat)
	local seat = humanoid.SeatPart
	if seat and (seat:IsA("VehicleSeat") or seat:IsA("Seat")) then
		-- Try to find the actual vehicle model root for better stability
		local model = seat:FindFirstAncestor(localPlayer.Name .. "'s Car") or
		              (seat:FindFirstAncestor("Body") and seat:FindFirstAncestor("Body").Parent) or
		              (seat:FindFirstAncestor("Misc") and seat:FindFirstAncestor("Misc").Parent) or
		              seat:FindFirstAncestorWhichIsA("Model")
		
		if model and model:IsA("Model") then
			local name = model.Name:lower()
			local isBoat = (name:find("boat") or name:find("ship") or name:find("yacht") or name:find("jetski") or name:find("sea") or name:find("water"))
			local isPlane = (name:find("plane") or name:find("aircraft") or name:find("air") or name:find("heli") or name:find("flight") or name:find("jet"))
			local isBike = (name:find("bike") or name:find("motor") or name:find("cycle") or name:find("dirt") or name:find("scooter"))
			States._isNonCarVehicle = (isBoat or isPlane or isBike)
			
			return model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart") or seat.AssemblyRootPart or seat
		end
		States._isNonCarVehicle = false
		return seat.AssemblyRootPart or seat
	end
	
	-- 2. Fallback for custom vehicles that weld the player without a SeatPart
	if humanoid.Sit then
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then
			for _, v in ipairs(root:GetJoints()) do
				if v:IsA("Weld") or v:IsA("ManualWeld") or v:IsA("Snap") then
					local part1 = v.Part0 == root and v.Part1 or v.Part0
					if part1 and part1:IsA("BasePart") and not part1:IsDescendantOf(char) then
						-- Use model detection for these custom welds too
						local model = part1:FindFirstAncestorWhichIsA("Model")
						if model then
							return model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart") or part1.AssemblyRootPart or part1
						end
						return part1.AssemblyRootPart or part1
					end
				end
			end
		end
	end
	
	return nil
end

function U.setButtonState(button, enabled)
	if not button then return end
	local indicator = button:FindFirstChild("Indicator")
	local action = button:GetAttribute("Action")
	local featureText = button:GetAttribute("FeatureText") or button.Text:gsub(" %|.*", ""):gsub(" %b[]", "")

	-- Reconstruct Text with current keybind if available
	local keyName = ""
	if action and Config.keybinds[action] and Config.keybinds[action] ~= Enum.KeyCode.Unknown then
		keyName = Config.keybinds[action].Name .. " | "
	elseif button:GetAttribute("StaticKey") then
		keyName = button:GetAttribute("StaticKey") .. " | "
	end

	local stateText = enabled and "[ON]" or "[OFF]"
	button.Text = string.format("%s%s %s", keyName, featureText, stateText)

	if enabled then
		button.BackgroundColor3 = Color3.fromRGB(45, 55, 110)
		button.BackgroundTransparency = 0.1
	else
		button.BackgroundColor3 = Color3.fromRGB(30, 34, 52)
		button.BackgroundTransparency = 0.2
	end

	if indicator then
		indicator.BackgroundColor3 = enabled and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(60, 65, 90)
		local stroke = indicator:FindFirstChild("UIStroke")
		if stroke then
			stroke.Color = enabled and Color3.fromRGB(150, 255, 180) or Color3.fromRGB(100, 110, 150)
		end
	end
end

function U.refreshDynamicButtons()
	for _, btn in pairs(UI.buttons) do
		if btn:GetAttribute("Action") then
			local state = btn.Text:find("%[ON%]") ~= nil
			U.setButtonState(btn, state)
		end
	end
end

function U.setupSmoothScroll(scroll)
	if not scroll or not scroll:IsA("ScrollingFrame") then return end
	
	-- Modern smooth scrollfeel using EasingStyle.Quint for Snappy, fluid response
	local function updateScroll(deltaY)
		local currentY = scroll.CanvasPosition.Y
		local maxH = math.max(0, scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteWindowSize.Y)
		local targetY = math.clamp(currentY + deltaY, 0, maxH)
		
		S.TweenService:Create(scroll, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			CanvasPosition = Vector2.new(0, targetY)
		}):Play()
	end
	
	-- MouseWheel Support
	scroll.MouseWheelForward:Connect(function() updateScroll(-(Config.scrollAmount or 100)) end)
	scroll.MouseWheelBackward:Connect(function() updateScroll(Config.scrollAmount or 100) end)
end


function U.notifyToggle(featureName, enabled)
	local status = enabled and "ON" or "OFF"
	local nType = enabled and "Success" or "Error"
	U.notify(featureName .. " (" .. status .. ")", "Feature status has been updated", 2.5, nType)
end

function U.notify(title, text, duration, nType)
	title = title or "Notification"
	text = text or ""
	duration = duration or 3
	nType = nType or "Info" -- Info, Success, Warning, Error

	-- Theme Colors
	local colors = {
		Info = States.panelThemeColor or Color3.fromRGB(60, 100, 255),
		Success = Color3.fromRGB(0, 255, 127),
		Warning = Color3.fromRGB(255, 200, 60),
		Error = Color3.fromRGB(255, 60, 60)
	}
	
	local icons = {
		Info = "ⓘ",
		Success = "✓",
		Warning = "⚠",
		Error = "✕"
	}

	local accentColor = colors[nType] or colors.Info
	local icon = icons[nType] or icons.Info

	-- Fallback to system notification if UI is not yet ready or destroyed
	if not UI or not UI.notificationContainer or States.isDestroyed then
		pcall(function()
			S.StarterGui:SetCore("SendNotification", {
				Title = title,
				Text = text,
				Duration = duration,
			})
		end)
		return
	end

	local notif = Instance.new("Frame")
	notif.Name = "Notification"
	notif.Size = UDim2.new(1, 0, 0, 0)
	notif.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
	notif.BackgroundTransparency = 0.15
	notif.BorderSizePixel = 0
	notif.ClipsDescendants = true
	notif.Parent = UI.notificationContainer

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 10)
	uiCorner.Parent = notif

	local uiStroke = Instance.new("UIStroke")
	uiStroke.Thickness = 1.2
	uiStroke.Color = accentColor
	uiStroke.Transparency = 0.5
	uiStroke.Parent = notif

	local sideAccent = Instance.new("Frame")
	sideAccent.Size = UDim2.new(0, 4, 1, 0)
	sideAccent.BackgroundColor3 = accentColor
	sideAccent.BorderSizePixel = 0
	sideAccent.Parent = notif
	
	local saCorner = Instance.new("UICorner"); saCorner.CornerRadius = UDim.new(0, 4); saCorner.Parent = sideAccent

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(0, 24, 0, 24)
	iconLabel.Position = UDim2.new(0, 12, 0, 8)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = icon
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextColor3 = accentColor
	iconLabel.TextSize = 16
	iconLabel.Parent = notif

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -50, 0, 20)
	titleLabel.Position = UDim2.new(0, 42, 0, 10)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = tostring(title):upper()
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
	titleLabel.TextSize = 13
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = notif

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, -50, 1, -40)
	textLabel.Position = UDim2.new(0, 42, 0, 28)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = tostring(text)
	textLabel.Font = Enum.Font.Gotham
	textLabel.TextColor3 = Color3.fromRGB(160, 170, 200)
	textLabel.TextSize = 11
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextYAlignment = Enum.TextYAlignment.Top
	textLabel.TextWrapped = true
	textLabel.Parent = notif

	local progressBarBg = Instance.new("Frame")
	progressBarBg.Size = UDim2.new(1, -20, 0, 2)
	progressBarBg.Position = UDim2.new(0, 10, 1, -4)
	progressBarBg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	progressBarBg.BackgroundTransparency = 0.95
	progressBarBg.BorderSizePixel = 0
	progressBarBg.Parent = notif

	local progressBar = Instance.new("Frame")
	progressBar.Size = UDim2.new(1, 0, 1, 0)
	progressBar.BackgroundColor3 = accentColor
	progressBar.BorderSizePixel = 0
	progressBar.Parent = progressBarBg

	notif.Position = UDim2.new(1.3, 0, 0, 0)
	S.TweenService:Create(notif, TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, 0, 0, 64),
		Position = UDim2.new(0, 0, 0, 0)
	}):Play()

	S.TweenService:Create(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		Size = UDim2.new(0, 0, 1, 0)
	}):Play()

	task.delay(duration, function()
		if notif and notif.Parent then
			local closeTween = S.TweenService:Create(notif, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
				Position = UDim2.new(1.3, 0, 0, 0),
				BackgroundTransparency = 1
			})
			closeTween:Play()
			closeTween.Completed:Connect(function()
				notif:Destroy()
			end)
		end
	end)
end

function U.parseNumber(text, fallback, allowNegative)
	if typeof(text) ~= "string" then text = tostring(text) end
	text = text:gsub(",", ".")
	local n = tonumber(text)
	if not n then return fallback end
	if not allowNegative and n <= 0 then return fallback end
	return n
end

---------------------------------------------------------------------
-- GLOBAL TABLES (To save local registers)
---------------------------------------------------------------------

States = G_States

local defaultStates = {
	isFlying = false,
	isNoclip = false,
	isNoclipFly = false,
	isFullbright = false,
	isEspUniversal = false,
	isEspNpc = false,
	isEspItems = false,
	isCameraControl = false,
	isNoFog = false,
	isAutoInteractProximity = false,
	isNoShadow = false,
	isVisibleAllParts = false,
	isNoTouch = false,
	isMouseLocked = false,
	isInvisible = false,
	isWalkOverride = false,
	isWalkBoost = false,
	isJumpBoost = false,
	isJumpSpam = false,
	isSpectating = false,
	isFreecamEnabled = false,
	isClickTeleportEnabled = false,
	isRemoveNCActive = false,
	isAntiMovementDelay = false,
	isFloating = false,
	isAntiFling = false,
	
	
	isSkyboxActive = false,
	isMinimized = false,
	isDestroyed = false,
	isFlashSpeedEnabled = false,
	isCameraSideView = false, -- Toggled for offset preference
	isAutoWalk = false,
	isBackwardsWalk = false,
	isSpinning = false,
	isSpiderClimbing = false,
	isAirWalking = false,
	
	isSmoothZoom = true,
	isCameraNoclip = false,
	
	-- Physic features
	isNetworkClaim = false,
	isPartFling = false,
	controlPartMode = "Hover", -- Hover grab by default
	targetControlPart = nil,

	-- New features
	isXRay = false,
	isLocalTimeLocked = false,
	localTimeValue = S.Lighting.ClockTime,
	isRGBTheme = false,
	panelThemeColor = Color3.fromRGB(60, 100, 255),
	isTeleportFling = false,
	teleportFlingTarget = nil,
	isRecordingPath = false,
	isRecordingDebounce = false,
	isRecordingPathPaused = false,
	isPlayingPath = false,
	isPathPlaybackPaused = false,
	pathPlaybackDirection = 1, -- 1 for forward, -1 for backward
	isPathVisualized = false,
	isPathLooping = false,
	playbackProgress = 1,
	recordedPath = {}, -- Stores CFrame points
	lastRecordTick = nil, -- Timer for delta recording
	
	-- Waypoint features
	waypoints = {},
	autoTeleportIndex = 1,
	isAutoTeleporting = false,
	isAutoTeleportPaused = false,
	autoTeleportDelay = 1,
	isWaypointLooping = false,
	isPauseOnJoin = false, -- Safety feature for auto tp

	isAntiCheatBypass = true, -- Default ON for protection
	isAntiAfk = true,
	isVehicleBoost = false,
	isVehicleStabilizer = true,
	isVehicleFly = false,
	isVehicleSprings = false,
	isUnlockJump = false,
	isAutoTpToSave = false,
	savedPosition = nil,
	
	loopTpTarget = nil, -- Stores the player currently being looped
	loopTpOffset = Vector3.new(0, 5, 0), -- Default offset (above head)
	loopWaypointTarget = nil, -- Stores the waypoint (table) currently being looped
	
	-- Engine internals
	isBlockGameInput = false,
	isFastAntiTraffic = false,
	isAutoRespawn = false,
	isAutoRespawnOnFinish = false,
	isRespawnToTpPos = false,
	tpPosToRespawn = nil,
	isAutoTransmission = false,
	
	-- Engine internals
	Clip = true,
	isAntiJumpscare = false,
	isInfiniteOxygenStamina = false,
	FLYING = false,
	QEfly = true,
}

for k, v in pairs(defaultStates) do
	if States[k] == nil then States[k] = v end
end

function U.saveSettings()
	if not E.writefile then return end
	local data = {
		isAntiCheatBypass = States.isAntiCheatBypass,
		isAntiJumpscare = States.isAntiJumpscare,
		isInfiniteOxygenStamina = States.isInfiniteOxygenStamina,
		isAutoWalk = States.isAutoWalk,
		isPathLooping = States.isPathLooping,
		isPathVisualized = States.isPathVisualized,
		isWaypointLooping = States.isWaypointLooping,
		autoTeleportDelay = States.autoTeleportDelay,
		isAutoTransmission = States.isAutoTransmission,
		isPartFling = States.isPartFling,
		partFlingRadius = Config.partFlingRadius,
		partFlingStrength = Config.partFlingStrength,
		partFlingMode = Config.partFlingMode,
		partPullGap = Config.partPullGap,
		isPauseOnJoin = States.isPauseOnJoin,
		walkSpeed = Config.walkSpeed,

		flySpeed = Config.flySpeed,
		vehicleFlySpeed = Config.vehicleFlySpeed,
		walkBoostMultiplier = Config.walkBoostMultiplier,
		jumpBoostMultiplier = Config.jumpBoostMultiplier,
		brightnessValue = Config.brightnessValue,
		exposureCompensationValue = Config.exposureCompensationValue,
		vehicleBoostAcceleration = Config.vehicleBoostAcceleration,
		vehicleBrakeForce = Config.vehicleBrakeForce,
		scrollAmount = Config.scrollAmount,
		zoomAmount = Config.zoomAmount,
		keybinds = {}
	}
	
	-- Convert KeyCodes to names for JSON storage
	if Config.keybinds then
		for action, keyCode in pairs(Config.keybinds) do
			if typeof(keyCode) == "EnumItem" then
				data.keybinds[action] = keyCode.Name
			end
		end
	end
	pcall(function()
		if not E.isfolder("FVKHUB_Data") then E.makefolder("FVKHUB_Data") end
		if not E.isfolder("FVKHUB_Data/Scripts") then E.makefolder("FVKHUB_Data/Scripts") end
		E.writefile("FVKHUB_Data/settings.json", S.HttpService:JSONEncode(data))
	end)
end

function U.loadSettings()
	if not E.readfile then return end
	pcall(function()
		local hasIsFile = (E.isfile ~= nil)
		if not hasIsFile or E.isfile("FVKHUB_Data/settings.json") then
			local content = E.readfile("FVKHUB_Data/settings.json")
			local data = S.HttpService:JSONDecode(content)
			if data.isAntiJumpscare ~= nil then States.isAntiJumpscare = data.isAntiJumpscare end
			if data.isInfiniteOxygenStamina ~= nil then States.isInfiniteOxygenStamina = data.isInfiniteOxygenStamina end
			if data.isAntiCheatBypass ~= nil then States.isAntiCheatBypass = data.isAntiCheatBypass end
			if data.isAutoWalk ~= nil then States.isAutoWalk = data.isAutoWalk end
			if data.isPathLooping ~= nil then States.isPathLooping = data.isPathLooping end
			if data.isPathVisualized ~= nil then States.isPathVisualized = data.isPathVisualized end
			if data.isWaypointLooping ~= nil then States.isWaypointLooping = data.isWaypointLooping end
			if data.autoTeleportDelay ~= nil then States.autoTeleportDelay = data.autoTeleportDelay end
			if data.isAntiAfk ~= nil then States.isAntiAfk = data.isAntiAfk end
			if data.isBlockGameInput ~= nil then States.isBlockGameInput = data.isBlockGameInput end
			if data.isAutoRespawn ~= nil then States.isAutoRespawn = data.isAutoRespawn end
			if data.isAutoRespawnOnFinish ~= nil then States.isAutoRespawnOnFinish = data.isAutoRespawnOnFinish end
			if data.isAutoTransmission ~= nil then States.isAutoTransmission = data.isAutoTransmission end
			if data.isPartFling ~= nil then States.isPartFling = data.isPartFling end
			if data.partFlingRadius ~= nil then Config.partFlingRadius = data.partFlingRadius end
			if data.partFlingStrength ~= nil then Config.partFlingStrength = data.partFlingStrength end
			if data.partFlingMode ~= nil then Config.partFlingMode = data.partFlingMode end
			if data.partPullGap ~= nil then Config.partPullGap = data.partPullGap end
			if data.isPauseOnJoin ~= nil then States.isPauseOnJoin = data.isPauseOnJoin end
			
			if data.walkSpeed ~= nil then Config.walkSpeed = data.walkSpeed end

			if data.flySpeed ~= nil then Config.flySpeed = data.flySpeed end
			if data.vehicleFlySpeed ~= nil then Config.vehicleFlySpeed = data.vehicleFlySpeed end
			if data.walkBoostMultiplier ~= nil then Config.walkBoostMultiplier = data.walkBoostMultiplier end
			if data.jumpBoostMultiplier ~= nil then Config.jumpBoostMultiplier = data.jumpBoostMultiplier end
			if data.brightnessValue ~= nil then Config.brightnessValue = data.brightnessValue end
			if data.exposureCompensationValue ~= nil then Config.exposureCompensationValue = data.exposureCompensationValue end
			if data.vehicleBoostAcceleration ~= nil then Config.vehicleBoostAcceleration = data.vehicleBoostAcceleration end
			if data.vehicleBrakeForce ~= nil then Config.vehicleBrakeForce = data.vehicleBrakeForce end
			if data.scrollAmount ~= nil then Config.scrollAmount = data.scrollAmount end
			if data.zoomAmount ~= nil then Config.zoomAmount = data.zoomAmount end
			
			-- Restore Keybinds
			if data.keybinds then
				for action, keyName in pairs(data.keybinds) do
					-- Handle KeyCode and UserInputType separately to avoid pcall failure on first check
					local success, result = pcall(function() return Enum.KeyCode[keyName] end)
					if not (success and result) then
						success, result = pcall(function() return Enum.UserInputType[keyName] end)
					end
					
					if success and result then
						Config.keybinds[action] = result
					end
				end
			end
		end
	end)
end

function U.refreshInputSinks()
	-- Clean up previous sinks with more robust name check
	if Config.keybinds then
		for action, _ in pairs(Config.keybinds) do
			pcall(function() S.ContextActionService:UnbindAction("AdminSink_" .. action) end)
		end
	end
	
	if not States.isBlockGameInput then return end
	
	-- Priority 3000 to override most games
	local movementKeys = {
		[Enum.KeyCode.W] = true, [Enum.KeyCode.A] = true, [Enum.KeyCode.S] = true, [Enum.KeyCode.D] = true,
		[Enum.KeyCode.Up] = true, [Enum.KeyCode.Down] = true, [Enum.KeyCode.Left] = true, [Enum.KeyCode.Right] = true,
		[Enum.KeyCode.Space] = true, [Enum.KeyCode.LeftShift] = true, [Enum.KeyCode.RightShift] = true,
		[Enum.KeyCode.Slash] = true, [Enum.KeyCode.Escape] = true
	}
	
	for action, keyCode in pairs(Config.keybinds) do
		if keyCode ~= Enum.KeyCode.Unknown and not movementKeys[keyCode] then
			pcall(function()
				S.ContextActionService:BindActionAtPriority(
					"AdminSink_" .. action,
					function() return Enum.ContextActionResult.Sink end,
					false,
					3000,
					keyCode
				)
			end)
		end
	end
end

-- Detection logic moved to top

-- Try to get more accurate initial speed if char not loaded
if not initialHumanoid then
	pcall(function()
		local dummy = Instance.new("Humanoid")
		actualGameWalkSpeed = dummy.WalkSpeed
		dummy:Destroy()
	end)
end

-- Default fallback keybinds (If settings.json is missing)
local DefaultKeybinds = {
	ToggleGui = Enum.KeyCode.RightShift,
	Minimize = Enum.KeyCode.F1,
	Destroy = Enum.KeyCode.Delete,
	Rejoin = Enum.KeyCode.F7,
	ServerHop = Enum.KeyCode.F12,

	Fly = Enum.KeyCode.F,
	Noclip = Enum.KeyCode.C,
	FlashSpeed = Enum.KeyCode.LeftControl,
	WalkBoost = Enum.KeyCode.R,
	JumpBoost = Enum.KeyCode.J,
	JumpSpam = Enum.KeyCode.H,
	AirWalk = Enum.KeyCode.Backquote,
	AirWalkBack = Enum.KeyCode.BackSlash,
	SpiderClimb = Enum.KeyCode.I,
	Spin = Enum.KeyCode.O,
	Flip = Enum.KeyCode.T,
	UnlockJump = Enum.KeyCode.L,
	AutoWalk = Enum.KeyCode.Comma,
	Invisible = Enum.KeyCode.X,

	Fullbright = Enum.KeyCode.B,
	NoFog = Enum.KeyCode.G,
	NoShadow = Enum.KeyCode.K,
	VisibleAllParts = Enum.KeyCode.Y,
	XRay = Enum.KeyCode.F6,
	EspAll = Enum.KeyCode.U,
	EspEnemy = Enum.KeyCode.Semicolon,
	EspNpc = Enum.KeyCode.N,
	EspItems = Enum.KeyCode.P,
	Spectate = Enum.KeyCode.F10,
	Freecam = Enum.KeyCode.V,

	Floating = Enum.KeyCode.F3,
	AntiFling = Enum.KeyCode.F4,

	AntiDelay = Enum.KeyCode.F2,
	AutoInteract = Enum.KeyCode.Minus,
	ClickTp = Enum.KeyCode.Z,
	RemoveNC = Enum.KeyCode.Clear,
	Recovery = Enum.KeyCode.Slash,
	VehicleFly = Enum.KeyCode.E,
	VehicleBoost = Enum.KeyCode.RightControl, -- Toggle
	VehicleBoostKey = Enum.KeyCode.W,        -- Active
	VehicleQuickBrake = Enum.KeyCode.S,      -- Active
	VehicleStop = Enum.KeyCode.P,
	LockTime = Enum.KeyCode.Period,
	RadiusFling = Enum.KeyCode.KeypadSix,
	WalkOverride = Enum.KeyCode.M,
	RecordPath = Enum.KeyCode.KeypadOne,
	PlayPath = Enum.KeyCode.KeypadTwo,
	StopPath = Enum.KeyCode.KeypadThree,
	AddWaypoint = Enum.KeyCode.Insert,
	ClearWaypoints = Enum.KeyCode.KeypadNine,
	NoTouch = Enum.KeyCode.K,
	GetBTools = Enum.KeyCode.Home,
	LoadDex = Enum.KeyCode.KeypadSeven,
	LoadSpy = Enum.KeyCode.KeypadEight,
	SkipCutscene = Enum.KeyCode.RightAlt,
	SkipLoading = Enum.KeyCode.PageUp,
	AutoTeleport = Enum.KeyCode.Backspace,
	PauseAutoTeleport = Enum.KeyCode.Pause,
	AntiAfk = Enum.KeyCode.End,
	NetworkClaim = Enum.KeyCode.Unknown,
	PartFling = Enum.KeyCode.Unknown,
	AntiCheatBypass = Enum.KeyCode.Unknown,
	FastAntiTraffic = Enum.KeyCode.Unknown,
}

-- Initialize keybinds with defaults
for k, v in pairs(DefaultKeybinds) do
	Config.keybinds[k] = v
end

-- Load persistent settings
U.loadSettings()


-- [CRITICAL] Separation: Ensure movement keys are not accidentally trapped
-- We let users bind what they want, but default safe keys are provided.
U.refreshInputSinks()

---------------------------------------------------------------------
-- ANTI-CHEAT BYPASS & ENVIRONMENT PROTECTION
---------------------------------------------------------------------

local function applyAntiCheatBypass()
	if not States.isAntiCheatBypass then return end
	
	pcall(function()
		local gmt = (E.getrawmetatable and E.getrawmetatable(game))
		if not gmt then return end
		
		-- Hooking __index to spoof properties
		local oldIndex = gmt.__index
		E.setreadonly(gmt, false)
		
		gmt.__index = E.newcclosure(function(self, key)
			if not E.checkcaller() then
				if States.isAntiCheatBypass then
					if typeof(self) == "Instance" then
						if self == workspace and key == "Gravity" then
							return 196.2
						end
						
						-- Faster check for Humanoid properties
						local isHum = false
						pcall(function() isHum = self:IsA("Humanoid") end)
						if isHum then
							if key == "WalkSpeed" then return 16 end
							if key == "JumpPower" then return 50 end
							if key == "JumpHeight" then return 7.2 end
							if key == "AutoRotate" then return true end
							if key == "CameraOffset" then return Vector3.new(0, 0, 0) end
						end
						
						-- Player property spoofing (Shiftlock detection)
						local isPlayer = false
						pcall(function() isPlayer = self:IsA("Player") end)
						if isPlayer and self == localPlayer then
							if key == "DevEnableMouseLock" then return false end
							if key == "DevComputerCameraMode" then return 0 end
							if key == "DevComputerMovementMode" then return 0 end
						end
					end
				end

				-- Device & Input Spoofing
				if typeof(self) == "Instance" then
					if self == S.UserInputService then
						if States.isAntiCheatBypass then
							if key == "MouseBehavior" then return Enum.MouseBehavior.Default end
							if key == "MouseIconEnabled" then return true end
						end
						
					end
				end
			end
			return oldIndex(self, key)
		end)
		
		-- Hooking __newindex to mask modifications from game scripts
		local oldNewIndex = gmt.__newindex
		gmt.__newindex = E.newcclosure(function(self, key, value)
			if not E.checkcaller() and States.isAntiCheatBypass then
				-- We can add logic here to "pretend" we set properties
				-- For now, just let the game's own sets through
			end
			return oldNewIndex(self, key, value)
		end)
		
		-- Protection against disallowed service detection (VirtualInputManager, etc)
		local oldNamecall = gmt.__namecall
		gmt.__namecall = E.newcclosure(function(self, ...)
			local method = E.getnamecallmethod()
			local args = {...}
			
			if not E.checkcaller() then
				if States.isAntiCheatBypass then
					if method == "GetService" or method == "FindService" then
						local serviceName = args[1]
						if serviceName == "VirtualInputManager" or serviceName == "LogService" then
							-- Return nil or a dummy object instead of letting the game know we exist
							return nil
						end
					end
					
					if method == "Kick" then
						-- Log and block the kick
						warn("Anti-Cheat tried to kick you. Blocked.")
						return nil
					end
				end

			end
			return oldNamecall(self, ...)
		end)
		
		E.setreadonly(gmt, true)
	end)
end

-- Run bypass at execution
-- Bypass runs at bootstrap now
-- task.spawn(applyAntiCheatBypass) 


-- UI state update (Keeping existing table reference for functions)
UI.inputs = {}
UI.sidebarButtons = {}
UI.keybindInputs = {}
UI.pages = {}
UI.buttons = {}
UI.PingLabel = nil
UI.BtnContainer = nil
UI.Header = nil
UI.ContentContainer = nil
UI.TitleLabel = nil
UI.DestroyButton = nil
UI.TeleportPopup = nil
UI.TeleportSearchBox = nil
UI.TeleportPopupList = nil
UI.TeleportEmptyLabel = nil
UI.TeleportSearchStroke = nil
UI.PlayersSearchBox = nil
UI.PlayersSearchStroke = nil
UI.PlayersListContainer = nil
UI.WaypointsEmptyLabel = nil
UI.PathNameInput = nil
UI.PathFileList = nil
UI.PathVisualFolder = nil
UI.ScriptsSearchBox = nil
UI.ScriptsListContainer = nil
UI.HotbarSlots = {}
UI.HotbarConnections = {}

-- Dash Animations
local DASH_ANIMATION_IDS = {
	"rbxassetid://3337994105", -- Roblox animation
	"rbxassetid://616160105", -- Another
	"rbxassetid://616163451", -- Another
}

---------------------------------------------------------------------
-- UI CREATION
---------------------------------------------------------------------

local playerGui = localPlayer:WaitForChild("PlayerGui")
local randomName = function()
	local s = ""
	for i = 1, 15 do s = s .. string.char(math.random(65, 90)) end
	return s
end

-- Use E.gethui if available for stealth
local parentTarget = playerGui
if E.gethui then
	pcall(function() parentTarget = E.gethui() end)
end

do
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = randomName()
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = true
	screenGui.IgnoreGuiInset = true
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

	screenGui.Parent = parentTarget
	UI.screenGui = screenGui
	if getgenv then getgenv().FVK_Gui = screenGui end

	local notifContainer = Instance.new("Frame")
	notifContainer.Name = "Notifications"
	notifContainer.Size = UDim2.new(0, 220, 1, -20)
	notifContainer.Position = UDim2.new(1, -230, 0, 10)
	notifContainer.BackgroundTransparency = 1
	notifContainer.ZIndex = 1000
	notifContainer.Parent = screenGui
	UI.notificationContainer = notifContainer

	local notifLayout = Instance.new("UIListLayout")
	notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	notifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	notifLayout.Padding = UDim.new(0, 8)
	notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
	notifLayout.Parent = notifContainer
end



local invisSound = Instance.new("Sound")
invisSound.SoundId = "rbxassetid://942127495"
invisSound.Volume = 1
invisSound.Parent = parentTarget

-- One-time cleanup for removed features (Forcefield & Float)
pcall(function()
	local char = localPlayer.Character
	if char then
		for _, ff in ipairs(char:GetChildren()) do
			if ff:IsA("ForceField") then
				ff:Destroy()
			end
		end
	end
	if workspace:FindFirstChild("AdminFloatPlatform") then
		workspace.AdminFloatPlatform:Destroy()
	end
end)

local mainFrame
do
	-- Glassmorphism-style main panel
	mainFrame = Instance.new("Frame")
	mainFrame.Name = randomName()
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.Size = UDim2.new(0, 600, 0, 550)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
	mainFrame.BackgroundTransparency = 0.12
	mainFrame.BorderSizePixel = 0
	mainFrame.ClipsDescendants = false -- Allow popups like player menu to spill out without delay
	mainFrame.Parent = UI.screenGui
	UI.mainFrame = mainFrame

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 16)
	uiCorner.Parent = mainFrame

	local uiStroke = Instance.new("UIStroke")
	uiStroke.Thickness = 1.8
	uiStroke.Color = Color3.fromRGB(100, 110, 160)
	uiStroke.Transparency = 0.3
	uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	uiStroke.Parent = mainFrame
end



local sidebar, btnContainer
do
	-- Sidebar
	sidebar = Instance.new("Frame")
	sidebar.Name = randomName()
	sidebar.Size = UDim2.new(0, 150, 1, 0)
	sidebar.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
	sidebar.BackgroundTransparency = 0.2
	sidebar.BorderSizePixel = 0
	sidebar.Parent = mainFrame
	UI.sidebar = sidebar

	local sidebarCorner = Instance.new("UICorner")
	sidebarCorner.CornerRadius = UDim.new(0, 16)
	sidebarCorner.Parent = sidebar

	local sidePadding = Instance.new("UIPadding")
	sidePadding.PaddingTop = UDim.new(0, 15)
	sidePadding.PaddingBottom = UDim.new(0, 15)
	sidePadding.PaddingLeft = UDim.new(0, 10)
	sidePadding.PaddingRight = UDim.new(0, 10)
	sidePadding.Parent = sidebar

	btnContainer = Instance.new("ScrollingFrame")
	btnContainer.Name = "Buttons"
	btnContainer.Size = UDim2.new(1, 0, 1, -110)
	btnContainer.Position = UDim2.new(0, 0, 0, 65)
	btnContainer.BackgroundTransparency = 1
	btnContainer.BorderSizePixel = 0
	btnContainer.ScrollBarThickness = 0 -- Keep it clean
	btnContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	btnContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
	btnContainer.Parent = sidebar
	UI.btnContainer = btnContainer
	U.setupSmoothScroll(btnContainer)

	local appTitle = Instance.new("TextLabel")
	appTitle.Size = UDim2.new(1, 0, 0, 30)
	appTitle.BackgroundTransparency = 1
	appTitle.Text = "FVKHUB"
	appTitle.Font = Enum.Font.GothamBold
	appTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	appTitle.TextSize = 14
	appTitle.Parent = sidebar

	local appSubTitle = Instance.new("TextLabel")
	appSubTitle.Size = UDim2.new(1, 0, 0, 12)
	appSubTitle.BackgroundTransparency = 1
	appSubTitle.Text = "PREMIUM EDITION"
	appSubTitle.Font = Enum.Font.GothamMedium
	appSubTitle.TextColor3 = Color3.fromRGB(100, 110, 160)
	appSubTitle.TextSize = 8
	appSubTitle.Position = UDim2.new(0, 0, 0, 25)
	appSubTitle.Parent = sidebar

	local sideDiv = Instance.new("Frame")
	sideDiv.Size = UDim2.new(1, 0, 0, 1)
	sideDiv.Position = UDim2.new(0, 0, 0, 45)
	sideDiv.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sideDiv.BackgroundTransparency = 0.92
	sideDiv.Parent = sidebar

	local sideLayout = Instance.new("UIListLayout")
	sideLayout.Padding = UDim.new(0, 4)
	sideLayout.Parent = btnContainer
end



local sidebarBottom = Instance.new("Frame")
sidebarBottom.Name = "Branding"
sidebarBottom.Size = UDim2.new(1, 0, 0, 30)
sidebarBottom.Position = UDim2.new(0, 0, 1, 0)
sidebarBottom.AnchorPoint = Vector2.new(0, 1)
sidebarBottom.BackgroundTransparency = 1
sidebarBottom.Parent = sidebar

local pingLabel = Instance.new("TextLabel")
pingLabel.Name = "PingLabel"
pingLabel.Size = UDim2.new(1, 0, 1, 0)
pingLabel.BackgroundTransparency = 1
pingLabel.Text = "PING: -- ms"
pingLabel.Font = Enum.Font.GothamMedium
pingLabel.TextColor3 = Color3.fromRGB(0, 255, 255)
pingLabel.TextSize = 11
pingLabel.TextXAlignment = Enum.TextXAlignment.Center
pingLabel.ZIndex = 11
pingLabel.Parent = sidebarBottom
UI.pingLabel = pingLabel

sidebarBottom.ZIndex = 10

local contentContainer, header, titleLabel, destroyButton
do
	-- Content area
	contentContainer = Instance.new("Frame")
	contentContainer.Name = "ContentContainer"
	contentContainer.Size = UDim2.new(1, -155, 1, -15)
	contentContainer.Position = UDim2.new(0, 155, 0, 10)
	contentContainer.BackgroundTransparency = 1
	contentContainer.Parent = mainFrame
	UI.contentContainer = contentContainer

	-- Header for app title and destroy
	header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 40)
	header.BackgroundTransparency = 1
	header.Parent = contentContainer
	UI.header = header

	titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -60, 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Movement Controls"
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
	titleLabel.TextSize = 18
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = header
	UI.titleLabel = titleLabel

	-- Destroy button moved to content area top right
	destroyButton = Instance.new("TextButton")
	destroyButton.Name = "DestroyButton"
	destroyButton.Size = UDim2.new(0, 26, 0, 26)
	destroyButton.AnchorPoint = Vector2.new(1, 0.5)
	destroyButton.Position = UDim2.new(1, -10, 0.5, 0)
	destroyButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
	destroyButton.BackgroundTransparency = 0.2
	destroyButton.Text = "✕"
	destroyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	destroyButton.Font = Enum.Font.GothamBold
	destroyButton.TextSize = 14
	destroyButton.Parent = header
	UI.destroyButton = destroyButton

	local destCorner = Instance.new("UICorner")
	destCorner.CornerRadius = UDim.new(1, 0)
	destCorner.Parent = destroyButton

	local badge = Instance.new("TextLabel")
	badge.Name = "Badge"
	badge.AnchorPoint = Vector2.new(1, 0.5)
	badge.Position = UDim2.new(1, -45, 0.5, 0)
	badge.Size = UDim2.new(0, 60, 0, 20)
	badge.BackgroundColor3 = Color3.fromRGB(60, 100, 255)
	badge.BackgroundTransparency = 0.2
	badge.Text = "PREMIUM"
	badge.Font = Enum.Font.GothamMedium
	badge.TextSize = 10
	badge.TextColor3 = Color3.fromRGB(220, 230, 255)
	badge.Parent = header

	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(1, 0)
	badgeCorner.Parent = badge
end

---------------------------------------------------------------------
-- UTILITIES
---------------------------------------------------------------------

local function createDashboardRow(parent, labelText, initialValue)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 40)
	row.BackgroundTransparency = 0.6
	row.BackgroundColor3 = Color3.fromRGB(20, 22, 35)
	row.BorderSizePixel = 0
	row.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = row
	
	local sideLine = Instance.new("Frame")
	sideLine.Size = UDim2.new(0, 3, 0.4, 0)
	sideLine.Position = UDim2.new(0, 0, 0.3, 0)
	sideLine.BackgroundColor3 = States.panelThemeColor
	sideLine.BorderSizePixel = 0
	sideLine.Parent = row
	
	local slCorner = Instance.new("UICorner")
	slCorner.CornerRadius = UDim.new(1, 0)
	slCorner.Parent = sideLine

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.4, -20, 1, 0)
	label.Position = UDim2.new(0, 15, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.Font = Enum.Font.Gotham
	label.TextSize = 12
	label.TextColor3 = Color3.fromRGB(160, 170, 210)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local val = Instance.new("TextLabel")
	val.Size = UDim2.new(0.6, -20, 1, 0)
	val.Position = UDim2.new(0.4, 5, 0, 0)
	val.BackgroundTransparency = 1
	val.Text = tostring(initialValue)
	val.Font = Enum.Font.GothamMedium
	val.TextSize = 12
	val.TextColor3 = Color3.fromRGB(240, 245, 255)
	val.TextXAlignment = Enum.TextXAlignment.Right
	val.ClipsDescendants = true
	val.Parent = row

	return val
end
-- createSectionLabel removed


local function createToggleButton(actionOrKey, text, parentPage)
	local button = Instance.new("TextButton")
	button.Name = text .. "_Toggle"
	button.Size = UDim2.new(1, 0, 0, 32) -- Default size, can be overridden
	button.BackgroundColor3 = Color3.fromRGB(30, 34, 52)
	button.BackgroundTransparency = 0.2
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	
	-- Determine if it's a dynamic action or a static key display
	local action = nil
	local keyName = actionOrKey
	if Config.keybinds[actionOrKey] then
		action = actionOrKey
		keyName = Config.keybinds[action].Name
		button:SetAttribute("Action", action)
	else
		button:SetAttribute("StaticKey", actionOrKey)
	end
	button:SetAttribute("FeatureText", text)

	local keyText = (keyName and keyName ~= "") and (keyName .. " | ") or ""
	button.Text = keyText .. text .. " [OFF]"
	button.Font = Enum.Font.GothamMedium
	button.TextSize = 13
	button.TextColor3 = Color3.fromRGB(225, 232, 255)
	button.Parent = parentPage

	-- Right-click support for binding
	button.MouseButton2Click:Connect(function()
		if action then
			Config.isAssigningKey = action
			Config.assigningStartTime = tick()
			button.Text = "[Press a Key to Bind]"
			U.notify("Rebinding", "Press any key for " .. text .. " (Esc to cancel)", 2)
			
			-- Timeout if no key pressed in 10 seconds
			task.delay(10, function()
				if Config.isAssigningKey == action then
					Config.isAssigningKey = nil
					local state = button.Text:find("%[ON%]") ~= nil
					U.setButtonState(button, state)
				end
			end)
		end
	end)

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Color = Color3.fromRGB(70, 80, 130)
	stroke.Transparency = 0.4
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = button

	local indicator = Instance.new("Frame")
	indicator.Name = "Indicator"
	indicator.Size = UDim2.new(0, 10, 0, 10)
	indicator.Position = UDim2.new(1, -20, 0.5, -5)
	indicator.BackgroundColor3 = Color3.fromRGB(60, 65, 90)
	indicator.Parent = button

	local indCorner = Instance.new("UICorner")
	indCorner.CornerRadius = UDim.new(1, 0)
	indCorner.Parent = indicator

	local indStroke = Instance.new("UIStroke")
	indStroke.Thickness = 1.5
	indStroke.Color = Color3.fromRGB(40, 45, 65)
	indStroke.Parent = indicator

	local sideHighlight = Instance.new("Frame")
	sideHighlight.Name = "SideHighlight"
	sideHighlight.Size = UDim2.new(0, 3, 0.6, 0)
	sideHighlight.Position = UDim2.new(0, 0, 0.2, 0)
	sideHighlight.BackgroundColor3 = Color3.fromRGB(60, 100, 255)
	sideHighlight.BackgroundTransparency = 0.5
	sideHighlight.BorderSizePixel = 0
	sideHighlight.Parent = button

	local shCorner = Instance.new("UICorner")
	shCorner.CornerRadius = UDim.new(1, 0)
	shCorner.Parent = sideHighlight

	return button
end

local function createLabeledInput(labelText, defaultValue, parentPage)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 30)
	row.BackgroundTransparency = 1
	row.Parent = parentPage

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.4, 0, 1, 0)
	label.Position = UDim2.new(0, 5, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.Font = Enum.Font.Gotham
	label.TextSize = 13
	label.TextColor3 = Color3.fromRGB(190, 198, 230)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local input = Instance.new("TextBox")
	input.Size = UDim2.new(0.4, -4, 1, 0)
	input.Position = UDim2.new(0.4, 5, 0, 0)
	input.BackgroundColor3 = Color3.fromRGB(22, 24, 36)
	input.BorderSizePixel = 0
	input.Text = tostring(defaultValue)
	input.Font = Enum.Font.Gotham
	input.TextSize = 13
	input.TextColor3 = Color3.fromRGB(255, 255, 255)
	input.ClearTextOnFocus = false
	input.Parent = row

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = input

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Color = Color3.fromRGB(70, 80, 130)
	stroke.Transparency = 0.5
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = input

	-- Tombol reset di sebelah kanan input
	local resetButton = Instance.new("TextButton")
	resetButton.Name = "Reset"
	resetButton.Size = UDim2.new(0, 48, 1, 0)
	resetButton.Position = UDim2.new(0.8, 5, 0, 0)
	resetButton.BackgroundColor3 = Color3.fromRGB(30, 32, 46)
	resetButton.BorderSizePixel = 0
	resetButton.Font = Enum.Font.GothamBold
	resetButton.TextSize = 11
	resetButton.TextColor3 = Color3.fromRGB(220, 220, 235)
	resetButton.Text = "RESET"
	resetButton.AutoButtonColor = true
	resetButton.Parent = row

	local resetCorner = Instance.new("UICorner")
	resetCorner.CornerRadius = UDim.new(0, 6)
	resetCorner.Parent = resetButton

	local resetStroke = Instance.new("UIStroke")
	resetStroke.Thickness = 1
	resetStroke.Color = Color3.fromRGB(70, 80, 130)
	resetStroke.Transparency = 0.6
	resetStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	resetStroke.Parent = resetButton

	return input, resetButton
end

-- U.setButtonState moved to utilities

-- Tab switching logic
local currentTab = "Home"
-- Tab switching logic
local function switchTab(tabName)
	currentTab = tabName
	if tabName == "Dashboard" then
		titleLabel.Text = "Game Dashboard"
	else
		titleLabel.Text = tabName .. " Controls"
	end

	for name, page in pairs(UI.pages) do
		page.Visible = (name == tabName)
	end
	for name, btn in pairs(UI.sidebarButtons) do
		local indicator = btn:FindFirstChild("Indicator")
		if name == tabName then
			S.TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(40, 60, 140), BackgroundTransparency = 0.3, TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
			if indicator then 
				indicator.BackgroundTransparency = 0 
				indicator.BackgroundColor3 = States.panelThemeColor
			end
		else
			S.TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(140, 150, 180)}):Play()
			if indicator then indicator.BackgroundTransparency = 1 end
		end
	end
	
	-- Auto-refresh server list if entering tab
	if tabName == "Servers" then
		pcall(function() _G.FVKHUB_RefreshServers() end)
	end
	if tabName == "Players" then
		pcall(function() _G.FVKHUB_RefreshPlayersList() end)
	end
	if tabName == "Scripts" then
		pcall(function() _G.FVKHUB_RefreshScriptsList() end)
	end
	if tabName == "Tools" then
		U.notify("Tools", "Utility tools ready", 1)
	end
end

function toggleNetworkClaim()
	States.isNetworkClaim = not States.isNetworkClaim
	
	if States.isNetworkClaim then
		if not Refs.connections.networkClaimLoop then
			Refs.connections.networkClaimLoop = S.RunService.Heartbeat:Connect(function()
				if not States.isNetworkClaim then return end
				pcall(function()
					settings().Physics.AllowSleep = false
					localPlayer.MaximumSimulationRadius = math.huge
					localPlayer.SimulationRadius = math.huge
				end)
			end)
		end
		U.notify("Network Claim", "Active - SimRadius set to math.huge", 2, "Success")
	else
		if Refs.connections.networkClaimLoop then
			Refs.connections.networkClaimLoop:Disconnect()
			Refs.connections.networkClaimLoop = nil
		end
		pcall(function()
			localPlayer.MaximumSimulationRadius = 1000
			localPlayer.SimulationRadius = 100
		end)
		U.notify("Network Claim", "Disabled - SimRadius restored", 2, "Info")
	end
	if UI.buttons.networkClaim then U.setButtonState(UI.buttons.networkClaim, States.isNetworkClaim) end
end

function togglePartFling()
	States.isPartFling = not States.isPartFling
	
	if States.isPartFling then
		if not Refs.connections.partFlingLoop then
			Refs.connections.partFlingLoop = S.RunService.Heartbeat:Connect(function()
				if not States.isPartFling or States.isDestroyed then 
					if Refs.connections.partFlingLoop then 
						Refs.connections.partFlingLoop:Disconnect() 
						Refs.connections.partFlingLoop = nil 
					end
					return 
				end
				
				-- Ensure Network Ownership from distance (Expansion)
				pcall(function()
					settings().Physics.AllowSleep = false
					localPlayer.MaximumSimulationRadius = 1e9
					localPlayer.SimulationRadius = 1e8
				end)

				local char = localPlayer.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if not hrp then return end
				
				-- Scan for unanchored parts in proximity (Adjustable Radius)
				local overlapParams = OverlapParams.new()
				overlapParams.FilterType = Enum.RaycastFilterType.Exclude
				overlapParams.FilterDescendantsInstances = {char}
				
				local foundParts = workspace:GetPartBoundsInRadius(hrp.Position, Config.partFlingRadius or 30, overlapParams)
				for _, part in ipairs(foundParts) do
					if part:IsA("BasePart") and not part.Anchored then
						pcall(function()
							-- [NETWORK CLAIM] Periodic 'Wake Up' to force ownership transfer from distance
							if part.AssemblyLinearVelocity.Magnitude < 0.01 then
								part.AssemblyLinearVelocity = Vector3.new(0, 0.01, 0)
							end
							
							local s = Config.partFlingStrength or 500000
							local mode = Config.partFlingMode or "Spin"

							if mode == "Spin" then
								-- Logic: Extreme rotation (Original)
								part.AssemblyAngularVelocity = Vector3.new(s, s, s)
								part.AssemblyLinearVelocity = Vector3.new(0, 10, 0)
							elseif mode == "Push" then
								-- Logic: Linear push away from player
								local diff = (part.Position - hrp.Position)
								local dist = diff.Magnitude
								if dist > 0.01 then
									local dir = diff.Unit
									local speed = math.clamp(s/100, 50, 1000)
									part.AssemblyLinearVelocity = (dir * speed) + Vector3.new(0, 20, 0)
									part.AssemblyAngularVelocity = Vector3.new(s/2, s/2, s/2)
								end
							elseif mode == "Pull" then
								-- Logic: Pull parts towards a gap distance
								local diff = (hrp.Position - part.Position)
								local dist = diff.Magnitude
								if dist > 0.1 then
									local dir = diff.Unit
									local gap = Config.partPullGap or 8
									
									if dist > gap then
										-- Optimized bring speed scaled by distance
										local speedFactor = math.clamp(dist * 15, 30, 500)
										-- Combine pull direction with character velocity to follow movement
										part.AssemblyLinearVelocity = (dir * speedFactor) + (hrp.AssemblyLinearVelocity * 0.8)
									elseif dist < gap - 1.5 then
										-- Gentle push back if too close
										part.AssemblyLinearVelocity = (-dir * 40) + hrp.AssemblyLinearVelocity
									else
										-- 'Hold' range: Match player velocity perfectly for a 'Grab' effect
										part.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity
									end
									
									-- Strong reduction in spin for Bring/Grab stability
									-- (Low enough to not bounce, high enough to keep physics awake)
									part.AssemblyAngularVelocity = Vector3.new(20, 20, 20)
								end
							elseif mode == "Vortex" then
								-- Logic: Centered fast orbit + Extreme spin
								local diff = (hrp.Position - part.Position)
								local dist = diff.Magnitude
								if dist > 0.1 then
									local dir = diff.Unit
									local gap = Config.partPullGap or 8
									
									-- Strong radial force to lock distance
									local radialVel = (dist - gap) * (s/15000)
									local tangent = dir:Cross(Vector3.new(0, 1, 0))
									-- Orbit speed based on strength
									local orbitSpeed = math.clamp(s/5000, 50, 150)
									
									part.AssemblyLinearVelocity = (dir * radialVel) + (tangent * orbitSpeed) + Vector3.new(0, 1, 0)
									-- Extreme spin for flinging effect
									part.AssemblyAngularVelocity = Vector3.new(s/1.5, s/1.5, s/1.5)
								end
							elseif mode == "Jitter" then
								-- Logic: Randomized velocity bursts
								part.AssemblyLinearVelocity = Vector3.new(math.random(-s, s)/10, math.random(-s, s)/10, math.random(-s, s)/10)
								part.AssemblyAngularVelocity = Vector3.new(math.random(-s, s), math.random(-s, s), math.random(-s, s))
							end
						end)
					end
				end
			end)
		end
		U.notify("Part Fling", string.format("Aura Active (%s | Rad: %d)", Config.partFlingMode:upper(), Config.partFlingRadius), 2, "Success")
	else
		if Refs.connections.partFlingLoop then 
			Refs.connections.partFlingLoop:Disconnect() 
			Refs.connections.partFlingLoop = nil 
		end
		U.notify("Part Fling", "Aura Disabled", 2, "Info")
	end
	if UI.buttons.partFling then U.setButtonState(UI.buttons.partFling, States.isPartFling) end
	if UI.buttons.radiusControl then U.setButtonState(UI.buttons.radiusControl, States.isPartFling) end
end

local function createSidebarButton(name, iconText)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 36)
	btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel = 0
	btn.Text = iconText .. "  " .. name
	btn.Font = Enum.Font.GothamMedium
	btn.TextSize = 13
	btn.TextColor3 = Color3.fromRGB(140, 150, 180)
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.AutoButtonColor = false
	btn.Parent = UI.btnContainer

	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 10)
	btnCorner.Parent = btn
	local btnPad = Instance.new("UIPadding")
	btnPad.PaddingLeft = UDim.new(0, 15)
	btnPad.Parent = btn
	
	local indicator = Instance.new("Frame")
	indicator.Name = "Indicator"
	indicator.Size = UDim2.new(0, 3, 0.45, 0)
	indicator.Position = UDim2.new(0, -10, 0.275, 0)
	indicator.BackgroundColor3 = Color3.fromRGB(100, 140, 255)
	indicator.BackgroundTransparency = 1
	indicator.BorderSizePixel = 0
	indicator.Parent = btn
	
	local indCorner = Instance.new("UICorner")
	indCorner.CornerRadius = UDim.new(1, 0)
	indCorner.Parent = indicator

	btn.MouseEnter:Connect(function()
		if currentTab ~= name then
			S.TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 0.9, TextColor3 = Color3.fromRGB(200, 210, 255)}):Play()
		end
	end)
	btn.MouseLeave:Connect(function()
		if currentTab ~= name then
			S.TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(140, 150, 180)}):Play()
		end
	end)
	
	UI.sidebarButtons[name] = btn
	btn.MouseButton1Click:Connect(function()
		switchTab(name)
	end)
end

local function createPage(name)
	local page = Instance.new("ScrollingFrame")
	page.Name = "Page_" .. name
	page.Size = UDim2.new(1, 0, 1, -50)
	page.Position = UDim2.new(0, 0, 0, 50)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 2
	page.ScrollBarImageColor3 = Color3.fromRGB(100, 110, 160)
	page.Visible = false
	page.Parent = contentContainer
	
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = page
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 5)
	pad.PaddingRight = UDim.new(0, 10)
	pad.PaddingTop = UDim.new(0, 5)
	pad.PaddingBottom = UDim.new(0, 35)
	pad.Parent = page
	
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
	end)
	
	UI.pages[name] = page
	U.setupSmoothScroll(page)
	return page
end

createSidebarButton("Dashboard", "📊")
createSidebarButton("Home", "🏠")
createSidebarButton("Visuals", "👁️")
createSidebarButton("Player", "👤")
createSidebarButton("Players", "👥")
createSidebarButton("World", "🌎")
createSidebarButton("Vehicle", "🚗")
createSidebarButton("AutoWalk", "🚶")
createSidebarButton("Waypoints", "📍")
createSidebarButton("Servers", "🌐")
createSidebarButton("Tools", "🛠️")
createSidebarButton("Keybinds", "⌨️")
createSidebarButton("Scripts", "📜")
createSidebarButton("Physic", "⚛️")
createSidebarButton("Config", "⚙️")

local dashboardPage = createPage("Dashboard")
local homePage = createPage("Home")
local visualsPage = createPage("Visuals")
local playerPage = createPage("Player")
local playersPage = createPage("Players")
local worldPage = createPage("World")
local vehiclePage = createPage("Vehicle")
local autoWalkPage = createPage("AutoWalk")
local waypointsPage = createPage("Waypoints")
local serversPage = createPage("Servers")
local toolsPage = createPage("Tools")
local keybindsPage = createPage("Keybinds")
local scriptsPage = createPage("Scripts")
local physicPage = createPage("Physic")
local configPage = createPage("Config")

-- Overriding playersPage layout type so search bar can be sticky
do
	playersPage:Destroy()
	playersPage = Instance.new("Frame")
	playersPage.Name = "Page_Players"
	playersPage.Size = UDim2.new(1, 0, 1, -50)
	playersPage.Position = UDim2.new(0, 0, 0, 50)
	playersPage.BackgroundTransparency = 1
	playersPage.BorderSizePixel = 0
	playersPage.Visible = false
	playersPage.Parent = contentContainer
	UI.pages["Players"] = playersPage

	local padPlayers = Instance.new("UIPadding")
	padPlayers.PaddingLeft = UDim.new(0, 5)
	padPlayers.PaddingRight = UDim.new(0, 10)
	padPlayers.PaddingTop = UDim.new(0, 5)
	padPlayers.PaddingBottom = UDim.new(0, 35)
	padPlayers.Parent = playersPage

	local layoutPlayers = Instance.new("UIListLayout")
	layoutPlayers.Padding = UDim.new(0, 6)
	layoutPlayers.SortOrder = Enum.SortOrder.LayoutOrder
	layoutPlayers.Parent = playersPage
end

switchTab("Dashboard")

-- [ZOOM BYPASS] Directly Active
task.spawn(function()
	while true do
		pcall(function()
			if localPlayer then
				localPlayer.CameraMaxZoomDistance = 100000
				localPlayer.CameraMinZoomDistance = 0
			end
		end)
		task.wait(2)
	end
end)

---------------------------------------------------------------------
-- SERVERS PAGE CONTENT
---------------------------------------------------------------------
do
	-- local _serverHeader removed

	
	local toolbar = Instance.new("Frame")
	toolbar.Name = "Toolbar"
	toolbar.Size = UDim2.new(1, 0, 0, 36)
	toolbar.BackgroundTransparency = 1
	toolbar.LayoutOrder = 1
	toolbar.Parent = serversPage

	-- [NEW] Server Info Section (Age & Region)
	local statusFrame = Instance.new("Frame")
	statusFrame.Name = "ServerStatus"
	statusFrame.Size = UDim2.new(1, 0, 0, 50)
	statusFrame.Position = UDim2.new(0, 0, 0, 45)
	statusFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 35)
	statusFrame.BorderSizePixel = 0
	statusFrame.LayoutOrder = 2
	statusFrame.Parent = serversPage

	local scStatus = Instance.new("UICorner")
	scStatus.CornerRadius = UDim.new(0, 8)
	scStatus.Parent = statusFrame

	local sAgeLabel = Instance.new("TextLabel")
	sAgeLabel.Size = UDim2.new(1, -20, 0, 25)
	sAgeLabel.Position = UDim2.new(0, 10, 0, 0)
	sAgeLabel.BackgroundTransparency = 1
	sAgeLabel.Text = "Server Age: Calculating..."
	sAgeLabel.TextColor3 = Color3.fromRGB(200, 210, 255)
	sAgeLabel.Font = Enum.Font.GothamMedium
	sAgeLabel.TextSize = 12
	sAgeLabel.TextXAlignment = Enum.TextXAlignment.Left
	sAgeLabel.Parent = statusFrame

	local sRegionLabel = Instance.new("TextLabel")
	sRegionLabel.Size = UDim2.new(1, -20, 0, 25)
	sRegionLabel.Position = UDim2.new(0, 10, 0, 22)
	sRegionLabel.BackgroundTransparency = 1
	sRegionLabel.Text = "Server Region: Detecting..."
	sRegionLabel.TextColor3 = Color3.fromRGB(150, 160, 210)
	sRegionLabel.Font = Enum.Font.GothamMedium
	sRegionLabel.TextSize = 11
	sRegionLabel.TextXAlignment = Enum.TextXAlignment.Left
	sRegionLabel.Parent = statusFrame

	-- Real-time update logic
	task.spawn(function()
		local function formatTime(seconds)
			local days = math.floor(seconds / 86400)
			local hours = math.floor((seconds % 86400) / 3600)
			local mins = math.floor((seconds % 3600) / 60)
			local secs = math.floor(seconds % 60)
			
			local res = ""
			if days > 0 then res = res .. days .. "d " end
			if hours > 0 or days > 0 then res = res .. hours .. "h " end
			if mins > 0 or hours > 0 or days > 0 then res = res .. mins .. "m " end
			res = res .. secs .. "s"
			return res
		end

		-- Region Detection (Approximated)
		task.spawn(function()
			pcall(function()
				local response = game:HttpGet("http://ip-api.com/json/")
				local data = S.HttpService:JSONDecode(response)
				if data and data.city and data.country then
					sRegionLabel.Text = string.format("Server Region: %s, %s (Network-approx)", data.city, data.country)
				else
					sRegionLabel.Text = "Server Region: Unknown / Proxied"
				end
			end)
		end)

		while task.wait(1) and not States.isDestroyed do
			local uptime = workspace.DistributedGameTime
			sAgeLabel.Text = "Server Age: " .. formatTime(uptime)
		end
	end)
	
	local function createToolbarBtn(text, color, pos)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 85, 1, 0)
		btn.Position = pos
		btn.BackgroundColor3 = color
		btn.BackgroundTransparency = 0.2
		btn.Text = text
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 11
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Parent = toolbar
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = btn
		
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1.2
		stroke.Color = Color3.new(1, 1, 1)
		stroke.Transparency = 0.8
		stroke.Parent = btn
		
		return btn
	end
	
	local refreshBtn = createToolbarBtn("REFRESH", Color3.fromRGB(60, 100, 255), UDim2.new(0, 0, 0, 0))
	local hopBtn = createToolbarBtn("HOP", Color3.fromRGB(100, 60, 255), UDim2.new(0, 90, 0, 0))
	local reBtn = createToolbarBtn("REJOIN", Color3.fromRGB(60, 200, 100), UDim2.new(0, 180, 0, 0))
	
	local listContainer = Instance.new("ScrollingFrame")
	listContainer.Name = "ServerList"
	listContainer.Size = UDim2.new(1, 0, 1, -110)
	listContainer.Position = UDim2.new(0, 0, 0, 105)
	listContainer.BackgroundTransparency = 1
	listContainer.BorderSizePixel = 0
	listContainer.ScrollBarThickness = 2
	listContainer.ScrollBarImageColor3 = Color3.fromRGB(60, 100, 255)
	listContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	listContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listContainer.LayoutOrder = 3
	listContainer.Parent = serversPage
	UI.serverList = listContainer
	U.setupSmoothScroll(listContainer)
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 6)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = listContainer
	
	-- Forward declare logic for callbacks
	refreshBtn.MouseButton1Click:Connect(function()
		pcall(function() _G.FVKHUB_RefreshServers() end)
	end)
	
	hopBtn.MouseButton1Click:Connect(function()
		pcall(function() _G.FVKHUB_ServerHop() end)
	end)
	
	reBtn.MouseButton1Click:Connect(function()
		pcall(function() _G.FVKHUB_Rejoin() end)
	end)
end

---------------------------------------------------------------------
-- PLAYERS PAGE CONTENT
---------------------------------------------------------------------
do
	-- createSectionLabel removed

	
	local searchFrame = Instance.new("Frame")
	searchFrame.Name = "SearchFrame"
	searchFrame.Size = UDim2.new(1, 0, 0, 36)
	searchFrame.BackgroundColor3 = Color3.fromRGB(25, 28, 45)
	searchFrame.BorderSizePixel = 0
	searchFrame.LayoutOrder = 1
	searchFrame.Parent = playersPage
	
	local sc = Instance.new("UICorner")
	sc.CornerRadius = UDim.new(0, 8)
	sc.Parent = searchFrame
	
	local sStroke = Instance.new("UIStroke")
	sStroke.Thickness = 1
	sStroke.Color = Color3.fromRGB(60, 100, 255)
	sStroke.Transparency = 0.5
	sStroke.Parent = searchFrame
	UI.playersSearchStroke = sStroke
	
	local sBox = Instance.new("TextBox")
	sBox.Name = "SearchBox"
	sBox.Size = UDim2.new(1, -40, 1, 0)
	sBox.Position = UDim2.new(0, 35, 0, 0)
	sBox.BackgroundTransparency = 1
	sBox.PlaceholderText = "Search players..."
	sBox.Text = ""
	sBox.TextColor3 = Color3.fromRGB(240, 245, 255)
	sBox.Font = Enum.Font.Gotham
	sBox.TextSize = 13
	sBox.TextXAlignment = Enum.TextXAlignment.Left
	sBox.Parent = searchFrame
	UI.playersSearchBox = sBox
	
	local sIcon = Instance.new("TextLabel")
	sIcon.Size = UDim2.new(0, 30, 1, 0)
	sIcon.BackgroundTransparency = 1
	sIcon.Text = "🔍"
	sIcon.TextSize = 14
	sIcon.TextColor3 = Color3.fromRGB(110, 120, 160)
	sIcon.Parent = searchFrame

	-- List Container for Players (Scrolling part)
	local listContainer = Instance.new("ScrollingFrame")
	listContainer.Name = "ListContainer"
	listContainer.Size = UDim2.new(1, 0, 1, -42)
	listContainer.BackgroundTransparency = 1
	listContainer.BorderSizePixel = 0
	listContainer.ScrollBarThickness = 2
	listContainer.ScrollBarImageColor3 = Color3.fromRGB(100, 110, 160)
	listContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	listContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listContainer.LayoutOrder = 2
	listContainer.Parent = playersPage
	UI.playersListContainer = listContainer
	U.setupSmoothScroll(listContainer)
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 5)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = listContainer
	
	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		listContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end)

	sBox.Focused:Connect(function()
		S.TweenService:Create(sStroke, TweenInfo.new(0.3), {Transparency = 0}):Play()
	end)
	sBox.FocusLost:Connect(function()
		S.TweenService:Create(sStroke, TweenInfo.new(0.3), {Transparency = 0.5}):Play()
	end)
	
	sBox:GetPropertyChangedSignal("Text"):Connect(function()
		pcall(function() _G.FVKHUB_RefreshPlayersList() end)
	end)
end

---------------------------------------------------------------------
-- TOOLS PAGE CONTENT
---------------------------------------------------------------------
do
	local btoolsBtn = Instance.new("TextButton")
	btoolsBtn.Size = UDim2.new(1, 0, 0, 36)
	btoolsBtn.BackgroundColor3 = Color3.fromRGB(40, 60, 140)
	btoolsBtn.BackgroundTransparency = 0.2
	btoolsBtn.Text = "GET BUILDING TOOLS (BTOOLS)"
	btoolsBtn.Font = Enum.Font.GothamBold
	btoolsBtn.TextSize = 13
	btoolsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btoolsBtn.Parent = toolsPage
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btoolsBtn
	
	btoolsBtn.MouseButton1Click:Connect(function()
		pcall(function() _G.FVKHUB_GetBTools() end)
	end)
	UI.buttons.GetBTools = btoolsBtn

	local dexBtn = Instance.new("TextButton")
	dexBtn.Size = UDim2.new(1, 0, 0, 36)
	dexBtn.BackgroundColor3 = Color3.fromRGB(30, 45, 90)
	dexBtn.Text = "LOAD D-E-X (EXPLORER)"
	dexBtn.Font = Enum.Font.GothamBold
	dexBtn.TextSize = 12
	dexBtn.TextColor3 = Color3.fromRGB(220, 230, 255)
	dexBtn.Parent = toolsPage
	local dc = Instance.new("UICorner")
	dc.CornerRadius = UDim.new(0, 8)
	dc.Parent = dexBtn
	
	dexBtn.MouseButton1Click:Connect(function()
		pcall(function() _G.FVKHUB_LoadDex() end)
	end)
	UI.buttons.LoadDex = dexBtn
	
	local spyBtn = Instance.new("TextButton")
	spyBtn.Size = UDim2.new(1, 0, 0, 36)
	spyBtn.BackgroundColor3 = Color3.fromRGB(30, 45, 90)
	spyBtn.Text = "LOAD S-P-Y (REMOTE)"
	spyBtn.Font = Enum.Font.GothamBold
	spyBtn.TextSize = 12
	spyBtn.TextColor3 = Color3.fromRGB(220, 230, 255)
	spyBtn.Parent = toolsPage
	Instance.new("UICorner", spyBtn).CornerRadius = UDim.new(0, 6)

	
	spyBtn.MouseButton1Click:Connect(function()
		U.notify("Spy", "Loading Remote Spy...", 2)
		pcall(function()
			loadstring(game:HttpGet("https://raw.githubusercontent.com/78n/SimpleSpy/main/main.lua"))()
		end)
	end)
end


---------------------------------------------------------------------
-- SCRIPTS PAGE CONTENT
---------------------------------------------------------------------
do
	local searchFrame = Instance.new("Frame")
	searchFrame.Name = "SearchFrame"
	searchFrame.Size = UDim2.new(1, 0, 0, 36)
	searchFrame.BackgroundColor3 = Color3.fromRGB(25, 28, 45)
	searchFrame.BorderSizePixel = 0
	searchFrame.LayoutOrder = 1
	searchFrame.Parent = scriptsPage
	
	local sc = Instance.new("UICorner")
	sc.CornerRadius = UDim.new(0, 8)
	sc.Parent = searchFrame
	
	local sStroke = Instance.new("UIStroke")
	sStroke.Thickness = 1
	sStroke.Color = Color3.fromRGB(60, 100, 255)
	sStroke.Transparency = 0.5
	sStroke.Parent = searchFrame
	
	local sBox = Instance.new("TextBox")
	sBox.Name = "SearchBox"
	sBox.Size = UDim2.new(1, -120, 1, 0)
	sBox.Position = UDim2.new(0, 35, 0, 0)
	sBox.BackgroundTransparency = 1
	sBox.PlaceholderText = "Search scripts..."
	sBox.Text = ""
	sBox.TextColor3 = Color3.fromRGB(240, 245, 255)
	sBox.Font = Enum.Font.Gotham
	sBox.TextSize = 13
	sBox.TextXAlignment = Enum.TextXAlignment.Left
	sBox.Parent = searchFrame
	UI.scriptsSearchBox = sBox
	
	local sIcon = Instance.new("TextLabel")
	sIcon.Size = UDim2.new(0, 30, 1, 0)
	sIcon.BackgroundTransparency = 1
	sIcon.Text = "🔍"
	sIcon.TextSize = 14
	sIcon.TextColor3 = Color3.fromRGB(110, 120, 160)
	sIcon.Parent = searchFrame

	local refreshBtn = Instance.new("TextButton")
	refreshBtn.Name = "RefreshBtn"
	refreshBtn.Size = UDim2.new(0, 80, 0, 26)
	refreshBtn.Position = UDim2.new(1, -85, 0.5, -13)
	refreshBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 255)
	refreshBtn.Text = "REFRESH"
	refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	refreshBtn.Font = Enum.Font.GothamBold
	refreshBtn.TextSize = 10
	refreshBtn.Parent = searchFrame
	Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 6)
	
	refreshBtn.MouseButton1Click:Connect(function()
		pcall(function() _G.FVKHUB_RefreshScriptsList() end)
	end)

	local listContainer = Instance.new("ScrollingFrame")
	listContainer.Name = "ListContainer"
	listContainer.Size = UDim2.new(1, 0, 1, -42)
	listContainer.BackgroundTransparency = 1
	listContainer.BorderSizePixel = 0
	listContainer.ScrollBarThickness = 2
	listContainer.ScrollBarImageColor3 = Color3.fromRGB(100, 110, 160)
	listContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	listContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listContainer.LayoutOrder = 2
	listContainer.Parent = scriptsPage
	UI.scriptsListContainer = listContainer
	U.setupSmoothScroll(listContainer)
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 5)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = listContainer

	sBox.Focused:Connect(function()
		S.TweenService:Create(sStroke, TweenInfo.new(0.3), {Transparency = 0}):Play()
	end)
	sBox.FocusLost:Connect(function()
		S.TweenService:Create(sStroke, TweenInfo.new(0.3), {Transparency = 0.5}):Play()
	end)
	
	sBox:GetPropertyChangedSignal("Text"):Connect(function()
		pcall(function() _G.FVKHUB_RefreshScriptsList() end)
	end)
end

local function refreshScriptsList()
	if not UI or not UI.scriptsListContainer then return end
	local searchText = (UI.scriptsSearchBox and UI.scriptsSearchBox.Text:lower()) or ""
	
	for _, child in ipairs(UI.scriptsListContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	if not E.listfiles or not E.readfile then
		U.notify("Error", "Executor does not support file operations", 3, "Error")
		return
	end
	
	local success, files = pcall(function()
		if not E.isfolder("FVKHUB_Data/Scripts") then E.makefolder("FVKHUB_Data/Scripts") end
		return E.listfiles("FVKHUB_Data/Scripts")
	end)
	
	if not success or not files then
		U.notify("Error", "Could not read Scripts folder", 3, "Error")
		return
	end
	
	local count = 0
	for _, file in ipairs(files) do
		local fileName = file:match("([^/\\]+)$") or file
		local isLua = fileName:lower():match("%.lua$") or fileName:lower():match("%.luau$")
		
		if isLua and (searchText == "" or fileName:lower():find(searchText)) then
			count = count + 1
			local row = Instance.new("Frame")
			row.Name = "ScriptRow"
			row.Size = UDim2.new(1, -2, 0, 42)
			row.BackgroundColor3 = Color3.fromRGB(30, 34, 52)
			row.BackgroundTransparency = 0.4
			row.BorderSizePixel = 0
			row.Parent = UI.scriptsListContainer
			
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 8)
			corner.Parent = row
			
			local icon = Instance.new("TextLabel")
			icon.Size = UDim2.new(0, 32, 0, 32)
			icon.Position = UDim2.new(0, 5, 0.5, -16)
			icon.BackgroundTransparency = 1
			icon.Text = "📜"
			icon.TextSize = 20
			icon.Parent = row
			
			local nameLab = Instance.new("TextLabel")
			nameLab.Size = UDim2.new(1, -110, 1, 0)
			nameLab.Position = UDim2.new(0, 45, 0, 0)
			nameLab.BackgroundTransparency = 1
			nameLab.Text = fileName
			nameLab.TextColor3 = Color3.fromRGB(240, 245, 255)
			nameLab.Font = Enum.Font.GothamMedium
			nameLab.TextSize = 12
			nameLab.TextXAlignment = Enum.TextXAlignment.Left
			nameLab.Parent = row
			
			local runBtn = Instance.new("TextButton")
			runBtn.Size = UDim2.new(0, 60, 0, 26)
			runBtn.Position = UDim2.new(1, -65, 0.5, -13)
			runBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
			runBtn.Text = "RUN"
			runBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			runBtn.Font = Enum.Font.GothamBold
			runBtn.TextSize = 10
			runBtn.Parent = row
			local rc = Instance.new("UICorner")
			rc.CornerRadius = UDim.new(0, 6)
			rc.Parent = runBtn
			
			runBtn.MouseButton1Click:Connect(function()
				U.notify("Executing", "Running " .. fileName .. "...", 2)
				pcall(function()
					local content = E.readfile(file)
					local func, err = E.loadstring(content)
					if func then
						task.spawn(func)
					else
						U.notify("Lua Error", tostring(err), 4, "Error")
					end
				end)
			end)
		end
	end
end
_G.FVKHUB_RefreshScriptsList = refreshScriptsList

-- PHYSIC PAGE CONTENT
do
	local sectionPhysic = Instance.new("TextLabel")
	sectionPhysic.Size = UDim2.new(1, 0, 0, 25)
	sectionPhysic.BackgroundTransparency = 1
	sectionPhysic.Text = "--- PHYSICS AURA & NETWORK ---"
	sectionPhysic.Font = Enum.Font.GothamBold
	sectionPhysic.TextSize = 12
	sectionPhysic.TextColor3 = Color3.fromRGB(110, 120, 160)
	sectionPhysic.Parent = physicPage

	local infoLabel = Instance.new("TextLabel")
	infoLabel.Size = UDim2.new(1, 0, 0, 32)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = string.format("Aura: %s | Rad: %d | Str: %d | Gap: %d", Config.partFlingMode:upper(), Config.partFlingRadius, Config.partFlingStrength, Config.partPullGap)
	infoLabel.Font = Enum.Font.Gotham
	infoLabel.TextSize = 10
	infoLabel.TextColor3 = Color3.fromRGB(160, 170, 210)
	infoLabel.Parent = physicPage

	local function updateInfoLabel()
		infoLabel.Text = string.format("Aura: %s | Rad: %d | Str: %d | Gap: %d", Config.partFlingMode:upper(), Config.partFlingRadius, Config.partFlingStrength, Config.partPullGap)
	end

	UI.buttons.partFling = createToggleButton("PartFling", "Part Fling Aura", physicPage)
	UI.buttons.partFling.MouseButton1Click:Connect(togglePartFling)

	-- Mode Selection Cycle Button
	local pfModeBtn = Instance.new("TextButton")
	pfModeBtn.Name = "FlingModeBtn"
	pfModeBtn.Size = UDim2.new(1, 0, 0, 32)
	pfModeBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 60)
	pfModeBtn.BackgroundTransparency = 0.2
	pfModeBtn.Text = "Fling Mode: [" .. Config.partFlingMode:upper() .. "]"
	pfModeBtn.Font = Enum.Font.GothamBold
	pfModeBtn.TextSize = 13
	pfModeBtn.TextColor3 = Color3.fromRGB(240, 245, 255)
	pfModeBtn.Parent = physicPage
	Instance.new("UICorner", pfModeBtn).CornerRadius = UDim.new(0, 8)
	local pfStroke = Instance.new("UIStroke", pfModeBtn)
	pfStroke.Thickness = 1.2; pfStroke.Color = Color3.fromRGB(80, 100, 255); pfStroke.Transparency = 0.5

	local modes = {"Spin", "Push", "Pull", "Vortex", "Jitter"}
	pfModeBtn.MouseButton1Click:Connect(function()
		local currentIdx = table.find(modes, Config.partFlingMode) or 1
		local nextIdx = (currentIdx % #modes) + 1
		Config.partFlingMode = modes[nextIdx]
		pfModeBtn.Text = "Fling Mode: [" .. Config.partFlingMode:upper() .. "]"
		updateInfoLabel()
		U.notify("Physic", "Fling Mode changed to: " .. Config.partFlingMode, 2)
		U.saveSettings()
	end)

	local pfRadiusInput, pfRadiusReset = createLabeledInput("Fling Radius Area:", Config.partFlingRadius, physicPage)
	pfRadiusInput.FocusLost:Connect(function()
		Config.partFlingRadius = U.parseNumber(pfRadiusInput.Text, 30)
		pfRadiusInput.Text = tostring(Config.partFlingRadius)
		updateInfoLabel()
		U.notify("Physic", "Fling Aura Radius updated to " .. Config.partFlingRadius, 2)
		U.saveSettings()
	end)
	pfRadiusReset.MouseButton1Click:Connect(function()
		Config.partFlingRadius = 30
		pfRadiusInput.Text = "30"
		updateInfoLabel()
		U.notify("Physic", "Radius reset to default (30)", 2)
		U.saveSettings()
	end)

	local pfStrengthInput, pfStrengthReset = createLabeledInput("Fling Strength Power:", Config.partFlingStrength, physicPage)
	pfStrengthInput.FocusLost:Connect(function()
		Config.partFlingStrength = U.parseNumber(pfStrengthInput.Text, 500000)
		pfStrengthInput.Text = tostring(Config.partFlingStrength)
		updateInfoLabel()
		U.notify("Physic", "Fling Strength updated to " .. Config.partFlingStrength, 2)
		U.saveSettings()
	end)
	pfStrengthReset.MouseButton1Click:Connect(function()
		Config.partFlingStrength = 500000
		pfStrengthInput.Text = "500000"
		updateInfoLabel()
		U.notify("Physic", "Strength reset to default (500000)", 2)
		U.saveSettings()
	end)

	local pfGapInput, pfGapReset = createLabeledInput("Pull Mode Gap Dist:", Config.partPullGap, physicPage)
	pfGapInput.FocusLost:Connect(function()
		Config.partPullGap = U.parseNumber(pfGapInput.Text, 8)
		pfGapInput.Text = tostring(Config.partPullGap)
		updateInfoLabel()
		U.notify("Physic", "Pull Gap updated to " .. Config.partPullGap, 2)
		U.saveSettings()
	end)
	pfGapReset.MouseButton1Click:Connect(function()
		Config.partPullGap = 8
		pfGapInput.Text = "8"
		updateInfoLabel()
		U.notify("Physic", "Pull Gap reset to default (8)", 2)
		U.saveSettings()
	end)

	UI.buttons.networkClaim = createToggleButton("NetworkClaim", "Active Network Claim", physicPage)
	UI.buttons.networkClaim.MouseButton1Click:Connect(toggleNetworkClaim)

	local unanchorBtn = Instance.new("TextButton")
	unanchorBtn.Size = UDim2.new(1, 0, 0, 36)
	unanchorBtn.BackgroundColor3 = Color3.fromRGB(160, 60, 60)
	unanchorBtn.Text = "UNANCHOR ALL NEARBY (SUPPORT)"
	unanchorBtn.Font = Enum.Font.GothamBold
	unanchorBtn.TextSize = 13
	unanchorBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	unanchorBtn.Parent = physicPage
	Instance.new("UICorner", unanchorBtn).CornerRadius = UDim.new(0, 8)
	
	unanchorBtn.MouseButton1Click:Connect(function()
		local count = 0
		local char = localPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then return end
		
		for _, v in ipairs(workspace:GetDescendants()) do
			if v:IsA("BasePart") and not v:IsDescendantOf(char) and v.Anchored then
				local dist = (v.Position - root.Position).Magnitude
				if dist < 100 then
					pcall(function() v.Anchored = false end)
					count = count + 1
				end
			end
		end
		U.notify("Physic", "Unanchored " .. count .. " parts supporting Fling Aura", 2)
	end)
end


-- DASHBOARD CONTENT
local placeInfo = { Name = "Unknown", Creator = "Unknown" }
pcall(function()
	local info = S.MarketplaceService:GetProductInfo(game.PlaceId)
	if info then
		placeInfo.Name = info.Name
		placeInfo.Creator = info.Creator.Name or "Unknown"
	end
end)

createDashboardRow(dashboardPage, "Place Name:", placeInfo.Name)
createDashboardRow(dashboardPage, "Place ID:", game.PlaceId)
createDashboardRow(dashboardPage, "Job ID:", game.JobId == "" and "Studio/Private" or game.JobId)
createDashboardRow(dashboardPage, "Server Size:", #S.Players:GetPlayers() .. " S.Players")
createDashboardRow(dashboardPage, "Account Age:", localPlayer.AccountAge .. " Days")
createDashboardRow(dashboardPage, "User / ID:", localPlayer.Name .. " (" .. localPlayer.UserId .. ")")

UI.buttons.antiAfk = createToggleButton("AntiAfk", "Anti-AFK Protection", dashboardPage)

-- QUICK ACTIONS ON DASHBOARD
local quickActionsLab = Instance.new("TextLabel")
quickActionsLab.Size = UDim2.new(1, 0, 0, 25)
quickActionsLab.BackgroundTransparency = 1
quickActionsLab.Text = "--- QUICK ACTIONS ---"
quickActionsLab.Font = Enum.Font.GothamBold
quickActionsLab.TextSize = 12
quickActionsLab.TextColor3 = Color3.fromRGB(110, 120, 160)
quickActionsLab.Parent = dashboardPage

UI.buttons.dash_dash = createToggleButton("Dash", "Dash Enabled", dashboardPage)
UI.buttons.dash_fly = createToggleButton("Fly", "Fly Mode", dashboardPage)
UI.buttons.dash_noclip = createToggleButton("Noclip", "Noclip Protocol", dashboardPage)
UI.buttons.dash_speed = createToggleButton("FlashSpeed", "Flash Speed", dashboardPage)

-- Re-assigning to main UI buttons table for multi-page linkage if needed, 
-- though connections will handle both if they share the same keys in UI.buttons. 
-- For now, let's just make sure they exist.
U.setButtonState(UI.buttons.antiAfk, States.isAntiAfk)
UI.buttons.antiAfk.MouseButton1Click:Connect(function()
	States.isAntiAfk = not States.isAntiAfk
	U.setButtonState(UI.buttons.antiAfk, States.isAntiAfk)
	U.notifyToggle("Anti-AFK", States.isAntiAfk)
	U.saveSettings()
end)

---------------------------------------------------------------------
-- DRAGGABLE + MINIMIZE
---------------------------------------------------------------------

local isDragging = false
local dragStart = nil
local dragStartPos = nil

header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isDragging = true
		dragStart = input.Position
		dragStartPos = mainFrame.Position
	end
end)

header.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isDragging = false
	end
end)

S.UserInputService.InputChanged:Connect(function(input)
	if not isDragging then return end
	if input.UserInputType ~= Enum.UserInputType.MouseMovement
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local delta = input.Position - dragStart
	mainFrame.Position = UDim2.new(
		dragStartPos.X.Scale,
		dragStartPos.X.Offset + delta.X,
		dragStartPos.Y.Scale,
		dragStartPos.Y.Offset + delta.Y
	)
end)

-- (isMinimized moved to States table)

-- Information Footer
local footerBar = Instance.new("Frame")
footerBar.Size = UDim2.new(1, -115, 0, 20)
footerBar.Position = UDim2.new(0, 110, 1, -25)
footerBar.BackgroundTransparency = 1
footerBar.Parent = mainFrame

local footerText = Instance.new("TextLabel")
footerText.Size = UDim2.new(1, 0, 1, 0)
footerText.BackgroundTransparency = 1
footerText.Text = "FVKHUB | ALT or DEL to Close"
footerText.Font = Enum.Font.Gotham
footerText.TextColor3 = Color3.fromRGB(110, 120, 160)
footerText.TextSize = 10
footerText.TextXAlignment = Enum.TextXAlignment.Right
footerText.Parent = footerBar

-- Teleport Row and Popup code removed.



local function rejoinServer()
	local TeleportService = S.TeleportService

	if #S.Players:GetPlayers() <= 1 then
		TeleportService:Teleport(game.PlaceId, localPlayer)
	else
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
	end
end

local function serverHop()
	local TeleportService = S.TeleportService
	
	local success, result = pcall(function()
		return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100")
	end)
	
	if not success then
		U.notify("Error", "Server list unreachable or HttpGet failed", 3)
		return
	end
	
	local decoded = nil
	pcall(function()
		decoded = S.HttpService:JSONDecode(result)
	end)
	
	if not decoded or not decoded.data then
		U.notify("Error", "No server data found", 3)
		return
	end
	
	local servers = {}
	for _, v in ipairs(decoded.data) do
		if v.playing and v.playing < v.maxPlayers and v.id ~= game.JobId then
			table.insert(servers, v.id)
		end
	end
	
	if #servers > 0 then
		U.notify("Server Hopper", "Teleporting to a random server...", 3)
		TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], localPlayer)
	else
		U.notify("Server Hopper", "No other servers found", 3)
	end
end

local function getBTools()
	local success, err = pcall(function()
		local backpack = localPlayer:FindFirstChildOfClass("Backpack")
		local character = localPlayer.Character
		
		-- 1. CLEANUP: Remove old tools so they don't pile up
		local function cleanup(parent)
			if not parent then return end
			for _, item in ipairs(parent:GetChildren()) do
				if item.Name:find("FVK_") or item.Name:find("BTool") or item:IsA("HopperBin") then
					item:Destroy()
				end
			end
		end
		cleanup(backpack)
		cleanup(character)



		local toolFolder = backpack or character
		if not toolFolder then
			U.notify("Error", "No valid container found", 3, "Error")
			return
		end

		-- 3. Create only 3 Essential Tools to keep it clean
		local toolNames = {"Hammer", "Clone", "Grab"}
		local toolsCreated = 0

		for i, name in ipairs(toolNames) do
			local bin = Instance.new("HopperBin")
			bin.Name = "FVK_" .. name
			bin.BinType = (i == 1 and Enum.BinType.Hammer) or (i == 2 and Enum.BinType.Clone) or Enum.BinType.Grab
			
			local pSuccess = pcall(function() bin.Parent = toolFolder end)
			if pSuccess then toolsCreated = toolsCreated + 1 end
		end

		if toolsCreated > 0 then
			U.notify("BTools Cleaned & Reset", "Clean set added to toolbar", 2, "Success")
			
			if character then
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid and backpack then
					task.delay(0.1, function()
						local t = backpack:FindFirstChild("FVK_Hammer")
						if t then humanoid:EquipTool(t) end
					end)
				end
			end
			

			
			-- Hook mouse to unanchor parts before BTool interacts, forcing network ownership
			if Refs.connections.btoolsClickSync then Refs.connections.btoolsClickSync:Disconnect() end
			Refs.connections.btoolsClickSync = mouse.Button1Down:Connect(function()
				local char = localPlayer.Character
				if not char then return end
				
				local activeTool = char:FindFirstChildOfClass("HopperBin")
				if activeTool and activeTool.Name:find("FVK_") then
					local target = mouse.Target
					if target and target:IsA("BasePart") and target.Anchored and not target:IsDescendantOf(char) then
						pcall(function()
							-- Unanchor to allow physics replication (Network Claim takes over)
							target.Anchored = false
							-- Wake up the part physics to trigger client Network Claim instantly
							target.AssemblyLinearVelocity = Vector3.new(0, 0.05, 0)
							target:ApplyImpulse(Vector3.new(0, 0.01, 0))
						end)
					end
				end
			end)
		end
	end)
	
	if not success then
		U.notify("BTools Error", tostring(err), 4, "Error")
	end
end



_G.FVKHUB_LoadDex = function()
	U.notify("DEX", "Loading DEX Explorer...", 2)
	pcall(function()
		local dex = loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))
		if dex then dex() end
	end)
end

_G.FVKHUB_GetBTools = getBTools
_G.FVKHUB_ServerHop = serverHop
_G.FVKHUB_Rejoin = rejoinServer

-- Logic functions for server list (moved early to ensure UI availability)
local function refreshServers()
	if not UI or not UI.serverList then return end
	
	-- Clear list
	for _, child in ipairs(UI.serverList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	U.notify("Servers", "Fetching server list...", 2)
	
	local success, result = pcall(function()
		return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100")
	end)
	
	if not success or not result then
		U.notify("Error", "Failed to fetch servers (HttpGet error)", 3)
		warn("FVKHUB Error: HttpGet failed for server list")
		return
	end
	
	local decoded = nil
	pcall(function() decoded = S.HttpService:JSONDecode(result) end)
	
	if not decoded or not decoded.data then
		U.notify("Error", "No server data found in response", 3)
		return
	end
	
	if #decoded.data == 0 then
		U.notify("Info", "No other public servers found", 3)
		return
	end

	local count = 0
	for i, sv in ipairs(decoded.data) do
		repeat
			if sv.id == game.JobId then break end
			count = count + 1
			
			local row = Instance.new("Frame")
			row.Name = "ServerRow"
			row.Size = UDim2.new(1, -10, 0, 50)
			row.BackgroundColor3 = Color3.fromRGB(25, 28, 45)
			row.BackgroundTransparency = 0.4
			row.BorderSizePixel = 0
			row.Parent = UI.serverList
			
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 10)
			corner.Parent = row
			
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 1
			stroke.Color = Color3.fromRGB(60, 100, 255)
			stroke.Transparency = 0.7
			stroke.Parent = row
			
			local info = Instance.new("TextLabel")
			info.Size = UDim2.new(0.65, 0, 1, 0)
			info.Position = UDim2.new(0, 15, 0, 0)
			info.BackgroundTransparency = 1
			local playing = tonumber(sv.playing) or 0
			local maxP = tonumber(sv.maxPlayers) or 0
			local ping = tonumber(sv.ping) or 0
			info.Text = string.format("👤 %d/%d  |  📡 %dms", playing, maxP, ping)
			info.TextColor3 = Color3.fromRGB(240, 245, 255)
			info.TextSize = 13
			info.Font = Enum.Font.GothamMedium
			info.TextXAlignment = Enum.TextXAlignment.Left
			info.Parent = row
			
			local joinBtn = Instance.new("TextButton")
			joinBtn.Size = UDim2.new(0, 75, 0, 30)
			joinBtn.AnchorPoint = Vector2.new(1, 0.5)
			joinBtn.Position = UDim2.new(1, -10, 0.5, 0)
			joinBtn.BackgroundColor3 = Color3.fromRGB(45, 55, 110)
			joinBtn.BackgroundTransparency = 0.1
			joinBtn.Text = "JOIN"
			joinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			joinBtn.Font = Enum.Font.GothamBold
			joinBtn.TextSize = 12
			joinBtn.AutoButtonColor = true
			joinBtn.Parent = row
			
			local btnCorner = Instance.new("UICorner")
			btnCorner.CornerRadius = UDim.new(0, 8)
			btnCorner.Parent = joinBtn
			
			local btnStroke = Instance.new("UIStroke")
			btnStroke.Thickness = 1.2
			btnStroke.Color = Color3.fromRGB(80, 100, 255)
			btnStroke.Parent = joinBtn

			joinBtn.MouseButton1Click:Connect(function()
				U.notify("Joining", "Teleporting to server...", 3)
				S.TeleportService:TeleportToPlaceInstance(game.PlaceId, sv.id, localPlayer)
			end)
		until true
	end
	
	if count == 0 then
		U.notify("Info", "No other public servers available", 2)
	else
		U.notify("Success", "Updated " .. count .. " servers", 1.5)
	end
end

_G.FVKHUB_RefreshServers = refreshServers

local function refreshPlayersListPage()
	if not UI or not UI.playersListContainer then return end
	local searchText = (UI.playersSearchBox and UI.playersSearchBox.Text:lower()) or ""
	
	for _, child in ipairs(UI.playersListContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	for _, player in ipairs(S.Players:GetPlayers()) do
		repeat
			if player == localPlayer then break end
		
		local pName = player.Name:lower()
		local dName = player.DisplayName:lower()
		
		if searchText == "" or pName:find(searchText) or dName:find(searchText) then
			local row = Instance.new("Frame")
			row.Name = "PlayerRow"
			row.Size = UDim2.new(1, -2, 0, 42)
			row.BackgroundColor3 = Color3.fromRGB(30, 34, 52)
			row.BackgroundTransparency = 0.4
			row.BorderSizePixel = 0
			row.Parent = UI.playersListContainer
			
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 8)
			corner.Parent = row
			
			local avatar = Instance.new("ImageLabel")
			avatar.Size = UDim2.new(0, 32, 0, 32)
			avatar.Position = UDim2.new(0, 5, 0.5, -16)
			avatar.BackgroundTransparency = 1
			avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=60&h=60"
			avatar.Parent = row
			
			local nameLab = Instance.new("TextLabel")
			nameLab.Size = UDim2.new(1, -155, 1, 0)
			nameLab.Position = UDim2.new(0, 45, 0, 0)
			nameLab.BackgroundTransparency = 1
			nameLab.Text = player.DisplayName .. " (@" .. player.Name .. ")"
			nameLab.TextColor3 = Color3.fromRGB(240, 245, 255)
			nameLab.Font = Enum.Font.GothamMedium
			nameLab.TextSize = 12
			nameLab.TextXAlignment = Enum.TextXAlignment.Left
			nameLab.Parent = row
			
			local tpBtn = Instance.new("TextButton")
			tpBtn.Size = UDim2.new(0, 50, 0, 26)
			tpBtn.Position = UDim2.new(1, -150, 0.5, -13)
			tpBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 255)
			tpBtn.Text = "TELEPORT"
			tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			tpBtn.Font = Enum.Font.GothamBold
			tpBtn.TextSize = 9
			tpBtn.Parent = row
			local tc = Instance.new("UICorner")
			tc.CornerRadius = UDim.new(0, 6)
			tc.Parent = tpBtn
			
			tpBtn.MouseButton1Click:Connect(function()
				local _, root = U.getHumanoidAndRoot()
				local pChar = player.Character
				local pRoot = pChar and pChar:FindFirstChild("HumanoidRootPart")
				if root and pRoot then
					States.loopTpTarget = nil -- Clear loop if manual TP
					root.CFrame = pRoot.CFrame * CFrame.new(0, 0, 3)
					U.notify("Teleport", "Teleported to " .. player.DisplayName, 2)
				end
			end)
			
			local specBtn = Instance.new("TextButton")
			specBtn.Size = UDim2.new(0, 40, 0, 26)
			specBtn.Position = UDim2.new(1, -95, 0.5, -13)
			specBtn.BackgroundColor3 = Color3.fromRGB(45, 50, 75)
			specBtn.Text = "SPEC"
			specBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			specBtn.Font = Enum.Font.GothamBold
			specBtn.TextSize = 9
			specBtn.Parent = row
			local scCorner = Instance.new("UICorner")
			scCorner.CornerRadius = UDim.new(0, 6)
			scCorner.Parent = specBtn
			
			specBtn.MouseButton1Click:Connect(function()
				toggleSpectate(player)
			end)
			
			local flingBtn = Instance.new("TextButton")
			flingBtn.Size = UDim2.new(0, 45, 0, 26)
			flingBtn.Position = UDim2.new(1, -50, 0.5, -13)
			flingBtn.BackgroundColor3 = (States.teleportFlingTarget == player) and Color3.fromRGB(200, 80, 40) or Color3.fromRGB(255, 60, 60)
			flingBtn.Text = "FLING"
			flingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			flingBtn.Font = Enum.Font.GothamBold
			flingBtn.TextSize = 9
			flingBtn.Parent = row
			local fcCorner = Instance.new("UICorner")
			fcCorner.CornerRadius = UDim.new(0, 6)
			fcCorner.Parent = flingBtn
			
			local invBtn = Instance.new("TextButton")
			invBtn.Size = UDim2.new(0, 35, 0, 26)
			invBtn.Position = UDim2.new(1, -190, 0.5, -13)
			invBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 120)
			invBtn.Text = "INV"
			invBtn.TextColor3 = Color3.fromRGB(240, 245, 255)
			invBtn.Font = Enum.Font.GothamBold
			invBtn.TextSize = 9
			invBtn.Parent = row
			Instance.new("UICorner", invBtn).CornerRadius = UDim.new(0, 6)
			
			invBtn.MouseButton1Click:Connect(function()
				U.showInventoryViewer(player)
			end)
			
			flingBtn.MouseButton1Click:Connect(function()
				if States.teleportFlingTarget == player then
					States.teleportFlingTarget = nil
					States.isTeleportFling = false
					if Refs.connections.flingLoop then Refs.connections.flingLoop:Disconnect() end
					U.notify("Fling", "Stopped flinging", 2)
					task.delay(0.1, refreshPlayersListPage)
				else
					States.teleportFlingTarget = player
					States.isTeleportFling = true
					if Refs.connections.flingLoop then Refs.connections.flingLoop:Disconnect() end
					U.notify("Fling", "Flinging " .. player.DisplayName, 2)
					
					Refs.connections.flingLoop = S.RunService.Heartbeat:Connect(function()
						if not States.isTeleportFling or not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then
							if Refs.connections.flingLoop then Refs.connections.flingLoop:Disconnect() end
							return
						end

						local char = localPlayer.Character
						local myHrp = char.HumanoidRootPart
						local targetChar = player.Character
						local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

						if targetHrp then
							-- Gunakan velocity sangat tinggi untuk mendorong target (Replication friendly)
							myHrp.AssemblyAngularVelocity = Vector3.new(0, 500000, 0)
							myHrp.AssemblyLinearVelocity = Vector3.new(5000, 5000, 5000)
							
							-- Pastikan collisions ON saat fling (untuk menembus noclip)
							pcall(function()
								for _, p in ipairs(char:GetChildren()) do
									if p:IsA("BasePart") then p.CanCollide = true end
								end
							end)

							-- Orbit target dengan jitter untuk memicu deteksi tabrakan
							local xOff = math.random(-80, 80)/100
							local zOff = math.random(-80, 80)/100
							myHrp.CFrame = targetHrp.CFrame * CFrame.new(xOff, 0, zOff) * CFrame.Angles(0, math.rad(tick() * 12000 % 360), 0)
						else
							States.isTeleportFling = false
							States.teleportFlingTarget = nil
							if Refs.connections.flingLoop then Refs.connections.flingLoop:Disconnect() end
						end
					end)

					task.delay(0.1, refreshPlayersListPage)
				end
			end)
		end
		until true
	end
end
_G.FVKHUB_RefreshPlayersList = refreshPlayersListPage

-- Teleport popup logic removed


local function startSpectate(targetPlayer)
	if not targetPlayer or targetPlayer == localPlayer then return end

	local character = targetPlayer.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local camera = workspace.CurrentCamera
	if not camera then return end

	camera.CameraSubject = humanoid
	States.isSpectating = true
	Refs.spectateTarget = targetPlayer
end

local function stopSpectate()
	if not States.isSpectating then
		return
	end

	local character = localPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local camera = workspace.CurrentCamera

	if camera and humanoid then
		camera.CameraSubject = humanoid
	end

	States.isSpectating = false
	Refs.spectateTarget = nil
end

function toggleSpectate(targetPlayer)
	if States.isSpectating then
		stopSpectate()
	else
		startSpectate(targetPlayer)
	end
end

local function toggleFlashSpeed(force)
	if force ~= nil then
		if States.isFlashSpeedEnabled == force then return end
		States.isFlashSpeedEnabled = force
	else
		States.isFlashSpeedEnabled = not States.isFlashSpeedEnabled
	end
	
	if States.isFlashSpeedEnabled then
		local connectionName = "AdminFlashSpeed"
		-- Changed to Camera priority + 1 for ultra-responsive movement sync
		S.RunService:BindToRenderStep(connectionName, Enum.RenderPriority.Camera.Value + 1, function()
			if not States.isFlashSpeedEnabled then
				S.RunService:UnbindFromRenderStep(connectionName)
				return
			end
			local character = localPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			
			if root and humanoid and humanoid.MoveDirection.Magnitude > 0 then
				-- Direct CFrame burst movement
				root.CFrame = root.CFrame + (humanoid.MoveDirection * Config.flashSpeedAmount)
			end
		end)
	else
		pcall(function() S.RunService:UnbindFromRenderStep("AdminFlashSpeed") end)
	end
end

function toggleBackwardsWalk()
	States.isBackwardsWalk = not States.isBackwardsWalk
	
	if States.isBackwardsWalk then
		S.RunService:BindToRenderStep("AdminBackwardsWalk", Enum.RenderPriority.Character.Value + 2, function()
			local currentHum, root = U.getHumanoidAndRoot()
			if not root or not currentHum then return end
			
			local joint = root:FindFirstChild("RootJoint")
			if not joint then
				local lowerTorso = root.Parent:FindFirstChild("LowerTorso")
				if lowerTorso then joint = lowerTorso:FindFirstChild("Root") end
			end
			
			if joint then
				if not Refs.originalJointC0 or Refs.cachedJoint ~= joint then
					Refs.cachedJoint = joint
					Refs.originalJointC0 = joint.C0
				end
				
				-- JANGAN override rotasi visual jika sedang memanjat (Climbing) atau duduk (Seating)
				local state = currentHum:GetState()
				if state == Enum.HumanoidStateType.Climbing or state == Enum.HumanoidStateType.Seated then
					joint.C0 = joint.C0:Lerp(Refs.originalJointC0, 0.4)
					return
				end
				
				joint.C0 = joint.C0:Lerp(CFrame.Angles(0, math.pi, 0) * Refs.originalJointC0, 0.2)
			end
		end)
	else
		pcall(function() S.RunService:UnbindFromRenderStep("AdminBackwardsWalk") end)
		local _, root = U.getHumanoidAndRoot()
		if root then
			local joint = root:FindFirstChild("RootJoint")
			if not joint then
				local lowerTorso = root.Parent:FindFirstChild("LowerTorso")
				if lowerTorso then joint = lowerTorso:FindFirstChild("Root") end
			end
			if joint and Refs.originalJointC0 then
				S.TweenService:Create(joint, TweenInfo.new(0.3), {C0 = Refs.originalJointC0}):Play()
			end
		end
	end

	U.setButtonState(UI.buttons.backwardsWalk, States.isBackwardsWalk)
	U.notifyToggle("Balik Badan", States.isBackwardsWalk)
end

function toggleSpin()
	States.isSpinning = not States.isSpinning
	
	if States.isSpinning then
		Refs.spinAngle = 0
		S.RunService:BindToRenderStep("AdminSpin", Enum.RenderPriority.Character.Value + 3, function(dt)
			local currentHum, root = U.getHumanoidAndRoot()
			if not root or not currentHum then return end
			
			local joint = root:FindFirstChild("RootJoint")
			if not joint then
				local lowerTorso = root.Parent:FindFirstChild("LowerTorso")
				if lowerTorso then joint = lowerTorso:FindFirstChild("Root") end
			end
			
			if joint then
				if not Refs.originalJointC0 or Refs.cachedJoint ~= joint then
					Refs.cachedJoint = joint
					Refs.originalJointC0 = joint.C0
				end
				
				Refs.spinAngle = (Refs.spinAngle + (15 * dt)) % (math.pi * 2)
				joint.C0 = CFrame.Angles(0, Refs.spinAngle, 0) * Refs.originalJointC0
			end
		end)
	else
		pcall(function() S.RunService:UnbindFromRenderStep("AdminSpin") end)
		local _, root = U.getHumanoidAndRoot()
		if root then
			local joint = root:FindFirstChild("RootJoint")
			if not joint then
				local lowerTorso = root.Parent:FindFirstChild("LowerTorso")
				if lowerTorso then joint = lowerTorso:FindFirstChild("Root") end
			end
			if joint and Refs.originalJointC0 then
				S.TweenService:Create(joint, TweenInfo.new(0.3), {C0 = Refs.originalJointC0}):Play()
			end
		end
	end

	if UI.buttons.spin then
		U.setButtonState(UI.buttons.spin, States.isSpinning)
	end
	U.notifyToggle("Spin", States.isSpinning)
end

function toggleSpiderClimb()
	States.isSpiderClimbing = not States.isSpiderClimbing
	
	if States.isSpiderClimbing then
		S.RunService:BindToRenderStep("AdminSpiderClimb", Enum.RenderPriority.Character.Value + 1, function()
			local currentHum, root = U.getHumanoidAndRoot()
			if not root or not currentHum then return end
			
			local lookVec = currentHum.MoveDirection
			if lookVec.Magnitude > 0 then
				local rayParams = RaycastParams.new()
				rayParams.FilterDescendantsInstances = {root.Parent}
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
				rayParams.RespectCanCollide = true
				
				local ray = workspace:Raycast(root.Position, lookVec.Unit * 3, rayParams)
				local bv = root:FindFirstChild("SpiderClimbForce")
				
				if ray and math.abs(ray.Normal.Y) < 0.5 then
					if not bv then
						bv = Instance.new("BodyVelocity")
						bv.Name = "SpiderClimbForce"
						bv.MaxForce = Vector3.new(100000, 100000, 100000)
						bv.Parent = root
					end
					bv.Velocity = Vector3.new(lookVec.X * 5, currentHum.WalkSpeed * 1.5, lookVec.Z * 5)
				else
					if bv then bv:Destroy() end
				end
			else
				local bv = root:FindFirstChild("SpiderClimbForce")
				if bv then bv:Destroy() end
			end
		end)
	else
		pcall(function() S.RunService:UnbindFromRenderStep("AdminSpiderClimb") end)
		local _, root = U.getHumanoidAndRoot()
		if root then
			local bv = root:FindFirstChild("SpiderClimbForce")
			if bv then bv:Destroy() end
		end
	end

	if UI.buttons.spiderClimb then
		U.setButtonState(UI.buttons.spiderClimb, States.isSpiderClimbing)
	end
	U.notifyToggle("Spider Climb", States.isSpiderClimbing)
end


function toggleAirWalk()
	States.isAirWalking = not States.isAirWalking
	if States.isAirWalking then
		if not Refs.airWalkPart then
			Refs.airWalkPart = Instance.new("Part")
			Refs.airWalkPart.Size = Vector3.new(7, 1, 7)
			Refs.airWalkPart.Transparency = 1
			Refs.airWalkPart.Anchored = true
			Refs.airWalkPart.CanCollide = true
			Refs.airWalkPart.Name = "AdminAirWalk"
			Refs.airWalkPart.Parent = workspace
		end
		
		S.RunService:BindToRenderStep("AdminAirWalk", Enum.RenderPriority.Character.Value + 1, function()
			local hum, root = U.getHumanoidAndRoot()
			if root and hum and Refs.airWalkPart then
				local offset = 3
				if hum.RigType == Enum.HumanoidRigType.R15 then
					offset = hum.HipHeight + (root.Size.Y/2)
				else
					offset = 3 -- R6 Default
				end
				Refs.airWalkPart.CFrame = root.CFrame * CFrame.new(0, -(offset + 0.5), 0)
			end
		end)
	else
		pcall(function() S.RunService:UnbindFromRenderStep("AdminAirWalk") end)
		if Refs.airWalkPart then
			Refs.airWalkPart:Destroy()
			Refs.airWalkPart = nil
		end
	end
	
	if UI.buttons.airWalk then
		U.setButtonState(UI.buttons.airWalk, States.isAirWalking)
	end
	U.notifyToggle("Air Walk", States.isAirWalking)
end

function skipCutscene()
	local camera = workspace.CurrentCamera
	local character = localPlayer.Character
	if camera and character then
		-- Reset Camera Properties
		camera.CameraType = Enum.CameraType.Custom
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			camera.CameraSubject = humanoid
		else
			local head = character:FindFirstChild("Head")
			if head then camera.CameraSubject = head end
		end
		
		-- Turn off any visual blur/effects cutscenes often use
		for _, effect in pairs(S.Lighting:GetChildren()) do

			if effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") or effect:IsA("DepthOfFieldEffect") or effect:IsA("BloomEffect") then
				effect.Enabled = false
			end
		end
		
		-- Enable character movement again, in case cutscene anchored them
		if humanoid then
			humanoid.WalkSpeed = Config.walkSpeed
			humanoid.AutoRotate = true
		end
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			root.Anchored = false
		end
		
		-- Force re-enable Leaderstats/CoreGui (except Backpack)
		pcall(function()
			S.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
		end)
	end
	U.notify("Camera Reset", "Cutscene skipped / Camera forced to player", 3)
end

function skipLoadingScreen()
	local playerGui = localPlayer:FindFirstChild("PlayerGui")
	if playerGui then
		for _, gui in pairs(playerGui:GetChildren()) do
			if gui:IsA("ScreenGui") then
				-- Deteksi nama umum GUI loading atau yang menghalangi layar 100%
				local name = string.lower(gui.Name)
				if name:find("load") or name:find("intro") or name:find("start") or name:find("splash") or name:find("blank") or name:find("transition") then
					gui.Enabled = false
				else
					-- Deteksi frame yang menutupi layar besar secara kasar
					for _, frame in pairs(gui:GetChildren()) do
						if (frame:IsA("Frame") or frame:IsA("ImageLabel")) and frame.Size.X.Scale >= 0.9 and frame.Size.Y.Scale >= 0.9 then
							gui.Enabled = false
							break
						end
					end
				end
			end
		end
	end
	
	-- Matikan default loading ui dari Roblox jika nyangkut
	pcall(function() getService("ReplicatedFirst"):RemoveDefaultLoadingScreen() end)

	
	-- Pulihkan pergerakan karakter (seringkali dev freeze karakter pas loading)
	local character = localPlayer.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Config.walkSpeed
			humanoid.AutoRotate = true
		end
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			root.Anchored = false
		end
		
		-- Force re-enable Leaderstats/CoreGui (except Backpack)
		pcall(function()
			S.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
			-- Additional attempt specifically for leaderstats if the above isn't enough
			S.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
		end)
		
		-- Seringkali game menggunakan SetCore untuk menonaktifkan leaderstats secara spesifik
		task.spawn(function()
			for i = 1, 5 do -- Coba beberapa kali karena terkadang didefer oleh game
				pcall(function()
					S.StarterGui:SetCore("TopbarEnabled", true)
				end)
				task.wait(1)
			end
		end)
	end
	
	U.notify("Bypass Loading", "Layar Loading dilewati & Gerak dipulihkan", 3)
end

-- Old bindings removed

-- Update dropdown text jika player keluar
S.Players.PlayerRemoving:Connect(function(player)
	if States.teleportFlingTarget == player then
		States.teleportFlingTarget = nil
		States.isTeleportFling = false
		if Refs.connections.flingLoop then
			Refs.connections.flingLoop:Disconnect()
			Refs.connections.flingLoop = nil
		end
	end
end)

-- Teleport Fling Loop removal point



-- Fling Loop removal point

function toggleFastAntiTraffic()
	States.isFastAntiTraffic = not States.isFastAntiTraffic
	U.notifyToggle("Fast Anti-Traffic", States.isFastAntiTraffic)
	U.saveSettings()
	
	-- Data storage for original properties to allow perfect restoration
	if not Refs.trafficProps then Refs.trafficProps = {} end

	-- Expanded keywords and folders to cover more game systems
	local keywords = {"traffic", "npc", "civilian", "citizen", "bot car", "ai_", "vehicle", "car", "ped", "dummy", "spawned", "bus", "truck", "van", "ai"}
	local trafficFolders = {"Traffic", "NPCs", "Civilian", "Citizens", "Vehicles.Traffic", "CarTraffic", "NPC_Vehicles", "AIVehicles", "AllVehicles", "CityCars", "TrafficSystem", "NPCHandler", "AICars", "TrafficVehicles", "AIBots"}

	local function processPart(v)
		if v:IsA("BasePart") then
			-- SAFETY 1: Filter Self
			if localPlayer.Character and v:IsDescendantOf(localPlayer.Character) then return end
			
			-- SAFETY 2: Filter Current Vehicle
			local char = localPlayer.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local seat = hum and hum.SeatPart
			if seat and v:IsDescendantOf(seat:FindFirstAncestorOfClass("Model") or seat.Parent) then
				return
			end
			
			-- SAFETY 3: Filter Other Players (Avoid accidental ghosting of players)
			for _, p in ipairs(S.Players:GetPlayers()) do
				if p ~= localPlayer and p.Character and v:IsDescendantOf(p.Character) then return end
			end

			-- Save original properties if not already cached
			if not Refs.trafficProps[v] then
				Refs.trafficProps[v] = {
					CanCollide = v.CanCollide,
					CanQuery = v.CanQuery,
					CanTouch = v.CanTouch,
					Transparency = v.Transparency
				}
			end
			
			-- Apply Ghost Mode
			v.CanCollide = false
			v.CanQuery = false
			v.CanTouch = false
			if v.Transparency < 0.5 then
				v.Transparency = 0.5
			end
		end
	end

	local function makeGhost(model)
		if not model then return end
		pcall(function()
			if model:IsA("BasePart") then
				processPart(model)
			end
			for _, v in ipairs(model:GetDescendants()) do
				processPart(v)
			end
		end)
	end

	local function isTrafficObject(inst)
		if not inst then return false end
		local name = inst.Name:lower()
		for _, kw in ipairs(keywords) do
			if name:find(kw) then return true end
		end
		-- Check parent logic
		local p = inst.Parent
		if p and p ~= workspace then
			local pName = p.Name:lower()
			for _, folder in ipairs(trafficFolders) do
				if pName == folder:lower() or pName:find(folder:lower()) then return true end
			end
		end
		return false
	end

	if States.isFastAntiTraffic then
		-- 1. INITIAL DEEP SCAN (Process existing workspace contents)
		task.spawn(function()
			pcall(function()
				for _, v in ipairs(workspace:GetDescendants()) do
					if not States.isFastAntiTraffic then break end
					if v:IsA("Model") or v:IsA("BasePart") then
						if isTrafficObject(v) then
							makeGhost(v)
						end
					end
				end
			end)
		end)

		-- 2. Aggressive Stepped Loop (Mandatory to override per-frame server resets)
		if not Refs.connections.fastAntiTrafficAggressive then
			Refs.connections.fastAntiTrafficAggressive = S.RunService.Stepped:Connect(function()
				if not States.isFastAntiTraffic then return end
				for part, _ in pairs(Refs.trafficProps) do
					pcall(function()
						if part and part.Parent then
							part.CanCollide = false
							part.CanTouch = false
							part.CanQuery = false
							if part.Transparency < 0.5 then
								part.Transparency = 0.5
							end
						else
							Refs.trafficProps[part] = nil
						end
					end)
				end
			end)
		end

		-- 3. Periodic Scanner (Folder-based updates)
		task.spawn(function()
			while States.isFastAntiTraffic and not States.isDestroyed do
				pcall(function()
					for _, name in ipairs(trafficFolders) do
						local folder = workspace:FindFirstChild(name, true)
						if folder then
							for _, v in ipairs(folder:GetChildren()) do
								if not States.isFastAntiTraffic then break end
								makeGhost(v)
							end
						end
					end
				end)
				task.wait(1.5)
			end
		end)
		
		-- 4. Event Listener (Reactive detection for newly spawned traffic)
		if not Refs.connections.fastAntiTraffic then
			Refs.connections.fastAntiTraffic = workspace.DescendantAdded:Connect(function(v)
				if States.isFastAntiTraffic then
					pcall(function()
						if v:IsA("Model") then
							if isTrafficObject(v) then
								task.wait(0.1) -- Quick wait ensures properties are initialized by game
								makeGhost(v)
							end
						elseif v:IsA("BasePart") then
							if isTrafficObject(v) or (v.Parent and isTrafficObject(v.Parent)) then
								processPart(v)
							end
						end
					end)
				end
			end)
		end
	else
		-- DEACTIVATE: Restore all modified parts to their original state
		if Refs.connections.fastAntiTraffic then
			Refs.connections.fastAntiTraffic:Disconnect()
			Refs.connections.fastAntiTraffic = nil
		end
		if Refs.connections.fastAntiTrafficAggressive then
			Refs.connections.fastAntiTrafficAggressive:Disconnect()
			Refs.connections.fastAntiTrafficAggressive = nil
		end
		
		pcall(function()
			for part, props in pairs(Refs.trafficProps) do
				if part and part.Parent then
					part.CanCollide = props.CanCollide
					part.CanQuery = props.CanQuery
					part.CanTouch = props.CanTouch
					part.Transparency = props.Transparency
				end
			end
			table.clear(Refs.trafficProps)
		end)
	end
	
	if UI.buttons and UI.buttons.fastAntiTraffic then
		U.setButtonState(UI.buttons.fastAntiTraffic, States.isFastAntiTraffic)
	end
end

-- AntiLandslide logic removed

---------------------------------------------------------------------


local function toggleNonCollideParts()
	local character = localPlayer.Character
	if not States.isRemoveNCActive then
		-- Inisialisasi storage tersembunyi jika belum ada (CoreGui for stealth, fallback to ReplicatedStorage)
		if not Refs.ncStorage then
			Refs.ncStorage = Instance.new("Folder")
			Refs.ncStorage.Name = "temp_nc_storage_" .. randomName()
			pcall(function() Refs.ncStorage.Parent = E.gethui and E.gethui() or S.ReplicatedStorage end)
		end

		table.clear(Refs.removedNonCollideParts)
		States.isRemoveNCActive = true

		local function processPart(part)
			if not States.isRemoveNCActive then return end
			if part:IsA("BasePart") and part.CanCollide == false and not part:IsA("Terrain") then
				-- SAFETY: Abaikan Trigger Zone, Senjata/Tools, dan Proximity Prompt
				if part:FindFirstChildOfClass("TouchInterest") or part:FindFirstChildOfClass("ProximityPrompt") then return end
				-- Safety: Jangan hapus bagian tubuh karakter sendiri
				if character and part:IsDescendantOf(character) then return end
				
				-- Safety: Jangan hapus bagian tubuh player lain
				for _, p in ipairs(S.Players:GetPlayers()) do
					if p.Character and part:IsDescendantOf(p.Character) then return end
				end

				local originalParent = part.Parent
				if originalParent and originalParent ~= Refs.ncStorage then
					table.insert(Refs.removedNonCollideParts, {part = part, parent = originalParent})
					-- Pindahkan ke storage agar tidak mengganggu workspace tapi tetap ada di memory
					part.Parent = Refs.ncStorage
				end
			end
		end

		-- Scan awal Map (Gunakan throttled processing agar tidak LAG di map besar)
		task.spawn(function()
			local allDescendants = workspace:GetDescendants()
			local count = 0
			for i, inst in ipairs(allDescendants) do
				processPart(inst)
				count = count + 1
				-- Throttle: setiap 500 objek, tunggu 1 frame agar engine tetap smooth
				if count % 500 == 0 then task.wait() end
			end
			U.notify("Remove NC", "Map processed. Sensitized triggers ignored.", 2, "Success")
		end)

		-- Koneksi untuk objek baru yang di-spawn game secara dinamis
		if Refs.connections.removeNCConn then Refs.connections.removeNCConn:Disconnect() end
		Refs.connections.removeNCConn = workspace.DescendantAdded:Connect(function(inst)
			task.defer(processPart, inst)
		end)

	else
		-- RESTORE MODE
		States.isRemoveNCActive = false
		if Refs.connections.removeNCConn then
			Refs.connections.removeNCConn:Disconnect()
			Refs.connections.removeNCConn = nil
		end

		local restoredCount = 0
		for _, data in ipairs(Refs.removedNonCollideParts) do
			if data.part and data.parent then
				pcall(function() 
					data.part.Parent = data.parent 
					restoredCount = restoredCount + 1
				end)
			end
		end

		table.clear(Refs.removedNonCollideParts)
		U.notify("Remove NC", "Restored " .. restoredCount .. " objects to original positions.", 2, "Info")
	end
end

-- (Redundant locals removed, moved to Config/States/Refs tables)

---------------------------------------------------------------------
-- Utility Functions Reference

local function applyMovementStats(humanoid)
	if not humanoid then return end
	
	-- Tentukan base speed: Gunakan Config.walkSpeed jika override aktif, jika tidak ikuti default game
	local baseWalk = (States.isWalkOverride or States.isWalkBoost) and Config.walkSpeed or Config.defaultWalkSpeedFromCharacter
	local targetWalk = baseWalk
	
	if States.isWalkBoost then
		targetWalk = targetWalk * Config.walkBoostMultiplier
	end

	local targetJump = Config.baseJumpPower
	-- Jump Multiplier dipakai kalau:
	-- - Jump Boost ON, atau
	-- - Spam Jump (infinite jump) ON
	if States.isJumpBoost or States.isJumpSpam then
		targetJump = Config.baseJumpPower * Config.jumpBoostMultiplier
	end
	
	-- Unlock Jump: Force a minimum jump if the game set it to 0
	if States.isUnlockJump and targetJump <= 0 then
		targetJump = 50 -- Standard Roblox jump power
	end

	humanoid.WalkSpeed = targetWalk
	-- Catatan: ClimbSpeed bukan property valid di Humanoid Roblox
	-- Dukungan untuk model jump baru (JumpHeight) dan lama (JumpPower)
	if humanoid.UseJumpPower ~= nil and humanoid.UseJumpPower == false then
		-- Engine pakai JumpHeight
		humanoid.JumpHeight = targetJump
	else
		humanoid.JumpPower = targetJump
	end
end

---------------------------------------------------------------------
-- ANTI MOVEMENT DELAY
---------------------------------------------------------------------

local function toggleUnlockJump()
	States.isUnlockJump = not States.isUnlockJump
	local h, _ = U.getHumanoidAndRoot()
	if h then applyMovementStats(h) end
end

local function enableAntiMovementDelay()
	if States.isAntiMovementDelay then return end
	States.isAntiMovementDelay = true

	-- Network & physics settings (bonus, tidak selalu efektif tergantung executor)
	pcall(function()
		settings().Network.IncomingReplicationLag = 0
		settings().Physics.AllowSleep = false
		localPlayer.MaximumSimulationRadius = math.huge
		localPlayer.SimulationRadius = math.huge
	end)
	pcall(function()
		if E.sethiddenproperty then
			E.sethiddenproperty(localPlayer, "SimulationRadius", math.huge)
			E.sethiddenproperty(localPlayer, "MaximumSimulationRadius", math.huge)
		end
	end)

	-- === TEKNIK UTAMA ===
	-- BindToRenderStep di priority Input+1 (sebelum physics step)
	-- Membaca IsKeyDown langsung (tanpa event queue) dan push humanoid:Move()
	-- Ini memotong 1 frame dari input pipeline Roblox:
	--   Normal: Input Event → [next frame] Heartbeat → Physics → Render
	--   Anti Delay: RenderStep(Input+1) → Physics → Render   ← 1 frame lebih cepat
	S.RunService:BindToRenderStep("AdminAntiMovDelay", Enum.RenderPriority.Input.Value + 1, function()
		if not States.isAntiMovementDelay then return end

		-- Ignore if other movement-overriding features are active
		if States.isFlying or States.isPlayingPath or States.isAutoWalk
			or States.isFreecamEnabled or States.isSpectating then
			return
		end

		local char = localPlayer.Character
		if not char then return end

		local hum = char:FindFirstChildOfClass("Humanoid")
		local root = char:FindFirstChild("HumanoidRootPart")
		if not hum or not root or hum.Health <= 0 or hum.Sit then return end

		local camera = workspace.CurrentCamera
		if not camera then return end

		-- Full input support (WASD + Arrows + Gamepad)
		local moveX, moveZ = 0, 0
		
		-- Keyboard
		if S.UserInputService:IsKeyDown(Enum.KeyCode.W) or S.UserInputService:IsKeyDown(Enum.KeyCode.Up) then moveZ = moveZ + 1 end
		if S.UserInputService:IsKeyDown(Enum.KeyCode.S) or S.UserInputService:IsKeyDown(Enum.KeyCode.Down) then moveZ = moveZ - 1 end
		if S.UserInputService:IsKeyDown(Enum.KeyCode.A) or S.UserInputService:IsKeyDown(Enum.KeyCode.Left) then moveX = moveX - 1 end
		if S.UserInputService:IsKeyDown(Enum.KeyCode.D) or S.UserInputService:IsKeyDown(Enum.KeyCode.Right) then moveX = moveX + 1 end

		-- Gamepad (Throttled for drift)
		local gamepads = S.UserInputService:GetConnectedGamepads()
		if #gamepads > 0 then
			local state = S.UserInputService:GetGamepadState(gamepads[1])
			for _, input in ipairs(state) do
				if input.KeyCode == Enum.KeyCode.Thumbstick1 then
					local pos = input.Position
					if pos.Magnitude > 0.15 then -- Deadzone
						moveX = moveX + pos.X
						moveZ = moveZ + pos.Y
					end
				end
			end
		end

		if moveX == 0 and moveZ == 0 then return end

		-- Calculate movement relative to camera
		local cameraCF = camera.CFrame
		local moveVector = (cameraCF.RightVector * moveX + cameraCF.LookVector * moveZ)
		local moveDir = Vector3.new(moveVector.X, 0, moveVector.Z) -- Keep it horizontal

		if moveDir.Magnitude > 0.01 then
			-- Push movement immediately to avoid Roblox's internal input queue delay
			hum:Move(moveDir.Unit, false)
			
			-- OPTIONAL: Tiny velocity nudge to force physics engine wake-up
			if root.AssemblyLinearVelocity.Magnitude < 0.1 then
				root.AssemblyLinearVelocity = moveDir.Unit * 0.1
			end
		end
	end)
end

local function disableAntiMovementDelay()
	if not States.isAntiMovementDelay then return end
	States.isAntiMovementDelay = false

	-- Hentikan RenderStep override
	pcall(function()
		S.RunService:UnbindFromRenderStep("AdminAntiMovDelay")
	end)

	-- Disconnect Heartbeat jika ada sisa (legacy guard)
	if Refs.connections.antiDelayConn then
		Refs.connections.antiDelayConn:Disconnect()
		Refs.connections.antiDelayConn = nil
	end

	-- Restore semua setting ke default Roblox
	pcall(function()
		localPlayer.MaximumSimulationRadius = 1000
		localPlayer.SimulationRadius = 100
		if E.sethiddenproperty then
			E.sethiddenproperty(localPlayer, "SimulationRadius", 100)
			E.sethiddenproperty(localPlayer, "MaximumSimulationRadius", 1000)
		end
	end)
end

local function toggleAntiMovementDelay()
	if States.isAntiMovementDelay then
		disableAntiMovementDelay()
	else
		enableAntiMovementDelay()
	end
end

---------------------------------------------------------------------
-- AUTO WALK SMOOTH
---------------------------------------------------------------------

local function toggleAutoWalk()
	States.isAutoWalk = not States.isAutoWalk
	U.notifyToggle("Auto Walk Smooth", States.isAutoWalk)
	U.saveSettings()

	if States.isAutoWalk then
		-- BindToRenderStep di Character priority — sync dengan physics step
		-- Dengan AutoRotate = true, Roblox handle rotasi + animasi kaki otomatis
		-- Kita cukup feed arah forward ke humanoid:Move() setiap frame
		S.RunService:BindToRenderStep("AdminAutoWalk", Enum.RenderPriority.Character.Value, function()
			if not States.isAutoWalk or States.isDestroyed then
				S.RunService:UnbindFromRenderStep("AdminAutoWalk")
				return
			end

			local char = localPlayer.Character
			if not char then return end

			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if not humanoid or humanoid.Health <= 0 or humanoid.Sit then return end

			-- Pastikan AutoRotate aktif — biarkan engine Roblox rotate karakter
			-- Ini yang memastikan animasi kaki sesuai dengan arah gerak
			if not humanoid.AutoRotate then
				humanoid.AutoRotate = true
			end

			-- Hitung arah maju berdasarkan camera (flat horizontal)
			local camera = workspace.CurrentCamera
			local dirUnit

			if camera then
				local camLook = camera.CFrame.LookVector
				local flatDir = Vector3.new(camLook.X, 0, camLook.Z)
				if flatDir.Magnitude > 0.01 then
					dirUnit = flatDir.Unit
				end
			end

			if not dirUnit then
				-- Fallback: maju relatif ke karakter (character-space)
				humanoid:Move(Vector3.new(0, 0, -1), true)
				return
			end

			-- Feed ke humanoid — engine otomatis rotate karakter ke arah ini
			-- dan Animate script mendeteksi MoveDirection → animasi berjalan natural
			humanoid:Move(dirUnit, false)
		end)

	else
		-- Stop
		pcall(function()
			S.RunService:UnbindFromRenderStep("AdminAutoWalk")
		end)

		local char = localPlayer.Character
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.AutoRotate = true
			humanoid:Move(Vector3.zero, false)
		end
	end
end

---------------------------------------------------------------------
-- PATH RECORD & PLAYBACK
---------------------------------------------------------------------

function U.clearPathVisuals()
	if UI.pathVisualFolder then
		UI.pathVisualFolder:ClearAllChildren()
	end
end

function U.updatePathVisualization()
	U.clearPathVisuals()
	if not States.isPathVisualized or #States.recordedPath < 2 then return end
	
	if not UI.pathVisualFolder then
		local f = Instance.new("Folder")
		f.Name = "AdminPathVisuals"
		f.Parent = workspace
		UI.pathVisualFolder = f
	end
	
	for i = 1, #States.recordedPath - 1 do 
		local p1 = States.recordedPath[i].cf.Position
		local nextIdx = i + 1
		local p2 = States.recordedPath[nextIdx].cf.Position
		
		local dist = (p1 - p2).Magnitude
		if dist > 0.5 then
			local part = Instance.new("Part")
			part.Size = Vector3.new(0.4, 0.4, dist)
			part.CFrame = CFrame.lookAt(p1:Lerp(p2, 0.5), p2)
			part.Anchored = true
			part.CanCollide = false
			part.Material = Enum.Material.Neon
			part.Color = Color3.fromRGB(60, 100, 255)
			part.Transparency = 0.5
			part.Parent = UI.pathVisualFolder
		end
	end
end

function U.togglePathRecordPause()
	if not States.isRecordingPath then return end
	States.isRecordingPathPaused = not States.isRecordingPathPaused
	U.notify("Record", States.isRecordingPathPaused and "Paused" or "Resumed", 1.5)
	U.setButtonState(UI.buttons.pauseRecord, States.isRecordingPathPaused)
end

function U.togglePathRecord()
	if States.isRecordingDebounce then return end
	States.isRecordingDebounce = true
	task.delay(0.5, function() States.isRecordingDebounce = false end)

	States.isRecordingPath = not States.isRecordingPath
	U.notifyToggle("Path Recording", States.isRecordingPath)
	U.setButtonState(UI.buttons.recordPath, States.isRecordingPath)
	
	if States.isRecordingPath then
		States.isRecordingPathPaused = false
		U.setButtonState(UI.buttons.pauseRecord, false)
		States.lastRecordTick = nil -- RESET TIMER START
		
		-- Resume logic: if we are at some playback point, trim the path before starting
		if #States.recordedPath > 0 and States.playbackProgress < #States.recordedPath then
			local trimIndex = math.floor(States.playbackProgress)
			local newPath = {}
			for i = 1, trimIndex do
				table.insert(newPath, States.recordedPath[i])
			end
			States.recordedPath = newPath
			U.notify("Path Trimmed", "Recording from index " .. trimIndex, 2)
			U.updatePathVisualization()
		elseif #States.recordedPath == 0 then
			States.playbackProgress = 0
		end
		
		-- Also ensure playback is OFF
		if States.isPlayingPath then
			States.isPlayingPath = false
			U.setButtonState(UI.buttons.playPath, false)
		end
		
		task.spawn(function()
			while States.isRecordingPath and not States.isDestroyed do
				if not States.isRecordingPathPaused then
					local humanoid, root = U.getHumanoidAndRoot()
					if root and humanoid then
						local anims = {}
						for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
							if track.Animation then
								table.insert(anims, {
									id = track.Animation.AnimationId,
									time = track.TimePosition,
									speed = track.Speed,
									weight = track.WeightTarget
								})
							end
						end
						
						local currentTime = tick()
						local dtPoint = States.lastRecordTick and (currentTime - States.lastRecordTick) or (1/120)
						States.lastRecordTick = currentTime

						table.insert(States.recordedPath, {
							cf = root.CFrame,
							anims = anims,
							dt = dtPoint -- Simpan jeda asli per titik (120Hz target)
						})
						States.playbackProgress = #States.recordedPath
						
						-- Real-time visualization update (120 FPS)
						if States.isPathVisualized then
							U.updatePathVisualization()
						end
					end
				end
				task.wait(1/120) -- 120 FPS Target Record
			end
		end)

	else
		U.notify("Recording Stopped", #States.recordedPath .. " points total", 2)
	end
end

function U.togglePathVisualize()
	States.isPathVisualized = not States.isPathVisualized
	U.notify("Path Visuals", States.isPathVisualized and "Enabled" or "Disabled", 1.5)
	if States.isPathVisualized then
		U.updatePathVisualization()
	else
		U.clearPathVisuals()
	end
	U.saveSettings()
end

function U.undoPathRecord(count)
	count = count or 1
	if #States.recordedPath > 0 then
		for i = 1, count do
			if #States.recordedPath > 0 then
				table.remove(States.recordedPath, #States.recordedPath)
			end
		end
		
		-- Teleport character back to the new last point
		local _, r = U.getHumanoidAndRoot()
		if r and #States.recordedPath > 0 then
			local lastData = States.recordedPath[#States.recordedPath]
			r.CFrame = lastData.cf
		end
		
		U.notify("Undo", "Removed " .. count .. " points & teleported back", 1.5)
		U.updatePathVisualization()
	end
end

function U.clearPathRecord()
	States.recordedPath = {}
	U.clearPathVisuals()
	U.notify("Cleared", "Recording path reset", 1.5)
end

function U.togglePathPause()
	if not States.isPlayingPath then return end
	States.isPathPlaybackPaused = not States.isPathPlaybackPaused
	U.notify("Playback", States.isPathPlaybackPaused and "Paused" or "Resumed", 1.5)
	U.setButtonState(UI.buttons.pausePath, States.isPathPlaybackPaused)
	if UI.buttons.pausePath then
		UI.buttons.pausePath.Text = States.isPathPlaybackPaused and "▶ Resume" or "|| Pause"
	end
end

function U.setPathDirection(dir)
	if States.isPlayingPath and not States.isPathPlaybackPaused then
		-- Let's change this to ALSO allow skipping during playback
		States.pathPlaybackDirection = dir
		local jumpStep = 10 * dir
		local nextProgress = math.clamp(States.playbackProgress + jumpStep, 1, #States.recordedPath)
		States.playbackProgress = nextProgress
		
		U.notify("Checkpoint", (dir == 1 and "Skipped > " or "Skipped < ") .. math.floor(nextProgress), 1)
		U.setButtonState(UI.buttons.forwardPath, dir == 1)
		U.setButtonState(UI.buttons.backwardPath, dir == -1)
	else
		-- Manual Scrubbing / Checkpoint when paused/stopped
		if #States.recordedPath == 0 then return end
		local jumpStep = 5 * dir
		local nextProgress = math.clamp(States.playbackProgress + jumpStep, 1, #States.recordedPath)
		States.playbackProgress = nextProgress
		
		local h, r = U.getHumanoidAndRoot()
		if r then
			r.Anchored = true
			r.CFrame = States.recordedPath[math.floor(nextProgress)].cf
			if not States.isPlayingPath then r.Anchored = false end
		end
		U.notify("Checkpoint", "Point " .. math.floor(nextProgress) .. "/" .. #States.recordedPath, 1)
	end
end


function U.togglePathPlayback()
	if States.isRecordingPath then
		U.notify("Error", "Stop recording first!", 2)
		return
	end
	
	if #States.recordedPath < 2 then
		U.notify("Error", "Path too short to play! (Need 2+ points)", 2)
		return
	end
	
	States.isPlayingPath = not States.isPlayingPath
	U.notifyToggle("Path Playback", States.isPlayingPath)
	U.setButtonState(UI.buttons.playPath, States.isPlayingPath)
	
	if States.isPlayingPath then
		States.isPathPlaybackPaused = false
		States.pathPlaybackDirection = 1
		
		-- Reset logic: Start from beginning if at end
		if #States.recordedPath > 0 then
			if States.playbackProgress >= #States.recordedPath then
				States.playbackProgress = 1
			elseif States.playbackProgress <= 1 and States.pathPlaybackDirection == -1 then
				States.playbackProgress = #States.recordedPath
			end
		end

		U.setButtonState(UI.buttons.pausePath, false)
		U.setButtonState(UI.buttons.forwardPath, true)
		U.setButtonState(UI.buttons.backwardPath, false)

		task.spawn(function()
			local pathCount = #States.recordedPath
			local connectionName = "AdminPathPlayback_" .. randomName()
			S.RunService:BindToRenderStep(connectionName, Enum.RenderPriority.Camera.Value - 1, function(dt)
				if not States.isPlayingPath or States.isDestroyed then
					S.RunService:UnbindFromRenderStep(connectionName)
					return
				end
				if not States.isPathPlaybackPaused then
					local currentIdx = math.floor(States.playbackProgress)
					local currentPoint = States.recordedPath[currentIdx]
					local stepInterval = (currentPoint and currentPoint.dt) or (1/120)
					States.playbackProgress = States.playbackProgress + (dt / stepInterval) * States.pathPlaybackDirection
					if States.pathPlaybackDirection == 1 then
						if States.playbackProgress >= pathCount then
							if States.isPathLooping then
								States.playbackProgress = 1
							else
								States.playbackProgress = pathCount
								States.isPlayingPath = false
								U.notify("Playback", "Finished (End)", 1.5)
							end
						end
					else
						if States.playbackProgress <= 1 then
							if States.isPathLooping then
								States.playbackProgress = pathCount
							else
								States.playbackProgress = 1
								States.isPlayingPath = false
								U.notify("Playback", "Finished (Start)", 1.5)
							end
						end
					end
				end
				local index = math.floor(States.playbackProgress)
				local alpha = States.playbackProgress % 1
				local data = States.recordedPath[index]
				local nextIndex = math.min(index + 1, pathCount)
				local nextData = States.recordedPath[nextIndex]
				if not data or not nextData then return end
				local currentHum, currentRoot = U.getHumanoidAndRoot()
				if currentRoot and currentHum then
					currentRoot.CFrame = data.cf:Lerp(nextData.cf, alpha)
					local moveVec = nextData.cf.Position - data.cf.Position
					local currentStepInterval = math.max(data.dt or (1/120), 1/240)
					local flatMoveVec = Vector3.new(moveVec.X, 0, moveVec.Z)
					if not States.isPathPlaybackPaused and flatMoveVec.Magnitude > 0.005 then
						local targetMoveDir = flatMoveVec.Unit
						States.lastPlaybackDir = States.lastPlaybackDir or targetMoveDir
						States.lastPlaybackDir = States.lastPlaybackDir:Lerp(targetMoveDir, 0.2)
						currentHum:Move(States.lastPlaybackDir, false)
						local targetSpeed = flatMoveVec.Magnitude / currentStepInterval
						local currentVel = currentRoot.AssemblyLinearVelocity
						local targetVel = Vector3.new(
							States.lastPlaybackDir.X * targetSpeed,
							currentVel.Y,
							States.lastPlaybackDir.Z * targetSpeed
						)
						currentRoot.AssemblyLinearVelocity = currentVel:Lerp(targetVel, 0.5)
					else
						currentHum:Move(Vector3.zero, false)
						States.lastPlaybackDir = nil
						currentRoot.AssemblyLinearVelocity = Vector3.new(0, currentRoot.AssemblyLinearVelocity.Y, 0)
					end
					local recordedDeltaY = moveVec.Y
					local hState = currentHum:GetState()
					if recordedDeltaY > 0.3 then
						if hState ~= Enum.HumanoidStateType.Jumping then
							currentHum:ChangeState(Enum.HumanoidStateType.Jumping)
						end
					elseif recordedDeltaY < -0.3 then
						if hState ~= Enum.HumanoidStateType.Freefall then
							currentHum:ChangeState(Enum.HumanoidStateType.Freefall)
						end
					else
						if hState == Enum.HumanoidStateType.Freefall or hState == Enum.HumanoidStateType.Jumping then
							currentHum:ChangeState(Enum.HumanoidStateType.Running)
						end
					end
				end
			end)
			while States.isPlayingPath and not States.isDestroyed do task.wait(0.5) end
			S.RunService:UnbindFromRenderStep(connectionName)
			task.wait()
			local hClean, rClean = U.getHumanoidAndRoot()
			if rClean then
				rClean.AssemblyLinearVelocity = Vector3.zero
				rClean.AssemblyAngularVelocity = Vector3.zero
				rClean.Anchored = false
			end
			if hClean then
				local st = hClean:GetState()
				if st == Enum.HumanoidStateType.Jumping or st == Enum.HumanoidStateType.Freefall or st == Enum.HumanoidStateType.Physics then
					hClean:ChangeState(Enum.HumanoidStateType.GettingUp)
				end
			end
			States.isPlayingPath = false
			U.setButtonState(UI.buttons.playPath, false)
			U.setButtonState(UI.buttons.pausePath, false)
			U.setButtonState(UI.buttons.forwardPath, false)
			U.setButtonState(UI.buttons.backwardPath, false)
		end)
	else
		local h, r = U.getHumanoidAndRoot()
		if r then
			r.AssemblyLinearVelocity = Vector3.zero
			r.AssemblyAngularVelocity = Vector3.zero
			r.Anchored = false
		end
		if h then
			local st = h:GetState()
			if st == Enum.HumanoidStateType.Jumping or st == Enum.HumanoidStateType.Freefall or st == Enum.HumanoidStateType.Physics then
				h:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end
		local animScript = localPlayer.Character and localPlayer.Character:FindFirstChild("Animate")
		if animScript then animScript.Disabled = false end
	end
end


function U.refreshPathFileList()
	if not E.listfiles or not E.isfolder then return end
	if not UI.pathFileList then return end
	for _, child in ipairs(UI.pathFileList:GetChildren()) do
		if child:IsA("GuiObject") and child.Name ~= "UIListLayout" and child.Name ~= "UIPadding" then
			child:Destroy()
		end
	end
	if not E.isfolder("FVKHUB_Data/Paths") then return end
	local files = E.listfiles("FVKHUB_Data/Paths")
	for _, fullPath in ipairs(files) do
		repeat
		local fileName = fullPath:match("([^/\\]+)$") or fullPath
		if not fileName:match("%.json$") then break end
		
		local row = Instance.new("Frame")
		row.Name = "FileRow"
		row.Size = UDim2.new(1, 0, 0, 26)
		row.BackgroundTransparency = 1
		row.Parent = UI.pathFileList
		
		local btn = Instance.new("TextButton")
		btn.Name = fileName
		btn.Size = UDim2.new(0.85, -2, 1, 0)
		btn.BackgroundColor3 = Color3.fromRGB(35, 40, 60)
		btn.BorderSizePixel = 0
		btn.Text = "📁 " .. fileName
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 11
		btn.TextColor3 = Color3.fromRGB(140, 150, 180)
		btn.Parent = row
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
		btn.MouseButton1Click:Connect(function()
			U.loadPathFromSpecificFile(fileName)
		end)

		local del = Instance.new("TextButton")
		del.Size = UDim2.new(0.15, -2, 1, 0)
		del.Position = UDim2.new(0.85, 2, 0, 0)
		del.BackgroundColor3 = Color3.fromRGB(70, 35, 35)
		del.Text = "X"
		del.Font = Enum.Font.GothamBold
		del.TextSize = 10
		del.TextColor3 = Color3.fromRGB(255, 120, 120)
		del.Parent = row
		Instance.new("UICorner", del).CornerRadius = UDim.new(0, 6)
		del.MouseButton1Click:Connect(function()
			U.deleteFile("FVKHUB_Data/Paths/" .. fileName, U.refreshPathFileList)
		end)
		until true
	end
end

function U.deleteFile(path, refreshFunc)
	if not E.delfile then
		U.notify("Error", "Executor doesn't support delfile", 2)
		return
	end
	local success, result = pcall(function() E.delfile(path) end)
	if success then
		U.notify("Deleted", path:match("([^/\\]+)$") or path, 2)
		if refreshFunc then refreshFunc() end
	else
		U.notify("Error", "Failed to delete: " .. tostring(result), 3)
	end
end

function U.savePathToFile()
	if #States.recordedPath == 0 then
		U.notify("Error", "No path recorded to save!", 2)
		return
	end
	local fileName = (UI.pathNameInput and UI.pathNameInput.Text ~= "" and UI.pathNameInput.Text) or "recorded_path"
	if not fileName:match("%.json$") then fileName = fileName .. ".json" end
	local success, result = pcall(function()
		local dataToSync = {}
		for _, point in ipairs(States.recordedPath) do
			local x, y, z, r10, r11, r12, r20, r21, r22, r30, r31, r32 = point.cf:GetComponents()
			table.insert(dataToSync, {
				cf = {x, y, z, r10, r11, r12, r20, r21, r22, r30, r31, r32},
				anims = point.anims
			})
		end
		local json = S.HttpService:JSONEncode(dataToSync)
		if E.writefile then
			if E.makefolder then
				if E.isfolder and not E.isfolder("FVKHUB_Data") then E.makefolder("FVKHUB_Data") end
				if E.isfolder and not E.isfolder("FVKHUB_Data/Paths") then E.makefolder("FVKHUB_Data/Paths") end
			end
			local fullPath = "FVKHUB_Data/Paths/" .. fileName
			E.writefile(fullPath, json)
			U.notify("Success", "Path exported to " .. fullPath, 3)
			U.refreshPathFileList()
		end
	end)
	if not success then U.notify("Error", "Failed to save path: " .. tostring(result), 3) end
end

function U.loadPathFromSpecificFile(fileName)
	if not fileName:match("%.json$") then fileName = fileName .. ".json" end
	local fullPath = "FVKHUB_Data/Paths/" .. fileName
	local success, result = pcall(function()
		if not E.readfile then return false, "Executor does not support E.readfile!" end
		if E.isfile and not E.isfile(fullPath) then return false, "No file found: " .. fullPath end
		local json = E.readfile(fullPath)
		local data = S.HttpService:JSONDecode(json)
		local newPath = {}
		for _, point in ipairs(data) do
			table.insert(newPath, {
				cf = CFrame.new(unpack(point.cf)),
				anims = point.anims
			})
		end
		States.recordedPath = newPath
		U.notify("Success", "Loaded " .. #States.recordedPath .. " points from " .. fileName, 3)
		if States.isPathVisualized then U.updatePathVisualization() end
		return true
	end)
	if not success or (typeof(result) == "string") then U.notify("Error", tostring(result), 3) end
end

function U.stopPathPlayback()
	States.isPlayingPath = false
	States.playbackProgress = 1
	States.isPathPlaybackPaused = false
	U.notify("Playback", "Stopped", 2)
	U.setButtonState(UI.buttons.playPath, false)
	U.setButtonState(UI.buttons.pausePath, false)
	if UI.buttons.pausePath then UI.buttons.pausePath.Text = "|| Pause" end
	U.setButtonState(UI.buttons.forwardPath, false)
	U.setButtonState(UI.buttons.backwardPath, false)
end

function U.loadPathFromFile()
	local fileName = (UI.pathNameInput and UI.pathNameInput.Text ~= "" and UI.pathNameInput.Text) or "recorded_path.json"
	U.loadPathFromSpecificFile(fileName)
end

-- WAYPOINT FUNCTIONS
-- WAYPOINT FUNCTIONS (dengan fitur resume dari waypoint tertentu)

function U.refreshWaypointListUI()
	if not UI.waypointListUI then 
		print("ERROR: UI.waypointListUI is nil in refreshWaypointListUI")
		return 
	end
	
	for _, child in ipairs(UI.waypointListUI:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	for i, wp in ipairs(States.waypoints) do
		local row = Instance.new("Frame")
		row.Name = "WaypointRow"
		row.Size = UDim2.new(1, 0, 0, 32)
		row.BackgroundTransparency = 1
		row.Parent = UI.waypointListUI
		
		-- [REORGANIZED LAYOUT]
		-- Label: 0.3 | GO: 0.15 | START: 0.15 | DEL: 0.15 | LOOP: 0.15 | Ind: 0.1
		
		-- Label nama waypoint
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.3, -5, 1, 0)
		label.Position = UDim2.new(0, 5, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = "[" .. i .. "] " .. wp.name
		label.TextColor3 = Color3.fromRGB(240, 245, 255)
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 11
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = row
		
		-- Tombol GO (Teleport)
		local tp = Instance.new("TextButton")
		tp.Size = UDim2.new(0.15, -2, 1, -4)
		tp.Position = UDim2.new(0.3, 2, 0, 2)
		tp.BackgroundColor3 = Color3.fromRGB(60, 100, 255)
		tp.Text = "GO"
		tp.Font = Enum.Font.GothamBold
		tp.TextSize = 9
		tp.TextColor3 = Color3.new(1, 1, 1)
		tp.Parent = row
		Instance.new("UICorner", tp).CornerRadius = UDim.new(0, 4)
		
		tp.MouseButton1Click:Connect(function()
			local _, root = U.getHumanoidAndRoot()
			if root then 
				root.CFrame = wp.cf
				U.notify("Teleport", "Teleport ke: " .. wp.name, 2)
			end
		end)
		
		-- Tombol SET START
		local setStart = Instance.new("TextButton")
		setStart.Size = UDim2.new(0.15, -2, 1, -4)
		setStart.Position = UDim2.new(0.45, 2, 0, 2)
		setStart.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
		setStart.Text = "START"
		setStart.Font = Enum.Font.GothamBold
		setStart.TextSize = 8
		setStart.TextColor3 = Color3.new(1, 1, 1)
		setStart.Parent = row
		Instance.new("UICorner", setStart).CornerRadius = UDim.new(0, 4)
		
		setStart.MouseButton1Click:Connect(function()
			States.autoTeleportIndex = i
			U.notify("Start Point", "Auto teleport akan mulai dari: " .. wp.name, 2)
			U.refreshWaypointListUI()
		end)
		
		-- Tombol DEL (Hapus)
		local del = Instance.new("TextButton")
		del.Size = UDim2.new(0.15, -2, 1, -4)
		del.Position = UDim2.new(0.6, 2, 0, 2)
		del.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
		del.Text = "DEL"
		del.Font = Enum.Font.GothamBold
		del.TextSize = 9
		del.TextColor3 = Color3.new(1, 1, 1)
		del.Parent = row
		Instance.new("UICorner", del).CornerRadius = UDim.new(0, 4)
		
		del.MouseButton1Click:Connect(function()
			table.remove(States.waypoints, i)
			if States.loopWaypointTarget == wp then States.loopWaypointTarget = nil end
			-- Jika index yang dihapus lebih kecil dari autoTeleportIndex, sesuaikan
			if i < States.autoTeleportIndex then
				States.autoTeleportIndex = States.autoTeleportIndex - 1
			elseif i == States.autoTeleportIndex then
				States.autoTeleportIndex = math.min(States.autoTeleportIndex, #States.waypoints)
				if States.autoTeleportIndex < 1 then States.autoTeleportIndex = 1 end
			end
			U.refreshWaypointListUI()
			U.notify("Waypoint", "Dihapus: " .. wp.name, 2)
		end)
		
		-- Input DELAY (Replace LOOP)
		local delayInput = Instance.new("TextBox")
		delayInput.Size = UDim2.new(0.15, -2, 1, -4)
		delayInput.Position = UDim2.new(0.75, 2, 0, 2)
		delayInput.BackgroundColor3 = Color3.fromRGB(25, 28, 45)
		delayInput.Text = tostring(wp.delay or States.autoTeleportDelay or 1)
		delayInput.TextColor3 = Color3.fromRGB(240, 245, 255)
		delayInput.Font = Enum.Font.GothamBold
		delayInput.TextSize = 10
		delayInput.ClearTextOnFocus = false
		delayInput.Parent = row
		Instance.new("UICorner", delayInput).CornerRadius = UDim.new(0, 4)
		
		local delayStroke = Instance.new("UIStroke")
		delayStroke.Thickness = 1
		delayStroke.Color = Color3.fromRGB(70, 80, 130)
		delayStroke.Transparency = 0.5
		delayStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		delayStroke.Parent = delayInput
		
		delayInput.FocusLost:Connect(function()
			local n = tonumber(delayInput.Text)
			if n and n >= 0 then
				wp.delay = n
				U.notify("Waypoint", wp.name .. " delay set to " .. n .. "s", 1)
			else
				delayInput.Text = tostring(wp.delay or States.autoTeleportDelay or 1)
			end
		end)
		
		-- Indikator start point (lingkaran hijau)
		if i == States.autoTeleportIndex then
			local indicator = Instance.new("Frame")
			indicator.Size = UDim2.new(0, 6, 0, 6)
			indicator.Position = UDim2.new(0.93, 0, 0.5, -3)
			indicator.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
			indicator.BorderSizePixel = 0
			indicator.Parent = row
			Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)
		end
	end
	
	-- Update info start point
	updateStartInfo()
end

function U.toggleAutoTeleport()
	if #States.waypoints == 0 then
		U.notify("Error", "No waypoints defined!", 2)
		return
	end
	
	-- Validasi index
	if States.autoTeleportIndex > #States.waypoints then
		States.autoTeleportIndex = 1
	elseif States.autoTeleportIndex < 1 then
		States.autoTeleportIndex = 1
	end
	
	States.isAutoTeleporting = not States.isAutoTeleporting
	U.notifyToggle("Auto Teleport", States.isAutoTeleporting)
	U.setButtonState(UI.buttons.autoTp, States.isAutoTeleporting)
	
	if States.isAutoTeleporting then
		local startWp = States.waypoints[States.autoTeleportIndex]
		U.notify("Auto Teleport", "Dimulai dari: " .. startWp.name .. " (" .. States.autoTeleportIndex .. "/" .. #States.waypoints .. ")", 3)
		
		States.isAutoTeleportPaused = false
		task.spawn(function()
			while States.isAutoTeleporting and not States.isDestroyed do
				if not States.isAutoTeleportPaused then
					local wp = States.waypoints[States.autoTeleportIndex]
					if wp then
						local _, root = U.getHumanoidAndRoot()
						if root then 
							root.CFrame = wp.cf
						end
						
						local waitTime = wp.delay or States.autoTeleportDelay or 1
						task.wait(waitTime)
						
						States.autoTeleportIndex = States.autoTeleportIndex + 1
						if States.autoTeleportIndex > #States.waypoints then
							-- Handle end of path
							if States.isAutoRespawnOnFinish then
								U.notify("Respawn","Auto respawn", 1 )
								task.wait(0)
								U.requestRespawn()
								-- Penting: Tunggu karakter baru sebelum reset index dan lanjut teleport
								-- agar tidak teleport saat sedang proses respawn/mati.
								localPlayer.CharacterAdded:Wait()
								task.wait(2) -- Stabilitas
							end
							
							if States.isWaypointLooping then
								States.autoTeleportIndex = 1
								U.notify("Looping", "Mengulang dari awal...", 2)
							else
								U.stopAutoTeleport()
								U.notify("Selesai", "Semua waypoint telah dikunjungi.", 3)
								break
							end
						end
					else
						U.stopAutoTeleport()
						break
					end
				else
					task.wait(0.5)
				end
			end
		end)
	end
end

-- Fungsi untuk set start point secara manual
function U.setAutoTeleportStart(index)
	if index < 1 or index > #States.waypoints then
		U.notify("Error", "Index waypoint tidak valid!", 2)
		return false
	end
	
	States.autoTeleportIndex = index
	local wp = States.waypoints[index]
	U.notify("Start Point", "Auto teleport akan mulai dari: " .. wp.name .. " (index " .. index .. ")", 3)
	U.refreshWaypointListUI() -- Refresh untuk update indikator
	return true
end

-- Fungsi untuk teleport ke start point
function U.teleportToStart()
	if #States.waypoints == 0 then
		U.notify("Error", "Tidak ada waypoint!", 2)
		return false
	end
	
	local wp = States.waypoints[States.autoTeleportIndex]
	if wp then
		local _, root = U.getHumanoidAndRoot()
		if root then
			root.CFrame = wp.cf
			U.notify("Teleport", "Ke start point: " .. wp.name, 2)
			return true
		end
	end
	return false
end

-- Update info start point
function updateStartInfo()
	if UI.startInfo then
		if #States.waypoints > 0 then
			local wp = States.waypoints[States.autoTeleportIndex]
			local wpName = wp and wp.name or "Unknown"
			UI.startInfo.Text = "Start point: Index " .. States.autoTeleportIndex .. " - " .. wpName .. " (" .. States.autoTeleportIndex .. "/" .. #States.waypoints .. ")"
		else
			UI.startInfo.Text = "Start point: Tidak ada waypoint"
		end
	end
	
	if UI.startIndexInput then
		UI.startIndexInput.Text = tostring(States.autoTeleportIndex)
	end
end

-- Tambahkan kontrol tambahan di UI Waypoints page
-- Tempatkan kode ini di bagian UI creation setelah waypoint list

-- Start Point Controls removed

local startControlRow = Instance.new("Frame")
startControlRow.Name = "StartControlRow"
startControlRow.Size = UDim2.new(1, -10, 0, 32)
startControlRow.BackgroundTransparency = 1
startControlRow.Parent = waypointsPage

-- Input untuk set start point manual
local startIndexLabel = Instance.new("TextLabel")
startIndexLabel.Size = UDim2.new(0.3, 0, 1, 0)
startIndexLabel.Position = UDim2.new(0, 5, 0, 0)
startIndexLabel.BackgroundTransparency = 1
startIndexLabel.Text = "Start Index:"
startIndexLabel.Font = Enum.Font.Gotham
startIndexLabel.TextSize = 12
startIndexLabel.TextColor3 = Color3.fromRGB(190, 198, 230)
startIndexLabel.TextXAlignment = Enum.TextXAlignment.Left
startIndexLabel.Parent = startControlRow

local startIndexInput = Instance.new("TextBox")
startIndexInput.Name = "StartIndexInput"
startIndexInput.Size = UDim2.new(0.2, -4, 1, 0)
startIndexInput.Position = UDim2.new(0.3, 5, 0, 0)
startIndexInput.BackgroundColor3 = Color3.fromRGB(22, 24, 36)
startIndexInput.BorderSizePixel = 0
startIndexInput.Text = tostring(States.autoTeleportIndex)
startIndexInput.Font = Enum.Font.Gotham
startIndexInput.TextSize = 12
startIndexInput.TextColor3 = Color3.fromRGB(255, 255, 255)
startIndexInput.ClearTextOnFocus = true
startIndexInput.Parent = startControlRow

local siCorner = Instance.new("UICorner")
siCorner.CornerRadius = UDim.new(0, 6)
siCorner.Parent = startIndexInput

local siStroke = Instance.new("UIStroke")
siStroke.Thickness = 1
siStroke.Color = Color3.fromRGB(70, 80, 130)
siStroke.Transparency = 0.5
siStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
siStroke.Parent = startIndexInput

startIndexInput.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		local idx = tonumber(startIndexInput.Text)
		if idx and idx >= 1 and idx <= #States.waypoints then
			U.setAutoTeleportStart(idx)
		else
			startIndexInput.Text = tostring(States.autoTeleportIndex)
			U.notify("Error", "Index harus antara 1 - " .. #States.waypoints, 2)
		end
	end
end)

UI.startIndexInput = startIndexInput

-- Tombol Go To Start
local goToStartBtn = Instance.new("TextButton")
goToStartBtn.Size = UDim2.new(0.2, -4, 1, 0)
goToStartBtn.Position = UDim2.new(0.5, 5, 0, 0)
goToStartBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
goToStartBtn.BorderSizePixel = 0
goToStartBtn.Text = "GO TO START"
goToStartBtn.Font = Enum.Font.GothamBold
goToStartBtn.TextSize = 10
goToStartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
goToStartBtn.Parent = startControlRow
Instance.new("UICorner", goToStartBtn).CornerRadius = UDim.new(0, 6)

goToStartBtn.MouseButton1Click:Connect(U.teleportToStart)

-- Tombol Reset Start ke index 1
local resetStartBtn = Instance.new("TextButton")
resetStartBtn.Size = UDim2.new(0.15, -4, 1, 0)
resetStartBtn.Position = UDim2.new(0.7, 5, 0, 0)
resetStartBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
resetStartBtn.BorderSizePixel = 0
resetStartBtn.Text = "RESET"
resetStartBtn.Font = Enum.Font.GothamBold
resetStartBtn.TextSize = 10
resetStartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
resetStartBtn.Parent = startControlRow
Instance.new("UICorner", resetStartBtn).CornerRadius = UDim.new(0, 6)

resetStartBtn.MouseButton1Click:Connect(function()
	if #States.waypoints > 0 then
		U.setAutoTeleportStart(1)
	else
		U.notify("Error", "Tidak ada waypoint!", 2)
	end
end)

-- Info label untuk start point
local startInfo = Instance.new("TextLabel")
startInfo.Size = UDim2.new(1, -20, 0, 20)
startInfo.Position = UDim2.new(0, 10, 0, 0)
startInfo.BackgroundTransparency = 1
startInfo.Text = "Start point: Index " .. States.autoTeleportIndex .. " dari " .. #States.waypoints .. " waypoint"
startInfo.Font = Enum.Font.Gotham
startInfo.TextSize = 11
startInfo.TextColor3 = Color3.fromRGB(0, 255, 100)
startInfo.TextXAlignment = Enum.TextXAlignment.Left
startInfo.Parent = waypointsPage
UI.startInfo = startInfo

-- Tombol quick jump ke waypoint tertentu
-- Quick Jump removed

local quickJumpRow = Instance.new("Frame")
quickJumpRow.Name = "QuickJumpRow"
quickJumpRow.Size = UDim2.new(1, -10, 0, 30)
quickJumpRow.BackgroundTransparency = 1
quickJumpRow.Parent = waypointsPage

local quickJumpInput, quickJumpReset = createLabeledInput("Jump ke index:", "1", quickJumpRow)
quickJumpInput.Size = UDim2.new(0.5, -4, 1, 0)
quickJumpInput.Position = UDim2.new(0.5, 5, 0, 0)

quickJumpInput.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		local idx = tonumber(quickJumpInput.Text)
		if idx and idx >= 1 and idx <= #States.waypoints then
			local wp = States.waypoints[idx]
			local _, root = U.getHumanoidAndRoot()
			if root and wp then
				root.CFrame = wp.cf
				U.notify("Jump", "Ke waypoint [" .. idx .. "] " .. wp.name, 2)
			end
		else
			U.notify("Error", "Index harus antara 1 - " .. #States.waypoints, 2)
			quickJumpInput.Text = "1"
		end
	end
end)

-- Modifikasi fungsi addWaypoint untuk mendukung nama kustom dan auto-increment
function U.addWaypoint()
	local _, root = U.getHumanoidAndRoot()
	if not root then 
		U.notify("Error", "Tidak dapat menemukan karakter!", 2)
		return 
	end
	
	-- Ambil nama dari input Point Name (jika ada), jika kosong gunakan default WP_X
	local input = UI.inputs.wpPointName
	local wpName = ""
	
	if input and input.Text ~= "" then
		wpName = input.Text
	else
		wpName = "WP_" .. (#States.waypoints + 1)
	end
	
	-- Tambahkan waypoint ke data
	table.insert(States.waypoints, {name = wpName, cf = root.CFrame})
	
	-- Notifikasi & Refresh UI
	U.notify("Waypoint", "Ditambahkan: " .. wpName, 2, "Success")
	U.refreshWaypointListUI()
	
	-- Update input field dengan saran nama untuk WP berikutnya
	if input then
		input.Text = "WP_" .. (#States.waypoints + 1)
	end
end

-- Override fungsi loadWaypoints untuk reset start index
local originalLoadWaypoints = U.loadWaypointsFromSpecificFile
U.loadWaypointsFromSpecificFile = function(fileName)
	if originalLoadWaypoints then originalLoadWaypoints(fileName) end
	-- Reset start index ke 1 setelah load
	if #States.waypoints > 0 then
		States.autoTeleportIndex = 1
		if U.refreshWaypointListUI then U.refreshWaypointListUI() end
		U.notify("Info", "Start point direset ke index 1", 2)
	end
end

-- Inisialisasi start info
task.spawn(function()
	task.wait(0.2)
	updateStartInfo()
end)



function U.saveWaypointsToFile()
	if #States.waypoints == 0 then
		U.notify("Error", "No waypoints to save!", 2)
		return
	end
	
	local fileName = (UI.waypointNameInput and UI.waypointNameInput.Text ~= "" and UI.waypointNameInput.Text) or "waypoints"
	if not fileName:match("%.json$") then fileName = fileName .. ".json" end
	
	local data = {}
	for _, wp in ipairs(States.waypoints) do
		local x, y, z, r10, r11, r12, r20, r21, r22, r30, r31, r32 = wp.cf:GetComponents()
		table.insert(data, {name = wp.name, cf = {x, y, z, r10, r11, r12, r20, r21, r22, r30, r31, r32}, delay = wp.delay})
	end
	
	local json = S.HttpService:JSONEncode(data)
	if E.writefile then
		pcall(function()
			if not E.isfolder("FVKHUB_Data") then E.makefolder("FVKHUB_Data") end
			if not E.isfolder("FVKHUB_Data/Waypoints") then E.makefolder("FVKHUB_Data/Waypoints") end
			E.writefile("FVKHUB_Data/Waypoints/" .. fileName, json)
			U.notify("Success", "Waypoints saved to " .. fileName, 3)
			U.refreshWaypointFileList()
		end)
	end
end


function U.refreshWaypointFileList()
	if not UI.waypointFileListUI or not E.listfiles then return end
	for _, child in ipairs(UI.waypointFileListUI:GetChildren()) do
		if child:IsA("GuiObject") and child.Name ~= "UIListLayout" and child.Name ~= "UIPadding" then
			child:Destroy()
		end
	end
	if not E.isfolder("FVKHUB_Data/Waypoints") then return end
	
	local files = E.listfiles("FVKHUB_Data/Waypoints")
	for _, fullPath in ipairs(files) do
		repeat
		local fileName = fullPath:match("([^/\\]+)$") or fullPath
		if not fileName:match("%.json$") then break end
		
		local row = Instance.new("Frame")
		row.Name = "FileRow"
		row.Size = UDim2.new(1, 0, 0, 24)
		row.BackgroundTransparency = 1
		row.Parent = UI.waypointFileListUI

		local btn = Instance.new("TextButton")
		btn.Name = fileName
		btn.Size = UDim2.new(0.85, -2, 1, 0)
		btn.BackgroundColor3 = Color3.fromRGB(35, 40, 60)
		btn.BorderSizePixel = 0
		btn.Text = "📍 " .. fileName
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 11
		btn.TextColor3 = Color3.fromRGB(200, 210, 255)
		btn.Parent = row
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
		btn.MouseButton1Click:Connect(function()
			U.loadWaypointsFromSpecificFile(fileName)
		end)

		local del = Instance.new("TextButton")
		del.Size = UDim2.new(0.15, -2, 1, 0)
		del.Position = UDim2.new(0.85, 2, 0, 0)
		del.BackgroundColor3 = Color3.fromRGB(70, 35, 35)
		del.Text = "X"
		del.Font = Enum.Font.GothamBold
		del.TextSize = 10
		del.TextColor3 = Color3.fromRGB(255, 120, 120)
		del.Parent = row
		Instance.new("UICorner", del).CornerRadius = UDim.new(0, 6)
		del.MouseButton1Click:Connect(function()
			U.deleteFile("FVKHUB_Data/Waypoints/" .. fileName, U.refreshWaypointFileList)
		end)
		until true
	end
end




function U.toggleAutoTeleportPause(forceState)
	if not States.isAutoTeleporting then return end
	if forceState ~= nil then
		States.isAutoTeleportPaused = forceState
	else
		States.isAutoTeleportPaused = not States.isAutoTeleportPaused
	end
	
	U.notify("Waypoints", States.isAutoTeleportPaused and "Paused (Safety)" or "Resumed", 1.5)
	U.setButtonState(UI.buttons.pauseAutoTp, States.isAutoTeleportPaused)
	if UI.buttons.pauseAutoTp then
		UI.buttons.pauseAutoTp.Text = States.isAutoTeleportPaused and "▶ Resume" or "|| Pause"
	end
end





---------------------------------------------------------------------
-- FLOATING
---------------------------------------------------------------------

local function disableFloating()
	States.isFloating = false
	if Refs.floatPart then
		Refs.floatPart:Destroy()
		Refs.floatPart = nil
	end
	if Refs.floatConnection then
		Refs.floatConnection:Disconnect()
		Refs.floatConnection = nil
	end
end

local function enableFloating()
	if States.isFloating then return end
	
	local humanoid, root = U.getHumanoidAndRoot()
	if not root then return end
	
	States.isFloating = true
	-- Hitung jarak akurat dari Root ke Lantai berdasarkan HipHeight + separuh ukuran RootPart
	-- Ditambah 0.5 karena ketebalan platform (Part.Size.Y / 2)
	local hipHeight = humanoid.HipHeight
	local rootSizeY = root.Size.Y / 2
	
	-- Gunakan offset yang lebih dalam agar tidak "menyundul" kaki saat dibuat
	Refs.floatHeight = root.Position.Y - (hipHeight + rootSizeY + 0.7)
	
	local part = Instance.new("Part")
	part.Name = "AdminFloatPlatform"
	part.Size = Vector3.new(6, 1, 6)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = true
	part.Parent = workspace
	Refs.floatPart = part
	
	-- Loop untuk sinkronisasi platform secara horizontal
	-- Simpan referensi root langsung agar tidak perlu U.getHumanoidAndRoot() tiap Heartbeat
	local cachedRoot = root
	Refs.floatConnection = S.RunService.Heartbeat:Connect(function()
		if not States.isFloating or not Refs.floatPart then
			if Refs.floatConnection then
				Refs.floatConnection:Disconnect()
				Refs.floatConnection = nil
			end
			return
		end
		-- Refresh cache jika root sudah tidak valid (respawn)
		if not cachedRoot or not cachedRoot.Parent then
			local char = localPlayer.Character
			cachedRoot = char and char:FindFirstChild("HumanoidRootPart")
		end
		if cachedRoot then
			Refs.floatPart.CFrame = CFrame.new(cachedRoot.Position.X, Refs.floatHeight, cachedRoot.Position.Z)
		end
	end)
end

local function toggleFloating()
	if States.isFloating then
		disableFloating()
	else
		enableFloating()
	end
end


---------------------------------------------------------------------
-- ANTI FLING
---------------------------------------------------------------------

local function enableAntiFling()
	States.isAntiFling = true

	-- Cache semua BasePart karakter sekali saja, update saat ada ChildAdded
	local cachedParts = {}
	local physProps = PhysicalProperties.new(100, 0.3, 0.5)
	local FLING_THRESHOLD = 150

	local function cacheParts(character)
		table.clear(cachedParts)
		for _, p in ipairs(character:GetDescendants()) do
			if p:IsA("BasePart") then
				p.CustomPhysicalProperties = physProps
				table.insert(cachedParts, p)
			end
		end
	end

	local charConn = nil
	local function hookChar(character)
		cacheParts(character)
		charConn = character.DescendantAdded:Connect(function(d)
			if d:IsA("BasePart") then
				d.CustomPhysicalProperties = physProps
				table.insert(cachedParts, d)
			end
		end)
	end

	if localPlayer.Character then hookChar(localPlayer.Character) end
	local charHookConn = localPlayer.CharacterAdded:Connect(function(c)
		if charConn then charConn:Disconnect(); charConn = nil end
		task.wait(0.5)
		hookChar(c)
	end)
	Refs.connections.antiFlingCharHook = charHookConn

	task.spawn(function()
		while States.isAntiFling do
			-- Iterasi hanya cache part (jauh lebih murah dari GetDescendants tiap frame)
			for i = #cachedParts, 1, -1 do
				repeat
				local part = cachedParts[i]
				if not part or not part.Parent then
					table.remove(cachedParts, i)
					break
				end
				local vel = part.AssemblyLinearVelocity
				if vel.X*vel.X + vel.Y*vel.Y + vel.Z*vel.Z > FLING_THRESHOLD * FLING_THRESHOLD then
					part.AssemblyLinearVelocity = Vector3.zero
					part.AssemblyAngularVelocity = Vector3.zero
				end
				until true
			end
			task.wait(0.05) -- 20 Hz cukup untuk anti-fling
		end
		-- Cleanup
		if charConn then charConn:Disconnect() end
		if charHookConn then charHookConn:Disconnect() end
		Refs.connections.antiFlingCharHook = nil
	end)
end

local function disableAntiFling()
	States.isAntiFling = false
	local character = localPlayer.Character
	if character then
		pcall(function()
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CustomPhysicalProperties = nil -- Reset to default
				end
			end
		end)
	end
end

local function toggleAntiFling()
	if States.isAntiFling then
		disableAntiFling()
	else
		enableAntiFling()
	end
end

---------------------------------------------------------------------
---------------------------------------------------------------------
-- FULLBRIGHT
---------------------------------------------------------------------

local function cacheOriginalLighting()
	if not Refs.originalLighting then
		Refs.originalLighting = {
			Brightness = S.Lighting.Brightness,
			ClockTime = S.Lighting.ClockTime,
			ExposureCompensation = S.Lighting.ExposureCompensation,
			Ambient = S.Lighting.Ambient,
			OutdoorAmbient = S.Lighting.OutdoorAmbient,
			ColorShift_Top = S.Lighting.ColorShift_Top,
			ColorShift_Bottom = S.Lighting.ColorShift_Bottom,
			EnvironmentDiffuseScale = S.Lighting.EnvironmentDiffuseScale,
			EnvironmentSpecularScale = S.Lighting.EnvironmentSpecularScale,
			FogEnd = S.Lighting.FogEnd,
			GlobalShadows = S.Lighting.GlobalShadows,
		}
	end
end

local function enableFullbright()
	States.isFullbright = true
	cacheOriginalLighting()

	-- Disable Realistic Lighting if active
	-- Apply Fullbright values
	S.Lighting.Brightness = Config.brightnessValue
	S.Lighting.ExposureCompensation = Config.exposureCompensationValue
	S.Lighting.ClockTime = 12
	S.Lighting.Ambient = Color3.fromRGB(255, 255, 255)
	S.Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
	S.Lighting.ColorShift_Top = Color3.fromRGB(255, 255, 255)
	S.Lighting.ColorShift_Bottom = Color3.fromRGB(255, 255, 255)
	S.Lighting.EnvironmentDiffuseScale = 1
	S.Lighting.EnvironmentSpecularScale = 1
	S.Lighting.FogEnd = 1e5
	S.Lighting.GlobalShadows = false
	
	if not Refs.clockTimeLockConnection then
		Refs.clockTimeLockConnection = S.Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
			-- Solo lock if not user-locked to a specific custom time
			if States.isFullbright and not States.isLocalTimeLocked and S.Lighting.ClockTime ~= 12 then
				S.Lighting.ClockTime = 12
			end
		end)
	end
end

local function applyBrightness()
	S.Lighting.Brightness = Config.brightnessValue
end

local function applyExposureCompensation()
	-- Hanya apply exposure compensation kalau fullbright aktif
	if States.isFullbright then
		S.Lighting.ExposureCompensation = Config.exposureCompensationValue
	end
end

local function disableFullbright()
	States.isFullbright = false
	
	-- Disconnect ClockTime lock
	if Refs.clockTimeLockConnection then
		Refs.clockTimeLockConnection:Disconnect()
		Refs.clockTimeLockConnection = nil
	end
	
	pcall(function()
		if Refs.originalLighting then
			S.Lighting.Brightness = Refs.originalLighting.Brightness
			S.Lighting.ClockTime = Refs.originalLighting.ClockTime
			S.Lighting.ExposureCompensation = Refs.originalLighting.ExposureCompensation
			S.Lighting.Ambient = Refs.originalLighting.Ambient
			S.Lighting.ColorShift_Top = Refs.originalLighting.ColorShift_Top
			S.Lighting.ColorShift_Bottom = Refs.originalLighting.ColorShift_Bottom
			S.Lighting.EnvironmentDiffuseScale = Refs.originalLighting.EnvironmentDiffuseScale
			S.Lighting.EnvironmentSpecularScale = Refs.originalLighting.EnvironmentSpecularScale
			S.Lighting.FogEnd = Refs.originalLighting.FogEnd
			S.Lighting.OutdoorAmbient = Refs.originalLighting.OutdoorAmbient
			S.Lighting.GlobalShadows = Refs.originalLighting.GlobalShadows
		end
	end)
end
local function toggleFullbright()
	if States.isFullbright then
		disableFullbright()
	else
		enableFullbright()
	end
	
	if UI.buttons.fullbright then
		U.setButtonState(UI.buttons.fullbright, States.isFullbright)
	end
	U.notifyToggle("Fullbright", States.isFullbright)
end

local function toggleAntiJumpscare()
	States.isAntiJumpscare = not States.isAntiJumpscare
	U.notifyToggle("Anti Jumpscare", States.isAntiJumpscare)
	U.saveSettings()
	
	if States.isAntiJumpscare then
		-- 1. Initial Scan for existing loud sounds
		local function processSound(s)
			if s:IsA("Sound") then
				if not Refs.originalVolumes[s] then
					Refs.originalVolumes[s] = s.Volume
				end
				if s.Volume > 0.3 then
					s.Volume = 0.1
				end
			end
		end
		
		pcall(function()
			for _, sound in ipairs(workspace:GetDescendants()) do processSound(sound) end
			for _, sound in ipairs(localPlayer.PlayerGui:GetDescendants()) do processSound(sound) end
		end)

		-- 2. Connections for new sounds and UI elements
		if not Refs.connections.antiJumpscare then
			Refs.connections.antiJumpscare = game.DescendantAdded:Connect(function(v)
				if not States.isAntiJumpscare then return end
				
				-- Sound Protection
				if v:IsA("Sound") then
					pcall(function()
						task.wait(0.1) -- Wait for game initialization
						if not Refs.originalVolumes[v] then Refs.originalVolumes[v] = v.Volume end
						if v.Volume > 0.3 then v.Volume = 0.1 end
						
						v:GetPropertyChangedSignal("Volume"):Connect(function()
							if States.isAntiJumpscare and v.Volume > 0.3 then
								v.Volume = 0.1
							end
						end)
					end)
				end
				
				-- UI Jumpscare Protection (Full-screen images/videos)
				if v:IsA("ImageLabel") or v:IsA("VideoFrame") then
					pcall(function()
						task.wait(0.2) -- Wait for sizing
						local absSize = v.AbsoluteSize
						local vpSize = workspace.CurrentCamera.ViewportSize
						if absSize.X > vpSize.X * 0.8 and absSize.Y > vpSize.Y * 0.8 then
							v.Visible = false
							-- Also monitor visibility
							v:GetPropertyChangedSignal("Visible"):Connect(function()
								if States.isAntiJumpscare and v.Visible then
									v.Visible = false
								end
							end)
						end
					end)
				end
			end)
		end
		
		-- 3. Lighting Flash Protection
		if not Refs.connections.antiJumpscareLighting then
			Refs.connections.antiJumpscareLighting = S.Lighting:GetPropertyChangedSignal("Brightness"):Connect(function()
				if States.isAntiJumpscare and S.Lighting.Brightness > 8 then
					S.Lighting.Brightness = 2
				end
			end)
		end
	else
		-- DEACTIVATE: Restore volumes
		if Refs.originalVolumes then
			for sound, vol in pairs(Refs.originalVolumes) do
				pcall(function()
					if sound and sound.Parent then
						sound.Volume = vol
					end
				end)
			end
			table.clear(Refs.originalVolumes)
		end
	end
	
	if UI.buttons.antiJumpscare then
		U.setButtonState(UI.buttons.antiJumpscare, States.isAntiJumpscare)
	end
end

-- NoFallDamage removed by user request

U.toggleInfiniteOxygenStamina = function()
	States.isInfiniteOxygenStamina = not States.isInfiniteOxygenStamina
	U.notifyToggle("Inf Oxygen/Stamina", States.isInfiniteOxygenStamina)
	U.saveSettings()
	
	if States.isInfiniteOxygenStamina then
		if not Refs.connections.infOxygenStamina then
			Refs.connections.infOxygenStamina = S.RunService.Heartbeat:Connect(function()
				if not States.isInfiniteOxygenStamina then return end
				pcall(function()
					local char = localPlayer.Character
					if not char then return end
					local keywords = {"oxygen", "stamina", "breath", "energy", "sprint", "power", "air", "dive"}
					for _, v in ipairs(char:GetDescendants()) do
						if v:IsA("ValueBase") then
							local name = v.Name:lower()
							for _, kw in ipairs(keywords) do
								if name:find(kw) then
									if typeof(v.Value) == "number" then v.Value = 100
									elseif typeof(v.Value) == "boolean" then v.Value = true end
								end
							end
						end
					end
					for attr, val in pairs(char:GetAttributes()) do
						local name = attr:lower()
						for _, kw in ipairs(keywords) do if name:find(kw) then char:SetAttribute(attr, 100) end end
					end
				end)
			end)
		end
	end
	if UI.buttons.infOxygenStamina then U.setButtonState(UI.buttons.infOxygenStamina, States.isInfiniteOxygenStamina) end
end

U.showInventoryViewer = function(player)
	if not player then return end
	if UI.inventoryViewer then UI.inventoryViewer:Destroy() end
	local viewer = Instance.new("Frame")
	viewer.Size = UDim2.new(0, 250, 0, 300)
	viewer.Position = UDim2.new(0.5, -125, 0.5, -150)
	viewer.BackgroundColor3 = Color3.fromRGB(15, 18, 32)
	viewer.BorderSizePixel = 0
	viewer.Parent = UI.screenGui
	UI.inventoryViewer = viewer
	Instance.new("UICorner", viewer).CornerRadius = UDim.new(0, 10)
	local stroke = Instance.new("UIStroke", viewer); stroke.Color = States.panelThemeColor; stroke.Thickness = 2
	local h = Instance.new("Frame", viewer); h.Size = UDim2.new(1, 0, 0, 35); h.BackgroundTransparency = 1
	local t = Instance.new("TextLabel", h); t.Size = UDim2.new(1, -40, 1, 0); t.Position = UDim2.new(0, 10, 0, 0); t.BackgroundTransparency = 1; t.Text = player.DisplayName .. "'s INV"; t.Font = Enum.Font.GothamBold; t.TextSize = 13; t.TextColor3 = Color3.fromRGB(240, 245, 255)
	local c = Instance.new("TextButton", h); c.Size = UDim2.new(0, 25, 0, 25); c.Position = UDim2.new(1, -30, 0, 5); c.BackgroundColor3 = Color3.fromRGB(255, 60, 60); c.Text = "X"; c.TextColor3 = Color3.fromRGB(255, 255, 255)
	Instance.new("UICorner", c).CornerRadius = UDim.new(1, 0); c.MouseButton1Click:Connect(function() viewer:Destroy() end)
	local list = Instance.new("ScrollingFrame", viewer); list.Size = UDim2.new(1, -10, 1, -45); list.Position = UDim2.new(0, 5, 0, 40); list.BackgroundTransparency = 1; list.ScrollBarThickness = 2; list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	local layout = Instance.new("UIListLayout", list); layout.Padding = UDim.new(0, 4)
	local function refresh()
		for _, v in ipairs(list:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
		local backpack = player:FindFirstChild("Backpack")
		if backpack then
			for _, tool in ipairs(backpack:GetChildren()) do
				if tool:IsA("Tool") or tool:IsA("HopperBin") then
					local row = Instance.new("Frame", list); row.Size = UDim2.new(1, 0, 0, 30); row.BackgroundColor3 = Color3.fromRGB(30, 35, 55)
					Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
					local label = Instance.new("TextLabel", row); label.Size = UDim2.new(1, -10, 1, 0); label.Position = UDim2.new(0, 5, 0, 0); label.BackgroundTransparency = 1; label.Text = tool.Name; label.TextColor3 = Color3.fromRGB(220, 230, 255); label.TextSize = 11; label.Font = Enum.Font.Gotham; label.TextXAlignment = Enum.TextXAlignment.Left
				end
			end
		end
		local char = player.Character
		if char then
			local tool = char:FindFirstChildOfClass("Tool")
			if tool then
				local row = Instance.new("Frame", list); row.Size = UDim2.new(1, 0, 0, 30); row.BackgroundColor3 = Color3.fromRGB(50, 60, 100)
				Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
				local label = Instance.new("TextLabel", row); label.Size = UDim2.new(1, -10, 1, 0); label.Position = UDim2.new(0, 5, 0, 0); label.BackgroundTransparency = 1; label.Text = "[EQUIPPED] " .. tool.Name; label.TextColor3 = Color3.fromRGB(240, 255, 240); label.TextSize = 11; label.Font = Enum.Font.GothamBold; label.TextXAlignment = Enum.TextXAlignment.Left
			end
		end
	end
	refresh()
	task.spawn(function() while viewer and viewer.Parent do refresh() task.wait(3) end end)
end

-- Metatable Hooks consolidated into bootstrap bypass at startup (Line 40)

-- GodMode removed


---------------------------------------------------------------------
-- NO TOUCH (CanTouch = false pada semua part karakter)
---------------------------------------------------------------------

local noTouchConnection = nil

local function applyNoTouchToCharacter(character)
	if not character then return end
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanTouch = false
		end
	end
end

local function restoreTouchToCharacter(character)
	if not character then return end
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanTouch = true
		end
	end
end

local function enableNoTouch()
	if States.isNoTouch then return end
	States.isNoTouch = true

	-- Apply ke karakter & pasang listener reaktif (bukan loop Heartbeat tiap frame)
	local function applyAndListen(character)
		if not character then return end
		applyNoTouchToCharacter(character)
		-- Pantau part baru (tool equip dll) secara reaktif
		if noTouchConnection then noTouchConnection:Disconnect() end
		noTouchConnection = character.DescendantAdded:Connect(function(d)
			if d:IsA("BasePart") and States.isNoTouch then
				d.CanTouch = false
			end
		end)
	end

	applyAndListen(localPlayer.Character)

	-- Re-apply saat karakter respawn
	Refs.connections.noTouchCharConn = localPlayer.CharacterAdded:Connect(function(c)
		task.defer(function() applyAndListen(c) end)
	end)
end

local function disableNoTouch()
	if not States.isNoTouch then return end
	States.isNoTouch = false

	if noTouchConnection then
		noTouchConnection:Disconnect()
		noTouchConnection = nil
	end
	if Refs.connections.noTouchCharConn then
		Refs.connections.noTouchCharConn:Disconnect()
		Refs.connections.noTouchCharConn = nil
	end

	-- Kembalikan CanTouch ke true
	restoreTouchToCharacter(localPlayer.Character)
end

---------------------------------------------------------------------
-- NO SHADOW
---------------------------------------------------------------------

local function enableNoShadow()
	States.isNoShadow = true
	Refs.originalGlobalShadows = S.Lighting.GlobalShadows
	S.Lighting.GlobalShadows = false
end

local function disableNoShadow()
	States.isNoShadow = false
	S.Lighting.GlobalShadows = Refs.originalGlobalShadows
end

local function toggleNoShadow()
	if States.isNoShadow then disableNoShadow() else enableNoShadow() end
	U.setButtonState(UI.buttons.noShadow, States.isNoShadow)
	U.notifyToggle("No Shadow", States.isNoShadow)
end

---------------------------------------------------------------------
-- VISIBLE ALL PARTS
---------------------------------------------------------------------

local function enableVisibleAllParts()
	if States.isVisibleAllParts then return end
	States.isVisibleAllParts = true
	table.clear(Refs.visiblePartsCache)

	local character = localPlayer.Character

	for _, inst in ipairs(workspace:GetDescendants()) do
		repeat
		if inst:IsA("BasePart") then
			-- Lewati part yang merupakan bagian dari karakter sendiri
			if character and inst:IsDescendantOf(character) then
				break
			end
			-- Simpan dan tampilkan hanya yang benar-benar tidak visible
			if inst.Transparency >= 1 then
				table.insert(Refs.visiblePartsCache, {
					part = inst,
					transparency = inst.Transparency,
				})
				inst.Transparency = 0.5 -- jadikan semi-transparan supaya terlihat, tidak solid
			end
		end
		until true
	end
end

local function disableVisibleAllParts()
	if not States.isVisibleAllParts then return end
	States.isVisibleAllParts = false

	for _, data in ipairs(Refs.visiblePartsCache) do
		local part = data.part
		if part and part.Parent then
			part.Transparency = data.transparency
		end
	end

	table.clear(Refs.visiblePartsCache)
end

local function toggleVisibleAllParts()
	if States.isVisibleAllParts then disableVisibleAllParts() else enableVisibleAllParts() end
	U.setButtonState(UI.buttons.visibleParts, States.isVisibleAllParts)
	U.notifyToggle("Visible Parts", States.isVisibleAllParts)
end

local function enableNoFog()
	States.isNoFog = true
	
	-- Simpan fog asli
	if Refs.originalFogStart == nil then
		Refs.originalFogStart = S.Lighting.FogStart
	end
	if Refs.originalFogEnd == nil then
		Refs.originalFogEnd = S.Lighting.FogEnd
	end

	S.Lighting.FogStart = 0
	S.Lighting.FogEnd = 1e6

	-- Simpan & ubah semua Atmosphere (fog modern Roblox)
	if not Refs.originalAtmospheres then
		Refs.originalAtmospheres = {}

		local function collectAtmospheres(root)
			for _, inst in ipairs(root:GetDescendants()) do
				if inst:IsA("Atmosphere") then
					if not Refs.originalAtmospheres[inst] then
						Refs.originalAtmospheres[inst] = {
							Density = inst.Density,
							Offset = inst.Offset,
							Color = inst.Color,
							Decay = inst.Decay,
							Glare = inst.Glare,
							Haze = inst.Haze,
						}
					end
				end
			end
		end

		collectAtmospheres(S.Lighting)
		collectAtmospheres(workspace)
	end

	for atmo, _ in pairs(Refs.originalAtmospheres) do
		if atmo and atmo.Parent then
			atmo.Density = 0
			atmo.Offset = 0
			atmo.Haze = 0
			atmo.Glare = 0
		end
	end
end

local function disableNoFog()
	States.isNoFog = false
	
	pcall(function()
		if Refs.originalFogStart ~= nil then
			S.Lighting.FogStart = Refs.originalFogStart
		end
		if Refs.originalFogEnd ~= nil then
			S.Lighting.FogEnd = Refs.originalFogEnd
		end

		if Refs.originalAtmospheres then
			for atmo, props in pairs(Refs.originalAtmospheres) do
				if atmo and atmo.Parent then
					atmo.Density = props.Density
					atmo.Offset = props.Offset
					atmo.Color = props.Color
					atmo.Decay = props.Decay
					atmo.Glare = props.Glare
					atmo.Haze = props.Haze
				end
			end
		end
	end)
end

---------------------------------------------------------------------
-- X-RAY (F6)
---------------------------------------------------------------------

local function enableXRay()
	if States.isXRay then return end
	States.isXRay = true
	
	-- Save and set transparency
	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst:IsA("BasePart") and not inst:IsDescendantOf(localPlayer.Character) then
			if Refs.originalTransparency[inst] == nil then
				Refs.originalTransparency[inst] = inst.Transparency
			end
			inst.Transparency = 0.5
		end
	end
end

local function disableXRay()
	States.isXRay = false
	for inst, original in pairs(Refs.originalTransparency) do
		if inst and inst.Parent then
			inst.Transparency = original
		end
	end
	table.clear(Refs.originalTransparency)
end

local function toggleXRay()
	if States.isXRay then
		disableXRay()
	else
		enableXRay()
	end
end

local function toggleClickTeleport()
	States.isClickTeleportEnabled = not States.isClickTeleportEnabled
	U.setButtonState(UI.buttons.clickTp, States.isClickTeleportEnabled)
	
	if States.isClickTeleportEnabled then
		if mouse and not Refs.clickTpConn then
			Refs.clickTpConn = mouse.Button1Down:Connect(function()
				if not States.isClickTeleportEnabled then 
					return 
				end
				local character = localPlayer.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root and mouse.Hit then 
					root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0)) 
				end
			end)
		end
	else
		if Refs.clickTpConn then 
			Refs.clickTpConn:Disconnect() 
			Refs.clickTpConn = nil 
		end
	end
	U.notifyToggle("Click TP", States.isClickTeleportEnabled)
end

---------------------------------------------------------------------
-- WORLD CONTROLS: TIME & GRAVITY
---------------------------------------------------------------------

function U.toggleTimeLock()
	States.isLocalTimeLocked = not States.isLocalTimeLocked
	
	if States.isLocalTimeLocked then
		-- Ensure standard latitude for sun movement if it was modified by the game
		S.Lighting.GeographicLatitude = 0 -- Khatulistiwa agar pergerakan terlihat jelas
		
		-- Sync target value to whatever is current IF NOT ALREADY SET by manual input
		if not States.localTimeValue then
			States.localTimeValue = S.Lighting.ClockTime
		else
			-- If already has a stored value, apply it immediately
			S.Lighting.ClockTime = States.localTimeValue
			pcall(function() S.Lighting.TimeOfDay = string.format("%02d:00:00", math.floor(States.localTimeValue)) end)
		end
		
		-- Nuclear Lock: Using Heartbeat + PropertyChanged to ensure total control
		if not Refs.connections.timeLoop then
			Refs.connections.timeLoop = S.RunService.Heartbeat:Connect(function()
				if States.isLocalTimeLocked and States.localTimeValue then
					-- Update both properties repeatedly to override server/game cycles
					S.Lighting.ClockTime = States.localTimeValue
					pcall(function() S.Lighting.TimeOfDay = string.format("%02.2f:00:00", States.localTimeValue) end)
				end
			end)
		end
		
		-- Also use signal for instant reaction
		if not Refs._timeLockPropConn then
			Refs._timeLockPropConn = S.Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
				if States.isLocalTimeLocked and States.localTimeValue and S.Lighting.ClockTime ~= States.localTimeValue then
					S.Lighting.ClockTime = States.localTimeValue
				end
			end)
		end
	end
	
	-- Update both UI and Keybind status
	if UI.buttons.lockTime then
		U.setButtonState(UI.buttons.lockTime, States.isLocalTimeLocked)
	end
	U.notifyToggle("Time Lock", States.isLocalTimeLocked)
	
	if States.isLocalTimeLocked and States.isFullbright then
		U.notify("Lighting Notice", "Fullbright is ON. Darkness will be masked by high ambient light.", 3, "Warning")
	end
end

local function updateLocalTime(newTime)
	States.localTimeValue = newTime
	S.Lighting.ClockTime = newTime
	pcall(function() S.Lighting.TimeOfDay = string.format("%02.2f:00:00", newTime) end)
	
	-- Inform user if Fullbright is masking their changes
	if States.isFullbright then
		U.notify("Lighting Notice", "Fullbright is currently active, which masks visual sunsets/nights.", 2, "Warning")
	end
	
	-- AUTO-LOCK: Force ON when manual input is used
	if not States.isLocalTimeLocked then
		States.isLocalTimeLocked = true
		if UI.buttons.lockTime then
			U.setButtonState(UI.buttons.lockTime, true)
		end
	end
end

local function updateGravity(newGravity)
	States.gravityValue = newGravity
	workspace.Gravity = newGravity
end

local function resetSkybox()
	States.isSkyboxActive = false
	if Refs.customSky then
		Refs.customSky:Destroy()
		Refs.customSky = nil
	end
	
	-- Restore original skyboxes
	if Refs.originalSkybox then
		for _, sky in ipairs(Refs.originalSkybox) do
			if sky then pcall(function() sky.Parent = S.Lighting end) end
		end
		table.clear(Refs.originalSkybox)
	end
end

local function applySkybox(assetId)
	if not assetId or assetId == "" then 
		resetSkybox()
		return 
	end
	
	-- Formatting asset ID if it's just a number
	local formattedId = tostring(assetId)
	if not string.find(formattedId, "rbxassetid://") and tonumber(formattedId) then
		formattedId = "rbxassetid://" .. formattedId
	end

	-- Save originals if not already saved
	if not States.isSkyboxActive then
		Refs.originalSkybox = {}
		for _, child in ipairs(S.Lighting:GetChildren()) do
			if child:IsA("Sky") then
				table.insert(Refs.originalSkybox, child)
				child.Parent = nil -- Temporary hide
			end
		end
	end
	
	States.isSkyboxActive = true
	Config.skyboxId = assetId
	
	-- Create/Update custom sky
	if not Refs.customSky then
		Refs.customSky = Instance.new("Sky")
		Refs.customSky.Name = "AdminCustomSky"
		Refs.customSky.Parent = S.Lighting
	end
	
	Refs.customSky.SkyboxBk = formattedId
	Refs.customSky.SkyboxDn = formattedId
	Refs.customSky.SkyboxFt = formattedId
	Refs.customSky.SkyboxLf = formattedId
	Refs.customSky.SkyboxRt = formattedId
	Refs.customSky.SkyboxUp = formattedId
end

---------------------------------------------------------------------
-- UTILITY: REJOIN
---------------------------------------------------------------------

---------------------------------------------------------------------
-- UTILITY: REJOIN
---------------------------------------------------------------------

-- Export removed to top definition section


---------------------------------------------------------------------
-- AUTO INTERACT: AUTO KEY E (tanpa scan / LOS)
---------------------------------------------------------------------

local function enableAutoInteractProximity()
	if States.isAutoInteractProximity then
		return
	end

	States.isAutoInteractProximity = true

	if Refs.connections.autoKeyEThreadRunning then
		return
	end

	Refs.connections.autoKeyEThreadRunning = true
	task.spawn(function()
		local vim = getVIM()
		while States.isAutoInteractProximity do
			if vim then
				pcall(function()
					vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
					task.wait(Config.autoEDownDelay)
					vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
				end)
			else
				task.wait(0.1) -- Avoid tight loop if VIM failed
			end
			task.wait(Config.autoEUpDelay)
		end
		Refs.connections.autoKeyEThreadRunning = false
	end)
end

local function disableAutoInteractProximity()
	States.isAutoInteractProximity = false
end

---------------------------------------------------------------------
-- INVISIBLE
---------------------------------------------------------------------

local INVIS_SEAT_NAME = "AdminInvisSeat"

local function waitCharacterRendered(character, timeout)
	local startTime = tick()
	local maxTime = timeout or 2

	repeat
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local rootPart = character:FindFirstChild("HumanoidRootPart")

		if humanoid and rootPart and humanoid.Health > 0 then
			return
		end

		task.wait()
	until tick() - startTime > maxTime
end

local function setCharacterTransparency(character, transparency)
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") or descendant:IsA("Decal") then
			if Refs.originalTransparency[descendant] == nil then
				Refs.originalTransparency[descendant] = descendant.Transparency
			end
			descendant.Transparency = transparency
		end
	end
end

local function destroyAllInvisSeats()
	for _, descendant in ipairs(workspace:GetDescendants()) do
		if descendant:IsA("Seat") and descendant.Name == INVIS_SEAT_NAME then
			descendant:Destroy()
		end
	end
end

local function disableInvisible()
	if not States.isInvisible then
		return
	end

	States.isInvisible = false

	local character = localPlayer.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Sit = false
		end

		for _, descendant in ipairs(character:GetDescendants()) do
			if descendant:IsA("Seat") and descendant.Name == INVIS_SEAT_NAME then
				descendant:Destroy()
			elseif descendant:IsA("Weld") and descendant.Part0 and descendant.Part0.Name == INVIS_SEAT_NAME then
				descendant:Destroy()
			end
		end

		for _, descendant in ipairs(character:GetDescendants()) do
			if descendant:IsA("BasePart") or descendant:IsA("Decal") then
				local original = Refs.originalTransparency[descendant]
				if original ~= nil then
					descendant.Transparency = original
				else
					descendant.Transparency = 0
				end
			end
		end
	end

	destroyAllInvisSeats()
	Refs.invisSeat = nil
	Refs.originalTransparency = {}

	U.notify("Invis (off)", "STATUS:", 3)
end

local function enableInvisible()
	if States.isInvisible then
		return
	end

	-- Bersihkan sisa seat lama kalau ada (biar gak numpuk / nyangkut)
	destroyAllInvisSeats()

	local character = U.getCharacter()
	local _, root = U.getHumanoidAndRoot()
	if not root then
		return
	end

	local savedCFrame = root.CFrame
	local targetPosition = Vector3.new(-25.95, 84, 3537.55)

	character:MoveTo(targetPosition)
	task.wait(0.15)

	local seat = Instance.new("Seat")
	seat.Anchored = false
	seat.CanCollide = false
	seat.Name = INVIS_SEAT_NAME
	seat.Transparency = 1
	seat.Position = targetPosition
	seat.Parent = workspace

	local torso =
		character:FindFirstChild("Torso")
		or character:FindFirstChild("UpperTorso")

	if torso then
		local weld = Instance.new("Weld")
		weld.Part0 = seat
		weld.Part1 = torso
		weld.Parent = seat
	end

	Refs.invisSeat = seat
	seat.CFrame = savedCFrame
	-- Tunggu sampai character benar-benar ter-render sebelum di-transparankan
	waitCharacterRendered(character, 2)
	setCharacterTransparency(character, 1)

	States.isInvisible = true

	if invisSound then
		invisSound:Play()
	end

	U.notify("Invis (on)", "STATUS:", 3)
end

local function toggleInvisible()
	if States.isInvisible then
		disableInvisible()
	else
		enableInvisible()
	end
end



---------------------------------------------------------------------
-- CINEMATIC FREECAM (Shift+P)
---------------------------------------------------------------------

local freecamController = nil

local function initCinematicFreecam()
	local pi = math.pi
	local abs = math.abs
	local clamp = math.clamp
	local exp = math.exp
	local rad = math.rad
	local sign = math.sign
	local sqrt = math.sqrt
	local tan = math.tan

	local LocalPlayer = localPlayer
	local Workspace = workspace

	local Camera = Workspace.CurrentCamera
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		local newCamera = Workspace.CurrentCamera
		if newCamera then
			Camera = newCamera
		end
	end)

	local TOGGLE_INPUT_PRIORITY = Enum.ContextActionPriority.Low.Value
	local INPUT_PRIORITY = Enum.ContextActionPriority.High.Value
	local FREECAM_MACRO_KB = {Enum.KeyCode.LeftShift, Enum.KeyCode.P}

	local NAV_GAIN = Vector3.new(1, 1, 1) * 64
	local PAN_GAIN = Vector2.new(0.75, 1) * 8
	local FOV_GAIN = 300

	local PITCH_LIMIT = rad(90)

	local VEL_STIFFNESS = 1.5
	local PAN_STIFFNESS = 1.0
	local FOV_STIFFNESS = 4.0

	local Spring = {}
	Spring.__index = Spring

	function Spring.new(freq, pos)
		local self = setmetatable({}, Spring)
		self.f = freq
		self.p = pos
		self.v = pos * 0
		return self
	end

	function Spring:Update(dt, goal)
		local f = self.f * 2 * pi
		local p0 = self.p
		local v0 = self.v

		local offset = goal - p0
		local decay = exp(-f * dt)

		local p1 = goal + (v0 * dt - offset * (f * dt + 1)) * decay
		local v1 = (f * dt * (offset * f - v0) + v0) * decay

		self.p = p1
		self.v = v1

		return p1
	end

	function Spring:Reset(pos)
		self.p = pos
		self.v = pos * 0
	end

	local cameraPos = Vector3.new()
	local cameraRot = Vector2.new()
	local cameraFov = 0

	local velSpring = Spring.new(VEL_STIFFNESS, Vector3.new())
	local panSpring = Spring.new(PAN_STIFFNESS, Vector2.new())
	local fovSpring = Spring.new(FOV_STIFFNESS, 0)

	local Input = {} do
		local thumbstickCurve do
			local K_CURVATURE = 2.0
			local K_DEADZONE = 0.15

			local function fCurve(x)
				return (exp(K_CURVATURE * x) - 1) / (exp(K_CURVATURE) - 1)
			end

			local function fDeadzone(x)
				return fCurve((x - K_DEADZONE) / (1 - K_DEADZONE))
			end

			function thumbstickCurve(x)
				return sign(x) * clamp(fDeadzone(abs(x)), 0, 1)
			end
		end

		local gamepad = {
			ButtonX = 0,
			ButtonY = 0,
			DPadDown = 0,
			DPadUp = 0,
			ButtonL2 = 0,
			ButtonR2 = 0,
			Thumbstick1 = Vector2.new(),
			Thumbstick2 = Vector2.new(),
		}

		local keyboard = {
			W = 0,
			A = 0,
			S = 0,
			D = 0,
			E = 0,
			Q = 0,
			U = 0,
			H = 0,
			J = 0,
			K = 0,
			I = 0,
			Y = 0,
			Up = 0,
			Down = 0,
			LeftShift = 0,
			RightShift = 0,
		}

		local mouse = {
			Delta = Vector2.new(),
			MouseWheel = 0,
		}

		local NAV_GAMEPAD_SPEED = Vector3.new(1, 1, 1)
		local NAV_KEYBOARD_SPEED = Vector3.new(1, 1, 1)
		local PAN_MOUSE_SPEED = Vector2.new(1, 1) * (pi / 64)
		local PAN_GAMEPAD_SPEED = Vector2.new(1, 1) * (pi / 8)
		local FOV_WHEEL_SPEED = 1.0
		local FOV_GAMEPAD_SPEED = 0.25
		local NAV_ADJ_SPEED = 1.0
		local NAV_SHIFT_MUL = 0.2 -- Holding Shift now makes it 5x slower (Precision Mode)

		local navSpeed = 1.0 -- Reset to 1.0 (previously 500)

		function Input.Vel(dt)
			navSpeed = clamp(navSpeed + dt * (keyboard.Up - keyboard.Down) * NAV_ADJ_SPEED, 0.01, 8)

			local kGamepad = Vector3.new(
				thumbstickCurve(gamepad.Thumbstick1.X),
				thumbstickCurve(gamepad.ButtonR2) - thumbstickCurve(gamepad.ButtonL2),
				thumbstickCurve(-gamepad.Thumbstick1.Y)
			) * NAV_GAMEPAD_SPEED

			local kKeyboard = Vector3.new(
				keyboard.D - keyboard.A + keyboard.K - keyboard.H,
				keyboard.E - keyboard.Q + keyboard.I - keyboard.Y,
				keyboard.S - keyboard.W + keyboard.J - keyboard.U
			) * NAV_KEYBOARD_SPEED

			local shift = S.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
				or S.UserInputService:IsKeyDown(Enum.KeyCode.RightShift)

			return (kGamepad + kKeyboard) * (navSpeed * Config.freecamBaseSpeed * (shift and NAV_SHIFT_MUL or 1.0))
		end

		function Input.Pan(_dt)
			local kGamepad = Vector2.new(
				thumbstickCurve(gamepad.Thumbstick2.Y),
				thumbstickCurve(-gamepad.Thumbstick2.X)
			) * PAN_GAMEPAD_SPEED
			local kMouse = mouse.Delta * PAN_MOUSE_SPEED
			mouse.Delta = Vector2.new()
			return kGamepad + kMouse
		end

		function Input.Fov(_dt)
			local kGamepad = (gamepad.ButtonX - gamepad.ButtonY) * FOV_GAMEPAD_SPEED
			local kMouse = mouse.MouseWheel * FOV_WHEEL_SPEED
			mouse.MouseWheel = 0
			return kGamepad + kMouse
		end

		do
			local function Keypress(_action, state, inputObject)
				keyboard[inputObject.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0
				return Enum.ContextActionResult.Sink
			end

			local function GpButton(_action, state, inputObject)
				gamepad[inputObject.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0
				return Enum.ContextActionResult.Sink
			end

			local function MousePan(_action, _state, inputObject)
				local delta = inputObject.Delta
				mouse.Delta = Vector2.new(-delta.Y, -delta.X)
				return Enum.ContextActionResult.Sink
			end

			local function Thumb(_action, _state, inputObject)
				gamepad[inputObject.KeyCode.Name] = inputObject.Position
				return Enum.ContextActionResult.Sink
			end

			local function Trigger(_action, _state, inputObject)
				gamepad[inputObject.KeyCode.Name] = inputObject.Position.Z
				return Enum.ContextActionResult.Sink
			end

			local function MouseWheel(_action, _state, inputObject)
				mouse[inputObject.UserInputType.Name] = -inputObject.Position.Z
				return Enum.ContextActionResult.Sink
			end

			local function Zero(t)
				for k, v in pairs(t) do
					t[k] = v * 0
				end
			end

			function Input.StartCapture()
				S.ContextActionService:BindActionAtPriority("FreecamKeyboard", Keypress, false, INPUT_PRIORITY,
					Enum.KeyCode.W, Enum.KeyCode.U,
					Enum.KeyCode.A, Enum.KeyCode.H,
					Enum.KeyCode.S, Enum.KeyCode.J,
					Enum.KeyCode.D, Enum.KeyCode.K,
					Enum.KeyCode.E, Enum.KeyCode.I,
					Enum.KeyCode.Q, Enum.KeyCode.Y,
					Enum.KeyCode.Up, Enum.KeyCode.Down
				)
				S.ContextActionService:BindActionAtPriority("FreecamMousePan", MousePan, false, INPUT_PRIORITY, Enum.UserInputType.MouseMovement)
				S.ContextActionService:BindActionAtPriority("FreecamMouseWheel", MouseWheel, false, INPUT_PRIORITY, Enum.UserInputType.MouseWheel)
				S.ContextActionService:BindActionAtPriority("FreecamGamepadButton", GpButton, false, INPUT_PRIORITY, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonY)
				S.ContextActionService:BindActionAtPriority("FreecamGamepadTrigger", Trigger, false, INPUT_PRIORITY, Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonL2)
				S.ContextActionService:BindActionAtPriority("FreecamGamepadThumbstick", Thumb, false, INPUT_PRIORITY, Enum.KeyCode.Thumbstick1, Enum.KeyCode.Thumbstick2)
			end

			function Input.StopCapture()
				navSpeed = 1
				Zero(gamepad)
				Zero(keyboard)
				Zero(mouse)
				S.ContextActionService:UnbindAction("FreecamKeyboard")
				S.ContextActionService:UnbindAction("FreecamMousePan")
				S.ContextActionService:UnbindAction("FreecamMouseWheel")
				S.ContextActionService:UnbindAction("FreecamGamepadButton")
				S.ContextActionService:UnbindAction("FreecamGamepadTrigger")
				S.ContextActionService:UnbindAction("FreecamGamepadThumbstick")
			end
		end
	end

	local function GetFocusDistance(cameraFrame)
		local znear = 0.1
		local viewport = Camera.ViewportSize
		local projy = 2 * tan(cameraFov / 2)
		local projx = viewport.X / viewport.Y * projy
		local fx = cameraFrame.RightVector
		local fy = cameraFrame.UpVector
		local fz = cameraFrame.LookVector

		local minVect = Vector3.new()
		local minDist = 512

		for x = 0, 1, 0.5 do
			for y = 0, 1, 0.5 do
				local cx = (x - 0.5) * projx
				local cy = (y - 0.5) * projy
				local offset = fx * cx - fy * cy + fz
				local origin = cameraFrame.Position + offset * znear
				local _, hitPos = Workspace:FindPartOnRay(Ray.new(origin, offset.Unit * minDist))
				if hitPos then
					local dist = (hitPos - origin).Magnitude
					if minDist > dist then
						minDist = dist
						minVect = offset.Unit
					end
				end
			end
		end

		return fz:Dot(minVect) * minDist
	end

	local function StepFreecam(dt)
		local vel = velSpring:Update(dt, Input.Vel(dt))
		local pan = panSpring:Update(dt, Input.Pan(dt))
		local fov = fovSpring:Update(dt, Input.Fov(dt))

		local zoomFactor = sqrt(tan(rad(70 / 2)) / tan(rad(cameraFov / 2)))

		cameraFov = clamp(cameraFov + fov * FOV_GAIN * (dt / zoomFactor), 1, 120)
		cameraRot = cameraRot + pan * PAN_GAIN * (dt / zoomFactor)
		cameraRot = Vector2.new(clamp(cameraRot.X, -PITCH_LIMIT, PITCH_LIMIT), cameraRot.Y % (2 * pi))

		local cameraCFrame = CFrame.new(cameraPos)
			* CFrame.fromOrientation(cameraRot.X, cameraRot.Y, 0)
			* CFrame.new(vel * NAV_GAIN * dt)

		cameraPos = cameraCFrame.Position

		Camera.CFrame = cameraCFrame
		Camera.Focus = cameraCFrame * CFrame.new(0, 0, -GetFocusDistance(cameraCFrame))
		Camera.FieldOfView = cameraFov
	end

	local PlayerState = {} do
		local mouseBehavior
		local mouseIconEnabled
		local cameraType
		local cameraFocus
		local cameraCFrame
		local cameraFieldOfView
		local screenGuis = {}
		local coreGuis = {
			Backpack = true,
			Chat = true,
			Health = true,
			PlayerList = true,
		}
		local setCores = {
			BadgesNotificationsActive = true,
			PointsNotificationsActive = true,
		}

		function PlayerState.Push()
			for name in pairs(coreGuis) do
				coreGuis[name] = S.StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType[name])
				S.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[name], false)
			end
			for name in pairs(setCores) do
				setCores[name] = S.StarterGui:GetCore(name)
				S.StarterGui:SetCore(name, false)
			end

			local playerGuiInstance = LocalPlayer:FindFirstChildOfClass("PlayerGui")
			if playerGuiInstance then
				for _, gui in pairs(playerGuiInstance:GetChildren()) do
					if gui:IsA("ScreenGui") and gui.Enabled then
						screenGuis[#screenGuis + 1] = gui
						gui.Enabled = false
					end
				end
			end

			cameraFieldOfView = Camera.FieldOfView
			Camera.FieldOfView = 70

			cameraType = Camera.CameraType
			Camera.CameraType = Enum.CameraType.Custom

			cameraCFrame = Camera.CFrame
			cameraFocus = Camera.Focus

			mouseIconEnabled = S.UserInputService.MouseIconEnabled
			S.UserInputService.MouseIconEnabled = false

			mouseBehavior = S.UserInputService.MouseBehavior
			S.UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		end

		function PlayerState.Pop()
			for name, isEnabled in pairs(coreGuis) do
				S.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[name], isEnabled)
			end
			for name, isEnabled in pairs(setCores) do
				S.StarterGui:SetCore(name, isEnabled)
			end
			for _, gui in pairs(screenGuis) do
				if gui.Parent then
					gui.Enabled = true
				end
			end

			Camera.FieldOfView = cameraFieldOfView
			cameraFieldOfView = nil

			Camera.CameraType = cameraType
			cameraType = nil

			Camera.CFrame = cameraCFrame
			cameraCFrame = nil

			Camera.Focus = cameraFocus
			cameraFocus = nil

			S.UserInputService.MouseIconEnabled = mouseIconEnabled
			mouseIconEnabled = nil

			S.UserInputService.MouseBehavior = mouseBehavior
			mouseBehavior = nil
		end
	end

	local enabled = false
	
	local function StartFreecam()
		if enabled then
			return
		end

		local cameraCFrame = Camera.CFrame
		cameraRot = Vector2.new(cameraCFrame:ToEulerAnglesYXZ())
		cameraPos = cameraCFrame.Position
		cameraFov = Camera.FieldOfView

		velSpring:Reset(Vector3.new())
		panSpring:Reset(Vector2.new())
		fovSpring:Reset(0)

		PlayerState.Push()
		S.RunService:BindToRenderStep("Freecam", Enum.RenderPriority.Camera.Value, StepFreecam)
		Input.StartCapture()

		enabled = true
		States.isFreecamEnabled = true
	end

	local function StopFreecam()
		if not enabled then
			return
		end

		Input.StopCapture()
		S.RunService:UnbindFromRenderStep("Freecam")
		PlayerState.Pop()

		enabled = false
		States.isFreecamEnabled = false
	end

	local function ToggleFreecam()
		if enabled then
			StopFreecam()
		else
			StartFreecam()
		end
	end

	local function CheckMacro(macro)
		for i = 1, #macro - 1 do
			if not S.UserInputService:IsKeyDown(macro[i]) then
				return
			end
		end
		ToggleFreecam()
	end

	local function HandleActivationInput(_action, state, inputObject)
		if state == Enum.UserInputState.Begin then
			if inputObject.KeyCode == FREECAM_MACRO_KB[#FREECAM_MACRO_KB] then
				CheckMacro(FREECAM_MACRO_KB)
			end
		end
		return Enum.ContextActionResult.Pass
	end

	S.ContextActionService:BindActionAtPriority(
		"FreecamToggle",
		HandleActivationInput,
		false,
		TOGGLE_INPUT_PRIORITY,
		FREECAM_MACRO_KB[#FREECAM_MACRO_KB]
	)

	return {
		toggle = ToggleFreecam,
		start = StartFreecam,
		stop = StopFreecam,
		isEnabled = function()
			return enabled
		end,
		setBaseSpeed = function(speed)
			if typeof(speed) == "number" and speed > 0 then
				Config.freecamBaseSpeed = speed
			end
		end,
	}
end

freecamController = initCinematicFreecam()

---------------------------------------------------------------------
-- MOUSE LOCK/UNLOCK (SHIFTLOCK)
---------------------------------------------------------------------

-- (Active and crosshairGui moved to Refs table)

local _MaxLength = 900000



-- Create crosshair dot
local function createCrosshair()
	if Refs.crosshairGui then return end
	
	Refs.crosshairGui = Instance.new("ScreenGui")
	Refs.crosshairGui.Name = "ShiftlockCrosshair"
	Refs.crosshairGui.Parent = parentTarget
	Refs.crosshairGui.ResetOnSpawn = false
	Refs.crosshairGui.IgnoreGuiInset = true -- Cover entire screen for GetMouseLocation()
	Refs.crosshairGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	Refs.crosshairGui.DisplayOrder = 2147483647 -- Max DisplayOrder to stay on top
	
	local crosshair = Instance.new("Frame")
	crosshair.Name = "Crosshair"
	crosshair.Size = UDim2.new(0, 4, 0, 4)
	crosshair.Position = UDim2.new(0.5, 0, 0.5, 0)
	crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
	crosshair.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	crosshair.BorderSizePixel = 0
	crosshair.Parent = Refs.crosshairGui
	
	-- Make it round
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = crosshair
	
	-- Add subtle stroke for visibility
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Transparency = 0.3
	stroke.Parent = crosshair
	
	Refs.crosshairGui.Enabled = false
end

-- ShiftLock toggle function
local function ShiftLock()
	if not localPlayer.Character then return end
	
	createCrosshair()
	
	if not Refs.Active then
		pcall(function()
			localPlayer.DevEnableMouseLock = true
			localPlayer.DevComputerCameraMode = Enum.DevComputerCameraMode.UserChoice
			localPlayer.DevComputerMovementMode = Enum.DevComputerMovementMode.UserChoice
		end)
		
		pcall(function()
			if workspace.CurrentCamera then
				workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
				localPlayer.CameraMode = Enum.CameraMode.Classic
			end
		end)
		
		S.UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		S.UserInputService.MouseIconEnabled = false

		local h, _ = U.getHumanoidAndRoot()
		if h then
			h.CameraOffset = Vector3.new(1.75, 0, 0)
			h.AutoRotate = false -- CRITICAL: Fix stuttering by disabling default rotation
		end
		
		local cachedChar = nil
		local cachedHumanoid = nil
		local cachedRoot = nil

		local function onShiftLockStep()
			local camera = workspace.CurrentCamera
			if not camera then return end

			local isPOV = (camera.CFrame.Position - camera.Focus.Position).Magnitude < 0.6
			
			-- Mouse Locking Strategy
			if isPOV then
				if S.UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
					S.UserInputService.MouseBehavior = Enum.MouseBehavior.Default
				end
				if S.UserInputService.MouseIconEnabled ~= true then
					S.UserInputService.MouseIconEnabled = true
				end
			else
				if S.UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
					S.UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
				end
				if S.UserInputService.MouseIconEnabled ~= false then
					S.UserInputService.MouseIconEnabled = false
				end
			end

			if States.isFreecamEnabled or States.isSpectating then return end

			local char = localPlayer.Character
			if not char then return end
			
			if char ~= cachedChar or not cachedHumanoid or not cachedRoot then
				cachedChar = char
				cachedHumanoid = char:FindFirstChildOfClass("Humanoid")
				cachedRoot = char:FindFirstChild("HumanoidRootPart")
			end
			
			local humanoid = cachedHumanoid
			local rootPart = cachedRoot
			
			if not humanoid or not rootPart or humanoid.Health <= 0 then return end
			
			-- FORCE OFFSET REPLICATION (Fix for camera shakes resetting shiftlock to center)
			if not isPOV and not States.isCameraControl then
				-- Gunakan penetapan langsung agar tidak ada delay geser (instan ke samping)
				humanoid.CameraOffset = Vector3.new(1.75, 0, 0)

			end
			
			-- Orientation Logic (Ultra-Responsive Sync)

			local isSwimming = humanoid:GetState() == Enum.HumanoidStateType.Swimming
			if not isPOV and not humanoid.Sit and not States.isFlying and not States.isPlayingPath and not isSwimming then
				if humanoid.AutoRotate then humanoid.AutoRotate = false end -- Force enforcement
				
				local look = camera.CFrame.LookVector
				-- Math optimized rotation for zero frame lag and no pitch/roll jitter
				local yaw = math.atan2(-look.X, -look.Z)
				rootPart.CFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, yaw, 0)
			elseif isSwimming and not isPOV then
				-- Restore AutoRotate so swimming rotation works naturally
				if not humanoid.AutoRotate then humanoid.AutoRotate = true end
			end

			Refs.shiftlockFrameCount = (Refs.shiftlockFrameCount or 0) + 1
			if Refs.shiftlockFrameCount >= 30 then
				Refs.shiftlockFrameCount = 0
				if camera.CameraType ~= Enum.CameraType.Custom and not States.isFreecamEnabled then
					camera.CameraType = Enum.CameraType.Custom
				end
			end
		end

		-- Priority Camera + 2 ensures it runs right after camera and flash movement
		-- Priority Camera - 2 ensures it runs BEFORE camera update
		S.RunService:BindToRenderStep("AdminShiftLock", Enum.RenderPriority.Camera.Value - 2, onShiftLockStep)

		Refs.Active = true
		States.isMouseLocked = true
	else
		-- DEACTIVATE
		if localPlayer.Character then
			local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.AutoRotate = true
				-- FIX: Only reset camera offset if Camera Control isn't currently using it
				if not States.isCameraControl then
					humanoid.CameraOffset = Vector3.new(0, 0, 0)
				else
					-- If Camera Control is on, keep its preferred offset (2.0 studs up)
					humanoid.CameraOffset = Vector3.new(0, 2.0, 0)
				end
			end
		end
		
		S.UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		S.UserInputService.MouseIconEnabled = true
		
		if Refs.crosshairGui then
			Refs.crosshairGui.Enabled = false
		end
		
		pcall(function()
			S.RunService:UnbindFromRenderStep("AdminShiftLock")
			Refs.Active = nil
		end)
		States.isMouseLocked = false
	end
end

local function _enableMouseLock()
	if not Refs.Active then
		ShiftLock()
	end
end

local function disableMouseLock()
	if Refs.Active then
		ShiftLock() -- This will disable it
	end
end

-- 1. Visibility & Mouse Icon Loop (Throttled for logic)
Refs.connections.crosshairVisibility = S.RunService.RenderStepped:Connect(function()
	if States.isDestroyed then return end
	local camera = workspace.CurrentCamera
	if not camera then return end
	
	local isPOV = (camera.CFrame.Position - camera.Focus.Position).Magnitude < 0.6
	local isInternalLocked = States.isMouseLocked or isPOV or States.isCameraControl
	
	local shouldShowCrosshair
	if States.isFreecamEnabled then
		shouldShowCrosshair = not isInternalLocked
	else
		shouldShowCrosshair = true
	end

	if Refs.crosshairGui then
		if Refs.crosshairGui.Enabled ~= shouldShowCrosshair then
			Refs.crosshairGui.Enabled = shouldShowCrosshair
		end
	elseif shouldShowCrosshair then
		createCrosshair()
	end
	
	local shouldHideMouse = shouldShowCrosshair or States.isFreecamEnabled
	if shouldHideMouse and S.UserInputService.MouseIconEnabled then
		S.UserInputService.MouseIconEnabled = false
	end
end)

-- 2. Smooth Zoom Handling
local function setupSmoothZoom()
	if States.isDestroyed then return end
	
	local camera = workspace.CurrentCamera
	if not camera then return end
	
	-- Initial setup
	Refs.zoomDist = (camera.CFrame.Position - camera.Focus.Position).Magnitude
	Refs.targetZoomDist = Refs.zoomDist
	
	-- Backup original limits
	Refs.originalMaxZoom = localPlayer.CameraMaxZoomDistance
	Refs.originalMinZoom = localPlayer.CameraMinZoomDistance
	
	-- Constant smoothing loop
	S.RunService:BindToRenderStep("SmoothZoomStep", Enum.RenderPriority.Camera.Value + 1, function(dt)
		if not States.isSmoothZoom or States.isDestroyed then return end
		
		local camera = workspace.CurrentCamera
		if not camera then return end

		-- Sync current zoom distance if we are not actively lerping to a target
		local currentActualDist = (camera.CFrame.Position - camera.Focus.Position).Magnitude
		
		-- If the target is very close to current, just sync it to avoid jumping
		local delta = Refs.targetZoomDist - currentActualDist
		if math.abs(delta) < 0.1 then
			Refs.targetZoomDist = currentActualDist
			Refs.zoomDist = currentActualDist
		else
			-- Smoothing lerp
			local lerpSpeed = math.clamp(dt * 15, 0, 1) -- Slightly faster for responsiveness
			Refs.zoomDist = Refs.zoomDist + ((Refs.targetZoomDist - Refs.zoomDist) * lerpSpeed)
			
			-- Force camera distance
			localPlayer.CameraMaxZoomDistance = Refs.zoomDist
			localPlayer.CameraMinZoomDistance = Refs.zoomDist
		end
	end)
	
	-- Input listener for wheel
	S.UserInputService.InputChanged:Connect(function(input, gpe)
		if gpe or not States.isSmoothZoom or States.isDestroyed then return end
		
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			local camera = workspace.CurrentCamera
			if not camera then return end
			
			-- Re-sync target with actual distance before applying new wheel delta
			-- This prevents the "snapping back" effect when coming out of a wall
			local actualDist = (camera.CFrame.Position - camera.Focus.Position).Magnitude
			if math.abs(Refs.targetZoomDist - actualDist) > 1 then
				Refs.targetZoomDist = actualDist
				Refs.zoomDist = actualDist
			end

			local step = input.Position.Z * (Config.zoomAmount or 5)
			Refs.targetZoomDist = math.clamp(Refs.targetZoomDist - step, 0.5, 1000)
		end
	end)
end

function U.toggleSmoothZoom(force)
	if force ~= nil then
		if States.isSmoothZoom == force then return end
		States.isSmoothZoom = force
	else
		States.isSmoothZoom = not States.isSmoothZoom
	end
	
	if not States.isSmoothZoom then
		pcall(function()
			S.RunService:UnbindFromRenderStep("SmoothZoomStep")
			-- Restore limits
			localPlayer.CameraMaxZoomDistance = Refs.originalMaxZoom or 128
			localPlayer.CameraMinZoomDistance = Refs.originalMinZoom or 0.5
		end)
	else
		setupSmoothZoom()
	end
	
	if UI.buttons.smoothZoom then U.setButtonState(UI.buttons.smoothZoom, States.isSmoothZoom) end
end

function U.toggleCameraNoclip(force)
	if force ~= nil then
		if States.isCameraNoclip == force then return end
		States.isCameraNoclip = force
	else
		States.isCameraNoclip = not States.isCameraNoclip
	end
	
	pcall(function()
		localPlayer.DevCameraOcclusionMode = States.isCameraNoclip and Enum.DevCameraOcclusionMode.Invisicam or Enum.DevCameraOcclusionMode.Zoom
	end)
	
	if UI.buttons.cameraNoclip then U.setButtonState(UI.buttons.cameraNoclip, States.isCameraNoclip) end
end

-- Initialize smooth zoom
task.spawn(function()
	task.wait(2) -- Wait for camera to initialize
	setupSmoothZoom()
end)

-- 2. Ultra-Responsive Position Sync (No Delay)
local function updateCrosshairPos()
	if not Refs.crosshairGui or not Refs.crosshairGui.Enabled then return end
	
	-- Pastikan part ter-cache
	if not Refs.crosshairPart then
		Refs.crosshairPart = Refs.crosshairGui:FindFirstChild("Crosshair")
		if not Refs.crosshairPart then return end
	end
	
	-- Gunakan GetMouseLocation() untuk presisi layar mutlak
	local mPos = S.UserInputService:GetMouseLocation()
	Refs.crosshairPart.Position = UDim2.new(0, mPos.X, 0, mPos.Y)
end

-- Bind se-awal mungkin di pipeline rendering (setelah input diproses)
S.RunService:BindToRenderStep("AdminCrosshairSync", Enum.RenderPriority.Input.Value + 1, updateCrosshairPos)

-- Raw Input Listener: Update secepat mouse mengirim data (melewati frame rate)
Refs.connections.crosshairInput = S.UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		Refs.realMousePos = S.UserInputService:GetMouseLocation()
		updateCrosshairPos()
	end
end)


local function toggleCameraControl(enabled)
	if enabled == nil then enabled = not States.isCameraControl end
	States.isCameraControl = enabled
	
	U.notifyToggle("Camera Control", enabled)
	
	if enabled then
		-- 1. CLEANUP PREVIOUS STATES (CRITICAL FIX)
		-- If Shiftlock is on, we MUST disable it first to stop its RenderStep and Offset override
		if States.isMouseLocked then
			disableMouseLock()
		end
		
		-- Also ensure previous Camera Control loop is gone
		if Refs.connections.cameraControlLoop then
			Refs.connections.cameraControlLoop:Disconnect()
			Refs.connections.cameraControlLoop = nil
		end
		
		S.UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		S.UserInputService.MouseIconEnabled = false
		
		-- 2. APPLY CAMERA CONTROL STATE
		local h, _ = U.getHumanoidAndRoot()
		if h then
			-- Fixed offset for Camera Control
			h.CameraOffset = Vector3.new(0, 2.0, 0)
		end
		
		-- Show dot
		createCrosshair()
		if Refs.crosshairGui then
			Refs.crosshairGui.Enabled = true
		end
		
		-- Loop to keep mouse locked if enabled
		if not Refs.connections.cameraControlLoop then
			Refs.connections.cameraControlLoop = S.RunService.RenderStepped:Connect(function()
				if not States.isCameraControl or States.isDestroyed then
					if Refs.connections.cameraControlLoop then
						Refs.connections.cameraControlLoop:Disconnect()
						Refs.connections.cameraControlLoop = nil
					end
					return
				end
				
				-- Aggressive Mouse Locking
				if S.UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
					S.UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
				end
				
				-- Force Cursor Invisible
				if S.UserInputService.MouseIconEnabled then
					S.UserInputService.MouseIconEnabled = false
				end
				
				-- Modal Override: Neutralize game GUIs that try to capture mouse
				pcall(function()
					local guiService = S.GuiService

					if not guiService.MenuOpened and guiService.SelectedObject ~= nil then
						local parent = guiService.SelectedObject.Parent
						local name = parent and tostring(parent):lower() or ""
						if not string.find(name, "panel") and not string.find(name, "admin") then
							guiService.SelectedObject = nil
						end
					end
				end)
			end)
		end
	else
		-- FAST CLEANUP
		if Refs.connections.cameraControlLoop then
			Refs.connections.cameraControlLoop:Disconnect()
			Refs.connections.cameraControlLoop = nil
		end

		S.UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		S.UserInputService.MouseIconEnabled = true
		
		-- Reset camera
		local h, _ = U.getHumanoidAndRoot()
		if h then
			h.CameraOffset = Vector3.new(0, 0, 0)
		end
		
		-- Hide dot if not needed by other features
		local camera = workspace.CurrentCamera
		local isPOV = camera and (camera.CFrame.Position - camera.Focus.Position).Magnitude < 0.6
		if not (States.isMouseLocked or isPOV) and Refs.crosshairGui then
			Refs.crosshairGui.Enabled = false
		end
	end
end

-- NOCLIP
---------------------------------------------------------------------

function updateClipState()
	-- Kalau ada salah satu sumber noclip aktif (manual atau fly),
	-- maka Clip = false (noclip). 
	if States.isNoclip or States.isNoclipFly then
		States.Clip = false
	else
		States.Clip = true
	end
end

function ensureNoclipConnection()
	if Refs.Noclipping then return end

	local function noclipLoop()
		if States.Clip then return end

		local character = localPlayer.Character
		if not character then return end

		for _, child in ipairs(character:GetDescendants()) do
			if child:IsA("BasePart") and child.CanCollide == true then
				child.CanCollide = false
			end
		end

		-- (Removed automatic vehicle noclip during fly to allow collisions)
	end

	Refs.Noclipping = S.RunService.Stepped:Connect(function()
		-- Jalan selama ada sumber noclip aktif
		if not (States.isNoclip or States.isNoclipFly) then return end
		noclipLoop()
	end)
end

local function enableNoclip()
	if States.isNoclip then return end
	States.isNoclip = true

	updateClipState()
	ensureNoclipConnection()
end

local function disableNoclip()
	States.isNoclip = false

	updateClipState()

	-- Kalau fly juga tidak lagi minta noclip, putus koneksi
	if not (States.isNoclip or States.isNoclipFly) and Refs.Noclipping then
		Refs.Noclipping:Disconnect()
		Refs.Noclipping = nil
	end
end

-- VEHICLE BOOST (Refactored from obfuscated & lite)
---------------------------------------------------------------------

-- VEHICLE BOOST (Refactored from obfuscated & lite)
---------------------------------------------------------------------

-- Ensure defaults are initialized
Config.vehicleBoostAcceleration = Config.vehicleBoostAcceleration or 25
Config.vehicleFlySpeed = Config.vehicleFlySpeed or 100
Config.vehicleBrakeForce = Config.vehicleBrakeForce or 150

local function toggleVehicleBoost()
	States.isVehicleBoost = not States.isVehicleBoost
	U.notifyToggle("Vehicle Boost", States.isVehicleBoost)
	
	-- Cleanup any potentially stuck velocities or constraints
	if not States.isVehicleBoost and Refs.boostBV then
		Refs.boostBV:Destroy()
		Refs.boostBV = nil
	end
end

-- VEHICLE BOOST LOOP (RunService.Stepped for better physics override)
-- Using Stepped ensures velocity applies BEFORE the engine's physics step
Refs.connections.vehicleBoost = S.RunService.Stepped:Connect(function()
	if not States.isVehicleBoost or States.isVehicleFly or States.isDestroyed then return end
	
	local character = localPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	
	-- Fallback for root: Try U.getSeatedVehicleRoot() then AssemblyRootPart then Seat itself
	local root = seat and (U.getSeatedVehicleRoot() or seat.AssemblyRootPart or (seat:IsA("BasePart") and seat))
	if not root then return end
	
	-- [CRITICAL] Network Ownership & Physics Sync: Reparent character to vehicle if not already
	-- This mirrors the logic in panel-admin.obfuscated.luau that ensures the assembly includes the player
	if character and character.Parent ~= root.Parent and root.Parent:IsA("Model") then
		pcall(function() character.Parent = root.Parent end)
	end
	
	if S.UserInputService:GetFocusedTextBox() then return end
	
	local boostKey = (Config.keybinds and Config.keybinds.VehicleBoostKey) or Enum.KeyCode.W
	local qbKey = (Config.keybinds and Config.keybinds.VehicleQuickBrake) or Enum.KeyCode.S
	local stopKey = (Config.keybinds and Config.keybinds.VehicleStop) or Enum.KeyCode.P
	
	local isForward = S.UserInputService:IsKeyDown(boostKey) or S.UserInputService:IsKeyDown(Enum.KeyCode.Up)
	local isBackward = S.UserInputService:IsKeyDown(qbKey) or S.UserInputService:IsKeyDown(Enum.KeyCode.Down)
	local isStop = S.UserInputService:IsKeyDown(stopKey)
	
	if isStop then
		root.AssemblyLinearVelocity = root.AssemblyLinearVelocity * Vector3.zero
		root.AssemblyAngularVelocity = root.AssemblyAngularVelocity * Vector3.zero
	elseif isForward then
		-- ACCELERATION CALCULATION
		local rawVal = tonumber(Config.vehicleBoostAcceleration) or 25
		local mult = rawVal / 1000
		local moveDir = root.CFrame.LookVector
		
		-- [IMPROVEMENT] Combine Multiplicative and Additive boost
		-- Multiplicative: Good for infinite speed scaling
		-- Additive: Essential for heavy vehicles (carrying players) and starting from standstill
		if root.AssemblyLinearVelocity.Magnitude > 0.1 then
			root.AssemblyLinearVelocity = root.AssemblyLinearVelocity * Vector3.new(1 + mult, 1, 1 + mult)
		end
		
		-- Always add a base velocity component based on multiplier to overcome mass/friction
		-- This fixes the issue where carrying players makes the boost feel "stuck"
		root.AssemblyLinearVelocity = root.AssemblyLinearVelocity + moveDir * (mult * 20)
		
	elseif isBackward then
		local rawBrake = tonumber(Config.vehicleBrakeForce) or 150
		local brake = rawBrake / 1000
		root.AssemblyLinearVelocity = root.AssemblyLinearVelocity * Vector3.new(1 - brake, 1, 1 - brake)
	end
end)

-- VEHICLE AUTO TRANSMISSION (Matic Bypass)
task.spawn(function()
	local lastShiftTime = 0
	while not States.isDestroyed do
		task.wait(0.1)
		if States.isAutoTransmission and not States.FLYING then
			pcall(function()
				local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
				local seat = humanoid and humanoid.SeatPart
				if seat and seat:IsA("VehicleSeat") then
					local vim = getVIM()
					if not vim then return end
					
					-- A-Chassis Detection (Most common system)
					local values = seat:FindFirstChild("Values")
					local rpmObj = values and values:FindFirstChild("RPM")
					local gearObj = values and values:FindFirstChild("Gear")
					
					if tick() - lastShiftTime > 0.5 then -- Shift delay
						if rpmObj and gearObj then
							local rpm = rpmObj.Value
							local gear = gearObj.Value
							
							-- Logic: Shift up at high RPM, down at low RPM
							if rpm > 5400 and gear < 8 and gear >= 1 and seat.Throttle > 0 then
								vim:SendKeyEvent(true, Enum.KeyCode.E, false, game)
								task.wait(0.05)
								vim:SendKeyEvent(false, Enum.KeyCode.E, false, game)
								lastShiftTime = tick()
							elseif rpm < 2200 and gear > 1 and seat.Throttle >= 0 then
								vim:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
								task.wait(0.05)
								vim:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
								lastShiftTime = tick()
							end
						end
					end
				end
			end)
		end
	end
end)


---------------------------------------------------------------------
-- ESP TEAM / ENEMY (client-side only, visual highlight)
---------------------------------------------------------------------

-- (npcCache and espConnections moved to Refs table)

local function getTeamRelation(player)
	if player == localPlayer then
		return "self"
	end

	local myTeam = localPlayer.Team
	local otherTeam = player.Team

	if not myTeam or not otherTeam then
		return "none"
	end

	if myTeam == otherTeam then
		return "team"
	end

	return "enemy"
end

local function isNPC(character)
	-- Check if character is an NPC (no associated Player)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end
	
	-- Check if there's a player associated with this character
	local player = S.Players:GetPlayerFromCharacter(character)
	return player == nil
end

local function createBillboard(target, mainText, subText, color)
	if not target then return end
	
	local character = target:IsA("Model") and target or target.Parent
	if not character then return end

	-- Optimization: Check direct child first, then children of children if needed (selective)
	local billboard = target:FindFirstChild("AdminESPBillboard") 
	if not billboard then
		billboard = character:FindFirstChild("AdminESPBillboard", true)
	end

	if not billboard then
		billboard = Instance.new("BillboardGui")
		billboard.Name = "AdminESPBillboard"
		billboard.Size = UDim2.new(0, 160, 0, 60)
		billboard.StudsOffset = Vector3.new(0, 3.5, 0)
		billboard.AlwaysOnTop = true
		billboard.MaxDistance = 2500
		billboard.ResetOnSpawn = false

		local mainLabel = Instance.new("TextLabel")
		mainLabel.Name = "MainLabel"
		mainLabel.BackgroundTransparency = 1
		mainLabel.Size = UDim2.new(1, 0, 0.45, 0)
		mainLabel.Text = mainText
		mainLabel.TextColor3 = color
		mainLabel.TextStrokeTransparency = 0.4
		mainLabel.Font = Enum.Font.GothamBold
		mainLabel.TextSize = 13
		mainLabel.Parent = billboard

		local subLabel = Instance.new("TextLabel")
		subLabel.Name = "SubLabel"
		subLabel.BackgroundTransparency = 1
		subLabel.Position = UDim2.new(0, 0, 0.35, 0)
		subLabel.Size = UDim2.new(1, 0, 0.3, 0)
		subLabel.Text = subText or ""
		subLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		subLabel.TextStrokeTransparency = 0.6
		subLabel.Font = Enum.Font.GothamMedium
		subLabel.TextSize = 10
		subLabel.Parent = billboard

		local distLabel = Instance.new("TextLabel")
		distLabel.Name = "DistanceLabel"
		distLabel.BackgroundTransparency = 1
		distLabel.Position = UDim2.new(0, 0, 0.65, 0)
		distLabel.Size = UDim2.new(1, 0, 0.3, 0)
		distLabel.Text = ""
		distLabel.TextColor3 = Color3.fromRGB(180, 190, 210)
		distLabel.TextStrokeTransparency = 0.6
		distLabel.Font = Enum.Font.Gotham
		distLabel.TextSize = 10
		distLabel.Parent = billboard

		billboard.Parent = target
		Refs.activeESP[billboard] = {
			target = target,
			mainLabel = mainLabel,
			subLabel = subLabel,
			distLabel = distLabel,
			lastTextUpdate = 0,
			lastDist = -1,
			parentChar = character
		}
	else
		-- Fast internal update
		local data = Refs.activeESP[billboard]
		if data then
			if data.mainLabel then 
				data.mainLabel.Text = mainText
				data.mainLabel.TextColor3 = color
			end
			if data.subLabel then
				data.subLabel.Text = subText or ""
			end
		else
			-- Re-sync if data lost
			local m = billboard:FindFirstChild("MainLabel")
			local s = billboard:FindFirstChild("SubLabel")
			local d = billboard:FindFirstChild("DistanceLabel")
			if m then m.Text = mainText; m.TextColor3 = color end
			if s then s.Text = subText or "" end
			
			Refs.activeESP[billboard] = {
				target = target,
				mainLabel = m,
				subLabel = s,
				distLabel = d,
				lastTextUpdate = 0,
				lastDist = -1,
				parentChar = character
			}
		end
		
		if billboard.Parent ~= target then
			billboard.Parent = target
		end
	end
end

local function cleanupESPForCharacter(character)
	if not character then return end
	
	-- OPTIMIZED: Search for specific children instead of GetDescendants iteration
	local namesToRemove = {"AdminESPHighlight", "AdminESPNPCHighlight", "AdminESPBillboard"}
	
	for _, name in ipairs(namesToRemove) do
		-- Billboard might be in a part, Highlight is in the model
		local found = character:FindFirstChild(name, true)
		if found then
			Refs.activeESP[found] = nil
			pcall(function() found:Destroy() end)
		end
	end
end

local function updateEspForPlayer(player)
	if not player or player == localPlayer or not player.Parent then return end
	
	local character = player.Character
	if not character or not character.Parent then return end

	local relation = getTeamRelation(player)
	local shouldShow = States.isEspUniversal and (relation ~= "self")
	local outlineColor = (relation == "team") and Color3.fromRGB(80, 160, 255) or Color3.fromRGB(255, 80, 80)

	if shouldShow then
		local highlight = character:FindFirstChild("AdminESPHighlight")
		if not highlight then
			highlight = Instance.new("Highlight")
			highlight.Name = "AdminESPHighlight"
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.Parent = character
		end
		highlight.OutlineColor = outlineColor
		highlight.OutlineTransparency = 0
		highlight.FillColor = outlineColor
		highlight.FillTransparency = 0.5
		highlight.Enabled = true

		local guiPart = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
		if guiPart then
			createBillboard(guiPart, player.DisplayName, "@" .. player.Name, outlineColor)
		end
	else
		cleanupESPForCharacter(character)
	end
end

local function updateEspForNPC(character)
	if not character or not isNPC(character) then return end

	local highlight = character:FindFirstChild("AdminESPNPCHighlight")
	if States.isEspNpc then
		if not highlight then
			highlight = Instance.new("Highlight")
			highlight.Name = "AdminESPNPCHighlight"
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.OutlineColor = Color3.fromRGB(255, 165, 0)
			highlight.Parent = character
		end
		highlight.FillColor = Color3.fromRGB(255, 165, 0)
		highlight.FillTransparency = 0.5
		highlight.OutlineTransparency = 0
		highlight.Enabled = true
		
		local guiPart = character:FindFirstChild("Head") or character.PrimaryPart or character:FindFirstChildWhichIsA("BasePart")
		if guiPart then
			createBillboard(guiPart, character.Name, "NPC", Color3.fromRGB(255, 165, 0))
		end
		Refs.npcCache[character] = true
	else
		cleanupESPForCharacter(character)
		Refs.npcCache[character] = nil
	end
end

local function setupPlayerESPTracking(player)
	if not player or player == localPlayer then return end
	
	-- Clean existing to avoid duplicates if called again
	if Refs.espConnections[player] then
		for _, conn in ipairs(Refs.espConnections[player]) do
			if conn then conn:Disconnect() end
		end
	end
	Refs.espConnections[player] = {}
	
	local function onCharAdded(character)
		if not character then return end
		
		-- Multiple retries to ensure it stays active
		task.spawn(function()
			for i = 1, 5 do
				if not character.Parent then break end
				local humanoid = character:WaitForChild("Humanoid", 3)
				local root = character:WaitForChild("HumanoidRootPart", 3)
				
				if humanoid and root then
					task.wait(0.3)
					if States.isEspUniversal and character.Parent then
						updateEspForPlayer(player)
					end
					break
				end
				task.wait(1)
			end
		end)
	end

	-- CharacterAdded connection
	table.insert(Refs.espConnections[player], player.CharacterAdded:Connect(onCharAdded))
	
	-- Team changes should update ESP color/visibility
	table.insert(Refs.espConnections[player], player:GetPropertyChangedSignal("Team"):Connect(function()
		if States.isEspUniversal and player.Character then
			updateEspForPlayer(player)
		end
	end))

	-- If character already exists, handle it
	if player.Character then
		onCharAdded(player.Character)
	end
end

local function refreshAllEsp()
	-- Update ESP for all players
	for _, player in ipairs(S.Players:GetPlayers()) do
		if player ~= localPlayer and player ~= nil then
			updateEspForPlayer(player)
		end
	end
	
	-- Update ESP untuk NPC yang sudah di-cache saja (jauh lebih cepat)
	if States.isEspNpc then
		-- Clean up invalid entries dari cache
		for npc, _ in pairs(Refs.npcCache) do
			if not npc.Parent then
				Refs.npcCache[npc] = nil
			else
				-- Update highlight untuk NPC yang masih valid
				updateEspForNPC(npc)
			end
		end
	else
		-- Remove all NPC highlights and billboards dari cache
		for npc, _ in pairs(Refs.npcCache) do
			if npc.Parent then
				updateEspForNPC(npc)
			end
		end
		Refs.npcCache = {}
	end
end

local function updateEspForItems()
	if not States.isEspItems then
		-- Cleanup dari cache (O(cached items), bukan O(workspace))
		for parent, _ in pairs(Refs.itemCache) do
			if parent and parent.Parent then
				local box = parent:FindFirstChild("AdminESPItemBox")
				if box then box:Destroy() end
				local bill = parent:FindFirstChild("AdminESPBillboard")
				if bill then
					Refs.activeESP[bill] = nil
					bill:Destroy()
				end
			end
		end
		Refs.itemCache = {}
		return
	end

	-- Scan workspace hanya saat pertama kali enable (initial populate)
	-- Setelah itu DescendantAdded akan menangani item baru secara reaktif
	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst:IsA("ProximityPrompt") then
			local parent = inst.Parent
			if parent and parent:IsA("BasePart") and not Refs.itemCache[parent] then
				Refs.itemCache[parent] = true
				local box = parent:FindFirstChild("AdminESPItemBox")
				if not box then
					box = Instance.new("SelectionBox")
					box.Name = "AdminESPItemBox"
					box.LineThickness = 0.05
					box.SurfaceTransparency = 0.8
					box.Color3 = Color3.fromRGB(0, 255, 150)
					box.Adornee = parent
					box.Parent = parent
				end
				local text = inst.ObjectText ~= "" and inst.ObjectText or inst.ActionText or "Item"
				createBillboard(parent, text, "Interactive", Color3.fromRGB(0, 255, 150))
			end
		end
	end
end

-- Scan workspace untuk NPC (dipanggil sekali saat ESP NPC pertama kali diaktifkan)
local function scanWorkspaceForNPCs()
	-- Hanya scan sekali, hasil di-cache
	local function scanRecursive(parent, depth)
		-- Limit depth untuk mencegah lag
		if depth > 8 then return end
		
		for _, child in pairs(parent:GetChildren()) do
			if child:IsA("Model") and child:FindFirstChildOfClass("Humanoid") then
				if isNPC(child) and not Refs.npcCache[child] then
					updateEspForNPC(child)
				end
			end
			-- Hanya scan Folder dan Model yang kemungkinan berisi NPC
			if child:IsA("Folder") or (child:IsA("Model") and not child:FindFirstChildOfClass("Humanoid")) then
				scanRecursive(child, depth + 1)
			end
		end
	end
	
	scanRecursive(workspace, 0)
end

-- Setup tracking untuk semua player yang sudah ada
for _, p in ipairs(S.Players:GetPlayers()) do
	if p ~= localPlayer then
		setupPlayerESPTracking(p)
	end
end

-- Track new players
Refs.playerAddedConn = S.Players.PlayerAdded:Connect(function(p)
	if p ~= localPlayer then
		setupPlayerESPTracking(p)
		
		-- Safety Waypoint Detection
		if States.isAutoTeleporting and States.isPauseOnJoin then
			U.toggleAutoTeleportPause(true)
			U.notify("Waypoint Safety", "Pemain @" .. p.Name .. " masuk! Auto TP dipause.", 5, "Warning")
		end
	end
end)


-- Track player removal
Refs.playerRemovingConn = S.Players.PlayerRemoving:Connect(function(p)
	-- Cleanup connections
	if Refs.espConnections[p] then
		for _, conn in ipairs(Refs.espConnections[p]) do
			if conn then conn:Disconnect() end
		end
		Refs.espConnections[p] = nil
	end
	
	-- Cleanup ESP
	if p.Character then
		cleanupESPForCharacter(p.Character)
	end
end)

-- Monitor loop (fallback recovery setiap 3 detik)
task.spawn(function()
	while not States.isDestroyed do
		task.wait(3)

		-- Player ESP recovery
		if States.isEspUniversal then
			for _, player in ipairs(S.Players:GetPlayers()) do
				if player ~= localPlayer and player.Character then
					local char = player.Character
					local hasBillboard = char:FindFirstChild("AdminESPBillboard", true)
					local hasHighlight = char:FindFirstChild("AdminESPHighlight")
					
					if not hasBillboard or not hasHighlight then
						updateEspForPlayer(player)
					end
				end
			end
		end

		-- NPC ESP recovery
		if States.isEspNpc then
			for npc, _ in pairs(Refs.npcCache) do
				if not npc.Parent then
					Refs.npcCache[npc] = nil
				elseif not npc:FindFirstChild("AdminESPNPCHighlight") then
					updateEspForNPC(npc)
				end
			end
		end

		-- Item ESP: prune cache saja, tidak perlu scan workspace
		if States.isEspItems then
			for parent, _ in pairs(Refs.itemCache) do
				if not parent or not parent.Parent then
					Refs.itemCache[parent] = nil
				end
			end
		end
	end
end)

-- HIGH FREQUENCY ESP LOOP (ULTRA OPTIMIZED)
local ESP_CULL_SQ = 1200 * 1200 
task.spawn(function()
	local lastMyPos = Vector3.zero
	local lastNpcCheck = 0
	
	while not States.isDestroyed do
		repeat
		local myChar = localPlayer.Character
		local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
		
		if not myRoot then 
			task.wait(1) 
			break
		end
		
		local myPos = myRoot.Position
		local now = os.clock()
		
		-- Loop through active ESP objects
		for billboard, data in pairs(Refs.activeESP) do
			repeat
			local target = data.target
			if not billboard or not billboard.Parent or not target or not target.Parent then
				Refs.activeESP[billboard] = nil
				break
			end

			-- Squared distance (Fast)
			local tp = target.Position
			local distSq = (tp - myPos).SqrMagnitude
			
			local isCulled = distSq > ESP_CULL_SQ
			
			-- Update Visibility state only on change
			if billboard.Enabled == isCulled then
				billboard.Enabled = not isCulled
				
				local parentChar = data.parentChar
				if parentChar then
					local hl = parentChar:FindFirstChild("AdminESPHighlight") or parentChar:FindFirstChild("AdminESPNPCHighlight")
					if hl then hl.Enabled = not isCulled end
					
					local box = target:FindFirstChild("AdminESPItemBox")
					if box then box.Visible = not isCulled end
				end
			end

			-- Throttle text update (Distance)
			if not isCulled then
				local dist = math.sqrt(distSq)
				if math.abs(dist - data.lastDist) > 1.2 or (now - data.lastTextUpdate) > 0.4 then
					if data.distLabel then
						data.distLabel.Text = string.format("[%d m]", math.round(dist))
					end
					data.lastDist = dist
					data.lastTextUpdate = now
				end
			end
			until true
		end
		
		-- NPC Cache Update
		if States.isEspNpc and now - lastNpcCheck > 2 then
			lastNpcCheck = now
			for npc, _ in pairs(Refs.npcCache) do
				if not npc or not npc.Parent then
					Refs.npcCache[npc] = nil
				end
			end
		end
		
		lastMyPos = myPos
		task.wait(0.12)
		until true
	end
end)

-- Monitor workspace untuk NPC & Items baru (REAKTIF)
Refs.npcDescendantConn = workspace.DescendantAdded:Connect(function(descendant)
	-- NPC Detection
	if descendant:IsA("Humanoid") then
		local character = descendant.Parent
		if character and character:IsA("Model") then
			task.wait(0.2)
			if States.isEspNpc and isNPC(character) and not Refs.npcCache[character] then
				updateEspForNPC(character)
			end
		end
	end
	
	-- Item Detection (ProximityPrompt)
	if descendant:IsA("ProximityPrompt") then
		local parent = descendant.Parent
		if parent and parent:IsA("BasePart") then
			task.wait(0.2)
			if States.isEspItems then
				local text = descendant.ObjectText ~= "" and descendant.ObjectText or descendant.ActionText or "Item"
				createBillboard(parent, text, Color3.fromRGB(0, 255, 150))
				Refs.itemCache[parent] = true
				
				-- Add box highlight too
				local box = parent:FindFirstChild("AdminESPItemBox")
				if not box then
					box = Instance.new("SelectionBox")
					box.Name = "AdminESPItemBox"
					box.LineThickness = 0.05
					box.SurfaceTransparency = 0.8
					box.Color3 = Color3.fromRGB(0, 255, 150)
					box.Adornee = parent
					box.Parent = parent
				end
			end
		end
	end
end)

Refs.npcDescendantRemovingConn = workspace.DescendantRemoving:Connect(function(descendant)
	-- Cleanup cache saat NPC dihapus
	if descendant:IsA("Model") and Refs.npcCache[descendant] then
		Refs.npcCache[descendant] = nil
	end
end)

-- FLY
---------------------------------------------------------------------

-- Implementasi fly ala Infinite Yield (disesuaikan)

local function startFly(vfly)
	local character = U.getCharacter()
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		repeat
			task.wait()
			humanoid = character:FindFirstChildOfClass("Humanoid")
		until humanoid
	end

	-- Putus koneksi lama kalau ada
	if Refs.flyKeyDown then
		Refs.flyKeyDown:Disconnect()
		Refs.flyKeyDown = nil
	end
	if Refs.flyKeyUp then
		Refs.flyKeyUp:Disconnect()
		Refs.flyKeyUp = nil
	end

	local _, charRoot = U.getHumanoidAndRoot()
	local root = charRoot
	
	if vfly then
		root = U.getSeatedVehicleRoot() or root
	end

	if not root then return end

	local CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
	local SPEED = 0

	local function FLY()
		States.FLYING = true
		States.isFlying = true
		if vfly then
			States.isVehicleFly = true
			-- Aggressive Mute from obfuscated logic
			local inputPriority = Enum.ContextActionPriority.High.Value + 100
			local inputsToMute = {
				Enum.KeyCode.W, Enum.KeyCode.S, Enum.KeyCode.A, Enum.KeyCode.D,
				Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right
			}
			S.ContextActionService:BindActionAtPriority("AdminVehicleFlyMuter", function()
				return Enum.ContextActionResult.Sink
			end, false, inputPriority, unpack(inputsToMute))
		else
			States.isNoclipFly = true
			updateClipState()
			ensureNoclipConnection()
		end

		if not vfly then
			local BG = Instance.new("BodyGyro")
			local BV = Instance.new("BodyVelocity")
			BG.P = 9e4
			BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
			BG.CFrame = root.CFrame
			BG.Parent = root
			BV.Velocity = Vector3.new(0, 0, 0)
			BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
			BV.Parent = root
			Refs.flyBG = BG
			Refs.flyBV = BV
		end
		
		if vfly then
			Refs.connections.vehicleFlyLoop = S.RunService.Stepped:Connect(function()
				if not States.FLYING or not States.isVehicleFly then
					if Refs.connections.vehicleFlyLoop then Refs.connections.vehicleFlyLoop:Disconnect() end
					return
				end

				local character = localPlayer.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				local seatPart = humanoid and humanoid.SeatPart
				if seatPart and seatPart:IsA("VehicleSeat") then
					local vehicle = U.getSeatedVehicleRoot() and U.getSeatedVehicleRoot().Parent
					if vehicle and vehicle:IsA("Model") then
						-- Stability from obfuscated: Character inside vehicle
						if character.Parent ~= vehicle then character.Parent = vehicle end
						if not vehicle.PrimaryPart then vehicle.PrimaryPart = seatPart end
						
						local camera = workspace.CurrentCamera
						if camera and vehicle.PrimaryPart then
							if not Refs.vehicleLastPos then Refs.vehicleLastPos = vehicle:GetPivot().Position end
							
							local speed = (Config.vehicleFlySpeed or 100) / 100
							local offset = Vector3.zero
							if not S.UserInputService:GetFocusedTextBox() then
								local dx = (S.UserInputService:IsKeyDown(Enum.KeyCode.D) and speed) or (S.UserInputService:IsKeyDown(Enum.KeyCode.A) and -speed) or 0
								local dy = (S.UserInputService:IsKeyDown(Enum.KeyCode.E) and speed/2) or (S.UserInputService:IsKeyDown(Enum.KeyCode.Q) and -speed/2) or 0
								local dz = (S.UserInputService:IsKeyDown(Enum.KeyCode.S) and speed) or (S.UserInputService:IsKeyDown(Enum.KeyCode.W) and -speed) or 0
								offset = Vector3.new(dx, dy, dz)
							end
							
							local camCF = camera.CFrame
							local targetCF = CFrame.new(Refs.vehicleLastPos) * (camCF - camCF.Position)
							local nextPos = targetCF:PointToWorldSpace(offset)
							
							Refs.vehicleLastPos = nextPos
							vehicle:PivotTo(CFrame.new(nextPos) * (camCF - camCF.Position))
							
							-- Physics Kill
							seatPart.AssemblyLinearVelocity = Vector3.zero
							seatPart.AssemblyAngularVelocity = Vector3.zero
						end
					end
				end
			end)
		else
			-- Standard Character Fly Loop
			local connectionName = "AdminFlyLoop"
			S.RunService:BindToRenderStep(connectionName, Enum.RenderPriority.Camera.Value, function()
				if not States.FLYING or not root or not root.Parent then
					S.RunService:UnbindFromRenderStep(connectionName)
					return
				end
				local camera = workspace.CurrentCamera
				if not camera then return end
				if humanoid then humanoid.PlatformStand = true end
				
				local moveDir = Vector3.zero

				if CONTROL.L + CONTROL.R ~= 0
					or CONTROL.F + CONTROL.B ~= 0
					or CONTROL.Q + CONTROL.E ~= 0 then
					local baseSpeed = Config.flySpeed
					SPEED = baseSpeed * (States.isWalkBoost and 2 or 1)

					local forward = camera.CFrame.LookVector
					local right = camera.CFrame.RightVector
					local up = Vector3.new(0, 1, 0)

					moveDir =
						forward * (CONTROL.F + CONTROL.B)
						+ right * (CONTROL.R + CONTROL.L)
						+ up * (CONTROL.Q + CONTROL.E)
				else
					SPEED = 0
					moveDir = Vector3.zero
				end

				if root and root.Parent then
					if not Refs.flyBV or not Refs.flyBV.Parent then
						Refs.flyBV = Instance.new("BodyVelocity")
						Refs.flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
						Refs.flyBV.Parent = root
					end
					if not Refs.flyBG or not Refs.flyBG.Parent then
						Refs.flyBG = Instance.new("BodyGyro")
						Refs.flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
						Refs.flyBG.P = 9e4
						Refs.flyBG.Parent = root
					end

					if moveDir.Magnitude > 0 then
						Refs.flyBV.Velocity = moveDir.Unit * SPEED
					else
						Refs.flyBV.Velocity = Vector3.zero
					end
					Refs.flyBG.CFrame = camera.CFrame
				end
			end)
		end
	end

	Refs.flyKeyDown = S.UserInputService.InputBegan:Connect(function(input, processed)
		if processed and S.UserInputService:GetFocusedTextBox() then return end

		local step = (vfly and Config.vehicleFlySpeed or Config.flySpeed)

		if input.KeyCode == Enum.KeyCode.W then
			CONTROL.F = step
		elseif input.KeyCode == Enum.KeyCode.S then
			CONTROL.B = -step
		elseif input.KeyCode == Enum.KeyCode.A then
			CONTROL.L = -step
		elseif input.KeyCode == Enum.KeyCode.D then
			CONTROL.R = step
		elseif input.KeyCode == Enum.KeyCode.E and States.QEfly then
			CONTROL.Q = step * 1
		elseif input.KeyCode == Enum.KeyCode.Q and States.QEfly then
			CONTROL.E = -step * 1
		end

		pcall(function()
			if workspace.CurrentCamera then
				workspace.CurrentCamera.CameraType = Enum.CameraType.Track
			end
		end)
	end)

	Refs.flyKeyUp = S.UserInputService.InputEnded:Connect(function(input, processed)
		if processed and S.UserInputService:GetFocusedTextBox() then return end

		if input.KeyCode == Enum.KeyCode.W then
			CONTROL.F = 0
		elseif input.KeyCode == Enum.KeyCode.S then
			CONTROL.B = 0
		elseif input.KeyCode == Enum.KeyCode.A then
			CONTROL.L = 0
		elseif input.KeyCode == Enum.KeyCode.D then
			CONTROL.R = 0
		elseif input.KeyCode == Enum.KeyCode.E then
			CONTROL.Q = 0
		elseif input.KeyCode == Enum.KeyCode.Q then
			CONTROL.E = 0
		end
	end)

	FLY()
end


local function stopFly()
	States.FLYING = false
	States.isFlying = false
	States.isVehicleFly = false
	States.isNoclipFly = false
	updateClipState()

	if Refs.flyKeyDown then
		Refs.flyKeyDown:Disconnect()
		Refs.flyKeyDown = nil
	end
	if Refs.flyKeyUp then
		Refs.flyKeyUp:Disconnect()
		Refs.flyKeyUp = nil
	end

	if Refs.flyBG then
		Refs.flyBG:Destroy()
		Refs.flyBG = nil
	end
	if Refs.flyBV then
		Refs.flyBV:Destroy()
		Refs.flyBV = nil
	end
	
	-- RESTORE disabled vehicle scripts
	if Refs.disabledVehicleScripts then
		for scr, state in pairs(Refs.disabledVehicleScripts) do
			pcall(function() scr.Enabled = state end)
		end
		table.clear(Refs.disabledVehicleScripts)
	end
	
	if Refs.connections.vehicleFlyLoop then
		Refs.connections.vehicleFlyLoop:Disconnect()
		Refs.connections.vehicleFlyLoop = nil
	end
	Refs.vehicleLastPos = nil
	
	local character = localPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = false
		-- Restore movement properties that were muted during flight
		humanoid.WalkSpeed = Config.walkSpeed or 16
		humanoid.AutoRotate = true
	end

	-- RESTORE char parent if it was flying in a vehicle
	if Refs.originalCharacterParent and character then
		pcall(function()
			character.Parent = Refs.originalCharacterParent
		end)
		Refs.originalCharacterParent = nil
	end

	-- Kalau tidak ada sumber noclip lain, matikan loop noclip
	if not (States.isNoclip or States.isNoclipFly) and Refs.Noclipping then
		Refs.Noclipping:Disconnect()
		Refs.Noclipping = nil
	end

	pcall(function()
		S.ContextActionService:UnbindAction("AdminVehicleFlyMuter")
	end)
	
	pcall(function()
		if workspace.CurrentCamera then
			workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
		end
	end)
end


local function setupWalkSpeedDetection(humanoid)
	-- Putus koneksi lama jika ada
	if Refs.connections.walkSpeedConnection then
		Refs.connections.walkSpeedConnection:Disconnect()
	end
	
	-- Monitor perubahan WalkSpeed dari tools atau script lain
	Refs.connections.walkSpeedConnection = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		-- Hanya update jika tidak sedang dalam boost mode dan tidak sedang terbang
		if not States.isWalkBoost and not States.isFlying then
			local currentSpeed = humanoid.WalkSpeed
			
			-- Update walkSpeed base value jika berbeda
			if currentSpeed ~= Config.walkSpeed then
				Config.walkSpeed = currentSpeed
				Config.defaultWalkSpeedFromCharacter = currentSpeed
				if UI.inputs.walkSpeedInput then
					UI.inputs.walkSpeedInput.Text = tostring(Config.walkSpeed)
				end
			end
		end
	end)
	
	-- Monitor tools yang di-equip/unequip
	local backpack = localPlayer:FindFirstChild("Backpack")
	if backpack then
		-- Monitor tool equip dari backpack
		backpack.ChildRemoved:Connect(function(tool)
			if tool:IsA("Tool") then
				-- Tool di-equip, tunggu sebentar lalu cek walkspeed
				task.wait(0.1)
				if humanoid.Parent and not States.isWalkBoost and not States.isFlying then
					local newSpeed = humanoid.WalkSpeed
					if newSpeed ~= Config.walkSpeed then
						Config.walkSpeed = newSpeed
						Config.defaultWalkSpeedFromCharacter = newSpeed
						if UI.inputs.walkSpeedInput then
							UI.inputs.walkSpeedInput.Text = tostring(Config.walkSpeed)
						end
					end
				end
			end
		end)
		
		-- Monitor tool unequip ke backpack
		backpack.ChildAdded:Connect(function(tool)
			if tool:IsA("Tool") then
				-- Tool di-unequip, tunggu sebentar lalu cek walkspeed
				task.wait(0.1)
				if humanoid.Parent and not States.isWalkBoost and not States.isFlying then
					local newSpeed = humanoid.WalkSpeed
					if newSpeed ~= Config.walkSpeed then
						Config.walkSpeed = newSpeed
						Config.defaultWalkSpeedFromCharacter = newSpeed
						if UI.inputs.walkSpeedInput then
							UI.inputs.walkSpeedInput.Text = tostring(Config.walkSpeed)
						end
					end
				end
			end
		end)
	end
	
	-- Monitor tools di character (equip/unequip)
	local character = humanoid.Parent
	if character then
		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				-- Tool di-equip ke character
				task.wait(0.1)
				if humanoid.Parent and not States.isWalkBoost and not States.isFlying then
					local newSpeed = humanoid.WalkSpeed
					if newSpeed ~= Config.walkSpeed then
						Config.walkSpeed = newSpeed
						Config.defaultWalkSpeedFromCharacter = newSpeed
						if UI.inputs.walkSpeedInput then
							UI.inputs.walkSpeedInput.Text = tostring(Config.walkSpeed)
						end
					end
				end
			end
		end)
		
		character.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") then
				-- Tool di-unequip dari character
				task.wait(0.1)
				if humanoid.Parent and not States.isWalkBoost and not States.isFlying then
					local newSpeed = humanoid.WalkSpeed
					if newSpeed ~= Config.walkSpeed then
						Config.walkSpeed = newSpeed
						Config.defaultWalkSpeedFromCharacter = newSpeed
						if UI.inputs.walkSpeedInput then
							UI.inputs.walkSpeedInput.Text = tostring(Config.walkSpeed)
						end
					end
				end
			end
		end)
	end
end

local function onCharacterAdded(character)
	-- Hook for Auto Respawn (Fast recovery)
	task.spawn(function()
		local humanoid = character:WaitForChild("Humanoid", 15)
		if humanoid then
			humanoid.Died:Connect(function()
				if States.isAutoRespawn then
					task.wait(0.2)
					pcall(function()
						local rs = S.ReplicatedStorage
						local remotes = {"Respawn", "Reset", "LoadCharacter", "RequestRespawn", "PlayerReady"}
						for _, rName in ipairs(remotes) do
							local r = rs:FindFirstChild(rName, true)
							if r and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) then
								if r:IsA("RemoteEvent") then r:FireServer() else r:InvokeServer() end
							end
						end
					end)
				end
			end)
		end
	end)

	-- Automatic Teleport to Saved Position (Instant & Parallel)
	if States.isAutoTpToSave and States.savedPosition and not States.isAutoTeleporting then
		task.spawn(function()
			local root = character:WaitForChild("HumanoidRootPart", 10)
			if root and States.savedPosition then
				-- Loop forcing for 1.5 seconds to immediately override game's checkpoint scripts
				local targetCF = States.savedPosition
				local startTime = tick()
				while tick() - startTime < 1.5 and character.Parent and root.Parent do
					root.CFrame = targetCF
					task.wait() -- High frequency to prevent even 1 frame at checkpoint
				end
				U.notify("Recovery Active", "Returned to saved position", 2)
			end
		end)
	end
	
	-- Respawn to custom coordinate (Teleport to Position link)
	if States.isRespawnToTpPos and States.tpPosToRespawn and not States.isAutoTeleporting then
		task.spawn(function()
			local root = character:WaitForChild("HumanoidRootPart", 10)
			if root and States.tpPosToRespawn then
				local targetPos = States.tpPosToRespawn
				local startTime = tick()
				while tick() - startTime < 1.5 and character.Parent and root.Parent do
					root.CFrame = CFrame.new(targetPos)
					task.wait()
				end
				U.notify("Respawn Link", "Teleported to linked coordinate", 2)
			end
		end)
	end

	-- Tunggu sampai karakter benar-benar selesai render saat pertama join / respawn
	waitCharacterRendered(character, 3)
	
	-- Pastikan fly dimatikan saat respawn
	if States.isFlying or States.FLYING then
		stopFly()
	end
	
	if States.isFloating then
		disableFloating()
	end

	if States.isInvisible then
		disableInvisible()
	end

	if States.isNoclip then
		ensureNoclipConnection()
	end

	-- Re-apply No Touch ke karakter baru jika fitur aktif
	if States.isNoTouch then
		task.defer(function()
			applyNoTouchToCharacter(character)
		end)
	end

	
	-- Re-enable mouse lock jika sebelumnya aktif
	if States.isMouseLocked then
		-- Reapply mouse lock untuk karakter baru
		task.defer(function()
			local humanoid = character:WaitForChild("Humanoid", 10)
			if humanoid then
				-- Restore side effects lost on respawn
				S.UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
				S.UserInputService.MouseIconEnabled = false
				
				-- Ensure AutoRotate is off for shiftlock to work correctly
				humanoid.AutoRotate = false
				
				-- Use side offset as default for better visibility
				local targetOffset = Vector3.new(1.75, 0, 0)
				humanoid.CameraOffset = targetOffset
				
				if Refs.crosshairGui then
					Refs.crosshairGui.Enabled = true
				end
			end
		end)
	end

	-- Refresh ESP saat karakter respawn (terutama ESP Universal)
	if States.isEspUniversal then
		task.wait(0.5)
		refreshAllEsp()
	end

	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid then
		-- Tunggu sejenak agar script game/tools selesai startup
		task.wait(0.3)
		
		local charOriginalSpeed = humanoid.WalkSpeed
		
		-- Cek apakah ada tool (speed coil dll) yang ter-equip
		local hasTools = false
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("Tool") then
				hasTools = true
				break
			end
		end
		
		-- Hanya capture sebagai 'Default' jika saat ini tidak pakai tools
		if not hasTools then
			Config.defaultWalkSpeedFromCharacter = charOriginalSpeed
			Config.lastKnownDefault = charOriginalSpeed
			
			-- Sync Config.walkSpeed if not overridden by user
			if not States.isWalkOverride then
				Config.walkSpeed = charOriginalSpeed
			end
		else
			-- Jika spawn sudah bawa tool, gunakan lastKnownDefault atau 16
			if not Config.defaultWalkSpeedFromCharacter or Config.defaultWalkSpeedFromCharacter == 0 then
				Config.defaultWalkSpeedFromCharacter = Config.lastKnownDefault or 16
				if not States.isWalkOverride then
					Config.walkSpeed = Config.defaultWalkSpeedFromCharacter
				end
			end
		end
		
		if UI.inputs.walkSpeedInput then
			UI.inputs.walkSpeedInput.Text = string.format("%.1f", Config.walkSpeed):gsub("%.0$", "")
		end
		-- ambil jump power/height asli sebagai dasar
		if humanoid.UseJumpPower ~= nil and humanoid.UseJumpPower == false then
			Config.baseJumpPower = humanoid.JumpHeight
		else
			Config.baseJumpPower = humanoid.JumpPower
		end
		
		-- Setup deteksi walkspeed dari tools
		setupWalkSpeedDetection(humanoid)
		
		applyMovementStats(humanoid)
	end
end

Refs.characterAddedConn = localPlayer.CharacterAdded:Connect(onCharacterAdded)
if localPlayer.Character then
	onCharacterAdded(localPlayer.Character)
end

---------------------------------------------------------------------
-- JUMP SPAM (INFINITE JUMP)
---------------------------------------------------------------------

local function startJumpSpam()
	if Refs.jumpSpamJumpConn then return end
	Refs.jumpSpamJumpConn = S.UserInputService.JumpRequest:Connect(function()
		local humanoid, root = U.getHumanoidAndRoot()
		if humanoid and root then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)
end

local function stopJumpSpam()
	if Refs.jumpSpamJumpConn then
		Refs.jumpSpamJumpConn:Disconnect()
		Refs.jumpSpamJumpConn = nil
	end
end

---------------------------------------------------------------------
-- DESTROY PANEL
---------------------------------------------------------------------

local function resetAllFeatures()
	-- 1. Explicitly stop/disable major systems WHILE THEY ARE STILL MARKED AS ACTIVE
	if States.FLYING or States.isFlying then stopFly() end
	if States.isNoclip then disableNoclip() end
	if States.isFullbright then disableFullbright() end
	if States.isNoFog then disableNoFog() end
	if States.isNoShadow then disableNoShadow() end
	if States.isVisibleAllParts then disableVisibleAllParts() end
	if States.isNoTouch then disableNoTouch() end
	if States.isAutoInteractProximity then disableAutoInteractProximity() end
	if States.isInvisible then disableInvisible() end
	if freecamController and freecamController.isEnabled() then freecamController.stop() end
	if States.isMouseLocked then disableMouseLock() end
	if States.isCameraControl then toggleCameraControl(false) end -- Added explicit cleanup
	if States.isAntiMovementDelay then disableAntiMovementDelay() end
	if States.isFloating then disableFloating() end
	if States.isAntiFling then disableAntiFling() end
	if States.isSpectating then stopSpectate() end
	if States.isJumpSpam then stopJumpSpam() end
	if States.isEspUniversal then refreshAllEsp() end
	if States.isXRay then disableXRay() end
	if States.isNetworkClaim then toggleNetworkClaim() end
	if States.isPartFling then togglePartFling() end
	
	-- New features explicit cleanup
	-- NoFall features removed
	if States.isInfiniteOxygenStamina then U.toggleInfiniteOxygenStamina() end
	if States.isFastAntiTraffic then toggleFastAntiTraffic() end
	if States.isAntiCheatBypass then pcall(applyAntiCheatBypass) end
	
	if States.isAutoWalk then
		States.isAutoWalk = false
		local _char = localPlayer.Character
		local _hum = _char and _char:FindFirstChildOfClass("Humanoid")
		if _hum then _hum:Move(Vector3.new(0,0,0), false) end
	end

	-- 2. ESP Cleanup
	States.isEspUniversal = false
	States.isEspTeam = false
	States.isEspEnemy = false
	States.isEspNpc = false
	States.isEspItems = false
	refreshAllEsp()
	updateEspForItems()
	
	-- 3. Restore Character Stats to config defaults
	local h, _ = U.getHumanoidAndRoot()
	if h then
		h.WalkSpeed = Config.defaultWalkSpeedFromCharacter
		if h.UseJumpPower ~= nil and h.UseJumpPower == false then
			h.JumpHeight = Config.baseJumpPower
		else
			h.JumpPower = Config.baseJumpPower
		end
		h.AutoRotate = true
		h.CameraOffset = Vector3.new(0, 0, 0)
		h.PlatformStand = false
	end

	-- 4. Restore World Stats & Camera
	pcall(function()
		workspace.Gravity = Config.DEFAULT_GRAVITY
		S.Lighting.ClockTime = Config.DEFAULT_CLOCKTIME
		if workspace.CurrentCamera then
			workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
			localPlayer.CameraMode = Enum.CameraMode.Classic
		end
	end)

	-- 5. MANDATORY CURSOR RESET
	pcall(function()
		S.UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		S.UserInputService.MouseIconEnabled = true
		if Refs.crosshairGui then
			Refs.crosshairGui.Enabled = false
		end
	end)

	-- 6. Zero out all state flags to be sure
	for key, val in pairs(States) do
		if typeof(val) == "boolean" and key:find("^is") and key ~= "isDestroyed" and key ~= "isMinimized" then
			States[key] = false
		end
	end

	-- 7. Update all UI buttons state to [OFF]
	if UI.buttons then
		for _, btn in pairs(UI.buttons) do
			if typeof(btn) == "Instance" and btn:IsA("TextButton") then
				U.setButtonState(btn, false)
			end
		end
	end
	
	U.notify("Reset Complete", "All features have been disabled and reverted.", 3)
end

destroyPanel = function()
	-- Call reset first to clean up game state
	resetAllFeatures()
	
	-- Stop destruction flag
	States.isDestroyed = true
	
	-- Click TP Logic
	if Refs.clickTpConn then
		Refs.clickTpConn:Disconnect()
		Refs.clickTpConn = nil
	end
	
	-- Remove NoCollide Logic
	if States.isRemoveNCActive then
		toggleNonCollideParts()
	end

	-- 2. Disconnect global connections
	if Refs.characterAddedConn then Refs.characterAddedConn:Disconnect(); Refs.characterAddedConn = nil end
	if Refs.playerAddedConn then Refs.playerAddedConn:Disconnect(); Refs.playerAddedConn = nil end
	if Refs.playerRemovingConn then Refs.playerRemovingConn:Disconnect(); Refs.playerRemovingConn = nil end
	if Refs.npcDescendantConn then Refs.npcDescendantConn:Disconnect(); Refs.npcDescendantConn = nil end
	if Refs.npcDescendantRemovingConn then Refs.npcDescendantRemovingConn:Disconnect(); Refs.npcDescendantRemovingConn = nil end
	
	if Refs.mainInputConn then Refs.mainInputConn:Disconnect(); Refs.mainInputConn = nil end
	if Refs.crosshairLoopConn then Refs.crosshairLoopConn:Disconnect(); Refs.crosshairLoopConn = nil end
	
	if Refs.Active then Refs.Active:Disconnect(); Refs.Active = nil end
	if Refs.Noclipping then Refs.Noclipping:Disconnect(); Refs.Noclipping = nil end
	if Refs.clockTimeLockConnection then Refs.clockTimeLockConnection:Disconnect(); Refs.clockTimeLockConnection = nil end
	
	for _, conn in pairs(Refs.connections) do
		if typeof(conn) == "RBXScriptConnection" then
			conn:Disconnect()
		end
	end
	table.clear(Refs.connections)
	
	-- Restore Metatable if modified
	pcall(function()
		local MT = E.getrawmetatable(game)
		if MT then
			E.setreadonly(MT, false)
			if Refs.originalNamecall then MT.__namecall = Refs.originalNamecall end
			if Refs.originalIndex then MT.__index = Refs.originalIndex end
			if Refs.originalNewIndex then MT.__newindex = Refs.originalNewIndex end
			E.setreadonly(MT, true)
		end
	end)
	
	for _, conns in pairs(Refs.espConnections) do
		if typeof(conns) == "table" then
			for _, conn in ipairs(conns) do
				if typeof(conn) == "RBXScriptConnection" then
					conn:Disconnect()
				end
			end
		end
	end

	-- 2.b Unbind ALL RenderStep bindings
	local renderBindings = {
		"AdminFlashSpeed", "AdminBackwardsWalk", "AdminSpin", 
		"AdminSpiderClimb", "AdminAirWalk", "AdminAntiMovDelay",
		"AdminAutoWalk", "AdminShiftLock", "AdminCrosshairSync",
		"Freecam"
	}
	for _, name in ipairs(renderBindings) do
		pcall(function() S.RunService:UnbindFromRenderStep(name) end)
	end

	-- 2.c Disconnect InputEnded
	if Refs.mainInputEndedConn then Refs.mainInputEndedConn:Disconnect(); Refs.mainInputEndedConn = nil end

	-- 3. Restore Character Stats
	local character = localPlayer.Character
	if character then
		local h, _r = U.getHumanoidAndRoot()
		if h then
			h.WalkSpeed = Config.defaultWalkSpeedFromCharacter
			if h.UseJumpPower ~= nil and h.UseJumpPower == false then
				h.JumpHeight = Config.baseJumpPower
			else
				h.JumpPower = Config.baseJumpPower
			end
			h.AutoRotate = true
			h.CameraOffset = Vector3.new(0, 0, 0)
			h.PlatformStand = false
		end
	end

	-- 4. Restore World Stats
	pcall(function()
		workspace.Gravity = Config.DEFAULT_GRAVITY
		S.Lighting.ClockTime = Config.DEFAULT_CLOCKTIME
	end)

	-- 5. Destroy UI Elements
	if UI.screenGui then UI.screenGui:Destroy() end
	if Refs.crosshairGui then Refs.crosshairGui:Destroy() end
	
	-- Clean up S.ContextActionService bindings
	pcall(function()
		S.ContextActionService:UnbindAction("FreecamToggle")
		S.ContextActionService:UnbindAction("FreecamKeyboard")
		S.ContextActionService:UnbindAction("FreecamMousePan")
		S.ContextActionService:UnbindAction("FreecamMouseWheel")
		S.ContextActionService:UnbindAction("FreecamGamepadButton")
		S.ContextActionService:UnbindAction("FreecamGamepadTrigger")
		S.ContextActionService:UnbindAction("FreecamGamepadThumbstick")
		
		-- Also unbind all AdminSinks to prevent input blocking stuck after destroy
		if Config.keybinds then
			for action, _ in pairs(Config.keybinds) do
				S.ContextActionService:UnbindAction("AdminSink_" .. action)
			end
		end
	end)

	print("panel-admin.client: Admin panel and logic cleaned up")
	
	pcall(function()
		script:Destroy()
	end)
end


---------------------------------------------------------------------
-- UI WIRING & POPULATION (CONSOLIDATED AT THE BOTTOM)
---------------------------------------------------------------------

Refs.mainInputConn = S.UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- [CRITICAL FIX] Assignment Interceptor MUST be at the very top.
	-- This allows keybind capture even when the Keybind TextBox is focused.
	if Config.isAssigningKey then
		-- Skip the input if it's too close to the start time (prevents auto-binding to the click that triggered this)
		if (tick() - Config.assigningStartTime) < 0.15 then return end

		-- Cancel with Escape
		if input.KeyCode == Enum.KeyCode.Escape then
			local action = Config.isAssigningKey
			Config.isAssigningKey = nil
			if UI.keybindInputs[action] then
				UI.keybindInputs[action].Text = Config.keybinds[action].Name
				UI.keybindInputs[action]:ReleaseFocus()
			end
			U.refreshDynamicButtons()
			U.notify("Cancelled", "Binding cancelled for " .. action, 2)
			return
		end
		
		-- Unbind with Delete or Backspace
		if input.KeyCode == Enum.KeyCode.Delete or input.KeyCode == Enum.KeyCode.Backspace then
			local action = Config.isAssigningKey
			Config.isAssigningKey = nil
			Config.keybinds[action] = Enum.KeyCode.Unknown
			if UI.keybindInputs[action] then
				UI.keybindInputs[action].Text = "Unknown"
				UI.keybindInputs[action]:ReleaseFocus()
			end
			U.refreshDynamicButtons()
			U.refreshInputSinks()
			U.notify("Unbound", action .. " keybind removed", 2)
			U.saveSettings()
			return
		end

		local isMouse = input.UserInputType.Name:find("MouseButton")
		if (input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode ~= Enum.KeyCode.Return) or isMouse then
			local action = Config.isAssigningKey
			
			-- Use UserInputType for mouse buttons, KeyCode for keys
			local bindValue = isMouse and input.UserInputType or input.KeyCode
			Config.keybinds[action] = bindValue
			Config.isAssigningKey = nil
			
			if UI.keybindInputs[action] then
				UI.keybindInputs[action].Text = bindValue.Name
				UI.keybindInputs[action]:ReleaseFocus()
			end
			
			U.refreshDynamicButtons()
			U.refreshInputSinks() -- Update sinks for new key
			U.notify("Keybind Updated", action .. " set to " .. bindValue.Name, 2)
			U.saveSettings()
		end
		return
	end

	local kb = Config.keybinds
	-- Helper for comparing both KeyCode and UserInputType against a bind
	local function matches(bind)
		return (input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode == bind) or
		       (input.UserInputType ~= Enum.UserInputType.Keyboard and input.UserInputType == bind)
	end

	-- [BYPASS] Camera control escapes (Middle Click, Alt, or FlashSpeed)
	-- Allows toggling these even if game GUI is obscuring the center of the screen,
	-- as long as we aren't typing in a TextBox.
	if not S.UserInputService:GetFocusedTextBox() then
		if input.UserInputType == Enum.UserInputType.MouseButton3 or 
		   input.KeyCode == kb.MouseLock or 
		   input.KeyCode == kb.FlashSpeed then
			
			if input.UserInputType == Enum.UserInputType.MouseButton3 then
				toggleCameraControl()
			elseif input.KeyCode == kb.MouseLock then
				ShiftLock()
				U.setButtonState(UI.buttons.mouseLock, States.isMouseLocked)
				U.notifyToggle("Mouse Lock", States.isMouseLocked)
			elseif input.KeyCode == kb.FlashSpeed then
				toggleFlashSpeed(true)
				U.setButtonState(UI.buttons.flashSpeed, States.isFlashSpeedEnabled)
			end
			return
		end
	end


	-- Allow our keys to pass even if gameProcessed is true, UNLESS we are typing in a TextBox.
	-- This ensures 'Block Game Keybinds' (which sets gameProcessed=true) works, but typing in chat doesn't.
	if gameProcessed and S.UserInputService:GetFocusedTextBox() then return end

	-- General
	if matches(kb.ToggleGui) then
		UI.screenGui.Enabled = not UI.screenGui.Enabled
	elseif matches(kb.Minimize) then
		States.isMinimized = not States.isMinimized
		if States.isMinimized then
			UI.mainFrame.Visible = false
			UI.pages[currentTab].Parent.Visible = false
			UI.sidebar.Visible = false
		else
			UI.mainFrame.Size = UDim2.new(0, 600, 0, 550)
			UI.pages[currentTab].Parent.Visible = true
			UI.mainFrame.Visible = true
			UI.sidebar.Visible = true
		end
	elseif matches(kb.Destroy) then
		destroyPanel()
	elseif matches(kb.Rejoin) then
		rejoinServer()
	elseif matches(kb.ServerHop) then
		serverHop()

	-- Movement
	elseif matches(kb.Fly) then
		if States.isFlying then stopFly() else startFly(false) end
		U.setButtonState(UI.buttons.fly, States.isFlying)
		U.notifyToggle("Fly", States.isFlying)
	elseif matches(kb.Noclip) then
		if States.isNoclip then disableNoclip() else enableNoclip() end
		U.setButtonState(UI.buttons.noclip, States.isNoclip)
		U.notifyToggle("Noclip", States.isNoclip)
	elseif matches(kb.WalkBoost) then
		States.isWalkBoost = not States.isWalkBoost
		local h, _ = U.getHumanoidAndRoot()
		if h then applyMovementStats(h) end
		U.setButtonState(UI.buttons.walkBoost, States.isWalkBoost)
		U.notifyToggle(States.isFlying and "Fly Boost (2x)" or "Walk Boost", States.isWalkBoost)
	elseif matches(kb.JumpBoost) then
		States.isJumpBoost = not States.isJumpBoost
		local h, _ = U.getHumanoidAndRoot()
		if h then applyMovementStats(h) end
		U.setButtonState(UI.buttons.jumpBoost, States.isJumpBoost)
		U.notifyToggle("Jump Boost", States.isJumpBoost)
	elseif matches(kb.JumpSpam) then
		States.isJumpSpam = not States.isJumpSpam
		if States.isJumpSpam then startJumpSpam() else stopJumpSpam() end
		U.setButtonState(UI.buttons.jumpSpam, States.isJumpSpam)
		U.notifyToggle("Spam Jump", States.isJumpSpam)
	elseif matches(kb.AutoWalk) then
		toggleAutoWalk()
		U.setButtonState(UI.buttons.autoWalk, States.isAutoWalk)
	elseif matches(kb.AirWalk) then
		toggleAirWalk()
	elseif matches(kb.AirWalkBack) then
		toggleBackwardsWalk()
	elseif matches(kb.SpiderClimb) then
		toggleSpiderClimb()
	elseif matches(kb.Spin) then
		toggleSpin()
	elseif matches(kb.Flip) then
		toggleBackwardsWalk()
	elseif matches(kb.UnlockJump) then
		toggleUnlockJump()
		U.setButtonState(UI.buttons.unlockJump, States.isUnlockJump)
		U.notifyToggle("Unlock Jump", States.isUnlockJump)
	elseif matches(kb.VehicleStop) then
		local char = localPlayer.Character
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		local seat = humanoid and humanoid.SeatPart
		if seat and seat:IsA("VehicleSeat") then
			local root = seat.AssemblyRootPart or seat
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			U.notify("Vehicle", "Stopped vehicle instantly", 1.5)
		end
	elseif matches(kb.Invisible) then
		toggleInvisible()
		U.setButtonState(UI.buttons.invisible, States.isInvisible)
		U.notifyToggle("Invisible", States.isInvisible)

	-- Visuals
	elseif matches(kb.Fullbright) then
		toggleFullbright()
	elseif matches(kb.NoFog) then
		if States.isNoFog then disableNoFog() else enableNoFog() end
		U.setButtonState(UI.buttons.noFog, States.isNoFog)
		U.notifyToggle("No Fog", States.isNoFog)
	elseif matches(kb.NoShadow) then
		toggleNoShadow()
	elseif matches(kb.VisibleAllParts) then
		toggleVisibleAllParts()
	elseif matches(kb.XRay) then
		toggleXRay()
		U.setButtonState(UI.buttons.xray, States.isXRay)
		U.notifyToggle("X-Ray", States.isXRay)
	elseif matches(kb.EspAll) then
		States.isEspUniversal = not States.isEspUniversal
		refreshAllEsp()
		U.setButtonState(UI.buttons.espAll, States.isEspUniversal)
		U.notifyToggle("ESP All", States.isEspUniversal)
	elseif matches(kb.EspEnemy) then
		States.isEspEnemy = not States.isEspEnemy
		refreshAllEsp()
		U.setButtonState(UI.buttons.espEnemy, States.isEspEnemy)
		U.notifyToggle("ESP Enemy", States.isEspEnemy)
	elseif matches(kb.EspNpc) then
		States.isEspNpc = not States.isEspNpc
		if States.isEspNpc then scanWorkspaceForNPCs() else refreshAllEsp() end
		U.setButtonState(UI.buttons.espNpc, States.isEspNpc)
		U.notifyToggle("ESP NPC", States.isEspNpc)
	elseif matches(kb.EspItems) then
		States.isEspItems = not States.isEspItems
		updateEspForItems()
		U.setButtonState(UI.buttons.espItems, States.isEspItems)
		U.notifyToggle("ESP Items", States.isEspItems)
	elseif matches(kb.Spectate) then
		if States.isSpectating then stopSpectate() else toggleSpectate(Refs.selectedTeleportPlayer) end
		U.setButtonState(UI.buttons.spectate, States.isSpectating)
		U.notifyToggle("Spectate", States.isSpectating)
	elseif matches(kb.Freecam) then
		if freecamController.isEnabled() then freecamController.stop() else freecamController.start() end
		U.setButtonState(UI.buttons.freecam, freecamController.isEnabled())
		U.notifyToggle("Freecam", freecamController.isEnabled())

	-- Physics / Combat
	elseif matches(kb.Floating) then
		toggleFloating()
		U.setButtonState(UI.buttons.floating, States.isFloating)
		U.notifyToggle("Floating", States.isFloating)
	elseif matches(kb.AntiFling) then
		toggleAntiFling()
		U.setButtonState(UI.buttons.antiFling, States.isAntiFling)
		U.notifyToggle("Anti Fling", States.isAntiFling)
	elseif matches(kb.ClickTp) then
		toggleClickTeleport()
	elseif matches(kb.NoTouch) then
		if States.isNoTouch then disableNoTouch() else enableNoTouch() end
		U.setButtonState(UI.buttons.noTouch, States.isNoTouch)
		U.notifyToggle("No Touch", States.isNoTouch)
	elseif matches(kb.RemoveNC) then
		toggleNonCollideParts()
		U.setButtonState(UI.buttons.removeNC, States.isRemoveNCActive)
		U.notifyToggle("Remove NoCollide", States.isRemoveNCActive)
	elseif matches(kb.Recovery) then
		States.isAutoTpToSave = not States.isAutoTpToSave
		if States.isAutoTpToSave and not States.savedPosition then
			local character = localPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then States.savedPosition = root.CFrame end
		end
		U.setButtonState(UI.buttons.autoTpOnDeath, States.isAutoTpToSave)
		U.notifyToggle("Recovery Mode", States.isAutoTpToSave)
	elseif matches(kb.VehicleFly) then
		if States.isVehicleFly then stopFly() else startFly(true) end
		U.setButtonState(UI.buttons.vehicleFly, States.isVehicleFly)
		U.notifyToggle("Vehicle Fly", States.isVehicleFly)
	elseif matches(kb.VehicleBoost) then
		States.isVehicleBoost = not States.isVehicleBoost
		U.setButtonState(UI.buttons.vehicleBoost, States.isVehicleBoost)
		U.notifyToggle("Vehicle Boost", States.isVehicleBoost)
	
	-- Physic
	elseif matches(kb.NetworkClaim) then
		toggleNetworkClaim()
	elseif matches(kb.PartFling) or matches(kb.RadiusFling) then
		togglePartFling()
	elseif matches(kb.LockTime) then
		U.toggleTimeLock()
	elseif matches(kb.FastAntiTraffic) then
	elseif matches(kb.RecordPath) then
		U.togglePathRecord()
	elseif matches(kb.PlayPath) then
		U.togglePathPlayback()
	elseif matches(kb.StopPath) then
		U.stopPathPlayback()
	elseif matches(kb.AddWaypoint) then
		U.addWaypoint()
	elseif matches(kb.ClearWaypoints) then
		States.waypoints = {}
		U.refreshWaypointListUI()
		U.notify("Waypoints", "All waypoints cleared", 2)
	elseif matches(kb.GetBTools) then
		getBTools()
	elseif matches(kb.LoadDex) then
		pcall(function() _G.FVKHUB_LoadDex() end)
	elseif matches(kb.LoadSpy) then
		pcall(function() 
			local spy = loadstring(game:HttpGet("https://raw.githubusercontent.com/78n/SimpleSpy/main/main.lua"))
			if spy then spy() end
		end)
	elseif matches(kb.SkipCutscene) then
		skipCutscene()
	elseif matches(kb.SkipLoading) then
		skipLoadingScreen()
	elseif matches(kb.AutoTeleport) then
		U.toggleAutoTeleport()
	elseif matches(kb.PauseAutoTeleport) then
		U.toggleAutoTeleportPause()
	elseif matches(kb.AntiAfk) then
		States.isAntiAfk = not States.isAntiAfk
		U.setButtonState(UI.buttons.antiAfk, States.isAntiAfk)
		U.notifyToggle("Anti-AFK", States.isAntiAfk)
	elseif matches(kb.AntiCheatBypass) then
		States.isAntiCheatBypass = not States.isAntiCheatBypass
		if UI.buttons.bypassAC then U.setButtonState(UI.buttons.bypassAC, States.isAntiCheatBypass) end
		if UI.buttons.bypassAC_Config then U.setButtonState(UI.buttons.bypassAC_Config, States.isAntiCheatBypass) end
		U.notifyToggle("Anti-Cheat Bypass", States.isAntiCheatBypass)
	end
end)

Refs.mainInputEndedConn = S.UserInputService.InputEnded:Connect(function(input, _)
	if input.KeyCode == Config.keybinds.FlashSpeed then
		toggleFlashSpeed(false)
		U.setButtonState(UI.buttons.flashSpeed, States.isFlashSpeedEnabled)
	end
end)

destroyButton.MouseButton1Click:Connect(function()
	destroyPanel()
end)


-- Ping update loop (Stealthy & Optimized)
task.spawn(function()
	while not States.isDestroyed do
		pcall(function()
			if UI.pingLabel and UI.pingLabel.Parent then
				-- Get current network ping (Returns seconds, convert to MS)
				local pingValue = localPlayer:GetNetworkPing() * 1000
				
				-- Ensure non-zero/reasonable value
				if pingValue <= 0 then
					-- Secondary fallback for some executors if GetNetworkPing is nil/zero
					pcall(function()
						local stats = getService("Stats")
						local network = stats and stats:FindFirstChild("Network")
						local statsItem = network and network:FindFirstChild("ServerStatsItem")
						local dataPing = statsItem and statsItem:FindFirstChild("Data Ping")
						if dataPing then pingValue = dataPing:GetValue() end
					end)
				end
				
				local ping = math.round(pingValue)
				UI.pingLabel.Text = string.format("PING: %d ms", ping)
				
				-- Dynamic color coding
				if ping < 150 then
					UI.pingLabel.TextColor3 = Color3.fromRGB(0, 255, 230) -- Healthy
				elseif ping < 350 then
					UI.pingLabel.TextColor3 = Color3.fromRGB(255, 200, 50) -- Lagging
				else
					UI.pingLabel.TextColor3 = Color3.fromRGB(255, 80, 80) -- High Latency
				end
			end
		end)
		task.wait(2)
	end
end)

-- Finalizing GUI population (to ensure all functions are defined)
task.defer(function()
	-- HOME PAGE CONTENT
	-- DYNAMIC DASHBOARD UTILITIES
	local dashUtilRow = Instance.new("Frame")
	dashUtilRow.Name = "DashUtilRow"
	dashUtilRow.Size = UDim2.new(1, -10, 0, 32)
	dashUtilRow.BackgroundTransparency = 1
	dashUtilRow.Parent = dashboardPage

	local rejoinBtn = Instance.new("TextButton")
	rejoinBtn.Size = UDim2.new(0.5, -2, 1, 0)
	rejoinBtn.BackgroundColor3 = Color3.fromRGB(40, 50, 80)
	rejoinBtn.Text = "REJOIN SERVER"
	rejoinBtn.Font = Enum.Font.GothamBold
	rejoinBtn.TextSize = 10
	rejoinBtn.TextColor3 = Color3.fromRGB(240, 245, 255)
	rejoinBtn.Parent = dashUtilRow
	Instance.new("UICorner", rejoinBtn).CornerRadius = UDim.new(0, 8)
	rejoinBtn.MouseButton1Click:Connect(function() rejoinServer() end)

	local hopBtn = Instance.new("TextButton")
	hopBtn.Size = UDim2.new(0.5, -2, 1, 0)
	hopBtn.Position = UDim2.new(0.5, 2, 0, 0)
	hopBtn.BackgroundColor3 = Color3.fromRGB(40, 50, 80)
	hopBtn.Text = "SERVER HOP"
	hopBtn.Font = Enum.Font.GothamBold
	hopBtn.TextSize = 10
	hopBtn.TextColor3 = Color3.fromRGB(240, 245, 255)
	hopBtn.Parent = dashUtilRow
	Instance.new("UICorner", hopBtn).CornerRadius = UDim.new(0, 8)
	hopBtn.MouseButton1Click:Connect(function() serverHop() end)

	-- HOME PAGE CONTENT
	local welcomeLab = Instance.new("TextLabel")
	welcomeLab.Size = UDim2.new(1, 0, 0, 40)
	welcomeLab.BackgroundTransparency = 1
	welcomeLab.Text = "Welcome to FVK HUB Admin Panel"
	welcomeLab.Font = Enum.Font.GothamBold
	welcomeLab.TextSize = 14
	welcomeLab.TextColor3 = Color3.fromRGB(60, 100, 255)
	welcomeLab.Parent = homePage

	local btoolsHomeBtn = Instance.new("TextButton")
	btoolsHomeBtn.Size = UDim2.new(1, 0, 0, 32)
	btoolsHomeBtn.BackgroundColor3 = Color3.fromRGB(60, 80, 160)
	btoolsHomeBtn.BorderSizePixel = 0
	btoolsHomeBtn.Text = "🛠️ GET BTOOLS (INSERT)"
	btoolsHomeBtn.Font = Enum.Font.GothamBold
	btoolsHomeBtn.TextSize = 13
	btoolsHomeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btoolsHomeBtn.Parent = homePage
	local btCorner = Instance.new("UICorner")
	btCorner.CornerRadius = UDim.new(0, 8)
	btCorner.Parent = btoolsHomeBtn

	btoolsHomeBtn.MouseButton1Click:Connect(function()
		pcall(function() _G.FVKHUB_GetBTools() end)
	end)

	local resetAllBtn = Instance.new("TextButton")
	resetAllBtn.Size = UDim2.new(1, 0, 0, 32)
	resetAllBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 40)
	resetAllBtn.BackgroundTransparency = 0.2
	resetAllBtn.BorderSizePixel = 0
	resetAllBtn.Text = "🚨 RESET ALL FEATURES"
	resetAllBtn.Font = Enum.Font.GothamBold
	resetAllBtn.TextSize = 13
	resetAllBtn.TextColor3 = Color3.fromRGB(255, 235, 225)
	resetAllBtn.Parent = homePage
	local resetCorner = Instance.new("UICorner")
	resetCorner.CornerRadius = UDim.new(0, 8)
	resetCorner.Parent = resetAllBtn

	resetAllBtn.MouseButton1Click:Connect(function()
		resetAllFeatures()
	end)

	UI.buttons.mouseLock = createToggleButton("MouseLock", "Mouse Lock / POV", homePage)
	UI.buttons.antiDelay = createToggleButton("AntiDelay", "Anti Movement Delay", homePage)
	UI.buttons.autoInteract = createToggleButton("AutoInteract", "Auto Interact", homePage)
	UI.buttons.radiusControl = createToggleButton("RadiusFling", "Radius Fling Aura", homePage)
	UI.buttons.radiusControl.MouseButton1Click:Connect(togglePartFling)

	-- VISUALS PAGE CONTENT
	UI.buttons.espAll = createToggleButton("EspAll", "ESP All S.Players", visualsPage)
	UI.buttons.espEnemy = createToggleButton("EspEnemy", "ESP Enemy", visualsPage)
	UI.buttons.espNpc = createToggleButton("EspNpc", "ESP NPC", visualsPage)
	UI.buttons.espItems = createToggleButton("EspItems", "ESP Items / Proximity", visualsPage)

	UI.buttons.fullbright = createToggleButton("Fullbright", "Fullbright", visualsPage)
	UI.buttons.noFog = createToggleButton("NoFog", "No Fog", visualsPage)
	UI.buttons.noShadow = createToggleButton("NoShadow", "No Shadow", visualsPage)
	UI.buttons.visibleParts = createToggleButton("VisibleAllParts", "Visible All Parts", visualsPage)
	UI.buttons.xray = createToggleButton("XRay", "X-Ray Mode", visualsPage)
	UI.buttons.smoothZoom = createToggleButton("SmoothZoom", "Smooth Zoom", visualsPage)
	UI.buttons.cameraNoclip = createToggleButton("CameraNoclip", "Camera Noclip", visualsPage)
	UI.buttons.antiJumpscare = createToggleButton("AntiJumpscare", "Anti Jumpscare Mode", visualsPage)
	UI.buttons.antiJumpscare.MouseButton1Click:Connect(toggleAntiJumpscare)
	U.setButtonState(UI.buttons.antiJumpscare, States.isAntiJumpscare)

	-- PLAYER PAGE CONTENT
	-- CORE MOVEMENT CONTROLS
	UI.buttons.fly = createToggleButton("Fly", "Fly Mode [Q/E]", playerPage)
	UI.buttons.flashSpeed = createToggleButton("FlashSpeed", "CFrame Speed (Flash)", playerPage)
	UI.buttons.noclip = createToggleButton("Noclip", "Noclip Protocol", playerPage)
	UI.buttons.clickTp = createToggleButton("ClickTp", "Click Teleport (Ctrl)", playerPage)

	-- BODY MODIFICATIONS
	UI.buttons.invisible = createToggleButton("Invisible", "Invisibility Protocol", playerPage)
	UI.buttons.backwardsWalk = createToggleButton("AirWalkBack", "Backward Walk", playerPage)
	UI.buttons.spin = createToggleButton("Spin", "Character Spin", playerPage)
	UI.buttons.spiderClimb = createToggleButton("SpiderClimb", "Spider Climb", playerPage)
	UI.buttons.airWalk = createToggleButton("AirWalk", "Air Walk / Plate", playerPage)

	-- ADVANCED PROTOCOL PROTECTION
	UI.buttons.antiFling = createToggleButton("AntiFling", "Advanced Anti-Fling", playerPage)
-- GodMode button removed
	UI.buttons.noTouch = createToggleButton("NoTouch", "No-Touch Protocol", playerPage)
	UI.buttons.bypassAC = createToggleButton("AntiCheatBypass", "Anti-Cheat Bypass Protocol", playerPage)

	-- CAPABILITY MULTIPLIERS
	UI.buttons.walkOverride = createToggleButton("WalkOverride", "Manual Speed Override", playerPage)
	UI.buttons.walkBoost = createToggleButton("WalkBoost", "Dynamic Speed Boost", playerPage)
	UI.buttons.jumpBoost = createToggleButton("JumpBoost", "High Jump Multiplier", playerPage)
	UI.buttons.jumpSpam = createToggleButton("JumpSpam", "Infinite / Spam Jump", playerPage)
	UI.buttons.unlockJump = createToggleButton("UnlockJump", "Unlock Stuck Jump", playerPage)
	
-- NoFall UI removed

	UI.buttons.infOxygenStamina = createToggleButton("InfOxygen", "Inf Oxygen / Stamina", playerPage)
	UI.buttons.infOxygenStamina.MouseButton1Click:Connect(U.toggleInfiniteOxygenStamina)
	U.setButtonState(UI.buttons.infOxygenStamina, States.isInfiniteOxygenStamina)
	
	-- Vehicle features moved to Vehicle page

	-- ACTION AUTOMATION
	-- ADVANCED TOOLS
	UI.buttons.freecam = createToggleButton("Freecam", "Cinematic Freecam", playerPage)
	UI.buttons.skipCutscene = createToggleButton("SkipCutscene", "Skip Cutscenes", playerPage)
	UI.buttons.skipLoading = createToggleButton("SkipLoading", "Skip Loading Screens", playerPage)
	UI.buttons.removeNC = createToggleButton("RemoveNC", "Remove Non-Collide", playerPage)
	UI.buttons.floating = createToggleButton("Floating", "Floating Mode", playerPage)
	
	-- Connections for character actions (Ensuring no nil errors)
	UI.buttons.backwardsWalk.MouseButton1Click:Connect(toggleBackwardsWalk)
	UI.buttons.spin.MouseButton1Click:Connect(toggleSpin)
	UI.buttons.spiderClimb.MouseButton1Click:Connect(toggleSpiderClimb)
	UI.buttons.airWalk.MouseButton1Click:Connect(toggleAirWalk)
	UI.buttons.skipCutscene.MouseButton1Click:Connect(skipCutscene)
	UI.buttons.skipLoading.MouseButton1Click:Connect(skipLoadingScreen)
	
	-- Vehicle boost toggle connection moved to bottom definition section


	-- VEHICLE PAGE CONTENT
	UI.buttons.vehicleFly = createToggleButton("VehicleFly", "Vehicle Fly (CFrame)", vehiclePage)
	UI.buttons.vehicleBoost = createToggleButton("VehicleBoost", "Vehicle Boost (Integrated Accelerator)", vehiclePage)
	UI.buttons.autoTransmission = createToggleButton("", "Vehicle Auto-Matic Gear (Matic)", vehiclePage)
	UI.buttons.vehicleSprings = createToggleButton("", "Show Vehicle Springs", vehiclePage)
	
	UI.buttons.vehicleSprings.MouseButton1Click:Connect(function()
		States.isVehicleSprings = not States.isVehicleSprings
		U.setButtonState(UI.buttons.vehicleSprings, States.isVehicleSprings)
		U.notifyToggle("Vehicle Springs", States.isVehicleSprings)
		pcall(function()
			local root = U.getSeatedVehicleRoot()
			local vehicle = root and root:FindFirstAncestorWhichIsA("Model")
			if vehicle then
				for _, v in ipairs(vehicle:GetDescendants()) do
					if v:IsA("SpringConstraint") then v.Visible = States.isVehicleSprings end
				end
			end
		end)
	end)

	UI.buttons.vehicleFly.MouseButton1Click:Connect(function()
		if States.isVehicleFly then stopFly() else startFly(true) end
		U.setButtonState(UI.buttons.vehicleFly, States.isVehicleFly)
		U.notifyToggle("Vehicle Fly", States.isVehicleFly)
	end)

	UI.inputs.vehicleFlySpeed = createLabeledInput("Flight Speed:", tostring(Config.vehicleFlySpeed or 100), vehiclePage)

	UI.buttons.vehicleBoost.MouseButton1Click:Connect(function()
		toggleVehicleBoost()
		U.setButtonState(UI.buttons.vehicleBoost, States.isVehicleBoost)
	end)

	UI.inputs.vehicleBoostAccelInput = createLabeledInput("Boost Mult (Thousandths):", tostring(Config.vehicleBoostAcceleration or 25), vehiclePage)

	UI.buttons.autoTransmission.MouseButton1Click:Connect(function()
		States.isAutoTransmission = not States.isAutoTransmission
		U.setButtonState(UI.buttons.autoTransmission, States.isAutoTransmission)
		U.notifyToggle("Auto Transmission", States.isAutoTransmission)
		U.saveSettings()
	end)

	UI.inputs.vehicleBrakeInput = createLabeledInput("Brake Force (Thousandths):", tostring(Config.vehicleBrakeForce or 150), vehiclePage)

	U.setButtonState(UI.buttons.vehicleBoost, States.isVehicleBoost)
	U.setButtonState(UI.buttons.vehicleFly, States.isVehicleFly)
	U.setButtonState(UI.buttons.autoTransmission, States.isAutoTransmission)
	U.setButtonState(UI.buttons.vehicleSprings, States.isVehicleSprings)

	-- TOOLS PAGE CONTENT
	-- TOOLS PAGE CONTENT
	UI.buttons.autoInteract = createToggleButton("AutoInteract", "Auto Interact / Proximity", toolsPage)
	UI.buttons.autoInteract.MouseButton1Click:Connect(function()
		States.isAutoInteract = not States.isAutoInteract
		U.setButtonState(UI.buttons.autoInteract, States.isAutoInteract)
		U.notifyToggle("Auto Interact", States.isAutoInteract)
	end)

	
	-- AUTOWALK PAGE CONTENT
	UI.buttons.autoWalk = createToggleButton("AutoWalk", "Auto Walk Smooth", autoWalkPage)
	
	local pathRow = Instance.new("Frame")
	pathRow.Name = "PathRow"
	pathRow.Size = UDim2.new(1, -10, 0, 32)
	pathRow.BackgroundTransparency = 1
	pathRow.Parent = autoWalkPage
	
	UI.buttons.recordPath = createToggleButton("RecordPath", "REC Path", pathRow)
	UI.buttons.recordPath.Size = UDim2.new(0.33, -4, 1, 0)
	UI.buttons.recordPath.MouseButton1Click:Connect(U.togglePathRecord)
	
	UI.buttons.pauseRecord = createToggleButton("", "|| Pause REC", pathRow)
	UI.buttons.pauseRecord.Size = UDim2.new(0.33, -4, 1, 0)
	UI.buttons.pauseRecord.Position = UDim2.new(0.33, 2, 0, 0)
	UI.buttons.pauseRecord.MouseButton1Click:Connect(U.togglePathRecordPause)
	
	UI.buttons.playPath = createToggleButton("PlayPath", "PLAY Path", pathRow)
	UI.buttons.playPath.Size = UDim2.new(0.33, -4, 1, 0)
	UI.buttons.playPath.Position = UDim2.new(0.66, 4, 0, 0)
	UI.buttons.playPath.MouseButton1Click:Connect(U.togglePathPlayback)

	local controlRow = Instance.new("Frame")
	controlRow.Name = "ControlRow"
	controlRow.Size = UDim2.new(1, -10, 0, 32)
	controlRow.BackgroundTransparency = 1
	controlRow.Parent = autoWalkPage
	
	UI.buttons.backwardPath = createToggleButton("", "<< Back", controlRow)
	UI.buttons.backwardPath.Size = UDim2.new(0.25, -4, 1, 0)
	UI.buttons.backwardPath.MouseButton1Click:Connect(function() U.setPathDirection(-1) end)
	
	UI.buttons.pausePath = createToggleButton("", "|| Pause", controlRow)
	UI.buttons.pausePath.Size = UDim2.new(0.25, -4, 1, 0)
	UI.buttons.pausePath.Position = UDim2.new(0.25, 2, 0, 0)
	UI.buttons.pausePath.MouseButton1Click:Connect(U.togglePathPause)
	
	UI.buttons.forwardPath = createToggleButton("", "Next >>", controlRow)
	UI.buttons.forwardPath.Size = UDim2.new(0.25, -4, 1, 0)
	UI.buttons.forwardPath.Position = UDim2.new(0.5, 2, 0, 0)
	UI.buttons.forwardPath.MouseButton1Click:Connect(function() U.setPathDirection(1) end)
	
	UI.buttons.stopPath = createToggleButton("StopPath", "STOP", controlRow)
	UI.buttons.stopPath.Size = UDim2.new(0.25, -4, 1, 0)
	UI.buttons.stopPath.Position = UDim2.new(0.75, 4, 0, 0)
	UI.buttons.stopPath.MouseButton1Click:Connect(U.stopPathPlayback)

	local playConfigRow = Instance.new("Frame")
	playConfigRow.Name = "PlayConfigRow"
	playConfigRow.Size = UDim2.new(1, -10, 0, 32)
	playConfigRow.BackgroundTransparency = 1
	playConfigRow.Parent = autoWalkPage

	UI.buttons.loopPath = createToggleButton("", "Loop Playback", playConfigRow)
	UI.buttons.loopPath.Size = UDim2.new(0.33, -4, 1, 0)
	UI.buttons.loopPath.MouseButton1Click:Connect(function()
		States.isPathLooping = not States.isPathLooping
		U.setButtonState(UI.buttons.loopPath, States.isPathLooping)
		U.saveSettings()
	end)

	local editRow = Instance.new("Frame")
	editRow.Name = "EditRow"
	editRow.Size = UDim2.new(1, -10, 0, 32)
	editRow.BackgroundTransparency = 1
	editRow.Parent = autoWalkPage
	
	UI.buttons.undoPath = createToggleButton("", "Undo (1s)", editRow)
	UI.buttons.undoPath.Size = UDim2.new(0.33, -4, 1, 0)
	UI.buttons.undoPath.MouseButton1Click:Connect(U.undoPathRecord)
	
	UI.buttons.visualPath = createToggleButton("", "Visualize", editRow)
	UI.buttons.visualPath.Size = UDim2.new(0.33, -4, 1, 0)
	UI.buttons.visualPath.Position = UDim2.new(0.33, 2, 0, 0)
	UI.buttons.visualPath.MouseButton1Click:Connect(U.togglePathVisualize)
	
	UI.buttons.clearPath = createToggleButton("", "Clear All", editRow)
	UI.buttons.clearPath.Size = UDim2.new(0.33, -4, 1, 0)
	UI.buttons.clearPath.Position = UDim2.new(0.66, 4, 0, 0)
	UI.buttons.clearPath.MouseButton1Click:Connect(U.clearPathRecord)

	-- Bulk Undo Points removed
	local multiUndoRow = Instance.new("Frame")
	multiUndoRow.Name = "MultiUndoRow"
	multiUndoRow.Size = UDim2.new(1, -10, 0, 30)
	multiUndoRow.BackgroundTransparency = 1
	multiUndoRow.Parent = autoWalkPage
	
	local undoValues = {5, 10, 15, 20, 25, 30, 35}
	for i, val in ipairs(undoValues) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1/#undoValues, -2, 1, 0)
		btn.Position = UDim2.new((i-1)/#undoValues, 1, 0, 0)
		btn.BackgroundColor3 = Color3.fromRGB(40, 45, 70)
		btn.BorderSizePixel = 0
		btn.Text = "-" .. val
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 11
		btn.TextColor3 = Color3.fromRGB(200, 210, 255)
		btn.Parent = multiUndoRow
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = btn
		
		btn.MouseButton1Click:Connect(function()
			U.undoPathRecord(val)
		end)
	end



	local fileRow = Instance.new("Frame")
	fileRow.Name = "FileRow"
	fileRow.Size = UDim2.new(1, -10, 0, 32)
	fileRow.BackgroundTransparency = 1
	fileRow.Parent = autoWalkPage
	
	UI.buttons.savePathFile = createToggleButton("", "SAVE File", fileRow)
	UI.buttons.savePathFile.Size = UDim2.new(0.5, -5, 1, 0)
	UI.buttons.savePathFile.MouseButton1Click:Connect(U.savePathToFile)
	
	UI.buttons.loadPathFile = createToggleButton("", "LOAD File", fileRow)
	UI.buttons.loadPathFile.Size = UDim2.new(0.5, -5, 1, 0)
	UI.buttons.loadPathFile.Position = UDim2.new(0.5, 5, 0, 0)
	UI.buttons.loadPathFile.MouseButton1Click:Connect(U.loadPathFromFile)

	local refreshPaths = Instance.new("TextButton")
	refreshPaths.Size = UDim2.new(0, 70, 0, 20)
	refreshPaths.Position = UDim2.new(1, -75, 0, 5)
	refreshPaths.BackgroundColor3 = Color3.fromRGB(40, 45, 70)
	refreshPaths.Text = "REFRESH"
	refreshPaths.Font = Enum.Font.GothamBold
	refreshPaths.TextSize = 10
	refreshPaths.TextColor3 = Color3.fromRGB(200, 210, 255)
	refreshPaths.Parent = autoWalkPage
	Instance.new("UICorner", refreshPaths).CornerRadius = UDim.new(0, 4)
	refreshPaths.MouseButton1Click:Connect(U.refreshPathFileList)
	local pathNameInput, _pathNameReset = createLabeledInput("Path Name:", "recorded_path", autoWalkPage)
	UI.pathNameInput = pathNameInput
	
	local scrollFiles = Instance.new("ScrollingFrame")
	scrollFiles.Name = "PathFileList"
	scrollFiles.Size = UDim2.new(1, -10, 0, 120)
	scrollFiles.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
	scrollFiles.BorderSizePixel = 0
	scrollFiles.ScrollBarThickness = 2
	scrollFiles.ScrollBarImageColor3 = Color3.fromRGB(60, 100, 255)
	scrollFiles.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFiles.Parent = autoWalkPage
	UI.pathFileList = scrollFiles
	U.setupSmoothScroll(scrollFiles)
	
	local scrollCorner = Instance.new("UICorner")
	scrollCorner.CornerRadius = UDim.new(0, 8)
	scrollCorner.Parent = scrollFiles
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 4)
	listLayout.SortOrder = Enum.SortOrder.Name
	listLayout.Parent = scrollFiles
	
	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingTop = UDim.new(0, 5)
	listPadding.PaddingBottom = UDim.new(0, 5)
	listPadding.PaddingLeft = UDim.new(0, 5)
	listPadding.PaddingRight = UDim.new(0, 5)
	listPadding.Parent = scrollFiles

	-- Initial refresh
	task.spawn(U.refreshPathFileList)


	-- WAYPOINTS PAGE CONTENT
	-- Input Nama untuk Waypoint baru
	local wpPointNameInput, _wpPointNameReset = createLabeledInput("Point Name:", "WP_" .. (#States.waypoints + 1), waypointsPage)
	UI.inputs.wpPointName = wpPointNameInput
	
	-- Teleport Waypoints removed
	local wpActionRow = Instance.new("Frame")
	wpActionRow.Name = "WPActionRow"
	wpActionRow.Size = UDim2.new(1, -10, 0, 32)
	wpActionRow.BackgroundTransparency = 1
	wpActionRow.Parent = waypointsPage
	
	UI.buttons.addWaypoint = createToggleButton("AddWaypoint", "Add Current Pos", wpActionRow)
	UI.buttons.addWaypoint.Size = UDim2.new(0.5, -4, 1, 0)
	UI.buttons.addWaypoint.MouseButton1Click:Connect(U.addWaypoint)
	
	UI.buttons.clearWaypoints = createToggleButton("ClearWaypoints", "Clear All", wpActionRow)
	UI.buttons.clearWaypoints.Size = UDim2.new(0.5, -4, 1, 0)
	UI.buttons.clearWaypoints.Position = UDim2.new(0.5, 2, 0, 0)
	UI.buttons.clearWaypoints.MouseButton1Click:Connect(function()
		States.waypoints = {}
		U.refreshWaypointListUI()
	end)

	-- Auto Teleport Controls removed
	local autoTpRow = Instance.new("Frame")
	autoTpRow.Name = "AutoTpRow"
	autoTpRow.Size = UDim2.new(1, -10, 0, 32)
	autoTpRow.BackgroundTransparency = 1
	autoTpRow.Parent = waypointsPage

	UI.buttons.autoTp = createToggleButton("AutoTeleport", "▶ Start Auto TP", autoTpRow)
	UI.buttons.autoTp.Size = UDim2.new(0.32, 0, 1, 0)
	UI.buttons.autoTp.MouseButton1Click:Connect(function()
		U.toggleAutoTeleport()
	end)

	UI.buttons.pauseAutoTp = createToggleButton("PauseAutoTeleport", "|| Pause", autoTpRow)
	UI.buttons.pauseAutoTp.Size = UDim2.new(0.32, 0, 1, 0)
	UI.buttons.pauseAutoTp.Position = UDim2.new(0.34, 0, 0, 0)
	UI.buttons.pauseAutoTp.MouseButton1Click:Connect(function()
		U.toggleAutoTeleportPause()
	end)
	
	UI.buttons.stopAutoTp = createToggleButton("", "STOP", autoTpRow)
	UI.buttons.stopAutoTp.Size = UDim2.new(0.32, 0, 1, 0)
	UI.buttons.stopAutoTp.Position = UDim2.new(0.68, 0, 0, 0)
	UI.buttons.stopAutoTp.MouseButton1Click:Connect(function()
		if U.stopAutoTeleport then U.stopAutoTeleport() end
	end)

	local autoTpConfigRow = Instance.new("Frame")
	autoTpConfigRow.Name = "AutoTpConfigRow"
	autoTpConfigRow.Size = UDim2.new(1, -10, 0, 32)
	autoTpConfigRow.BackgroundTransparency = 1
	autoTpConfigRow.Parent = waypointsPage
	
	UI.buttons.loopWps = createToggleButton("", "Loop Waypoints", autoTpConfigRow)
	UI.buttons.loopWps.Size = UDim2.new(0.49, 0, 1, 0)
	UI.buttons.loopWps.MouseButton1Click:Connect(function()
		States.isWaypointLooping = not States.isWaypointLooping
		U.setButtonState(UI.buttons.loopWps, States.isWaypointLooping)
		U.saveSettings()
	end)

	UI.buttons.pauseOnJoin = createToggleButton("", "Pause on Join", autoTpConfigRow)
	UI.buttons.pauseOnJoin.Size = UDim2.new(0.49, 0, 1, 0)
	UI.buttons.pauseOnJoin.Position = UDim2.new(0.51, 0, 0, 0)
	UI.buttons.pauseOnJoin.MouseButton1Click:Connect(function()
		States.isPauseOnJoin = not States.isPauseOnJoin
		U.setButtonState(UI.buttons.pauseOnJoin, States.isPauseOnJoin)
		U.saveSettings()
	end)
	U.setButtonState(UI.buttons.pauseOnJoin, States.isPauseOnJoin)


	UI.buttons.autoTpOnDeath = createToggleButton("Recovery", "Recovery Mode", autoTpConfigRow)
	UI.buttons.autoTpOnDeath.Size = UDim2.new(0.49, 0, 1, 0)
	UI.buttons.autoTpOnDeath.Position = UDim2.new(0.51, 0, 0, 0)
	UI.buttons.autoTpOnDeath.MouseButton1Click:Connect(function()
		States.isAutoTpToSave = not States.isAutoTpToSave
		if States.isAutoTpToSave then
			local character = localPlayer.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then States.savedPosition = root.CFrame end
			U.notify("Recovery Active", "Current position saved for rescue!", 2)
		end
		U.setButtonState(UI.buttons.autoTpOnDeath, States.isAutoTpToSave)
	end)

	local autoTpMoreRow = Instance.new("Frame")
	autoTpMoreRow.Name = "AutoTpMoreRow"
	autoTpMoreRow.Size = UDim2.new(1, -10, 0, 32)
	autoTpMoreRow.BackgroundTransparency = 1
	autoTpMoreRow.Parent = waypointsPage
	
	UI.buttons.autoRespawn = createToggleButton("", "Fast Respawn", autoTpMoreRow)
	UI.buttons.autoRespawn.Size = UDim2.new(0.49, 0, 1, 0)
	UI.buttons.autoRespawn.MouseButton1Click:Connect(function()
		States.isAutoRespawn = not States.isAutoRespawn
		U.setButtonState(UI.buttons.autoRespawn, States.isAutoRespawn)
		U.saveSettings()
	end)
	U.setButtonState(UI.buttons.autoRespawn, States.isAutoRespawn)

	UI.buttons.autoRespawnOnFinish = createToggleButton("", "Respawn on End", autoTpMoreRow)
	UI.buttons.autoRespawnOnFinish.Size = UDim2.new(0.49, 0, 1, 0)
	UI.buttons.autoRespawnOnFinish.Position = UDim2.new(0.51, 0, 0, 0)
	UI.buttons.autoRespawnOnFinish.MouseButton1Click:Connect(function()
		States.isAutoRespawnOnFinish = not States.isAutoRespawnOnFinish
		U.setButtonState(UI.buttons.autoRespawnOnFinish, States.isAutoRespawnOnFinish)
		U.saveSettings()
	end)
	U.setButtonState(UI.buttons.autoRespawnOnFinish, States.isAutoRespawnOnFinish)

	local savePosRow = Instance.new("Frame")
	savePosRow.Name = "SavePosRow"
	savePosRow.Size = UDim2.new(1, -10, 0, 32)
	savePosRow.BackgroundTransparency = 1
	savePosRow.Parent = waypointsPage

	UI.buttons.savePos = createToggleButton("", "SAVE CURRENT POS (Manual)", savePosRow)
	UI.buttons.savePos.Size = UDim2.new(1, 0, 1, 0)
	-- Connection is already at the bottom of the script

	-- New features: Respawn and TP to Coords
	local extraWpRow = Instance.new("Frame")
	extraWpRow.Name = "ExtraWpRow"
	extraWpRow.Size = UDim2.new(1, -10, 0, 32)
	extraWpRow.BackgroundTransparency = 1
	extraWpRow.Parent = waypointsPage
	
	UI.buttons.manualRespawn = createToggleButton("", "MANUAL RESPAWN", extraWpRow)
	UI.buttons.manualRespawn.Size = UDim2.new(1, 0, 1, 0)
	UI.buttons.manualRespawn.MouseButton1Click:Connect(U.requestRespawn)

	local tpPosHeader = Instance.new("TextLabel")
	tpPosHeader.Size = UDim2.new(1, 0, 0, 25)
	tpPosHeader.BackgroundTransparency = 1
	tpPosHeader.Text = "--- TELEPORT TO POSITION ---"
	tpPosHeader.Font = Enum.Font.GothamBold
	tpPosHeader.TextSize = 12
	tpPosHeader.TextColor3 = Color3.fromRGB(110, 120, 160)
	tpPosHeader.Parent = waypointsPage

	local tpPosInputRow = Instance.new("Frame")
	tpPosInputRow.Name = "TpPosInputRow"
	tpPosInputRow.Size = UDim2.new(1, -10, 0, 32)
	tpPosInputRow.BackgroundTransparency = 1
	tpPosInputRow.Parent = waypointsPage
	
	local function createMiniInput(placeholder, size, pos, parent)
		local input = Instance.new("TextBox")
		input.Size = size
		input.Position = pos
		input.BackgroundColor3 = Color3.fromRGB(22, 24, 36)
		input.BorderSizePixel = 0
		input.PlaceholderText = placeholder
		input.Text = ""
		input.Font = Enum.Font.Gotham
		input.TextSize = 12
		input.TextColor3 = Color3.fromRGB(255, 255, 255)
		input.ClearTextOnFocus = false
		input.Parent = parent
		Instance.new("UICorner", input).CornerRadius = UDim.new(0, 6)
		local s = Instance.new("UIStroke", input)
		s.Thickness = 1
		s.Color = Color3.fromRGB(70, 80, 130)
		s.Transparency = 0.5
		return input
	end

	local xInput = createMiniInput("X", UDim2.new(0.24, 0, 1, 0), UDim2.new(0, 0, 0, 0), tpPosInputRow)
	local yInput = createMiniInput("Y", UDim2.new(0.24, 0, 1, 0), UDim2.new(0.25, 0, 0, 0), tpPosInputRow)
	local zInput = createMiniInput("Z", UDim2.new(0.24, 0, 1, 0), UDim2.new(0.5, 0, 0, 0), tpPosInputRow)
	
	local tpGoBtn = Instance.new("TextButton")
	tpGoBtn.Size = UDim2.new(0.24, 0, 1, 0)
	tpGoBtn.Position = UDim2.new(0.75, 4, 0, 0)
	tpGoBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 255)
	tpGoBtn.Text = "TP"
	tpGoBtn.Font = Enum.Font.GothamBold
	tpGoBtn.TextSize = 12
	tpGoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	tpGoBtn.Parent = tpPosInputRow
	Instance.new("UICorner", tpGoBtn).CornerRadius = UDim.new(0, 6)

	tpGoBtn.MouseButton1Click:Connect(function()
		local x = U.parseNumber(xInput.Text, nil, true)
		local y = U.parseNumber(yInput.Text, nil, true)
		local z = U.parseNumber(zInput.Text, nil, true)
		if x and y and z then
			local _, root = U.getHumanoidAndRoot()
			if root then
				root.CFrame = CFrame.new(x, y, z)
				U.notify("Teleport", "Teleported to " .. x .. ", " .. y .. ", " .. z, 2)
			end
		else
			U.notify("Error", "Invalid coordinates", 2, "Error")
		end
	end)

	local getPosRow = Instance.new("Frame")
	getPosRow.Name = "GetPosRow"
	getPosRow.Size = UDim2.new(1, -10, 0, 28)
	getPosRow.BackgroundTransparency = 1
	getPosRow.Parent = waypointsPage
	
	local getPosBtn = Instance.new("TextButton")
	getPosBtn.Size = UDim2.new(1, 0, 1, 0)
	getPosBtn.BackgroundColor3 = Color3.fromRGB(40, 45, 70)
	getPosBtn.Text = "FETCH CURRENT POSITION"
	getPosBtn.Font = Enum.Font.GothamBold
	getPosBtn.TextSize = 10
	getPosBtn.TextColor3 = Color3.fromRGB(200, 210, 255)
	getPosBtn.Parent = getPosRow
	Instance.new("UICorner", getPosBtn).CornerRadius = UDim.new(0, 6)

	getPosBtn.MouseButton1Click:Connect(function()
		local _, root = U.getHumanoidAndRoot()
		if root then
			local pos = root.Position
			xInput.Text = string.format("%.2f", pos.X)
			yInput.Text = string.format("%.2f", pos.Y)
			zInput.Text = string.format("%.2f", pos.Z)
		end
	end)

	local spawnToPosRow = Instance.new("Frame")
	spawnToPosRow.Name = "SpawnToPosRow"
	spawnToPosRow.Size = UDim2.new(1, -10, 0, 32)
	spawnToPosRow.BackgroundTransparency = 1
	spawnToPosRow.Parent = waypointsPage

	UI.buttons.respawnToTpPos = createToggleButton("", "Respawn to this Pos", spawnToPosRow)
	UI.buttons.respawnToTpPos.Size = UDim2.new(1, 0, 1, 0)
	UI.buttons.respawnToTpPos.MouseButton1Click:Connect(function()
		States.isRespawnToTpPos = not States.isRespawnToTpPos
		U.setButtonState(UI.buttons.respawnToTpPos, States.isRespawnToTpPos)
		
		if States.isRespawnToTpPos then
			local x = U.parseNumber(xInput.Text, nil, true)
			local y = U.parseNumber(yInput.Text, nil, true)
			local z = U.parseNumber(zInput.Text, nil, true)
			if x and y and z then
				States.tpPosToRespawn = Vector3.new(x, y, z)
				U.notify("Respawn Set", "Will teleport to coordinate on respawn", 2)
			else
				States.isRespawnToTpPos = false
				U.setButtonState(UI.buttons.respawnToTpPos, false)
				U.notify("Error", "Enter valid coordinates first", 2, "Error")
			end
		end
	end)


	local delayInput, delayAllBtn = createLabeledInput("Delay (s):", tostring(States.autoTeleportDelay or 1), waypointsPage)
	delayAllBtn.Text = "ALL"
	delayAllBtn.MouseButton1Click:Connect(function()
		local n = tonumber(delayInput.Text)
		if n and n >= 0 then
			States.autoTeleportDelay = n
			for _, wp in ipairs(States.waypoints) do
				wp.delay = n
			end
			U.refreshWaypointListUI()
			U.notify("Waypoint", "Applied " .. n .. "s delay to ALL waypoints", 2, "Success")
			U.saveSettings()
		end
	end)
	
	delayInput.FocusLost:Connect(function()
		States.autoTeleportDelay = U.parseNumber(delayInput.Text, 1)
		delayInput.Text = tostring(States.autoTeleportDelay)
		U.saveSettings()
	end)

	-- Waypoint List removed
	local scrollWps = Instance.new("ScrollingFrame")
	scrollWps.Name = "WaypointList"
	scrollWps.Size = UDim2.new(1, -10, 0, 150)
	scrollWps.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
	scrollWps.BorderSizePixel = 0
	scrollWps.ScrollBarThickness = 2
	scrollWps.ScrollBarImageColor3 = Color3.fromRGB(60, 100, 255)
	scrollWps.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollWps.Parent = waypointsPage
	UI.waypointListUI = scrollWps
	U.setupSmoothScroll(scrollWps)
	Instance.new("UICorner", scrollWps).CornerRadius = UDim.new(0, 8)
	local listWp = Instance.new("UIListLayout", scrollWps)
	listWp.Padding = UDim.new(0, 4)
	listWp.SortOrder = Enum.SortOrder.LayoutOrder
	local listPad = Instance.new("UIPadding", scrollWps)
	listPad.PaddingTop = UDim.new(0, 5)
	listPad.PaddingBottom = UDim.new(0, 5)
	listPad.PaddingLeft = UDim.new(0, 5)
	listPad.PaddingRight = UDim.new(0, 5)

	-- local wpPersistLabel removed
	local refreshWps = Instance.new("TextButton")
	refreshWps.Size = UDim2.new(0, 70, 0, 20)
	refreshWps.Position = UDim2.new(1, -75, 0, 5)
	refreshWps.BackgroundColor3 = Color3.fromRGB(40, 45, 70)
	refreshWps.Text = "REFRESH"
	refreshWps.Font = Enum.Font.GothamBold
	refreshWps.TextSize = 10
	refreshWps.TextColor3 = Color3.fromRGB(200, 210, 255)
	refreshWps.Parent = waypointsPage
	Instance.new("UICorner", refreshWps).CornerRadius = UDim.new(0, 4)
	refreshWps.MouseButton1Click:Connect(U.refreshWaypointFileList)
	local wpFileRow = Instance.new("Frame")
	wpFileRow.Name = "WPFileRow"
	wpFileRow.Size = UDim2.new(1, -10, 0, 32)
	wpFileRow.BackgroundTransparency = 1
	wpFileRow.Parent = waypointsPage
	
	UI.buttons.saveWpFile = createToggleButton("", "SAVE File", wpFileRow)
	UI.buttons.saveWpFile.Size = UDim2.new(0.5, -4, 1, 0)
	UI.buttons.saveWpFile.MouseButton1Click:Connect(U.saveWaypointsToFile)
	
	UI.buttons.loadWpFile = createToggleButton("", "LOAD File", wpFileRow)
	UI.buttons.loadWpFile.Size = UDim2.new(0.5, -4, 1, 0)
	UI.buttons.loadWpFile.Position = UDim2.new(0.5, 2, 0, 0)
	UI.buttons.loadWpFile.MouseButton1Click:Connect(function()
		local fileName = (UI.waypointNameInput and UI.waypointNameInput.Text ~= "" and UI.waypointNameInput.Text) or "waypoints.json"
		U.loadWaypointsFromSpecificFile(fileName)
	end)

	local wpNameInput, _wpNameReset = createLabeledInput("File Name:", "waypoints", waypointsPage)
	UI.waypointNameInput = wpNameInput
	
	local scrollWpFiles = Instance.new("ScrollingFrame")
	scrollWpFiles.Name = "WaypointFileList"
	scrollWpFiles.Size = UDim2.new(1, -10, 0, 100)
	scrollWpFiles.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
	scrollWpFiles.BorderSizePixel = 0
	scrollWpFiles.ScrollBarThickness = 2
	scrollWpFiles.ScrollBarImageColor3 = Color3.fromRGB(60, 100, 255)
	scrollWpFiles.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollWpFiles.Parent = waypointsPage
	UI.waypointFileListUI = scrollWpFiles
	U.setupSmoothScroll(scrollWpFiles)
	Instance.new("UICorner", scrollWpFiles).CornerRadius = UDim.new(0, 8)
	local listWpFiles = Instance.new("UIListLayout", scrollWpFiles)
	listWpFiles.Padding = UDim.new(0, 4)
	local listPadF = Instance.new("UIPadding", scrollWpFiles)
	listPadF.PaddingTop = UDim.new(0, 5)
	listPadF.PaddingBottom = UDim.new(0, 5)
	listPadF.PaddingLeft = UDim.new(0, 5)
	listPadF.PaddingRight = UDim.new(0, 5)

	task.spawn(function()
		task.wait(0.1)
		U.refreshWaypointListUI()
		U.refreshWaypointFileList()
	end)



	-- WORLD PAGE CONTENT
	-- Environment Settings removed
	local timeInput, timeReset = createLabeledInput("Local Time (0-24):", math.floor(S.Lighting.ClockTime * 100) / 100, worldPage)
	UI.inputs.localTimeInput = timeInput
	UI.inputs.localTimeReset = timeReset
	UI.buttons.lockTime = createToggleButton("LockTime", "Lock Local Time", worldPage)
	U.setButtonState(UI.buttons.lockTime, States.isLocalTimeLocked)

	local gravityInput, gravReset = createLabeledInput("Workspace Gravity:", workspace.Gravity, worldPage)
	UI.inputs.gravityInput = gravityInput
	UI.inputs.gravityReset = gravReset
	
	UI.buttons.fastAntiTraffic = createToggleButton("FastAntiTraffic", "Fast Anti-Traffic", worldPage)
	U.setButtonState(UI.buttons.fastAntiTraffic, States.isFastAntiTraffic)

-- AntiLandslide UI removed

	-- Skybox Settings removed
	local skyInput, skyReset = createLabeledInput("Skybox ID:", Config.skyboxId, worldPage)
	UI.inputs.skyboxInput = skyInput
	UI.inputs.skyboxReset = skyReset
	
	UI.buttons.applySkybox = createToggleButton("", "Apply Skybox", worldPage)


	-- CONFIG PAGE CONTENT
	-- Link redundant config button if needed, or remove
	UI.buttons.bypassAC_Config = createToggleButton("AntiCheatBypass", "Anti-Cheat Bypass", configPage)
	U.setButtonState(UI.buttons.bypassAC, States.isAntiCheatBypass)
	
	UI.buttons.blockGameInput = createToggleButton("BlockGameInput", "Block Game Keybinds", configPage)
	UI.buttons.blockGameInput.MouseButton1Click:Connect(function()
		States.isBlockGameInput = not States.isBlockGameInput
		U.setButtonState(UI.buttons.blockGameInput, States.isBlockGameInput)
		U.refreshInputSinks()
		U.notifyToggle("Block Game Input", States.isBlockGameInput)
		U.saveSettings()
	end)
	U.setButtonState(UI.buttons.blockGameInput, States.isBlockGameInput)

	
	-- Theme Editor removed
	local themeContainer = Instance.new("Frame")
	themeContainer.Size = UDim2.new(1, 0, 0, 40)
	themeContainer.BackgroundTransparency = 1
	themeContainer.Parent = configPage
	local themeLayout = Instance.new("UIListLayout")
	themeLayout.FillDirection = Enum.FillDirection.Horizontal
	themeLayout.Padding = UDim.new(0, 5)
	themeLayout.Parent = themeContainer

	local function createThemeBtn(name, color, isRGB)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0.24, 0, 1, 0)
		b.BackgroundColor3 = color or Color3.fromRGB(30, 30, 30)
		b.Text = name
		b.Font = Enum.Font.GothamBold
		b.TextSize = 10
		b.TextColor3 = Color3.fromRGB(255, 255, 255)
		b.Parent = themeContainer
		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(0, 6)
		bc.Parent = b
		
		b.MouseButton1Click:Connect(function()
			States.isRGBTheme = isRGB or false
			if not isRGB then
				States.panelThemeColor = color
				-- Update UI color immediately
				if UI.mainFrame then
					local stroke = UI.mainFrame:FindFirstChildOfClass("UIStroke")
					if stroke then stroke.Color = color end
				end
				if UI.pingLabel then UI.pingLabel.TextColor3 = color end
				switchTab(currentTab) -- Refresh indicators
			end
		end)
	end

	createThemeBtn("BLUE", Color3.fromRGB(60, 100, 255))
	createThemeBtn("RED", Color3.fromRGB(255, 60, 60))
	createThemeBtn("GREEN", Color3.fromRGB(60, 255, 100))
	createThemeBtn("RGB", Color3.fromRGB(255, 255, 255), true)

	-- Keybind Settings removed
	local function createKeybindInput(action, defaultValue)
		local input, delBtn = createLabeledInput(action .. ":", defaultValue, keybindsPage)
		UI.keybindInputs[action] = input
		
		-- Repurpose reset button to delete/unbind
		delBtn.Text = "DEL"
		delBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
		delBtn.TextColor3 = Color3.fromRGB(255, 150, 150)
		
		delBtn.MouseButton1Click:Connect(function()
			Config.keybinds[action] = Enum.KeyCode.Unknown
			input.Text = "Unknown"
			U.refreshDynamicButtons()
			U.refreshInputSinks() -- Update sinks to unbind this key
			U.notify("Unbound", action .. " keybind removed", 2)
			U.saveSettings()
		end)

		input.Focused:Connect(function()
			input.Text = "[Press a Key]"
			Config.isAssigningKey = action
			Config.assigningStartTime = tick()
		end)

		input.FocusLost:Connect(function(enterPressed)
			if Config.isAssigningKey == action then
				-- If focus lost without a key press (e.g., clicked elsewhere), reset the text
				input.Text = Config.keybinds[action].Name
				Config.isAssigningKey = nil
			elseif enterPressed then
				-- Manual input fallback
				local success, keyCode = pcall(function() return Enum.KeyCode[input.Text] end)
				if success and keyCode then
					Config.keybinds[action] = keyCode
					input.Text = keyCode.Name
					U.refreshInputSinks() -- Update sinks for new key
					U.notify("Keybind Updated", action .. " is now " .. keyCode.Name, 2)
					U.saveSettings()
				else
					input.Text = Config.keybinds[action].Name
				end
			end
		end)
	end

	-- Automatically generate all keybind inputs
	local keybindDisplayOrder = {
		"ToggleGui", "Minimize", "Destroy", "Rejoin", "ServerHop",
		"Fly", "Noclip", "FlashSpeed", "Freecam", "WalkBoost", "JumpBoost", "JumpSpam",
		"AirWalk", "AirWalkBack", "SpiderClimb", "Spin", "Flip", "UnlockJump", "AutoWalk",
		"Fullbright", "NoFog", "NoShadow", "VisibleAllParts", "XRay",
		"EspAll", "EspEnemy", "EspNpc", "EspItems", "Spectate",
		"Floating", "AntiFling",
		"VehicleFly", "VehicleBoost", "VehicleBoostKey", "VehicleQuickBrake", "VehicleStop", "FastAntiTraffic", "LockTime", "Recovery", "WalkOverride", "RecordPath", "PlayPath", "StopPath", "AddWaypoint", "ClearWaypoints",
		"AntiDelay", "Invisible", "MouseLock", "NoTouch", "ClickTp", "RemoveNC", "AutoInteract",
		"GetBTools", "LoadDex", "LoadSpy", "SkipCutscene", "SkipLoading", "AutoTeleport", "PauseAutoTeleport", "AntiAfk", "AntiCheatBypass"
	}

	for _, action in ipairs(keybindDisplayOrder) do
		if Config.keybinds[action] then
			createKeybindInput(action, Config.keybinds[action].Name)
		end
	end

	-- Catch any missing ones
	for action, keyCode in pairs(Config.keybinds) do
		if not table.find(keybindDisplayOrder, action) then
			createKeybindInput(action, keyCode.Name)
		end
	end

	UI.inputs.walkSpeedInput = createLabeledInput("WalkSpeed:", Config.walkSpeed, configPage)
	UI.inputs.walkSpeedReset = UI.inputs.walkSpeedInput.Parent.Reset
	UI.inputs.walkSpeedInput.FocusLost:Connect(function()
		Config.walkSpeed = U.parseNumber(UI.inputs.walkSpeedInput.Text, Config.defaultWalkSpeedFromCharacter)
		UI.inputs.walkSpeedInput.Text = tostring(Config.walkSpeed)
		local h, _ = U.getHumanoidAndRoot()
		if h then applyMovementStats(h) end
		U.saveSettings()
	end)
	UI.inputs.walkSpeedReset.MouseButton1Click:Connect(function()
		Config.walkSpeed = Config.defaultWalkSpeedFromCharacter
		UI.inputs.walkSpeedInput.Text = tostring(Config.walkSpeed)
		local h, _ = U.getHumanoidAndRoot()
		if h then applyMovementStats(h) end
		U.saveSettings()
	end)

	UI.inputs.walkBoostMultiplier = createLabeledInput("Walk Boost Mult:", Config.walkBoostMultiplier, configPage)
	UI.inputs.walkBoostReset = UI.inputs.walkBoostMultiplier.Parent.Reset
	UI.inputs.walkBoostMultiplier.FocusLost:Connect(function()
		Config.walkBoostMultiplier = U.parseNumber(UI.inputs.walkBoostMultiplier.Text, 2)
		UI.inputs.walkBoostMultiplier.Text = tostring(Config.walkBoostMultiplier)
		local h, _ = U.getHumanoidAndRoot()
		if h then applyMovementStats(h) end
		U.saveSettings()
	end)
	UI.inputs.walkBoostReset.MouseButton1Click:Connect(function()
		Config.walkBoostMultiplier = 2
		UI.inputs.walkBoostMultiplier.Text = tostring(Config.walkBoostMultiplier)
		local h, _ = U.getHumanoidAndRoot()
		if h then applyMovementStats(h) end
		U.saveSettings()
	end)

	UI.inputs.flySpeed = createLabeledInput("Fly Speed:", Config.flySpeed, configPage)
	UI.inputs.flySpeedReset = UI.inputs.flySpeed.Parent.Reset
	UI.inputs.flySpeed.FocusLost:Connect(function()
		Config.flySpeed = U.parseNumber(UI.inputs.flySpeed.Text, 80)
		UI.inputs.flySpeed.Text = tostring(Config.flySpeed)
		U.saveSettings()
	end)
	UI.inputs.flySpeedReset.MouseButton1Click:Connect(function()
		Config.flySpeed = 80
		UI.inputs.flySpeed.Text = tostring(Config.flySpeed)
		U.saveSettings()
	end)

	UI.inputs.flashSpeedAmount = createLabeledInput("Flash Speed Mult:", Config.flashSpeedAmount, configPage)
	UI.inputs.flashSpeedReset = UI.inputs.flashSpeedAmount.Parent.Reset
	UI.inputs.flashSpeedAmount.FocusLost:Connect(function()
		Config.flashSpeedAmount = U.parseNumber(UI.inputs.flashSpeedAmount.Text, 1)
		UI.inputs.flashSpeedAmount.Text = tostring(Config.flashSpeedAmount)
		U.saveSettings()
	end)
	UI.inputs.flashSpeedReset.MouseButton1Click:Connect(function()
		Config.flashSpeedAmount = 1
		UI.inputs.flashSpeedAmount.Text = tostring(Config.flashSpeedAmount)
		U.saveSettings()
	end)

	UI.inputs.jumpBoost = createLabeledInput("Jump Boost Mult:", Config.jumpBoostMultiplier, configPage)
	UI.inputs.jumpBoostReset = UI.inputs.jumpBoost.Parent.Reset
	UI.inputs.jumpBoost.FocusLost:Connect(function()
		Config.jumpBoostMultiplier = U.parseNumber(UI.inputs.jumpBoost.Text, 1.5)
		UI.inputs.jumpBoost.Text = tostring(Config.jumpBoostMultiplier)
		local h, _ = U.getHumanoidAndRoot()
		if h then applyMovementStats(h) end
		U.saveSettings()
	end)
	UI.inputs.jumpBoostReset.MouseButton1Click:Connect(function()
		Config.jumpBoostMultiplier = 1.5
		UI.inputs.jumpBoost.Text = tostring(Config.jumpBoostMultiplier)
		local h, _ = U.getHumanoidAndRoot()
		if h then applyMovementStats(h) end
		U.saveSettings()
	end)

	UI.inputs.bringRadiusInput = createLabeledInput("Bring Radius:", Config.bringRadius, configPage)
	UI.inputs.bringRadiusReset = UI.inputs.bringRadiusInput.Parent.Reset
	UI.inputs.bringRadiusInput.FocusLost:Connect(function()
		Config.bringRadius = U.parseNumber(UI.inputs.bringRadiusInput.Text, 100)
		UI.inputs.bringRadiusInput.Text = tostring(Config.bringRadius)
		U.saveSettings()
	end)
	UI.inputs.bringRadiusReset.MouseButton1Click:Connect(function()
		Config.bringRadius = 100
		UI.inputs.bringRadiusInput.Text = tostring(Config.bringRadius)
		U.saveSettings()
	end)


	UI.inputs.autoEDown = createLabeledInput("E Down Delay:", Config.autoEDownDelay, configPage)
	UI.inputs.autoEDownReset = UI.inputs.autoEDown.Parent.Reset
	UI.inputs.autoEDown.FocusLost:Connect(function()
		Config.autoEDownDelay = U.parseNumber(UI.inputs.autoEDown.Text, 0.03)
		UI.inputs.autoEDown.Text = tostring(Config.autoEDownDelay)
		U.saveSettings()
	end)
	UI.inputs.autoEDownReset.MouseButton1Click:Connect(function()
		Config.autoEDownDelay = 0.03
		UI.inputs.autoEDown.Text = tostring(Config.autoEDownDelay)
		U.saveSettings()
	end)

	UI.inputs.autoEUp = createLabeledInput("E Up Delay:", Config.autoEUpDelay, configPage)
	UI.inputs.autoEUpReset = UI.inputs.autoEUp.Parent.Reset
	UI.inputs.autoEUp.FocusLost:Connect(function()
		Config.autoEUpDelay = U.parseNumber(UI.inputs.autoEUp.Text, 0.12)
		UI.inputs.autoEUp.Text = tostring(Config.autoEUpDelay)
		U.saveSettings()
	end)
	UI.inputs.autoEUpReset.MouseButton1Click:Connect(function()
		Config.autoEUpDelay = 0.12
		UI.inputs.autoEUp.Text = tostring(Config.autoEUpDelay)
		U.saveSettings()
	end)

	UI.inputs.scrollAmount = createLabeledInput("Scroll Amount (UI):", Config.scrollAmount or 100, configPage)
	UI.inputs.scrollAmountReset = UI.inputs.scrollAmount.Parent.Reset
	UI.inputs.scrollAmount.FocusLost:Connect(function()
		Config.scrollAmount = U.parseNumber(UI.inputs.scrollAmount.Text, 100)
		UI.inputs.scrollAmount.Text = tostring(Config.scrollAmount)
		U.saveSettings()
	end)
	UI.inputs.scrollAmountReset.MouseButton1Click:Connect(function()
		Config.scrollAmount = 100
		UI.inputs.scrollAmount.Text = tostring(Config.scrollAmount)
		U.saveSettings()
	end)

	UI.inputs.zoomAmount = createLabeledInput("Zoom Amount (Cam):", Config.zoomAmount or 5, configPage)
	UI.inputs.zoomAmountReset = UI.inputs.zoomAmount.Parent.Reset
	UI.inputs.zoomAmount.FocusLost:Connect(function()
		Config.zoomAmount = U.parseNumber(UI.inputs.zoomAmount.Text, 5)
		UI.inputs.zoomAmount.Text = tostring(Config.zoomAmount)
		U.saveSettings()
	end)
	UI.inputs.zoomAmountReset.MouseButton1Click:Connect(function()
		Config.zoomAmount = 5
		UI.inputs.zoomAmount.Text = tostring(Config.zoomAmount)
		U.saveSettings()
	end)


	UI.inputs.freecamSpeed = createLabeledInput("Freecam Base Spd:", Config.freecamBaseSpeed, configPage)
	UI.inputs.freecamSpeedReset = UI.inputs.freecamSpeed.Parent.Reset
	UI.inputs.freecamSpeed.FocusLost:Connect(function()
		Config.freecamBaseSpeed = U.parseNumber(UI.inputs.freecamSpeed.Text, 0.2)
		UI.inputs.freecamSpeed.Text = tostring(Config.freecamBaseSpeed)
		U.saveSettings()
	end)
	UI.inputs.freecamSpeedReset.MouseButton1Click:Connect(function()
		Config.freecamBaseSpeed = 0.2
		UI.inputs.freecamSpeed.Text = tostring(Config.freecamBaseSpeed)
		U.saveSettings()
	end)

	UI.inputs.brightness = createLabeledInput("Brightness:", Config.brightnessValue, configPage)
	UI.inputs.brightnessReset = UI.inputs.brightness.Parent.Reset
	UI.inputs.brightness.FocusLost:Connect(function()
		Config.brightnessValue = U.parseNumber(UI.inputs.brightness.Text, 2)
		UI.inputs.brightness.Text = tostring(Config.brightnessValue)
		if States.isFullbright then applyBrightness() end
		U.saveSettings()
	end)
	UI.inputs.brightnessReset.MouseButton1Click:Connect(function()
		Config.brightnessValue = 2
		UI.inputs.brightness.Text = tostring(Config.brightnessValue)
		if States.isFullbright then applyBrightness() end
		U.saveSettings()
	end)

	UI.inputs.exposure = createLabeledInput("Exposure Comp:", Config.exposureCompensationValue, configPage)
	UI.inputs.exposureReset = UI.inputs.exposure.Parent.Reset
	UI.inputs.exposure.FocusLost:Connect(function()
		Config.exposureCompensationValue = U.parseNumber(UI.inputs.exposure.Text, 1)
		UI.inputs.exposure.Text = tostring(Config.exposureCompensationValue)
		if States.isFullbright then applyExposureCompensation() end
		U.saveSettings()
	end)
	UI.inputs.exposureReset.MouseButton1Click:Connect(function()
		Config.exposureCompensationValue = 1
		UI.inputs.exposure.Text = tostring(Config.exposureCompensationValue)
		if States.isFullbright then applyExposureCompensation() end
		U.saveSettings()
	end)

	
	-- Toggle Connections
	UI.buttons.fly.MouseButton1Click:Connect(function()
		if States.isFlying then 
			stopFly() 
		else 
			startFly(false) 
		end
		U.setButtonState(UI.buttons.fly, States.isFlying)
		if States.isFlying and States.isWalkBoost then
			U.notifyToggle("Fly (Boosted 2x)", true)
		else
			U.notifyToggle("Fly", States.isFlying)
		end
	end)

	UI.buttons.flashSpeed.MouseButton1Click:Connect(function()
		toggleFlashSpeed()
		U.setButtonState(UI.buttons.flashSpeed, States.isFlashSpeedEnabled)
		U.notifyToggle("Flash Speed", States.isFlashSpeedEnabled)
	end)

	UI.buttons.noclip.MouseButton1Click:Connect(function()
		if States.isNoclip then 
			disableNoclip() 
		else 
			enableNoclip() 
		end
		U.setButtonState(UI.buttons.noclip, States.isNoclip)
		U.notifyToggle("Noclip", States.isNoclip)
	end)

	UI.buttons.walkBoost.MouseButton1Click:Connect(function()
		States.isWalkBoost = not States.isWalkBoost
		local h, _ = U.getHumanoidAndRoot()
		if h then applyMovementStats(h) end
		U.setButtonState(UI.buttons.walkBoost, States.isWalkBoost)
		if States.isFlying then
			U.notifyToggle("Fly Boost (2x)", States.isWalkBoost)
		else
			U.notifyToggle("Walk Boost", States.isWalkBoost)
		end
	end)

	UI.buttons.jumpBoost.MouseButton1Click:Connect(function()
		States.isJumpBoost = not States.isJumpBoost
		local h, _ = U.getHumanoidAndRoot()
		if h then applyMovementStats(h) end
		U.setButtonState(UI.buttons.jumpBoost, States.isJumpBoost)
		U.notifyToggle("Jump Boost", States.isJumpBoost)
	end)

	UI.buttons.jumpSpam.MouseButton1Click:Connect(function()
		States.isJumpSpam = not States.isJumpSpam
		if States.isJumpSpam then startJumpSpam() else stopJumpSpam() end
		U.setButtonState(UI.buttons.jumpSpam, States.isJumpSpam)
		U.notifyToggle("Spam Jump", States.isJumpSpam)
	end)

	UI.buttons.unlockJump.MouseButton1Click:Connect(function()
		toggleUnlockJump()
		U.setButtonState(UI.buttons.unlockJump, States.isUnlockJump)
		U.notifyToggle("Unlock Jump", States.isUnlockJump)
	end)

	UI.buttons.walkOverride.MouseButton1Click:Connect(function()
		States.isWalkOverride = not States.isWalkOverride
		U.setButtonState(UI.buttons.walkOverride, States.isWalkOverride)
		local h, _ = U.getHumanoidAndRoot()
		if h then applyMovementStats(h) end
		U.notifyToggle("Walk Override", States.isWalkOverride)
	end)

	UI.buttons.mouseLock.MouseButton1Click:Connect(function()
		ShiftLock()
		U.setButtonState(UI.buttons.mouseLock, States.isMouseLocked)
		U.notifyToggle("Mouse Lock", States.isMouseLocked)
	end)

	UI.buttons.antiDelay.MouseButton1Click:Connect(function()
		toggleAntiMovementDelay()
		U.setButtonState(UI.buttons.antiDelay, States.isAntiMovementDelay)
		U.notifyToggle("Anti Delay", States.isAntiMovementDelay)
	end)

	UI.buttons.autoWalk.MouseButton1Click:Connect(function()
		toggleAutoWalk()
		U.setButtonState(UI.buttons.autoWalk, States.isAutoWalk)
	end)

	UI.buttons.autoInteract.MouseButton1Click:Connect(function()
		if States.isAutoInteractProximity then disableAutoInteractProximity() else enableAutoInteractProximity() end
		U.setButtonState(UI.buttons.autoInteract, States.isAutoInteractProximity)
		U.notifyToggle("Auto Interact", States.isAutoInteractProximity)
	end)


	UI.buttons.fullbright.MouseButton1Click:Connect(function()
		toggleFullbright()
	end)

	UI.buttons.noFog.MouseButton1Click:Connect(function()
		if States.isNoFog then disableNoFog() else enableNoFog() end
		U.setButtonState(UI.buttons.noFog, States.isNoFog)
		U.notifyToggle("No Fog", States.isNoFog)
	end)

	UI.buttons.noShadow.MouseButton1Click:Connect(function()
		if States.isNoShadow then disableNoShadow() else enableNoShadow() end
		U.setButtonState(UI.buttons.noShadow, States.isNoShadow)
		U.notifyToggle("No Shadow", States.isNoShadow)
	end)

	UI.buttons.visibleParts.MouseButton1Click:Connect(function()
		if States.isVisibleAllParts then disableVisibleAllParts() else enableVisibleAllParts() end
		U.setButtonState(UI.buttons.visibleParts, States.isVisibleAllParts)
		U.notifyToggle("Visible Parts", States.isVisibleAllParts)
	end)

	UI.buttons.espAll.MouseButton1Click:Connect(function()
		States.isEspUniversal = not States.isEspUniversal
		U.setButtonState(UI.buttons.espAll, States.isEspUniversal)
		refreshAllEsp()
		U.notifyToggle("ESP All", States.isEspUniversal)
	end)



	UI.buttons.espNpc.MouseButton1Click:Connect(function()
		States.isEspNpc = not States.isEspNpc
		U.setButtonState(UI.buttons.espNpc, States.isEspNpc)
		if States.isEspNpc then scanWorkspaceForNPCs() else refreshAllEsp() end
		U.notifyToggle("ESP NPC", States.isEspNpc)
	end)

	UI.buttons.espItems.MouseButton1Click:Connect(function()
		States.isEspItems = not States.isEspItems
		U.setButtonState(UI.buttons.espItems, States.isEspItems)
		updateEspForItems()
		U.notifyToggle("ESP Items", States.isEspItems)
	end)

	UI.buttons.xray.MouseButton1Click:Connect(function()
		toggleXRay()
		U.setButtonState(UI.buttons.xray, States.isXRay)
		U.notifyToggle("X-Ray", States.isXRay)
	end)

	UI.buttons.smoothZoom.MouseButton1Click:Connect(function()
		U.toggleSmoothZoom()
		U.notifyToggle("Smooth Zoom", States.isSmoothZoom)
	end)
	
	UI.buttons.cameraNoclip.MouseButton1Click:Connect(function()
		U.toggleCameraNoclip()
		U.notifyToggle("Camera Noclip", States.isCameraNoclip)
	end)

	UI.buttons.invisible.MouseButton1Click:Connect(function()
		toggleInvisible()
		U.setButtonState(UI.buttons.invisible, States.isInvisible)
		U.notifyToggle("Invisible", States.isInvisible)
	end)

	UI.buttons.floating.MouseButton1Click:Connect(function()
		toggleFloating()
		U.setButtonState(UI.buttons.floating, States.isFloating)
		U.notifyToggle("Floating", States.isFloating)
	end)

	UI.buttons.antiFling.MouseButton1Click:Connect(function()
		toggleAntiFling()
		U.setButtonState(UI.buttons.antiFling, States.isAntiFling)
		U.notifyToggle("Anti Fling", States.isAntiFling)
	end)

-- GodMode UI update removed

	UI.buttons.noTouch.MouseButton1Click:Connect(function()
		if States.isNoTouch then disableNoTouch() else enableNoTouch() end
		U.setButtonState(UI.buttons.noTouch, States.isNoTouch)
		U.notifyToggle("No Touch", States.isNoTouch)
	end)

	UI.buttons.clickTp.MouseButton1Click:Connect(function()
		toggleClickTeleport()
	end)

	UI.buttons.removeNC.MouseButton1Click:Connect(function()
		toggleNonCollideParts()
		U.setButtonState(UI.buttons.removeNC, States.isRemoveNCActive)
		U.notifyToggle("Remove NoCollide", States.isRemoveNCActive)
	end)

	UI.buttons.freecam.MouseButton1Click:Connect(function()
		if freecamController.isEnabled() then freecamController.stop() else freecamController.start() end
		U.setButtonState(UI.buttons.freecam, freecamController.isEnabled())
		U.notifyToggle("Freecam", freecamController.isEnabled())
	end)





	UI.buttons.vehicleBoost.MouseButton1Click:Connect(function()
		toggleVehicleBoost()
		U.setButtonState(UI.buttons.vehicleBoost, States.isVehicleBoost)
	end)

	UI.buttons.vehicleFly.MouseButton1Click:Connect(function()
		if States.isVehicleFly then stopFly() else startFly(true) end
		U.setButtonState(UI.buttons.vehicleFly, States.isVehicleFly)
		U.notifyToggle("Vehicle Fly", States.isVehicleFly)
	end)

	UI.buttons.autoTransmission.MouseButton1Click:Connect(function()
		States.isAutoTransmission = not States.isAutoTransmission
		U.setButtonState(UI.buttons.autoTransmission, States.isAutoTransmission)
		U.notifyToggle("Auto Transmission", States.isAutoTransmission)
	end)

	UI.buttons.lockTime.MouseButton1Click:Connect(function()
		U.toggleTimeLock()
	end)

	UI.buttons.fastAntiTraffic.MouseButton1Click:Connect(function()
		toggleFastAntiTraffic()
	end)


	UI.buttons.bypassAC.MouseButton1Click:Connect(function()
		States.isAntiCheatBypass = not States.isAntiCheatBypass
		U.setButtonState(UI.buttons.bypassAC, States.isAntiCheatBypass)
		U.notifyToggle("AC Bypass", States.isAntiCheatBypass)
	end)


	-- Input FocusLost Connections (With safety check)
	local function bindInput(inputObj, configKey, callback)
		if not inputObj then return end
		inputObj.FocusLost:Connect(function(enterPressed)
			if enterPressed then
				local val = U.parseNumber(inputObj.Text, Config[configKey] or 0)
				Config[configKey] = val
				inputObj.Text = tostring(val)
				if callback then callback(val) end
			end
		end)
	end

	bindInput(UI.inputs.walkSpeedInput, "walkSpeed", function() 
		States.isWalkOverride = true
		U.setButtonState(UI.buttons.walkOverride, true)
		local h, _ = U.getHumanoidAndRoot() 
		if h then applyMovementStats(h) end 
	end)
	bindInput(UI.inputs.walkBoostMultiplier, "walkBoostMultiplier", function() 
		local h, _ = U.getHumanoidAndRoot() 
		if h then applyMovementStats(h) end 
	end)
	bindInput(UI.inputs.flySpeed, "flySpeed")
	bindInput(UI.inputs.vehicleFlySpeed, "vehicleFlySpeed")
	bindInput(UI.inputs.freecamSpeed, "freecamBaseSpeed")
	bindInput(UI.inputs.jumpBoost, "jumpBoostMultiplier", function() 
		local h, _ = U.getHumanoidAndRoot() 
		if h then applyMovementStats(h) end 
	end)
	bindInput(UI.inputs.autoEDown, "autoEDownDelay")
	bindInput(UI.inputs.autoEUp, "autoEUpDelay")
	bindInput(UI.inputs.scrollAmount, "scrollAmount")
	bindInput(UI.inputs.zoomAmount, "zoomAmount")
	bindInput(UI.inputs.brightness, "brightnessValue", applyBrightness)
	bindInput(UI.inputs.exposure, "exposureCompensationValue", function() 
		if States.isFullbright then applyExposureCompensation() end 
	end)
	bindInput(UI.inputs.vehicleBoostAccelInput, "vehicleBoostAcceleration", function(val)
		local rounded = math.round(val)
		Config.vehicleBoostAcceleration = rounded
		UI.inputs.vehicleBoostAccelInput.Text = tostring(rounded)
	end)
	bindInput(UI.inputs.vehicleBrakeInput, "vehicleBrakeForce", function(val)
		local rounded = math.round(val)
		Config.vehicleBrakeForce = rounded
		UI.inputs.vehicleBrakeInput.Text = tostring(rounded)
	end)
	bindInput(UI.inputs.bringRadiusInput, "bringRadius")

	UI.inputs.skyboxInput.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			local id = UI.inputs.skyboxInput.Text
			applySkybox(id)
			U.setButtonState(UI.buttons.applySkybox, States.isSkyboxActive)
		end
	end)

	UI.buttons.applySkybox.MouseButton1Click:Connect(function()
		if States.isSkyboxActive then
			resetSkybox()
		else
			applySkybox(UI.inputs.skyboxInput.Text)
		end
		U.setButtonState(UI.buttons.applySkybox, States.isSkyboxActive)
		U.notifyToggle("Custom Skybox", States.isSkyboxActive)
	end)

	UI.inputs.localTimeInput.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			local t = U.parseNumber(UI.inputs.localTimeInput.Text, States.localTimeValue)
			updateLocalTime(t)
			UI.inputs.localTimeInput.Text = tostring(t)
		end
	end)

	UI.inputs.gravityInput.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			local g = U.parseNumber(UI.inputs.gravityInput.Text, States.gravityValue)
			updateGravity(g)
			UI.inputs.gravityInput.Text = tostring(g)
		end
	end)

	-- Reset Connections
	local function bindReset(btn, configKey, inputObj, defaultValOrKey, callback)
		if not btn then return end
		btn.MouseButton1Click:Connect(function()
			local finalDefault = defaultValOrKey
			if type(defaultValOrKey) == "string" and Config[defaultValOrKey] ~= nil then
				finalDefault = Config[defaultValOrKey]
			end
			
			Config[configKey] = finalDefault
			inputObj.Text = tostring(finalDefault)
			if callback then callback() end
		end)
	end

	bindReset(UI.inputs.walkSpeedReset, "walkSpeed", UI.inputs.walkSpeedInput, "defaultWalkSpeedFromCharacter", function() 
		-- Saat reset, matikan override agar ikut default game
		States.isWalkOverride = false
		U.setButtonState(UI.buttons.walkOverride, false)
		local h, _ = U.getHumanoidAndRoot() 
		if h then applyMovementStats(h) end 
	end)
	bindReset(UI.inputs.walkBoostReset, "walkBoostMultiplier", UI.inputs.walkBoostMultiplier, Config.DEFAULT_WALK_MULTIPLIER, function() 
		local h, _ = U.getHumanoidAndRoot() 
		if h then applyMovementStats(h) end 
	end)
	bindReset(UI.inputs.flySpeedReset, "flySpeed", UI.inputs.flySpeed, Config.DEFAULT_FLY_SPEED)
	bindReset(UI.inputs.freecamSpeedReset, "freecamBaseSpeed", UI.inputs.freecamSpeed, Config.DEFAULT_FREECAM_BASE_SPEED)
	bindReset(UI.inputs.jumpBoostReset, "jumpBoostMultiplier", UI.inputs.jumpBoost, Config.DEFAULT_JUMP_MULTIPLIER, function() 
		local h, _ = U.getHumanoidAndRoot() 
		if h then applyMovementStats(h) end 
	end)
	bindReset(UI.inputs.autoEDownReset, "autoEDownDelay", UI.inputs.autoEDown, Config.DEFAULT_AUTO_E_DOWN_DELAY)
	bindReset(UI.inputs.autoEUpReset, "autoEUpDelay", UI.inputs.autoEUp, Config.DEFAULT_AUTO_E_UP_DELAY)
	bindReset(UI.inputs.scrollAmountReset, "scrollAmount", UI.inputs.scrollAmount, 100)
	bindReset(UI.inputs.zoomAmountReset, "zoomAmount", UI.inputs.zoomAmount, Config.DEFAULT_ZOOM_AMOUNT or 5)
	bindReset(UI.inputs.brightnessReset, "brightnessValue", UI.inputs.brightness, Config.DEFAULT_BRIGHTNESS, applyBrightness)
	bindReset(UI.inputs.exposureReset, "exposureCompensationValue", UI.inputs.exposure, Config.DEFAULT_EXPOSURE_COMPENSATION, function() if States.isFullbright then applyExposureCompensation() end end)
	bindReset(UI.inputs.bringRadiusReset, "bringRadius", UI.inputs.bringRadiusInput, 100)

	UI.inputs.skyboxReset.MouseButton1Click:Connect(function()
		resetSkybox()
		UI.inputs.skyboxInput.Text = ""
		U.setButtonState(UI.buttons.applySkybox, false)
	end)

	UI.inputs.localTimeReset.MouseButton1Click:Connect(function()
		updateLocalTime(Config.DEFAULT_CLOCKTIME)
		UI.inputs.localTimeInput.Text = tostring(math.floor(Config.DEFAULT_CLOCKTIME * 100) / 100)
	end)

	UI.inputs.gravityReset.MouseButton1Click:Connect(function()
		updateGravity(Config.DEFAULT_GRAVITY)
		UI.inputs.gravityInput.Text = tostring(Config.DEFAULT_GRAVITY)
	end)

	-- ESP Distance Update Loop
	task.spawn(function()
		while not States.isDestroyed do
			local char = localPlayer.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			
			if root then
				local myPos = root.Position
				
				-- Update Player Distances
				for _, p in ipairs(S.Players:GetPlayers()) do
					if p ~= localPlayer and p.Character then
						local head = p.Character:FindFirstChild("Head")
						local b = head and head:FindFirstChild("AdminESPBillboard")
						if b then
							local distLabel = b:FindFirstChild("DistanceLabel")
							local targetRoot = p.Character:FindFirstChild("HumanoidRootPart")
							if distLabel and targetRoot then
								local dist = math.round((targetRoot.Position - myPos).Magnitude)
								distLabel.Text = "[" .. dist .. "m]"
							end
						end
					end
				end
				
				-- Update NPC Distances
				if States.isEspNpc then
					for npc, _ in pairs(Refs.npcCache) do
						if npc.Parent then
							local b = npc:FindFirstChild("AdminESPBillboard", true)
							if b then
								local distLabel = b:FindFirstChild("DistanceLabel")
								local targetRoot = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
								if distLabel and targetRoot then
									local dist = math.round((targetRoot.Position - myPos).Magnitude)
									distLabel.Text = "[" .. dist .. "m]"
								end
							end
						end
					end
				end
				
				-- Update Item Distances
				if States.isEspItems then
					for _, b in ipairs(workspace:GetDescendants()) do
						if b.Name == "AdminESPBillboard" and b:IsA("BillboardGui") then
							-- Check if it's an item (parent not in a character/NPC)
							local parent = b.Parent
							if parent and parent:IsA("BasePart") and not parent:FindFirstAncestorOfClass("Model") then
								local distLabel = b:FindFirstChild("DistanceLabel")
								if distLabel then
									local dist = math.round((parent.Position - myPos).Magnitude)
									distLabel.Text = "[" .. dist .. "m]"
								end
							end
						end
					end
				end
			end
			task.wait(0.1)
		end
	end)

	-- RGB Loop
	task.spawn(function()
		local h = 0
		while not States.isDestroyed do
			if States.isRGBTheme then
				h = (h + 1) % 360
				local color = Color3.fromHSV(h/360, 0.8, 1)
				States.panelThemeColor = color
				if UI.mainFrame then
					local stroke = UI.mainFrame:FindFirstChildOfClass("UIStroke")
					if stroke then stroke.Color = color end
				end
				if UI.pingLabel then UI.pingLabel.TextColor3 = color end
				for name, btn in pairs(UI.sidebarButtons) do
					local indicator = btn:FindFirstChild("Indicator")
					if name == currentTab and indicator then indicator.BackgroundColor3 = color end
				end
			end
			task.wait(0.05)
		end
	end)
-- (Removing the prematurely closed task.defer block to keep connections inside)

-- Position Save Functions
UI.buttons.savePos.MouseButton1Click:Connect(function()
	print("SavePos clicked!") -- Debug print
	local character = localPlayer.Character
	if character then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			States.savedPosition = root.CFrame
			U.notify("Position Saved", "Your current location has been recorded", 2)
			
			-- Visual feedback
			local originalColor = UI.buttons.savePos.BackgroundColor3
			S.TweenService:Create(UI.buttons.savePos, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0, 200, 100)}):Play()
			task.delay(0.2, function()
				S.TweenService:Create(UI.buttons.savePos, TweenInfo.new(0.3), {BackgroundColor3 = originalColor}):Play()
			end)
		else
			U.notify("Error", "Could not find character root", 2)
		end
	end
end)

UI.inputs.flashSpeedAmount.FocusLost:Connect(function()
	Config.flashSpeedAmount = tonumber(UI.inputs.flashSpeedAmount.Text) or Config.flashSpeedAmount
	UI.inputs.flashSpeedAmount.Text = tostring(Config.flashSpeedAmount)
end)

UI.inputs.flashSpeedReset.MouseButton1Click:Connect(function()
	Config.flashSpeedAmount = 1
	UI.inputs.flashSpeedAmount.Text = "1"
end)



-- Background loop for Loop TP
task.spawn(function()
	while not States.isDestroyed do
		task.wait(0.1)
		if States.loopTpTarget then
			local target = States.loopTpTarget
			if target and target.Parent then
				local pChar = target.Character
				local pRoot = pChar and pChar:FindFirstChild("HumanoidRootPart")
				
				local _, root = U.getHumanoidAndRoot()
				
				if root and pRoot then
					root.CFrame = pRoot.CFrame * CFrame.new(States.loopTpOffset or Vector3.new(0, 5, 0))
				end
			else
				States.loopTpTarget = nil
			end
		elseif States.loopWaypointTarget then
			local wp = States.loopWaypointTarget
			local _, root = U.getHumanoidAndRoot()
			if root and wp and wp.cf then
				root.CFrame = wp.cf
			else
				States.loopWaypointTarget = nil
			end
		end
	end
end)

-- Background loop for falling detection (Ultra-fast to prevent death delays)
task.spawn(function()
	while not States.isDestroyed do
		task.wait(0.05)
		if States.isAutoTpToSave and States.savedPosition then
			local character = localPlayer.Character
			local humanoid = character and character:FindFirstChild("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart")
			
			if root and humanoid and humanoid.Health > 0 then
				-- Calculate the exact height before the Roblox engine kills them
				-- Adding 50 studs padding to be safe
				local killHeight = workspace.FallenPartsDestroyHeight + 50
				
				-- If falling out of bounds OR below arbitrary fall limit (-400 fallback)
				if root.Position.Y < killHeight or root.Position.Y < -400 then
					-- Zero out momentum so they don't fall through the saved floor
					root.AssemblyLinearVelocity = Vector3.new(0,0,0)
					root.AssemblyAngularVelocity = Vector3.new(0,0,0)
					
					root.CFrame = States.savedPosition
					U.notify("Saved from Void!", "Teleported back to safety before dying.", 2)
					task.wait(1) -- Delay to avoid multiple triggers
				end
			end
		end
	end
end)

-- (Empty - moved logic above and deleted duplicates)

-- (Moved everything inside the closure)


-- task.delay(5, function()
-- 	skipLoadingScreen()
-- end)
	-- Dashboard Quick Action Connections
	local function linkDash(dashBtn, mainBtn)
		if not dashBtn or not mainBtn then return end
		dashBtn.MouseButton1Click:Connect(function()
			-- Simulate click on main button by firing its connections
			if E.getconnections then
				for _, connection in ipairs(E.getconnections(mainBtn.MouseButton1Click)) do
					connection:Fire()
				end
			end
		end)
		-- Synchronize state visually (colors/text)
		task.spawn(function()
			while task.wait(0.5) and not States.isDestroyed do
				dashBtn.BackgroundColor3 = mainBtn.BackgroundColor3
				dashBtn.Text = mainBtn.Text
			end
		end)
	end
	
	if UI.buttons and UI.buttons.dash_fly and UI.buttons.fly then linkDash(UI.buttons.dash_fly, UI.buttons.fly) end
	if UI.buttons and UI.buttons.dash_noclip and UI.buttons.noclip then linkDash(UI.buttons.dash_noclip, UI.buttons.noclip) end
	if UI.buttons and UI.buttons.dash_speed and UI.buttons.flashSpeed then linkDash(UI.buttons.dash_speed, UI.buttons.flashSpeed) end
	if UI.buttons and UI.buttons.dash_boost and UI.buttons.vehicleBoost then linkDash(UI.buttons.dash_boost, UI.buttons.vehicleBoost) end

-- Anti-AFK Background Loop (Resets idle timer by simulating key activity)
task.spawn(function()
	while not States.isDestroyed do
		if States.isAntiAfk then
			local vim = getVIM()
			if vim then
				pcall(function()
					-- Correct VirtualInputManager signature: SendKeyEvent(isKeyDown, keyCode, isProcessed, game)
					-- Using F15 as it's a silent key that resets the 20-minute idle threshold
					vim:SendKeyEvent(true, Enum.KeyCode.F15, false, game)
					task.wait(0.1)
					vim:SendKeyEvent(false, Enum.KeyCode.F15, false, game)
				end)
			end
		end
		task.wait(60) -- Repeat every minute to ensure the server sees activity
	end
end)

print("panel-admin.client: Admin panel loaded")
U.notify("FVKHUB", "fvkhub load success", 3)end) -- Final closure
