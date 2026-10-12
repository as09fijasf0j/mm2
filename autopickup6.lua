-- Custom Auto Pickup Gun Script for MM2 (Teleport Chain + Fling + Role Tracker)
-- Mobile Friendly with Clean Draggable GUI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- Configuration
local TELEPORT_OFFSET = 3
local RETURN_DELAY = 0.25
local RESET_DELAY = 3
local LOBBY_LOCK_ENABLED = false
local AUTO_PICKUP_ENABLED = false
local TARGET_PLAYER_NAME = ""
local FLING_ENABLED = true
local FLING_DURATION = 2
local FLING_SPIN_SPEED = 100

-- Saved state
local chainRunning = false
local roleTrackerConn = nil

--============================================================
-- GUI CREATION
--============================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoPickupGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- MAIN PANEL (Left side)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 240, 0, 290)
MainFrame.Position = UDim2.new(0, 10, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(70, 70, 85)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 34)
TopBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 14)
TopCorner.Parent = TopBar

local TopCover = Instance.new("Frame")
TopCover.Size = UDim2.new(1, 0, 0, 14)
TopCover.Position = UDim2.new(0, 0, 1, -14)
TopCover.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
TopCover.BorderSizePixel = 0
TopCover.Parent = TopBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -20, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "MM2 AUTO PICKUP"
TitleLabel.TextColor3 = Color3.fromRGB(230, 230, 240)
TitleLabel.TextSize = 14
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local HintLabel = Instance.new("TextLabel")
HintLabel.Size = UDim2.new(1, -20, 0, 14)
HintLabel.Position = UDim2.new(0, 12, 0, 34)
HintLabel.BackgroundTransparency = 1
HintLabel.Text = "Drag this bar to move"
HintLabel.TextColor3 = Color3.fromRGB(120, 120, 140)
HintLabel.TextSize = 10
HintLabel.Font = Enum.Font.Gotham
HintLabel.TextXAlignment = Enum.TextXAlignment.Left
HintLabel.Parent = MainFrame

-- Lobby Lock button
local LobbyLockButton = Instance.new("TextButton")
LobbyLockButton.Name = "LobbyLockButton"
LobbyLockButton.Size = UDim2.new(1, -24, 0, 38)
LobbyLockButton.Position = UDim2.new(0, 12, 0, 52)
LobbyLockButton.BackgroundColor3 = Color3.fromRGB(210, 60, 60)
LobbyLockButton.BorderSizePixel = 0
LobbyLockButton.Text = "LOBBY LOCK: OFF"
LobbyLockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
LobbyLockButton.TextSize = 14
LobbyLockButton.Font = Enum.Font.GothamBold
LobbyLockButton.AutoButtonColor = false
LobbyLockButton.Parent = MainFrame

local LobbyLockCorner = Instance.new("UICorner")
LobbyLockCorner.CornerRadius = UDim.new(0, 10)
LobbyLockCorner.Parent = LobbyLockButton

-- Auto pickup button
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(1, -24, 0, 38)
ToggleButton.Position = UDim2.new(0, 12, 0, 96)
ToggleButton.BackgroundColor3 = Color3.fromRGB(210, 60, 60)
ToggleButton.BorderSizePixel = 0
ToggleButton.Text = "AUTO PICKUP: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 14
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.AutoButtonColor = false
ToggleButton.Parent = MainFrame

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 10)
ToggleCorner.Parent = ToggleButton

-- Target label
local TargetLabel = Instance.new("TextLabel")
TargetLabel.Size = UDim2.new(1, -24, 0, 14)
TargetLabel.Position = UDim2.new(0, 12, 0, 142)
TargetLabel.BackgroundTransparency = 1
TargetLabel.Text = "TARGET PLAYER USERNAME"
TargetLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
TargetLabel.TextSize = 10
TargetLabel.Font = Enum.Font.GothamBold
TargetLabel.TextXAlignment = Enum.TextXAlignment.Left
TargetLabel.Parent = MainFrame

local TargetBox = Instance.new("TextBox")
TargetBox.Name = "TargetBox"
TargetBox.Size = UDim2.new(1, -24, 0, 34)
TargetBox.Position = UDim2.new(0, 12, 0, 158)
TargetBox.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
TargetBox.BorderSizePixel = 0
TargetBox.Text = ""
TargetBox.PlaceholderText = "Type username here..."
TargetBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
TargetBox.TextColor3 = Color3.fromRGB(230, 230, 240)
TargetBox.TextSize = 13
TargetBox.Font = Enum.Font.Gotham
TargetBox.ClearTextOnFocus = false
TargetBox.Parent = MainFrame

local BoxCorner = Instance.new("UICorner")
BoxCorner.CornerRadius = UDim.new(0, 8)
BoxCorner.Parent = TargetBox

local BoxStroke = Instance.new("UIStroke")
BoxStroke.Color = Color3.fromRGB(70, 70, 85)
BoxStroke.Thickness = 1
BoxStroke.Parent = TargetBox

TargetBox.Focused:Connect(function()
    BoxStroke.Color = Color3.fromRGB(100, 150, 255)
end)
TargetBox.FocusLost:Connect(function()
    BoxStroke.Color = Color3.fromRGB(70, 70, 85)
    TARGET_PLAYER_NAME = TargetBox.Text
end)
TargetBox:GetPropertyChangedSignal("Text"):Connect(function()
    TARGET_PLAYER_NAME = TargetBox.Text
end)

-- Fling header
local FlingLabel = Instance.new("TextLabel")
FlingLabel.Size = UDim2.new(1, -24, 0, 14)
FlingLabel.Position = UDim2.new(0, 12, 0, 200)
FlingLabel.BackgroundTransparency = 1
FlingLabel.Text = "FLING TARGET"
FlingLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
FlingLabel.TextSize = 10
FlingLabel.Font = Enum.Font.GothamBold
FlingLabel.TextXAlignment = Enum.TextXAlignment.Left
FlingLabel.Parent = MainFrame

local FlingMurdererButton = Instance.new("TextButton")
FlingMurdererButton.Name = "FlingMurdererButton"
FlingMurdererButton.Size = UDim2.new(0.5, -18, 0, 38)
FlingMurdererButton.Position = UDim2.new(0, 12, 0, 218)
FlingMurdererButton.BackgroundColor3 = Color3.fromRGB(170, 50, 50)
FlingMurdererButton.BorderSizePixel = 0
FlingMurdererButton.Text = "FLING MURDERER"
FlingMurdererButton.TextColor3 = Color3.fromRGB(255, 255, 255)
FlingMurdererButton.TextSize = 12
FlingMurdererButton.Font = Enum.Font.GothamBold
FlingMurdererButton.AutoButtonColor = false
FlingMurdererButton.Parent = MainFrame

local FlingMCorner = Instance.new("UICorner")
FlingMCorner.CornerRadius = UDim.new(0, 10)
FlingMCorner.Parent = FlingMurdererButton

local FlingSheriffButton = Instance.new("TextButton")
FlingSheriffButton.Name = "FlingSheriffButton"
FlingSheriffButton.Size = UDim2.new(0.5, -18, 0, 38)
FlingSheriffButton.Position = UDim2.new(0.5, 6, 0, 218)
FlingSheriffButton.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
FlingSheriffButton.BorderSizePixel = 0
FlingSheriffButton.Text = "FLING SHERIFF"
FlingSheriffButton.TextColor3 = Color3.fromRGB(255, 255, 255)
FlingSheriffButton.TextSize = 12
FlingSheriffButton.Font = Enum.Font.GothamBold
FlingSheriffButton.AutoButtonColor = false
FlingSheriffButton.Parent = MainFrame

local FlingSCorner = Instance.new("UICorner")
FlingSCorner.CornerRadius = UDim.new(0, 10)
FlingSCorner.Parent = FlingSheriffButton

-- Status label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Size = UDim2.new(1, -24, 0, 16)
StatusLabel.Position = UDim2.new(0, 12, 0, 264)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = ""
StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame

local function setStatus(msg)
    StatusLabel.Text = msg
    task.delay(2.5, function()
        if StatusLabel.Text == msg then
            StatusLabel.Text = ""
        end
    end)
end

--============================================================
-- ROLE TRACKER GUI (Top Right)
--============================================================

local RoleFrame = Instance.new("Frame")
RoleFrame.Name = "RoleFrame"
RoleFrame.Size = UDim2.new(0, 200, 0, 80)
RoleFrame.Position = UDim2.new(1, -210, 0, 10)
RoleFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
RoleFrame.BorderSizePixel = 0
RoleFrame.Active = true
RoleFrame.Parent = ScreenGui

local RoleCorner = Instance.new("UICorner")
RoleCorner.CornerRadius = UDim.new(0, 10)
RoleCorner.Parent = RoleFrame

local RoleStroke = Instance.new("UIStroke")
RoleStroke.Color = Color3.fromRGB(70, 70, 85)
RoleStroke.Thickness = 1
RoleStroke.Parent = RoleFrame

local RoleTitle = Instance.new("TextLabel")
RoleTitle.Size = UDim2.new(1, 0, 0, 24)
RoleTitle.Position = UDim2.new(0, 0, 0, 0)
RoleTitle.BackgroundTransparency = 1
RoleTitle.Text = "ROLES"
RoleTitle.TextColor3 = Color3.fromRGB(230, 230, 240)
RoleTitle.TextSize = 12
RoleTitle.Font = Enum.Font.GothamBold
RoleTitle.Parent = RoleFrame

local MurdererLabel = Instance.new("TextLabel")
MurdererLabel.Name = "MurdererLabel"
MurdererLabel.Size = UDim2.new(1, -20, 0, 22)
MurdererLabel.Position = UDim2.new(0, 10, 0, 28)
MurdererLabel.BackgroundTransparency = 1
MurdererLabel.Text = "Murderer: Scanning..."
MurdererLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
MurdererLabel.TextSize = 11
MurdererLabel.Font = Enum.Font.Gotham
MurdererLabel.TextXAlignment = Enum.TextXAlignment.Left
MurdererLabel.Parent = RoleFrame

local SheriffLabel = Instance.new("TextLabel")
SheriffLabel.Name = "SheriffLabel"
SheriffLabel.Size = UDim2.new(1, -20, 0, 22)
SheriffLabel.Position = UDim2.new(0, 10, 0, 50)
SheriffLabel.BackgroundTransparency = 1
SheriffLabel.Text = "Sheriff: Scanning..."
SheriffLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
SheriffLabel.TextSize = 11
SheriffLabel.Font = Enum.Font.Gotham
SheriffLabel.TextXAlignment = Enum.TextXAlignment.Left
SheriffLabel.Parent = RoleFrame

--============================================================
-- DRAG SUPPORT
--============================================================

local dragging = false
local dragStart = nil
local startPos = nil

local function updateDrag(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or
       input.UserInputType == Enum.UserInputType.Touch then
        if dragging then updateDrag(input) end
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                     input.UserInputType == Enum.UserInputType.Touch) then
        updateDrag(input)
    end
end)

--============================================================
-- CORE HELPERS
--============================================================

local function getRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getLobbyCFrame()
    local lobby = workspace:FindFirstChild("RegularLobby")
    if lobby then
        local spawn = lobby:FindFirstChildOfClass("SpawnLocation")
        if spawn then return spawn.CFrame + Vector3.new(0, 5, 0) end
        local mainLobby = lobby:FindFirstChild("MainLobby")
        if mainLobby and mainLobby:IsA("Model") and mainLobby.PrimaryPart then
            return mainLobby.PrimaryPart.CFrame + Vector3.new(0, 5, 0)
        end
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") then
            return obj.CFrame + Vector3.new(0, 5, 0)
        end
    end
    return nil
end

local function isInLobby()
    local root = getRoot()
    if not root then return true end
    local lobby = workspace:FindFirstChild("RegularLobby")
    if not lobby then return true end
    local lobbyCF = getLobbyCFrame()
    if not lobbyCF then return true end
    return (root.Position - lobbyCF.Position).Magnitude < 100
end

local function findNearestGun()
    local root = getRoot()
    if not root then return nil end
    local nearest, shortest = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "GunDrop" then
            local d = (obj.Position - root.Position).Magnitude
            if d < shortest then
                shortest = d
                nearest = obj
            end
        end
    end
    return nearest
end

local function findTargetPlayer()
    local name = TARGET_PLAYER_NAME
    if not name or name == "" then return nil end
    name = name:lower():gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return nil end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Name:lower() == name then
            local c = plr.Character
            local h = c and c:FindFirstChild("HumanoidRootPart")
            if h then return h end
        end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Name:lower():find(name, 1, true) then
            local c = plr.Character
            local h = c and c:FindFirstChild("HumanoidRootPart")
            if h then return h end
        end
    end
    return nil
end

local function pickupGun(gunPart)
    if not gunPart or not gunPart.Parent then return end
    local prompt = gunPart:FindFirstChildOfClass("ProximityPrompt")
        or (gunPart.Parent and gunPart.Parent:FindFirstChildOfClass("ProximityPrompt"))
    if prompt then
        pcall(function() fireproximityprompt(prompt) end)
        return
    end
    local cd = gunPart:FindFirstChildOfClass("ClickDetector")
        or (gunPart.Parent and gunPart.Parent:FindFirstChildOfClass("ClickDetector"))
    if cd then
        pcall(function() fireclickdetector(cd) end)
        return
    end
    local root = getRoot()
    if root then
        pcall(function()
            firetouchinterest(root, gunPart, 0)
            task.wait(0.05)
            firetouchinterest(root, gunPart, 1)
        end)
    end
end

--============================================================
-- TELEPORT CHAIN
--============================================================

local function teleportToLobby()
    local root = getRoot()
    if not root then return end
    local cf = getLobbyCFrame()
    if cf then
        pcall(function() root.CFrame = cf end)
    end
end

local function runChain(gunPart)
    if chainRunning then return end
    chainRunning = true

    local root = getRoot()
    if not root then chainRunning = false return end

    setStatus("Chain: teleporting to gun...")

    if gunPart and gunPart.Parent then
        pcall(function()
            root.CFrame = CFrame.new(gunPart.Position + Vector3.new(0, TELEPORT_OFFSET, 0))
        end)
        task.wait(RETURN_DELAY)
        pickupGun(gunPart)
        task.wait(RETURN_DELAY)
    end

    teleportToLobby()
    task.wait(RETURN_DELAY)

    local targetHRP = findTargetPlayer()
    if targetHRP then
        setStatus("Chain: teleporting to target...")
        pcall(function()
            root.CFrame = targetHRP.CFrame + Vector3.new(0, 3, 0)
        end)
        task.wait(RETURN_DELAY)
    end

    setStatus("Chain: resetting in " .. RESET_DELAY .. "s...")
    task.wait(RESET_DELAY)

    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function() hum.Health = 0 end)
    end

    chainRunning = false
end

--============================================================
-- LOBBY LOCK LOOP
--============================================================

local lobbyConn = nil

local function startLobbyLock()
    if lobbyConn then return end
    lobbyConn = RunService.Heartbeat:Connect(function()
        if not LOBBY_LOCK_ENABLED then return end
        if chainRunning then return end
        if not isInLobby() then
            teleportToLobby()
        end
    end)
end

local function stopLobbyLock()
    if lobbyConn then
        lobbyConn:Disconnect()
        lobbyConn = nil
    end
end

--============================================================
-- AUTO PICKUP LOOP
--============================================================

local pickupConn = nil

local function startAutoPickup()
    if pickupConn then return end
    pickupConn = RunService.Heartbeat:Connect(function()
        if not AUTO_PICKUP_ENABLED then return end
        if chainRunning then return end

        local gun = findNearestGun()
        if gun then
            task.spawn(function()
                runChain(gun)
            end)
        end
    end)
end

local function stopAutoPickup()
    if pickupConn then
        pickupConn:Disconnect()
        pickupConn = nil
    end
end

--============================================================
-- ROLE TRACKING
--============================================================

local function checkPlayerForRole(plr, roleName)
    local char = plr.Character
    local function checkContainer(container)
        if not container then return false end
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") then
                local n = tool.Name:lower()
                if roleName == "murderer" and n:find("knife") then return true end
                if roleName == "sheriff" and n:find("gun") and not n:find("drop") then
                    return true
                end
            end
        end
        return false
    end
    if checkContainer(char) then return true end
    return checkContainer(plr:FindFirstChildOfClass("Backpack"))
end

local function updateRoleTracker()
    local murdererName = "None"
    local sheriffName = "None"
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if checkPlayerForRole(plr, "murderer") then
                murdererName = plr.Name
            elseif checkPlayerForRole(plr, "sheriff") then
                sheriffName = plr.Name
            end
        end
    end
    MurdererLabel.Text = "Murderer: " .. murdererName
    SheriffLabel.Text = "Sheriff: " .. sheriffName
end

local function startRoleTracker()
    if roleTrackerConn then return end
    roleTrackerConn = RunService.Heartbeat:Connect(function()
        pcall(updateRoleTracker)
    end)
end

--============================================================
-- ROLE DETECTION (For Fling Buttons)
--============================================================

local function findRolePlayer(roleName)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and checkPlayerForRole(plr, roleName) then
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then return plr, hrp end
        end
    end
    return nil, nil
end

--============================================================
-- FLING (Using BodyVelocity/BodyGyro - more reliable method)
--============================================================

local function flingTarget(targetHRP)
    if not targetHRP or not targetHRP.Parent then return end
    if not FLING_ENABLED then return end

    local char = targetHRP.Parent
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    -- Try to grab network ownership
    pcall(function()
        targetHRP:SetNetworkOwner(LocalPlayer)
    end)

    -- Disable seated state
    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    end)

    -- Zero velocity
    pcall(function()
        targetHRP.Velocity = Vector3.new(0, 0, 0)
        targetHRP.RotVelocity = Vector3.new(0, 0, 0)
    end)

    -- Create fling forces
    local bv = Instance.new("BodyVelocity")
    bv.Name = "FlingVelocity"
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.P = math.huge
    bv.Parent = targetHRP

    local bg = Instance.new("BodyGyro")
    bg.Name = "FlingAngular"
    bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bg.P = math.huge
    bg.D = 50
    bg.CFrame = targetHRP.CFrame
    bg.Parent = targetHRP

    -- Main fling loop
    local startTime = tick()
    local angle = 0

    while tick() - startTime < FLING_DURATION do
        if not targetHRP or not targetHRP.Parent then break end

        angle = angle + FLING_SPIN_SPEED
        local spin = CFrame.Angles(math.rad(angle), 0, 0)

        pcall(function()
            bg.CFrame = targetHRP.CFrame * spin
            bv.Velocity = Vector3.new(
                (math.random() - 0.5) * 2000,
                math.random() * 1000,
                (math.random() - 0.5) * 2000
            )
        end)
        task.wait()
    end

    -- Clean up
    pcall(function()
        if bv and bv.Parent then bv:Destroy() end
        if bg and bg.Parent then bg:Destroy() end
    end)

    -- Re-enable seated
    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    end)
end

--============================================================
-- BUTTON HANDLERS
--============================================================

LobbyLockButton.MouseButton1Click:Connect(function()
    LOBBY_LOCK_ENABLED = not LOBBY_LOCK_ENABLED
    if LOBBY_LOCK_ENABLED then
        LobbyLockButton.Text = "LOBBY LOCK: ON"
        LobbyLockButton.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
        startLobbyLock()
        setStatus("Lobby lock enabled")
    else
        LobbyLockButton.Text = "LOBBY LOCK: OFF"
        LobbyLockButton.BackgroundColor3 = Color3.fromRGB(210, 60, 60)
        stopLobbyLock()
        setStatus("Lobby lock disabled")
    end
end)

ToggleButton.MouseButton1Click:Connect(function()
    AUTO_PICKUP_ENABLED = not AUTO_PICKUP_ENABLED
    if AUTO_PICKUP_ENABLED then
        ToggleButton.Text = "AUTO PICKUP: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
        startAutoPickup()
        setStatus("Auto pickup enabled")
    else
        ToggleButton.Text = "AUTO PICKUP: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(210, 60, 60)
        stopAutoPickup()
        setStatus("Auto pickup disabled")
    end
end)

FlingMurdererButton.MouseButton1Click:Connect(function()
    local plr, hrp = findRolePlayer("murderer")
    if plr and hrp then
        setStatus("Flinging murderer: " .. plr.Name)
        task.spawn(function() flingTarget(hrp) end)
    else
        setStatus("Murderer not found")
    end
end)

FlingSheriffButton.MouseButton1Click:Connect(function()
    local plr, hrp = findRolePlayer("sheriff")
    if plr and hrp then
        setStatus("Flinging sheriff: " .. plr.Name)
        task.spawn(function() flingTarget(hrp) end)
    else
        setStatus("Sheriff not found")
    end
end)

-- Start role tracker on load
startRoleTracker()

LocalPlayer.CharacterAdded:Connect(function()
    if LOBBY_LOCK_ENABLED then
        task.wait(1)
        teleportToLobby()
    end
end)

print("MM2 Auto Pickup + Fling + Role Tracker Loaded!")
