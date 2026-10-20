local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- ===== CONFIG =====
local COIN_NAME = "Coin_Server"
local CONTAINER_NAME = "CoinContainer" 
local LOBBY_NAME = "MainLobby"  -- si tocas algo dentro de esto, el script se detiene
local TOGGLE_KEY = Enum.KeyCode.H
local REST_TIME = 0.5
local TRAVEL_DELAY = 0.25
local TRAVEL_SPEED = 21    -- velocidad de vuelo hacia la moneda (studs/segundo)
local HOVER_HEIGHT = 3     -- studs por encima de la moneda
local DROP_TIME = 0.35     -- tiempo de espera para que caiga
local SAFE_DISTANCE = 40   -- skip coins with another player closer than this (studs)
local AVOID_PLAYERS = true
local SKIP_SECONDS = 5     -- ignore a coin this long if it's still there after a visit
local REQUIRE_VISIBLE = false -- true = solo monedas con Transparency < 1

-- ===== THEME =====
local BG = Color3.fromRGB(24, 24, 30)
local PANEL = Color3.fromRGB(38, 38, 48)
local TEXT = Color3.fromRGB(235, 235, 240)
local SUBTEXT = Color3.fromRGB(150, 150, 165)
local GREEN = Color3.fromRGB(70, 190, 110)
local RED = Color3.fromRGB(200, 70, 70)

-- ===== GUI =====
local gui = Instance.new("ScreenGui")
gui.Name = "CoinTpGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 0)
frame.AutomaticSize = Enum.AutomaticSize.Y
frame.Position = UDim2.new(0, 20, 0.35, 0)
frame.BackgroundColor3 = BG
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(60, 60, 75)
stroke.Thickness = 1
Instance.new("UIListLayout", frame).SortOrder = Enum.SortOrder.LayoutOrder

-- header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 36)
header.BackgroundTransparency = 1
header.LayoutOrder = 1
header.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 14, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Coin TP"
title.TextColor3 = TEXT
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 26, 0, 26)
minBtn.Position = UDim2.new(1, -34, 0, 5)
minBtn.BackgroundColor3 = PANEL
minBtn.Text = "–"
minBtn.TextColor3 = TEXT
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 16
minBtn.Parent = header
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

-- body
local body = Instance.new("Frame")
body.Size = UDim2.new(1, 0, 0, 0)
body.AutomaticSize = Enum.AutomaticSize.Y
body.BackgroundTransparency = 1
body.LayoutOrder = 2
body.Parent = frame

local pad = Instance.new("UIPadding", body)
pad.PaddingLeft = UDim.new(0, 12)
pad.PaddingRight = UDim.new(0, 12)
pad.PaddingBottom = UDim.new(0, 12)

local list = Instance.new("UIListLayout", body)
list.Padding = UDim.new(0, 8)
list.SortOrder = Enum.SortOrder.LayoutOrder

minBtn.MouseButton1Click:Connect(function()
	body.Visible = not body.Visible
	minBtn.Text = body.Visible and "–" or "+"
end)

local order = 0
local function nextOrder()
	order += 1
	return order
end

local function makeButton(text, color)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, 34)
	b.BackgroundColor3 = color
	b.Text = text
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamSemibold
	b.TextSize = 13
	b.AutoButtonColor = true
	b.LayoutOrder = nextOrder()
	b.Parent = body
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	return b
end

local function makeRow(label, default)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 28)
	row.BackgroundTransparency = 1
	row.LayoutOrder = nextOrder()
	row.Parent = body

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -70, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = label
	lbl.TextColor3 = SUBTEXT
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0, 62, 1, 0)
	box.Position = UDim2.new(1, -62, 0, 0)
	box.BackgroundColor3 = PANEL
	box.Text = tostring(default)
	box.TextColor3 = TEXT
	box.Font = Enum.Font.GothamMedium
	box.TextSize = 12
	box.ClearTextOnFocus = false
	box.Parent = row
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
	return box
end

local mainBtn = makeButton("Coin TP: OFF  [H]", RED)
local avoidBtn = makeButton("Avoid players: ON", PANEL)
local safeBox = makeRow("Safe distance (studs)", SAFE_DISTANCE)
local restBox = makeRow("Rest at coin (sec)", REST_TIME)
local travelBox = makeRow("Delay before TP (sec)", TRAVEL_DELAY)
local speedBox = makeRow("Fly speed (studs/s)", TRAVEL_SPEED)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, 0, 0, 34)
status.BackgroundColor3 = PANEL
status.BackgroundTransparency = 0.4
status.Text = "Idle"
status.TextColor3 = SUBTEXT
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextWrapped = true
status.LayoutOrder = nextOrder()
status.Parent = body
Instance.new("UICorner", status).CornerRadius = UDim.new(0, 6)

local function bindNumber(box, get, set, minValue)
	box.FocusLost:Connect(function()
		local n = tonumber(box.Text)
		if n then set(math.max(minValue, n)) end
		box.Text = tostring(get())
	end)
end
bindNumber(safeBox, function() return SAFE_DISTANCE end, function(v) SAFE_DISTANCE = v end, 0)
bindNumber(restBox, function() return REST_TIME end, function(v) REST_TIME = v end, 0)
bindNumber(travelBox, function() return TRAVEL_DELAY end, function(v) TRAVEL_DELAY = v end, 0)
bindNumber(speedBox, function() return TRAVEL_SPEED end, function(v) TRAVEL_SPEED = v end, 1)

local function refreshAvoid()
	avoidBtn.Text = "Avoid players: " .. (AVOID_PLAYERS and "ON" or "OFF")
	avoidBtn.BackgroundColor3 = AVOID_PLAYERS and Color3.fromRGB(55, 90, 70) or PANEL
end
avoidBtn.MouseButton1Click:Connect(function()
	AVOID_PLAYERS = not AVOID_PLAYERS
	refreshAvoid()
end)
refreshAvoid()

-- ===== Helpers =====
local enabled = false
local visited = 0
local skippedNearby = 0
local skipUntil = setmetatable({}, { __mode = "k" })
local containerCache
local deadThisRound = false 

local function findContainer()
	if containerCache and containerCache.Parent then
		return containerCache
	end
	local wp = workspace:FindFirstChild("Workplace")
	containerCache = (wp and wp:FindFirstChild(CONTAINER_NAME, true))
		or workspace:FindFirstChild(CONTAINER_NAME, true)
	return containerCache
end

local function getCoinPart(coin)
	if coin:IsA("BasePart") then
		return coin
	elseif coin:IsA("Model") then
		return coin.PrimaryPart or coin:FindFirstChildWhichIsA("BasePart", true)
	end
end

local function isCoinVisible(part)
	if not part or not part:IsDescendantOf(workspace) then return false end
	if REQUIRE_VISIBLE and part.Transparency >= 1 then return false end
	return true
end

local function getRoot()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return nil end
	return char:FindFirstChild("HumanoidRootPart")
end

local function hookCharacter(char)
	local hum = char:WaitForChild("Humanoid", 10)
	if hum then
		hum.Died:Connect(function()
			deadThisRound = true
		end)
	end
end
player.CharacterAdded:Connect(hookCharacter)
if player.Character then
	task.spawn(hookCharacter, player.Character)
end

local lobbyCache
local lobbyParams = OverlapParams.new()
lobbyParams.FilterType = Enum.RaycastFilterType.Include

local function findLobby()
	if lobbyCache and lobbyCache.Parent then
		return lobbyCache
	end
	lobbyCache = workspace:FindFirstChild(LOBBY_NAME, true)
	return lobbyCache
end

local function touchingLobby(root)
	local lobby = findLobby()
	if not lobby or not root then return false end
	lobbyParams.FilterDescendantsInstances = { lobby }
	local size = Vector3.new(6, 10, 6)
	local parts = workspace:GetPartBoundsInBox(root.CFrame * CFrame.new(0, -2, 0), size, lobbyParams)
	return #parts > 0
end

local function playerNear(position)
	if not AVOID_PLAYERS then return false end
	for _, other in Players:GetPlayers() do
		if other ~= player then
			local char = other.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp and (hrp.Position - position).Magnitude < SAFE_DISTANCE then
				return true
			end
		end
	end
	return false
end

local function collectCoins(container)
	local result, skipped, visibleCount = {}, 0, 0
	local now = os.clock()
	for _, obj in container:GetDescendants() do
		-- Solo busca exactamente "Coin_Server"
		if obj.Name == COIN_NAME then
			local part = getCoinPart(obj)
			if isCoinVisible(part) then
				visibleCount += 1
				if not skipUntil[obj] or skipUntil[obj] < now then
					if playerNear(part.Position) then
						skipped += 1
					else
						table.insert(result, { coin = obj, part = part })
					end
				end
			end
		end
	end
	return result, skipped, visibleCount
end

local function touch(root, part)
	if firetouchinterest then
		pcall(function()
			firetouchinterest(root, part, 0)
			firetouchinterest(root, part, 1)
		end)
	end
end

local function glideAbove(root, part)
	local targetPos = part.CFrame + Vector3.new(0, HOVER_HEIGHT, 0)
	local distance = (targetPos.Position - root.Position).Magnitude
	local duration = math.max(distance / TRAVEL_SPEED, 0.05)

	root.AssemblyLinearVelocity = Vector3.zero
	root.Anchored = true

	local tween = TweenService:Create(
		root,
		TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
		{ CFrame = targetPos }
	)
	tween:Play()

	task.spawn(function()
		while tween.PlaybackState == Enum.PlaybackState.Playing do
			if not enabled or deadThisRound or not isCoinVisible(part) or touchingLobby(root) then
				tween:Cancel()
				break
			end
			task.wait(0.05)
		end
	end)

	tween.Completed:Wait()
	root.Anchored = false
end

-- ===== Main loop =====
local function loop()
	while enabled do
		local container = findContainer()
		if not container then
			status.Text = "Waiting for round (no Container)"
			task.wait(1)
			continue
		end

		local root = getRoot()
		if not root then
			status.Text = "Waiting for character..."
			task.wait(0.5)
			continue
		end

		if touchingLobby(root) then
			status.Text = ("Waiting for round to start | Visited: %d"):format(visited)
			task.wait(0.3)
			continue
		end

		local coins, skipped, visibleCount = collectCoins(container)

		if visibleCount == 0 then
			deadThisRound = false 
			status.Text = ("Waiting for round to start | Visited: %d"):format(visited)
			task.wait(0.5)
			continue
		end

		if deadThisRound then
			status.Text = ("Dead / in lobby - waiting for next round | Visited: %d"):format(visited)
			task.wait(0.5)
			continue
		end

		if #coins == 0 then
			status.Text = ("No safe coins | Skipped (players nearby): %d | Visited: %d"):format(skipped, visited)
			task.wait(0.5)
			continue
		end

		local pos = root.Position
		local best, bestDist
		for _, entry in coins do
			local d = (entry.part.Position - pos).Magnitude
			if not bestDist or d < bestDist then
				best, bestDist = entry, d
			end
		end
		local entry = best

		task.wait(TRAVEL_DELAY)

		root = getRoot()
		if not enabled or deadThisRound or not root then continue end
		if not entry.coin.Parent or not isCoinVisible(entry.part) then
			status.Text = ("Coin already taken, picking another | Visited: %d"):format(visited)
			continue 
		end
		if touchingLobby(root) then continue end

		if playerNear(entry.part.Position) then
			skippedNearby += 1
			skipUntil[entry.coin] = os.clock() + SKIP_SECONDS
			status.Text = ("Skipped a coin, player nearby | Visited: %d"):format(visited)
			continue
		end

		status.Text = ("Going to nearest coin (%d studs) | Visited: %d"):format(math.floor(bestDist), visited)
		glideAbove(root, entry.part) 

		if not enabled or deadThisRound or touchingLobby(root) then continue end
		if not entry.coin.Parent or not isCoinVisible(entry.part) then
			status.Text = ("Coin taken while flying | Visited: %d"):format(visited)
			continue
		end

		task.wait(DROP_TIME)
		if isCoinVisible(entry.part) then
			touch(root, entry.part) 
		end
		visited += 1
		status.Text = ("Visited: %d | Skipped: %d | Coins left: %d"):format(visited, skippedNearby, #coins - 1)

		task.wait(REST_TIME)

		if entry.coin.Parent then
			skipUntil[entry.coin] = os.clock() + SKIP_SECONDS
		end

		task.wait()
	end
	status.Text = ("Idle | Visited: %d | Skipped: %d"):format(visited, skippedNearby)
end

local function setEnabled(state)
	enabled = state
	mainBtn.Text = "Coin TP: " .. (enabled and "ON" or "OFF") .. "  [H]"
	mainBtn.BackgroundColor3 = enabled and GREEN or RED
	if enabled then
		task.spawn(loop)
	else
		local root = getRoot()
		if root then root.Anchored = false end
	end
end

mainBtn.MouseButton1Click:Connect(function()
	setEnabled(not enabled)
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == TOGGLE_KEY then
		setEnabled(not enabled)
	end
end)
