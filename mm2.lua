-- MM2 Auto Pickup + Role Tracker + Player Dropdown (Custom GUI)
-- Mobile Friendly with Clean Draggable GUI
-- Sheriff mode + proper dead-state handling

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- Configuration
local TELEPORT_OFFSET = 3
local RETURN_DELAY = 0.25
local RESET_DELAY = 3
local POST_RESET_COOLDOWN = 4  -- seconds to wait after a reset before allowing another chain
local LOBBY_LOCK_ENABLED = false
local AUTO_PICKUP_ENABLED = false

-- Selected target (from dropdown)
local SelectedTarget = nil

-- Saved state
local chainRunning = false
local chainCooldownUntil = 0
local roleTrackerConn = nil
local charConn = nil

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
TargetLabel.Text = "TARGET PLAYER"
TargetLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
TargetLabel.TextSize = 10
TargetLabel.Font = Enum.Font.GothamBold
TargetLabel.TextXAlignment = Enum.TextXAlignment.Left
TargetLabel.Parent = MainFrame

local SelectButton = Instance.new("TextButton")
SelectButton.Name = "SelectButton"
SelectButton.Size = UDim2.new(1, -24, 0, 34)
SelectButton.Position = UDim2.new(0, 12, 0, 158)
SelectButton.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
SelectButton.BorderSizePixel = 0
SelectButton.Text = "SELECT PLAYER..."
SelectButton.TextColor3 = Color3.fromRGB(200, 200, 220)
SelectButton.TextSize = 13
SelectButton.Font = Enum.Font.Gotham
SelectButton.AutoButtonColor = false
SelectButton.Parent = MainFrame

local SelectCorner = Instance.new("UICorner")
SelectCorner.CornerRadius = UDim.new(0, 8)
SelectCorner.Parent = SelectButton

local SelectStroke = Instance.new("UIStroke")
SelectStroke.Color = Color3.fromRGB(70, 70, 85)
SelectStroke.Thickness = 1
SelectStroke.Parent = SelectButton

local TeleportButton = Instance.new("TextButton")
TeleportButton.Name = "TeleportButton"
TeleportButton.Size = UDim2.new(0.5, -18, 0, 32)
TeleportButton.Position = UDim2.new(0, 12, 0, 200)
TeleportButton.BackgroundColor3 = Color3.fromRGB(70, 120, 200)
TeleportButton.BorderSizePixel = 0
TeleportButton.Text = "TELEPORT"
TeleportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TeleportButton.TextSize = 12
TeleportButton.Font = Enum.Font.GothamBold
TeleportButton.AutoButtonColor = false
TeleportButton.Parent = MainFrame

local TeleportCorner = Instance.new("UICorner")
TeleportCorner.CornerRadius = UDim.new(0, 8)
TeleportCorner.Parent = TeleportButton

local ResetButton = Instance.new("TextButton")
ResetButton.Name = "ResetButton"
ResetButton.Size = UDim2.new(0.5, -18, 0, 32)
ResetButton.Position = UDim2.new(0.5, 6, 0, 200)
ResetButton.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
ResetButton.BorderSizePixel = 0
ResetButton.Text = "RESET"
ResetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ResetButton.TextSize = 12
ResetButton.Font = Enum.Font.GothamBold
ResetButton.AutoButtonColor = false
ResetButton.Parent = MainFrame

local ResetCorner = Instance.new("UICorner")
ResetCorner.CornerRadius = UDim.new(0, 8)
ResetCorner.Parent = ResetButton

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Size = UDim2.new(1, -24, 0, 16)
StatusLabel.Position = UDim2.new(0, 12, 0, 244)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = ""
StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame

-- Player list popup
local PlayerListFrame = Instance.new("ScrollingFrame")
PlayerListFrame.Name = "PlayerListFrame"
PlayerListFrame.Size = UDim2.new(1, -24, 0, 180)
PlayerListFrame.Position = UDim2.new(0, 12, 0, 158)
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
                SelectedTarget = plr
                SelectButton.Text = plr.Name
                SelectButton.TextColor3 = Color3.fromRGB(100, 200, 255)
                PlayerListFrame.Visible = false
                setStatus("Target: " .. plr.Name)
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

-- Dead OR respawning returns false
local function isAlive()
    local char = LocalPlayer.Character
    if not char then return false end
    if not char.Parent then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    return hum.Health > 0
end

-- Strict check: alive AND has root AND has humanoid with full parenting
local function canAct()
    if not isAlive() then return false end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    if hum.Parent ~= char then return false end
    return true
end

-- Chain cooldown check
local function isOnCooldown()
    return tick() < chainCooldownUntil
end

local function startCooldown()
    chainCooldownUntil = tick() + POST_RESET_COOLDOWN
end

local function getRoot()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
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
    if not canAct() then return true end
    local root = getRoot()
    if not root then return true end
    if not workspace:FindFirstChild("RegularLobby") then return true end
    local lobbyCF = getLobbyCFrame()
    if not lobbyCF then return true end
    return (root.Position - lobbyCF.Position).Magnitude < 100
end

local function findNearestGun()
    if not canAct() then return nil end
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

local function getSelectedTargetRoot()
    if not SelectedTarget then return nil end
    local char = SelectedTarget.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function isLocalPlayerSheriff()
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")

    local function checkContainer(container)
        if not container then return false end
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") then
                local n = tool.Name:lower()
                if n:find("gun") and not n:find("drop") then
                    return true
                end
            end
        end
        return false
    end

    if checkContainer(char) then return true end
    if checkContainer(backpack) then return true end
    return false
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
    if not canAct() then return end
    local root = getRoot()
    if not root then return end
    local cf = getLobbyCFrame()
    if cf then pcall(function() root.CFrame = cf end) end
end

local function doReset()
    if not canAct() then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function() hum.Health = 0 end)
    end
end

local function runSheriffChain()
    if chainRunning then return end
    if isOnCooldown() then return end
    if not canAct() then return end

    chainRunning = true
    setStatus("Sheriff mode: teleporting to target...")

    local targetHRP = getSelectedTargetRoot()
    if not targetHRP then
        setStatus("No target selected")
        chainRunning = false
        return
    end

    local root = getRoot()
    if root then
        pcall(function()
            root.CFrame = targetHRP.CFrame + Vector3.new(0, 3, 0)
        end)
    end

    task.wait(RETURN_DELAY)

    -- Check alive before reset
    if not canAct() then
        chainRunning = false
        return
    end

    setStatus("Resetting by target in " .. RESET_DELAY .. "s...")
    task.wait(RESET_DELAY)

    if canAct() then
        startCooldown()
        doReset()
    end

    chainRunning = false
end

local function runChain(gunPart)
    if chainRunning then return end
    if isOnCooldown() then return end
    if not canAct() then return end

    chainRunning = true

    local root = getRoot()
    if not root then chainRunning = false return end

    setStatus("Chain: teleporting to gun...")

    if gunPart and gunPart.Parent and canAct() then
        pcall(function()
            root.CFrame = CFrame.new(gunPart.Position + Vector3.new(0, TELEPORT_OFFSET, 0))
        end)
        task.wait(RETURN_DELAY)
        if canAct() then
            pickupGun(gunPart)
        end
        task.wait(RETURN_DELAY)
    end

    if not canAct() then
        chainRunning = false
        return
    end

    teleportToLobby()
    task.wait(RETURN_DELAY)

    if not canAct() then
        chainRunning = false
        return
    end

    local targetHRP = getSelectedTargetRoot()
    if targetHRP and canAct() then
        setStatus("Chain: teleporting to target...")
        pcall(function()
            root.CFrame = targetHRP.CFrame + Vector3.new(0, 3, 0)
        end)
        task.wait(RETURN_DELAY)
    end

    if not canAct() then
        chainRunning = false
        return
    end

    setStatus("Chain: resetting in " .. RESET_DELAY .. "s...")
    task.wait(RESET_DELAY)

    if canAct() then
        startCooldown()
        doReset()
    end

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
        if isOnCooldown() then return end
        if not canAct() then return end
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
        if isOnCooldown() then return end
        if not canAct() then return end

        if isLocalPlayerSheriff() then
            if SelectedTarget then
                task.spawn(function() runSheriffChain() end)
            end
            return
        end

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

TeleportButton.MouseButton1Click:Connect(function()
    if not SelectedTarget then
        setStatus("Select a player first")
        return
    end
    local hrp = getSelectedTargetRoot()
    if not hrp then
        setStatus(SelectedTarget.Name .. " has no character")
        return
    end
    if not canAct() then
        setStatus("You are dead")
        return
    end
    local root = getRoot()
    if not root then
        setStatus("You have no character")
        return
    end
    pcall(function()
        root.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
    end)
    setStatus("Teleported to " .. SelectedTarget.Name)
end)

ResetButton.MouseButton1Click:Connect(function()
    if not canAct() then
        setStatus("You are already dead")
        return
    end
    doReset()
    startCooldown()
    setStatus("Resetting...")
end)

Players.PlayerAdded:Connect(function()
    if PlayerListFrame.Visible then refreshPlayerList() end
end)
Players.PlayerRemoving:Connect(function(plr)
    if SelectedTarget == plr then
        SelectedTarget = nil
        SelectButton.Text = "SELECT PLAYER..."
        SelectButton.TextColor3 = Color3.fromRGB(200, 200, 220)
    end
    if PlayerListFrame.Visible then refreshPlayerList() end
end)

--============================================================
-- CHARACTER RESPAWN HANDLING
--============================================================

LocalPlayer.CharacterAdded:Connect(function()
    -- Reset chain state on respawn
    chainRunning = false

    -- If we reset, wait the full cooldown before re-engaging
    if LOBBY_LOCK_ENABLED then
        task.wait(1)
        if canAct() then teleportToLobby() end
    end
end)

startRoleTracker()

print("MM2 Auto Pickup + Sheriff Mode + Cooldown Loaded!")
