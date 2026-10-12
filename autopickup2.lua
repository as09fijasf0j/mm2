-- Custom Auto Pickup Gun Script for MM2 (Teleport Chain + Fling Buttons)
-- Mobile Friendly with Clean Draggable GUI
-- Role detection via Character AND Backpack scanning

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- Configuration
local TELEPORT_OFFSET = 3
local RETURN_DELAY = 0.2
local RESET_DELAY = 3
local AUTO_PICKUP_ENABLED = false
local TARGET_PLAYER_NAME = ""
local FLING_ENABLED = true

--============================================================
-- GUI CREATION
--============================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoPickupGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 240, 0, 250)
MainFrame.Position = UDim2.new(0.5, -120, 0.15, 0)
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

-- Top bar (drag handle)
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

-- Toggle button
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(1, -24, 0, 38)
ToggleButton.Position = UDim2.new(0, 12, 0, 52)
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

-- Target player label + box
local TargetLabel = Instance.new("TextLabel")
TargetLabel.Size = UDim2.new(1, -24, 0, 14)
TargetLabel.Position = UDim2.new(0, 12, 0, 98)
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
TargetBox.Position = UDim2.new(0, 12, 0, 114)
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

-- FLING SECTION header
local FlingLabel = Instance.new("TextLabel")
FlingLabel.Size = UDim2.new(1, -24, 0, 14)
FlingLabel.Position = UDim2.new(0, 12, 0, 156)
FlingLabel.BackgroundTransparency = 1
FlingLabel.Text = "FLING TARGET"
FlingLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
FlingLabel.TextSize = 10
FlingLabel.Font = Enum.Font.GothamBold
FlingLabel.TextXAlignment = Enum.TextXAlignment.Left
FlingLabel.Parent = MainFrame

-- Fling Murderer button
local FlingMurdererButton = Instance.new("TextButton")
FlingMurdererButton.Name = "FlingMurdererButton"
FlingMurdererButton.Size = UDim2.new(0.5, -18, 0, 38)
FlingMurdererButton.Position = UDim2.new(0, 12, 0, 174)
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

-- Fling Sheriff button
local FlingSheriffButton = Instance.new("TextButton")
FlingSheriffButton.Name = "FlingSheriffButton"
FlingSheriffButton.Size = UDim2.new(0.5, -18, 0, 38)
FlingSheriffButton.Position = UDim2.new(0.5, 6, 0, 174)
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
StatusLabel.Position = UDim2.new(0, 12, 0, 220)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = ""
StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
StatusLabel.TextSize = 11
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame

local function setStatus(msg)
    StatusLabel.Text = msg
    task.delay(2, function()
        if StatusLabel.Text == msg then
            StatusLabel.Text = ""
        end
    end)
end

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
        if dragging then
            updateDrag(input)
        end
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                     input.UserInputType == Enum.UserInputType.Touch) then
        updateDrag(input)
    end
end)

--============================================================
-- CORE LOGIC
--============================================================

local function hasGun()
    local character = LocalPlayer.Character
    if not character then return true end
    for _, tool in pairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            return true
        end
    end
    return false
end

local function findNearestGun()
    local character = LocalPlayer.Character
    if not character then return nil end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end

    local nearestGun = nil
    local shortestDistance = math.huge

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "GunDrop" then
            local distance = (obj.Position - rootPart.Position).Magnitude
            if distance < shortestDistance then
                shortestDistance = distance
                nearestGun = obj
            end
        end
    end
    return nearestGun
end

local function getLobbySpawn()
    local lobby = workspace:FindFirstChild("RegularLobby")
    if lobby then
        local spawn = lobby:FindFirstChildOfClass("SpawnLocation")
        if spawn then return spawn.CFrame end
        local mainLobby = lobby:FindFirstChild("MainLobby")
        if mainLobby and mainLobby:IsA("Model") then
            local primary = mainLobby.PrimaryPart
            if primary then return primary.CFrame + Vector3.new(0, 5, 0) end
        end
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("SpawnLocation") then
            return obj.CFrame + Vector3.new(0, 5, 0)
        end
    end
    return nil
end

local function findTargetPlayer()
    local name = TARGET_PLAYER_NAME
    if name == nil or name == "" then return nil end
    name = name:lower():gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then return nil end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Name:lower() == name then
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then return hrp end
        end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Name:lower():find(name, 1, true) then
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then return hrp end
        end
    end
    return nil
end

local function pickupGun(gunPart)
    local picked = false

    local prompt = gunPart:FindFirstChildOfClass("ProximityPrompt")
        or (gunPart.Parent and gunPart.Parent:FindFirstChildOfClass("ProximityPrompt"))
    if prompt then
        pcall(function() fireproximityprompt(prompt) end)
        picked = true
    end
    if not picked then
        local clickDetector = gunPart:FindFirstChildOfClass("ClickDetector")
            or (gunPart.Parent and gunPart.Parent:FindFirstChildOfClass("ClickDetector"))
        if clickDetector then
            pcall(function() fireclickdetector(clickDetector) end)
            picked = true
        end
    end
    if not picked then
        local character = LocalPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            pcall(function()
                firetouchinterest(rootPart, gunPart, 0)
                task.wait(0.05)
                firetouchinterest(rootPart, gunPart, 1)
            end)
        end
    end
end

local function fullTeleportChain(gunPart)
    local character = LocalPlayer.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local lobbyCFrame = getLobbySpawn()
    if lobbyCFrame then
        pcall(function() rootPart.CFrame = lobbyCFrame end)
        task.wait(RETURN_DELAY)
    end

    if gunPart and gunPart.Parent then
        local targetCFrame = CFrame.new(gunPart.Position + Vector3.new(0, TELEPORT_OFFSET, 0))
        pcall(function() rootPart.CFrame = targetCFrame end)
        task.wait(RETURN_DELAY)
        pickupGun(gunPart)
        task.wait(RETURN_DELAY)
    end

    local targetHRP = findTargetPlayer()
    if targetHRP then
        pcall(function()
            rootPart.CFrame = targetHRP.CFrame + Vector3.new(0, 3, 0)
        end)
        task.wait(RETURN_DELAY)
    end

    task.wait(RESET_DELAY)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        pcall(function() humanoid.Health = 0 end)
    end
end

--============================================================
-- IMPROVED ROLE DETECTION (Character + Backpack)
--============================================================

local function findRolePlayer(roleName)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character

            local function checkContainer(container)
                if not container then return false end
                for _, tool in ipairs(container:GetChildren()) do
                    if tool:IsA("Tool") then
                        local toolName = tool.Name:lower()
                        if roleName == "murderer" and toolName:find("knife") then
                            return true
                        end
                        if roleName == "sheriff" and
                           toolName:find("gun") and
                           not toolName:find("drop") then
                            return true
                        end
                    end
                end
                return false
            end

            -- Check equipped tools AND Backpack
            local found = false
            if char then
                found = checkContainer(char)
            end
            if not found then
                local backpack = plr:FindFirstChildOfClass("Backpack")
                found = checkContainer(backpack)
            end

            if found then
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then return plr, hrp end
            end
        end
    end
    return nil, nil
end

--============================================================
-- FLING LOGIC
--============================================================

local function flingTarget(targetHRP)
    if not targetHRP or not targetHRP.Parent then return end
    if not FLING_ENABLED then return end

    for _, obj in ipairs(targetHRP:GetChildren()) do
        if obj.Name == "FlingVelocity" or obj.Name == "FlingAngular" then
            pcall(function() obj:Destroy() end)
        end
    end

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

    local startTime = tick()
    local spinConnection
    spinConnection = RunService.Heartbeat:Connect(function()
        if not targetHRP or not targetHRP.Parent then
            spinConnection:Disconnect()
            return
        end
        if tick() - startTime > 1 then
            spinConnection:Disconnect()
            if bv then pcall(function() bv:Destroy() end) end
            if bg then pcall(function() bg:Destroy() end) end
            return
        end
        local spin = CFrame.Angles(math.random() * math.pi, math.random() * math.pi * 2, math.random() * math.pi)
        pcall(function()
            bg.CFrame = targetHRP.CFrame * spin
            bv.Velocity = Vector3.new(
                (math.random() - 0.5) * 2000,
                math.random() * 1000,
                (math.random() - 0.5) * 2000
            )
        end)
    end)

    task.delay(1.5, function()
        if bv and bv.Parent then pcall(function() bv:Destroy() end) end
        if bg and bg.Parent then pcall(function() bg:Destroy() end) end
    end)
end

--============================================================
-- MAIN LOOP
--============================================================

local connection = nil

local function startAutoPickup()
    if connection then return end
    connection = RunService.Heartbeat:Connect(function()
        if not AUTO_PICKUP_ENABLED then return end
        if hasGun() then return end
        local nearestGun = findNearestGun()
        if nearestGun then
            pcall(function() fullTeleportChain(nearestGun) end)
        end
    end)
end

local function stopAutoPickup()
    if connection then
        connection:Disconnect()
        connection = nil
    end
end

ToggleButton.MouseButton1Click:Connect(function()
    AUTO_PICKUP_ENABLED = not AUTO_PICKUP_ENABLED
    if AUTO_PICKUP_ENABLED then
        ToggleButton.Text = "AUTO PICKUP: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
    else
        ToggleButton.Text = "AUTO PICKUP: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(210, 60, 60)
        stopAutoPickup()
    end
end)

FlingMurdererButton.MouseButton1Click:Connect(function()
    local plr, hrp = findRolePlayer("murderer")
    if plr and hrp then
        setStatus("Flinging murderer: " .. plr.Name)
        flingTarget(hrp)
    else
        setStatus("Murderer not found in any inventory")
    end
end)

FlingSheriffButton.MouseButton1Click:Connect(function()
    local plr, hrp = findRolePlayer("sheriff")
    if plr and hrp then
        setStatus("Flinging sheriff: " .. plr.Name)
        flingTarget(hrp)
    else
        setStatus("Sheriff not found in any inventory")
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    if AUTO_PICKUP_ENABLED then
        startAutoPickup()
    end
end)

print("MM2 Auto Pickup + Fling Loaded!")
print("Role detection: Character AND Backpack")
