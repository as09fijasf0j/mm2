-- MM2 Auto Pickup + Role Tracker + Working Fling (Custom GUI)
-- Mobile Friendly with Clean Draggable GUI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local env = getgenv and getgenv() or getfenv and getfenv(0) or _G

-- Configuration
local TELEPORT_OFFSET = 3
local RETURN_DELAY = 0.25
local RESET_DELAY = 3
local LOBBY_LOCK_ENABLED = false
local AUTO_PICKUP_ENABLED = false
local TARGET_PLAYER_NAME = ""
local TARGET_PLAYER_OBJ = nil
local FLING_TIMEOUT = 2.5

-- Saved state
local chainRunning = false
local roleTrackerConn = nil
local flinging = false
local flingThread = nil

--============================================================
-- GUI
--============================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoPickupGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 240, 0, 340)
MainFrame.Position = UDim2.new(0, 10, 0.05, 0)
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

TargetBox.Focused:Connect(function() BoxStroke.Color = Color3.fromRGB(100, 150, 255) end)
TargetBox.FocusLost:Connect(function()
    BoxStroke.Color = Color3.fromRGB(70, 70, 85)
    TARGET_PLAYER_NAME = TargetBox.Text
end)
TargetBox:GetPropertyChangedSignal("Text"):Connect(function()
    TARGET_PLAYER_NAME = TargetBox.Text
end)

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

-- SELECT PLAYER dropdown button
local SelectButton = Instance.new("TextButton")
SelectButton.Name = "SelectButton"
SelectButton.Size = UDim2.new(1, -24, 0, 30)
SelectButton.Position = UDim2.new(0, 12, 0, 218)
SelectButton.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
SelectButton.BorderSizePixel = 0
SelectButton.Text = "SELECT PLAYER..."
SelectButton.TextColor3 = Color3.fromRGB(220, 220, 240)
SelectButton.TextSize = 12
SelectButton.Font = Enum.Font.Gotham
SelectButton.AutoButtonColor = false
SelectButton.Parent = MainFrame

local SelectCorner = Instance.new("UICorner")
SelectCorner.CornerRadius = UDim.new(0, 8)
SelectCorner.Parent = SelectButton

local FlingMurdererButton = Instance.new("TextButton")
FlingMurdererButton.Name = "FlingMurdererButton"
FlingMurdererButton.Size = UDim2.new(0.5, -18, 0, 38)
FlingMurdererButton.Position = UDim2.new(0, 12, 0, 254)
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
FlingSheriffButton.Position = UDim2.new(0.5, 6, 0, 254)
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

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Size = UDim2.new(1, -24, 0, 16)
StatusLabel.Position = UDim2.new(0, 12, 0, 314)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = ""
StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame

-- Player list popup (initially hidden)
local PlayerListFrame = Instance.new("ScrollingFrame")
PlayerListFrame.Name = "PlayerListFrame"
PlayerListFrame.Size = UDim2.new(1, -24, 0, 150)
PlayerListFrame.Position = UDim2.new(0, 12, 0, 218)
PlayerListFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
PlayerListFrame.BorderSizePixel = 0
PlayerListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerListFrame.ScrollBarThickness = 3
PlayerListFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 130)
PlayerListFrame.Visible = false
PlayerListFrame.ZIndex = 20
PlayerListFrame.Parent = MainFrame

local ListCorner = Instance.new("UICorner")
ListCorner.CornerRadius = UDim.new(0, 8)
ListCorner.Parent = PlayerListFrame

local ListStroke = Instance.new("UIStroke")
ListStroke.Color = Color3.fromRGB(100, 100, 130)
ListStroke.Thickness = 1
ListStroke.Parent = PlayerListFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 3)
ListLayout.Parent = PlayerListFrame

local function setStatus(msg)
    StatusLabel.Text = msg
    task.delay(2.5, function()
        if StatusLabel.Text == msg then StatusLabel.Text = "" end
    end)
end

local function refreshPlayerList()
    for _, child in ipairs(PlayerListFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -8, 0, 26)
            btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
            btn.BorderSizePixel = 0
            btn.Text = "  " .. plr.Name
            btn.TextColor3 = Color3.fromRGB(220, 220, 240)
            btn.TextSize = 12
            btn.Font = Enum.Font.Gotham
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.AutoButtonColor = false
            btn.Parent = PlayerListFrame

            local bc = Instance.new("UICorner")
            bc.CornerRadius = UDim.new(0, 6)
            bc.Parent = btn

            btn.MouseButton1Click:Connect(function()
                TARGET_PLAYER_OBJ = plr
                SelectButton.Text = "TARGET: " .. plr.Name
                SelectButton.BackgroundColor3 = Color3.fromRGB(60, 100, 180)
                PlayerListFrame.Visible = false
                setStatus("Selected: " .. plr.Name)
            end)
        end
    end
    task.wait()
    PlayerListFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 10)
end

SelectButton.MouseButton1Click:Connect(function()
    refreshPlayerList()
    PlayerListFrame.Visible = not PlayerListFrame.Visible
end)

--============================================================
-- ROLE TRACKER
--============================================================

local RoleFrame = Instance.new("Frame")
RoleFrame.Name = "RoleFrame"
RoleFrame.Size = UDim2.new(0, 200, 0, 80)
RoleFrame.Position = UDim2.new(1, -210, 0, 10)
RoleFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
RoleFrame.BorderSizePixel = 0
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
RoleTitle.BackgroundTransparency = 1
RoleTitle.Text = "ROLES"
RoleTitle.TextColor3 = Color3.fromRGB(230, 230, 240)
RoleTitle.TextSize = 12
RoleTitle.Font = Enum.Font.GothamBold
RoleTitle.Parent = RoleFrame

local MurdererLabel = Instance.new("TextLabel")
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
-- DRAG
--============================================================

local dragging = false
local dragStart = nil
local startPos = nil

local function updateDrag(input)
    local delta = input.Position - dragStart
    MainFrame.Position = UDim2.new(
        startPos.X.Scale, startPos.X.Offset + delta.X,
        startPos.Y.Scale, startPos.Y.Offset + delta.Y
    )
end

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
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
    if not workspace:FindFirstChild("RegularLobby") then return true end
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
            if d < shortest then shortest = d; nearest = obj end
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
    if prompt then pcall(function() fireproximityprompt(prompt) end) return end
    local cd = gunPart:FindFirstChildOfClass("ClickDetector")
        or (gunPart.Parent and gunPart.Parent:FindFirstChildOfClass("ClickDetector"))
    if cd then pcall(function() fireclickdetector(cd) end) return end
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
    if cf then pcall(function() root.CFrame = cf end) end
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
    if hum then pcall(function() hum.Health = 0 end) end

    chainRunning = false
end

--============================================================
-- LOBBY LOCK / AUTO PICKUP
--============================================================

local lobbyConn = nil
local pickupConn = nil

local function startLobbyLock()
    if lobbyConn then return end
    lobbyConn = RunService.Heartbeat:Connect(function()
        if not LOBBY_LOCK_ENABLED then return end
        if chainRunning then return end
        if flinging then return end
        if not isInLobby() then teleportToLobby() end
    end)
end

local function stopLobbyLock()
    if lobbyConn then lobbyConn:Disconnect() lobbyConn = nil end
end

local function startAutoPickup()
    if pickupConn then return end
    pickupConn = RunService.Heartbeat:Connect(function()
        if not AUTO_PICKUP_ENABLED then return end
        if chainRunning then return end
        if flinging then return end
        local gun = findNearestGun()
        if gun then
            task.spawn(function() runChain(gun) end)
        end
    end)
end

local function stopAutoPickup()
    if pickupConn then pickupConn:Disconnect() pickupConn = nil end
end

--============================================================
-- ROLE DETECTION
--============================================================

local function checkPlayerForRole(plr, roleName)
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
    if checkContainer(plr.Character) then return true end
    return checkContainer(plr:FindFirstChildOfClass("Backpack"))
end

local function updateRoleTracker()
    local mName, sName = "None", "None"
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if checkPlayerForRole(plr, "murderer") then
                mName = plr.Name
            elseif checkPlayerForRole(plr, "sheriff") then
                sName = plr.Name
            end
        end
    end
    MurdererLabel.Text = "Murderer: " .. mName
    SheriffLabel.Text = "Sheriff: " .. sName
end

local function startRoleTracker()
    if roleTrackerConn then return end
    roleTrackerConn = RunService.Heartbeat:Connect(function()
        pcall(updateRoleTracker)
    end)
end

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
-- FLING (Proven working — from open source)
--============================================================

local function SHubFling(TargetPlayer)
    if not TargetPlayer then return end

    local Char = LocalPlayer.Character
    if not Char then return end
    local Hum = Char:FindFirstChildOfClass("Humanoid")
    local Root = Hum and Hum.RootPart
    if not (Char and Hum and Root) then return end

    local TCharacter = TargetPlayer.Character
    if not TCharacter then return end
    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    local Handle = Accessory and Accessory:FindFirstChild("Handle")
    local target = TRootPart or THead or Handle
    if not target then return end

    flinging = true
    setStatus("Flinging " .. TargetPlayer.Name)

    env.OldPos = Root.CFrame

    -- Camera swap (critical for position replication)
    repeat
        task.wait()
        Workspace.CurrentCamera.CameraSubject = THead or Handle or THumanoid
    until Workspace.CurrentCamera.CameraSubject == THead
       or Workspace.CurrentCamera.CameraSubject == Handle
       or Workspace.CurrentCamera.CameraSubject == THumanoid

    local function FPos(BasePart, Pos, Ang)
        local targetCF = CFrame.new(BasePart.Position) * Pos * Ang
        Root.CFrame = targetCF
        Char:SetPrimaryPartCFrame(targetCF)
        Root.Velocity = Vector3.new(9e7, 9e8, 9e7)
        Root.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
    end

    local start = tick()
    local angle = 0
    env.timeout = env.timeout or FLING_TIMEOUT
    repeat
        if Root and THumanoid then
            angle = angle + 100
            for _, offset in ipairs{
                CFrame.new(0, 1.5, 0),
                CFrame.new(0, -1.5, 0),
                CFrame.new(2.25, 1.5, -2.25),
                CFrame.new(-2.25, -1.5, 2.25)
            } do
                FPos(target, offset + THumanoid.MoveDirection, CFrame.Angles(math.rad(angle), 0, 0))
                task.wait()
            end
        end
    until target.Velocity.Magnitude > 500 or tick() - start > env.timeout

    local BV = Instance.new("BodyVelocity")
    BV.Name = "FlingVel"
    BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
    BV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    BV.Parent = Root
    Hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    task.wait(0.2)

    if BV then pcall(function() BV:Destroy() end) end
    pcall(function()
        Hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    end)

    repeat
        task.wait()
        Workspace.CurrentCamera.CameraSubject = Hum
    until Workspace.CurrentCamera.CameraSubject == Hum

    repeat
        local cf = env.OldPos * CFrame.new(0, .5, 0)
        Root.CFrame = cf
        Char:SetPrimaryPartCFrame(cf)
        Hum:ChangeState("GettingUp")
        for _, part in ipairs(Char:GetChildren()) do
            if part:IsA("BasePart") then
                part.Velocity = Vector3.zero
                part.RotVelocity = Vector3.zero
            end
        end
        task.wait()
    until (Root.Position - env.OldPos.p).Magnitude < 25

    flinging = false
    setStatus("Fling complete")
end

local function startFling(targetPlr)
    if not targetPlr then
        setStatus("Target not found")
        return
    end
    if flingThread then
        pcall(function() task.cancel(flingThread) end)
    end
    flingThread = task.spawn(function()
        pcall(function() SHubFling(targetPlr) end)
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
    if plr then
        setStatus("Flinging murderer: " .. plr.Name)
        startFling(plr)
    elseif TARGET_PLAYER_OBJ and TARGET_PLAYER_OBJ.Character then
        setStatus("Flinging selected: " .. TARGET_PLAYER_OBJ.Name)
        startFling(TARGET_PLAYER_OBJ)
    else
        setStatus("Murderer not found - select a player")
        refreshPlayerList()
        PlayerListFrame.Visible = true
    end
end)

FlingSheriffButton.MouseButton1Click:Connect(function()
    local plr, hrp = findRolePlayer("sheriff")
    if plr then
        setStatus("Flinging sheriff: " .. plr.Name)
        startFling(plr)
    elseif TARGET_PLAYER_OBJ and TARGET_PLAYER_OBJ.Character then
        setStatus("Flinging selected: " .. TARGET_PLAYER_OBJ.Name)
        startFling(TARGET_PLAYER_OBJ)
    else
        setStatus("Sheriff not found - select a player")
        refreshPlayerList()
        PlayerListFrame.Visible = true
    end
end)

-- Auto-refresh the list when players join/leave
Players.PlayerAdded:Connect(function()
    if PlayerListFrame.Visible then refreshPlayerList() end
end)
Players.PlayerRemoving:Connect(function()
    if PlayerListFrame.Visible then refreshPlayerList() end
end)

startRoleTracker()

LocalPlayer.CharacterAdded:Connect(function()
    if LOBBY_LOCK_ENABLED then
        task.wait(1)
        teleportToLobby()
    end
end)

print("MM2 Auto Pickup + Working Fling + Role Tracker Loaded!")
print("Fling: camera swap + 4-corner oscillation (from open source)")
