local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Configuration
local RESET_DELAY = 0.55 -- Time spent pinned to target's head before resetting so server replicates position
local POST_RESET_COOLDOWN = 4
local FLING_DURATION = 2.0
local LOBBY_LOCK_ENABLED = false
local AUTO_PICKUP_ENABLED = false
local ESP_ENABLED = true

-- State
local SelectedTarget = nil
local chainRunning = false
local flingRunning = false
local chainCooldownUntil = 0
local cachedLobbyCF = nil

getgenv().OldPos = nil
getgenv().FPDH = workspace.FallenPartsDestroyHeight

-- Cached Role Data
local CurrentMurderer = nil
local CurrentSheriff = nil
local IsAliveInRound = false

--============================================================
-- GUI SETUP
--============================================================

local parentGui = (gethui and gethui()) or (pcall(function() return CoreGui end) and CoreGui) or LocalPlayer:WaitForChild("PlayerGui")
if parentGui:FindFirstChild("MM2UtilityGui") then
    parentGui.MM2UtilityGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2UtilityGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Parent = parentGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 195, 0, 266)
MainFrame.Position = UDim2.new(0, 12, 0.08, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(70, 70, 85)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 28)
TopBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 12)
TopCorner.Parent = TopBar

local TopCover = Instance.new("Frame")
TopCover.Size = UDim2.new(1, 0, 0, 12)
TopCover.Position = UDim2.new(0, 0, 1, -12)
TopCover.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
TopCover.BorderSizePixel = 0
TopCover.Parent = TopBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -16, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "MM2 GUN DELIVERY + ESP"
TitleLabel.TextColor3 = Color3.fromRGB(230, 230, 240)
TitleLabel.TextSize = 10
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local function createButton(name, text, pos, size, color)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = size
    btn.Position = pos
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 10
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.Parent = MainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    return btn
end

local LobbyLockButton = createButton(
    "LobbyLockButton", "LOBBY LOCK: OFF",
    UDim2.new(0, 8, 0, 34), UDim2.new(1, -16, 0, 26),
    Color3.fromRGB(210, 60, 60)
)

local ToggleButton = createButton(
    "ToggleButton", "AUTO GUN TO TARGET: OFF",
    UDim2.new(0, 8, 0, 64), UDim2.new(1, -16, 0, 26),
    Color3.fromRGB(210, 60, 60)
)

local EspButton = createButton(
    "EspButton", "ESP (M/S/GUN): ON",
    UDim2.new(0, 8, 0, 94), UDim2.new(1, -16, 0, 26),
    Color3.fromRGB(60, 200, 100)
)

local TargetLabel = Instance.new("TextLabel")
TargetLabel.Size = UDim2.new(1, -16, 0, 12)
TargetLabel.Position = UDim2.new(0, 8, 0, 125)
TargetLabel.BackgroundTransparency = 1
TargetLabel.Text = "DELIVERY / TP TARGET"
TargetLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
TargetLabel.TextSize = 9
TargetLabel.Font = Enum.Font.GothamBold
TargetLabel.TextXAlignment = Enum.TextXAlignment.Left
TargetLabel.Parent = MainFrame

local SelectButton = createButton(
    "SelectButton", "SELECT PLAYER...",
    UDim2.new(0, 8, 0, 139), UDim2.new(1, -16, 0, 26),
    Color3.fromRGB(35, 35, 45)
)
SelectButton.Font = Enum.Font.Gotham
SelectButton.TextColor3 = Color3.fromRGB(200, 200, 220)

local SelectStroke = Instance.new("UIStroke")
SelectStroke.Color = Color3.fromRGB(70, 70, 85)
SelectStroke.Thickness = 1
SelectStroke.Parent = SelectButton

local TeleportButton = createButton(
    "TeleportButton", "TP TARGET",
    UDim2.new(0, 8, 0, 170), UDim2.new(0.5, -10, 0, 26),
    Color3.fromRGB(70, 120, 200)
)

local ResetButton = createButton(
    "ResetButton", "RESET",
    UDim2.new(0.5, 2, 0, 170), UDim2.new(0.5, -10, 0, 26),
    Color3.fromRGB(180, 60, 60)
)

local FlingMurdererButton = createButton(
    "FlingMurdererButton", "FLING MURD",
    UDim2.new(0, 8, 0, 201), UDim2.new(0.5, -10, 0, 28),
    Color3.fromRGB(200, 50, 80)
)

local FlingSheriffButton = createButton(
    "FlingSheriffButton", "FLING SHERIFF",
    UDim2.new(0.5, 2, 0, 201), UDim2.new(0.5, -10, 0, 28),
    Color3.fromRGB(50, 110, 210)
)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Size = UDim2.new(1, -16, 0, 14)
StatusLabel.Position = UDim2.new(0, 8, 0, 236)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Ready"
StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
StatusLabel.TextSize = 9
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame

local PlayerListFrame = Instance.new("ScrollingFrame")
PlayerListFrame.Name = "PlayerListFrame"
PlayerListFrame.Size = UDim2.new(1, -16, 0, 120)
PlayerListFrame.Position = UDim2.new(0, 8, 0, 139)
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
    task.delay(3, function()
        if StatusLabel.Text == msg then
            StatusLabel.Text = ""
        end
    end)
end

local function refreshPlayerList()
    for _, child in ipairs(PlayerListFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -8, 0, 22)
            btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
            btn.BorderSizePixel = 0
            btn.Text = "  " .. plr.Name
            btn.TextColor3 = Color3.fromRGB(220, 220, 240)
            btn.TextSize = 10
            btn.Font = Enum.Font.Gotham
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.AutoButtonColor = false
            btn.ZIndex = 21
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
-- ROLE TRACKER HUD (Bottom Right)
--============================================================

local RoleFrame = Instance.new("Frame")
RoleFrame.Name = "RoleFrame"
RoleFrame.Size = UDim2.new(0, 155, 0, 60)
RoleFrame.Position = UDim2.new(1, -165, 1, -72)
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
RoleTitle.Size = UDim2.new(1, 0, 0, 18)
RoleTitle.BackgroundTransparency = 1
RoleTitle.Text = "MM2 ROLES"
RoleTitle.TextColor3 = Color3.fromRGB(230, 230, 240)
RoleTitle.TextSize = 10
RoleTitle.Font = Enum.Font.GothamBold
RoleTitle.Parent = RoleFrame

local MurdererLabel = Instance.new("TextLabel")
MurdererLabel.Size = UDim2.new(1, -12, 0, 16)
MurdererLabel.Position = UDim2.new(0, 6, 0, 22)
MurdererLabel.BackgroundTransparency = 1
MurdererLabel.Text = "M: None"
MurdererLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
MurdererLabel.TextSize = 9
MurdererLabel.Font = Enum.Font.Gotham
MurdererLabel.TextXAlignment = Enum.TextXAlignment.Left
MurdererLabel.TextTruncate = Enum.TextTruncate.AtEnd
MurdererLabel.Parent = RoleFrame

local SheriffLabel = Instance.new("TextLabel")
SheriffLabel.Size = UDim2.new(1, -12, 0, 16)
SheriffLabel.Position = UDim2.new(0, 6, 0, 40)
SheriffLabel.BackgroundTransparency = 1
SheriffLabel.Text = "S: None"
SheriffLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
SheriffLabel.TextSize = 9
SheriffLabel.Font = Enum.Font.Gotham
SheriffLabel.TextXAlignment = Enum.TextXAlignment.Left
SheriffLabel.TextTruncate = Enum.TextTruncate.AtEnd
SheriffLabel.Parent = RoleFrame

--============================================================
-- 3D HIGHLIGHT ESP ENGINE (Murderer, Sheriff, GunDrop)
--============================================================

local function createHighlight(name, fillColor, outlineColor)
    local hl = Instance.new("Highlight")
    hl.Name = name
    hl.FillColor = fillColor
    hl.OutlineColor = outlineColor
    hl.FillTransparency = 0.45
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = false
    hl.Parent = ScreenGui
    return hl
end

local MurdererHighlight = createHighlight("MurdererESP", Color3.fromRGB(255, 45, 45), Color3.fromRGB(255, 180, 180))
local SheriffHighlight  = createHighlight("SheriffESP",  Color3.fromRGB(45, 125, 255), Color3.fromRGB(180, 220, 255))
local GunDropHighlight  = createHighlight("GunDropESP",  Color3.fromRGB(45, 255, 95),  Color3.fromRGB(200, 255, 200))

local GunBillboard = Instance.new("BillboardGui")
GunBillboard.Name = "GunDropTag"
GunBillboard.Size = UDim2.new(0, 110, 0, 26)
GunBillboard.StudsOffset = Vector3.new(0, 2, 0)
GunBillboard.AlwaysOnTop = true
GunBillboard.Enabled = false
GunBillboard.Parent = ScreenGui

local GunTagLabel = Instance.new("TextLabel")
GunTagLabel.Size = UDim2.new(1, 0, 1, 0)
GunTagLabel.BackgroundTransparency = 1
GunTagLabel.Text = "[ GUN DROP ]"
GunTagLabel.TextColor3 = Color3.fromRGB(65, 255, 110)
GunTagLabel.TextStrokeTransparency = 0.15
GunTagLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
GunTagLabel.Font = Enum.Font.GothamBold
GunTagLabel.TextSize = 11
GunTagLabel.Parent = GunBillboard

--============================================================
-- DRAGGABLE WINDOW
--============================================================

local dragging, dragStart, startPos = false, nil, nil

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

--============================================================
-- HELPER FUNCTIONS
--============================================================

local function hasTool(plr, toolName)
    if not plr then return false end
    local char = plr.Character
    local bp = plr:FindFirstChildOfClass("Backpack")
    if char and char:FindFirstChild(toolName) then return true end
    if bp and bp:FindFirstChild(toolName) then return true end
    return false
end

local function canAct()
    local char = LocalPlayer.Character
    if not char or not char.Parent then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    return hum ~= nil and root ~= nil and hum.Health > 0
end

local function getRoot()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function isLocalPlayerSheriff()
    return hasTool(LocalPlayer, "Gun")
end

local function isLocalPlayerMurderer()
    return hasTool(LocalPlayer, "Knife")
end

local function isOnCooldown()
    return os.clock() < chainCooldownUntil
end

local function startCooldown()
    chainCooldownUntil = os.clock() + POST_RESET_COOLDOWN
end

local function getLobbyCFrame()
    if cachedLobbyCF then return cachedLobbyCF end
    local lobby = workspace:FindFirstChild("Lobby") or workspace:FindFirstChild("RegularLobby")
    if lobby then
        local spawn = lobby:FindFirstChildOfClass("SpawnLocation", true)
        if spawn then
            cachedLobbyCF = spawn.CFrame + Vector3.new(0, 5, 0)
            return cachedLobbyCF
        end
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") then
            cachedLobbyCF = obj.CFrame + Vector3.new(0, 5, 0)
            return cachedLobbyCF
        end
    end
    return nil
end

local function isInLobby()
    if not canAct() then return true end
    local root = getRoot()
    local lobbyCF = getLobbyCFrame()
    if not root or not lobbyCF then return false end
    return (root.Position - lobbyCF.Position).Magnitude < 120
end

local function teleportToLobby()
    if not canAct() then return end
    local root = getRoot()
    local cf = getLobbyCFrame()
    if root and cf then
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.zero
            root.CFrame = cf
        end)
    end
end

local function doReset()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function()
            hum.Health = 0
            hum:ChangeState(Enum.HumanoidStateType.Dead)
            char:BreakJoints()
        end)
    end
end

local function findGunDrop()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "GunDrop" and obj:IsA("BasePart") and obj.Parent then
            return obj
        end
    end
    return nil
end

--============================================================
-- MM2 CORE & ROLE DETECTION
--============================================================

local getPlayerDataRemote = nil
task.spawn(function()
    getPlayerDataRemote = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
end)

local function updateESP(gunDropPart)
    if not ESP_ENABLED then
        MurdererHighlight.Adornee = nil
        MurdererHighlight.Enabled = false
        SheriffHighlight.Adornee = nil
        SheriffHighlight.Enabled = false
        GunDropHighlight.Adornee = nil
        GunDropHighlight.Enabled = false
        GunBillboard.Adornee = nil
        GunBillboard.Enabled = false
        return
    end

    local mChar = (CurrentMurderer and CurrentMurderer ~= LocalPlayer) and CurrentMurderer.Character or nil
    if mChar and mChar:FindFirstChildOfClass("Humanoid") and mChar.Humanoid.Health > 0 then
        MurdererHighlight.Adornee = mChar
        MurdererHighlight.Enabled = true
    else
        MurdererHighlight.Adornee = nil
        MurdererHighlight.Enabled = false
    end

    local sChar = (CurrentSheriff and CurrentSheriff ~= LocalPlayer) and CurrentSheriff.Character or nil
    if sChar and sChar:FindFirstChildOfClass("Humanoid") and sChar.Humanoid.Health > 0 then
        SheriffHighlight.Adornee = sChar
        SheriffHighlight.Enabled = true
    else
        SheriffHighlight.Adornee = nil
        SheriffHighlight.Enabled = false
    end

    if gunDropPart and gunDropPart.Parent then
        GunDropHighlight.Adornee = gunDropPart
        GunDropHighlight.Enabled = true
        GunBillboard.Adornee = gunDropPart
        GunBillboard.Enabled = true
    else
        GunDropHighlight.Adornee = nil
        GunDropHighlight.Enabled = false
        GunBillboard.Adornee = nil
        GunBillboard.Enabled = false
    end
end

local function updateRoles()
    local foundMurderer, foundSheriff = nil, nil
    local localAlive = false

    if not getPlayerDataRemote then
        getPlayerDataRemote = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
    end

    if getPlayerDataRemote and getPlayerDataRemote:IsA("RemoteFunction") then
        local ok, data = pcall(function()
            return getPlayerDataRemote:InvokeServer()
        end)
        if ok and type(data) == "table" then
            local myInfo = data[LocalPlayer.Name]
            if type(myInfo) == "table" and not myInfo.Dead and not myInfo.Killed and myInfo.Role ~= nil then
                localAlive = true
            end
            for plrName, info in pairs(data) do
                if type(info) == "table" and not info.Dead and not info.Killed then
                    local plr = Players:FindFirstChild(plrName)
                    if plr then
                        if info.Role == "Murderer" then
                            foundMurderer = plr
                        elseif info.Role == "Sheriff" or info.Role == "Hero" then
                            foundSheriff = plr
                        end
                    end
                end
            end
        end
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character.Humanoid.Health > 0 then
            if hasTool(plr, "Knife") then
                foundMurderer = plr
            elseif hasTool(plr, "Gun") then
                foundSheriff = plr
            end
        end
    end

    if not localAlive and canAct() then
        localAlive = true
    end

    CurrentMurderer = foundMurderer
    CurrentSheriff = foundSheriff
    IsAliveInRound = localAlive

    MurdererLabel.Text = "M: " .. (foundMurderer and foundMurderer.Name or "None")
    SheriffLabel.Text = "S: " .. (foundSheriff and foundSheriff.Name or "None")
end

--============================================================
-- WORKING SKIDFLING ENGINE (from zqyDSUWX)
--============================================================

local function flingPlayer(TargetPlayer, roleLabel)
    if flingRunning or chainRunning then
        setStatus("Busy with another action!")
        return
    end
    if not TargetPlayer or not TargetPlayer.Character then
        setStatus("No valid " .. roleLabel .. " found!")
        return
    end
    if TargetPlayer == LocalPlayer then
        setStatus("You are the " .. roleLabel .. "!")
        return
    end
    if not canAct() then
        setStatus("You are dead!")
        return
    end

    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    if not TCharacter then return end

    local THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter:FindFirstChild("Head")
    local Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    local Handle = Accessory and Accessory:FindFirstChild("Handle")

    if not (Character and Humanoid and RootPart) then
        setStatus("Your character is not ready!")
        return
    end

    if THumanoid and THumanoid.Sit then
        setStatus(TargetPlayer.Name .. " is sitting!")
        return
    end

    if not TCharacter:FindFirstChildWhichIsA("BasePart") then
        setStatus(roleLabel .. " has no valid parts!")
        return
    end

    flingRunning = true
    setStatus("Flinging " .. TargetPlayer.Name .. "...")

    if RootPart.Velocity.Magnitude < 50 then
        getgenv().OldPos = RootPart.CFrame
    end

    if THead then
        workspace.CurrentCamera.CameraSubject = THead
    elseif Handle then
        workspace.CurrentCamera.CameraSubject = Handle
    elseif THumanoid and TRootPart then
        workspace.CurrentCamera.CameraSubject = THumanoid
    end

    local FPos = function(BasePart, Pos, Ang)
        if not RootPart or not RootPart.Parent or not BasePart or not BasePart.Parent then return end
        local targetCF = CFrame.new(BasePart.Position) * Pos * Ang
        RootPart.CFrame = targetCF
        pcall(function()
            Character:SetPrimaryPartCFrame(targetCF)
        end)
        RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
        RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
    end

    local SFBasePart = function(BasePart)
        local TimeToWait = FLING_DURATION
        local Time = tick()
        local Angle = 0
        repeat
            if RootPart and THumanoid and BasePart and BasePart.Parent then
                if BasePart.Velocity.Magnitude < 50 then
                    Angle = Angle + 100
                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection, CFrame.Angles(math.rad(Angle), 0, 0))
                    task.wait()
                else
                    FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                    task.wait()
                    FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                    task.wait()
                end
            else
                break
            end
        until BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TCharacter or TargetPlayer.Parent ~= Players or not TCharacter:IsDescendantOf(workspace) or THumanoid.Sit or Humanoid.Health <= 0 or tick() > Time + TimeToWait
    end

    workspace.FallenPartsDestroyHeight = 0 / 0

    local BV = Instance.new("BodyVelocity")
    BV.Name = "EpixVel"
    BV.Parent = RootPart
    BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
    BV.MaxForce = Vector3.new(1 / 0, 1 / 0, 1 / 0)

    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

    if TRootPart and THead then
        if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then
            SFBasePart(THead)
        else
            SFBasePart(TRootPart)
        end
    elseif TRootPart and not THead then
        SFBasePart(TRootPart)
    elseif not TRootPart and THead then
        SFBasePart(THead)
    elseif not TRootPart and not THead and Accessory and Handle then
        SFBasePart(Handle)
    else
        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        workspace.CurrentCamera.CameraSubject = Humanoid
        flingRunning = false
        setStatus("No valid parts to fling!")
        return
    end

    BV:Destroy()
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    workspace.CurrentCamera.CameraSubject = Humanoid

    if getgenv().OldPos then
        local returnStart = tick()
        repeat
            if not canAct() then break end
            RootPart.CFrame = getgenv().OldPos * CFrame.new(0, 0.5, 0)
            pcall(function()
                Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, 0.5, 0))
            end)
            Humanoid:ChangeState("GettingUp")
            for _, part in pairs(Character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Velocity, part.RotVelocity = Vector3.new(), Vector3.new()
                end
            end
            task.wait()
        until (RootPart.Position - getgenv().OldPos.p).Magnitude < 25 or tick() - returnStart > 2.5
        workspace.FallenPartsDestroyHeight = getgenv().FPDH
    end

    flingRunning = false
    setStatus("Finished flinging " .. TargetPlayer.Name)
end

--============================================================
-- GUN PICKUP -> TELEPORT TO TARGET HEAD -> RESET
--============================================================

local function resetOnTargetHead(targetPlr)
    if not targetPlr or not targetPlr.Character then
        setStatus("No valid target!")
        return
    end

    local tChar = targetPlr.Character
    local tHead = tChar:FindFirstChild("Head") or tChar:FindFirstChild("HumanoidRootPart")
    if not tHead then return end

    setStatus("Pinning to " .. targetPlr.Name .. "'s head...")

    local pinStart = os.clock()
    while os.clock() - pinStart < RESET_DELAY do
        if not canAct() or not tChar.Parent or not tHead.Parent then break end
        local root = getRoot()
        if root then
            pcall(function()
                root.Velocity = Vector3.zero
                root.AssemblyLinearVelocity = Vector3.zero
                root.CFrame = tHead.CFrame * CFrame.new(0, 1.5, 0)
            end)
        end
        RunService.Heartbeat:Wait()
    end

    if canAct() then
        startCooldown()
        doReset()
        local postStart = os.clock()
        while os.clock() - postStart < 0.3 and LocalPlayer.Character do
            local root = getRoot()
            if root and tHead and tHead.Parent then
                pcall(function()
                    root.CFrame = tHead.CFrame * CFrame.new(0, 1.5, 0)
                end)
            end
            RunService.Heartbeat:Wait()
        end
    end
end

local function touchGunWithCharacter(gunPart)
    local char = LocalPlayer.Character
    if not char or not gunPart or not gunPart.Parent then return end
    if firetouchinterest then
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                pcall(function()
                    firetouchinterest(part, gunPart, 0)
                    firetouchinterest(part, gunPart, 1)
                end)
            end
        end
    end
end

local function runGunDeliveryChain(gunPart)
    if isOnCooldown() or not canAct() or flingRunning or isLocalPlayerMurderer() then
        chainRunning = false
        return
    end

    local root = getRoot()
    local oldSafeCF = root and root.CFrame or nil

    -- Step 1: Grab the dropped gun if we don't already have it
    if not isLocalPlayerSheriff() and gunPart and gunPart.Parent then
        setStatus("Grabbing dropped gun...")
        local grabStart = os.clock()
        local step = 0

        while os.clock() - grabStart < 2.2 do
            if not canAct() or isLocalPlayerSheriff() or not gunPart or not gunPart.Parent then
                break
            end
            root = getRoot()
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if root then
                step = step + 1
                -- Micro-oscillate height & position on GunDrop so server physics registers touch
                local yOffset = (step % 2 == 0) and 0.2 or -0.5
                local xOffset = (step % 4 < 2) and 0.15 or -0.15
                pcall(function()
                    if hum and hum.Sit then hum.Sit = false end
                    root.Velocity = Vector3.new(0, -2, 0)
                    root.AssemblyLinearVelocity = Vector3.new(0, -2, 0)
                    root.CFrame = CFrame.new(gunPart.Position + Vector3.new(xOffset, yOffset, 0))
                end)
                touchGunWithCharacter(gunPart)
            end
            RunService.Heartbeat:Wait()
        end
    end

    if not canAct() then
        chainRunning = false
        return
    end

    -- Step 2: Check if we successfully became Sheriff/Hero
    if not isLocalPlayerSheriff() then
        setStatus("Could not grab gun (taken or out of round)")
        if LOBBY_LOCK_ENABLED then
            teleportToLobby()
        elseif oldSafeCF and getRoot() then
            pcall(function() getRoot().CFrame = oldSafeCF end)
        end
        chainRunning = false
        return
    end

    -- Step 3: Deliver to Target (or Lobby Reset if Target is Murderer)
    if SelectedTarget and SelectedTarget == CurrentMurderer then
        setStatus("Target is Murderer! Resetting in lobby...")
        for _ = 1, 15 do
            if not canAct() then break end
            teleportToLobby()
            RunService.Heartbeat:Wait()
        end
        startCooldown()
        doReset()
        chainRunning = false
        return
    end

    if SelectedTarget and SelectedTarget.Character then
        resetOnTargetHead(SelectedTarget)
    else
        setStatus("Gun grabbed! (Select a target to deliver)")
        if LOBBY_LOCK_ENABLED then
            teleportToLobby()
        elseif oldSafeCF and getRoot() then
            pcall(function() getRoot().CFrame = oldSafeCF end)
        end
    end

    chainRunning = false
end

--============================================================
-- MAIN BACKGROUND LOOP
--============================================================

local lastRoleScan = 0

RunService.Heartbeat:Connect(function()
    local now = os.clock()

    if now - lastRoleScan >= 0.3 then
        lastRoleScan = now
        local gunDrop = findGunDrop()
        updateESP(gunDrop)
        task.spawn(updateRoles)
    end

    if chainRunning or flingRunning or isOnCooldown() or not canAct() then
        return
    end

    -- Auto Pickup & Head Reset Delivery runs BEFORE Lobby Lock so it can leave the lobby to grab the gun
    if AUTO_PICKUP_ENABLED and not isLocalPlayerMurderer() then
        if isLocalPlayerSheriff() then
            if SelectedTarget and SelectedTarget.Character then
                chainRunning = true
                task.spawn(function()
                    runGunDeliveryChain(nil)
                end)
                return
            end
        else
            local gunDrop = findGunDrop()
            if gunDrop then
                chainRunning = true
                task.spawn(function()
                    runGunDeliveryChain(gunDrop)
                end)
                return
            end
        end
    end

    -- Lobby Lock (only holds you in lobby when not actively grabbing/delivering gun)
    if LOBBY_LOCK_ENABLED and not isInLobby() then
        teleportToLobby()
    end
end)

--============================================================
-- BUTTON CONNECTIONS
--============================================================

LobbyLockButton.MouseButton1Click:Connect(function()
    LOBBY_LOCK_ENABLED = not LOBBY_LOCK_ENABLED
    if LOBBY_LOCK_ENABLED then
        LobbyLockButton.Text = "LOBBY LOCK: ON"
        LobbyLockButton.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
        setStatus("Lobby lock enabled")
    else
        LobbyLockButton.Text = "LOBBY LOCK: OFF"
        LobbyLockButton.BackgroundColor3 = Color3.fromRGB(210, 60, 60)
        setStatus("Lobby lock disabled")
    end
end)

ToggleButton.MouseButton1Click:Connect(function()
    AUTO_PICKUP_ENABLED = not AUTO_PICKUP_ENABLED
    if AUTO_PICKUP_ENABLED then
        ToggleButton.Text = "AUTO GUN TO TARGET: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
        setStatus("Auto gun delivery enabled")
    else
        ToggleButton.Text = "AUTO GUN TO TARGET: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(210, 60, 60)
        setStatus("Auto gun delivery disabled")
    end
end)

EspButton.MouseButton1Click:Connect(function()
    ESP_ENABLED = not ESP_ENABLED
    if ESP_ENABLED then
        EspButton.Text = "ESP (M/S/GUN): ON"
        EspButton.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
        setStatus("3D Highlight ESP enabled")
    else
        EspButton.Text = "ESP (M/S/GUN): OFF"
        EspButton.BackgroundColor3 = Color3.fromRGB(210, 60, 60)
        setStatus("3D Highlight ESP disabled")
    end
    updateESP(findGunDrop())
end)

TeleportButton.MouseButton1Click:Connect(function()
    if not SelectedTarget or not SelectedTarget.Character then
        setStatus("Select a valid player first")
        return
    end
    local tRoot = SelectedTarget.Character:FindFirstChild("HumanoidRootPart")
    local root = getRoot()
    if tRoot and root and canAct() then
        pcall(function()
            root.CFrame = tRoot.CFrame * CFrame.new(0, 3, 0)
        end)
        setStatus("Teleported to " .. SelectedTarget.Name)
    end
end)

ResetButton.MouseButton1Click:Connect(function()
    if not canAct() then
        setStatus("Already dead")
        return
    end
    if SelectedTarget and SelectedTarget.Character and isLocalPlayerSheriff() then
        task.spawn(function()
            resetOnTargetHead(SelectedTarget)
        end)
    else
        startCooldown()
        doReset()
        setStatus("Resetting...")
    end
end)

FlingMurdererButton.MouseButton1Click:Connect(function()
    updateRoles()
    task.spawn(function()
        flingPlayer(CurrentMurderer, "Murderer")
    end)
end)

FlingSheriffButton.MouseButton1Click:Connect(function()
    updateRoles()
    task.spawn(function()
        flingPlayer(CurrentSheriff, "Sheriff")
    end)
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

LocalPlayer.CharacterAdded:Connect(function()
    chainRunning = false
    flingRunning = false
    if LOBBY_LOCK_ENABLED then
        task.wait(0.8)
        if canAct() then teleportToLobby() end
    end
end)

LocalPlayer.CharacterRemoving:Connect(function()
    chainRunning = false
    IsAliveInRound = false
    startCooldown()
end)

print("MM2 Gun Delivery + SkidFling + 3D ESP v3 Loaded!")
