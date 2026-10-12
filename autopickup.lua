-- Custom Auto Pickup Gun Script for MM2 (Teleport Version)
-- Mobile Friendly with Movable GUI
-- Detects dropped guns by searching for ProximityPrompts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- Configuration
local TELEPORT_OFFSET = 3        -- How high above the gun you land
local RETURN_DELAY = 0.2         -- Seconds to wait before teleporting back
local AUTO_PICKUP_ENABLED = false

-- Create GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoPickupGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main Frame (Movable)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 160, 0, 50)
MainFrame.Position = UDim2.new(0.5, -80, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Toggle Button
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(1, 0, 1, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleButton.BorderSizePixel = 0
ToggleButton.Text = "AUTO PICKUP: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextScaled = true
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Parent = MainFrame

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Check if player already has a tool
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

-- Find nearest dropped gun by searching for ProximityPrompts
local function findNearestGun()
    local character = LocalPlayer.Character
    if not character then return nil end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end

    local nearestGun = nil
    local shortestDistance = math.huge

    -- Search the entire workspace for any object with a ProximityPrompt
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            -- The prompt's parent is likely the gun model
            local gunModel = obj.Parent
            local handle = gunModel and gunModel:FindFirstChild("Handle")
            
            if handle then
                local distance = (handle.Position - rootPart.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearestGun = gunModel
                end
            end
        end
    end

    return nearestGun
end

-- Fire the correct pickup method
local function pickupGun(gun)
    if not gun then return end

    -- Find the ProximityPrompt inside the gun model
    local prompt = gun:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
        pcall(function()
            fireproximityprompt(prompt)
        end)
        return
    end
end

-- Core routine: teleport -> pick up -> teleport back
local function teleportAndPickup(gun)
    local character = LocalPlayer.Character
    if not character then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local handle = gun:FindFirstChild("Handle")
    if not handle then return end

    -- Save original position
    local originalCFrame = rootPart.CFrame

    -- Calculate target position next to gun
    local gunPos = handle.Position
    local targetCFrame = CFrame.new(gunPos + Vector3.new(0, TELEPORT_OFFSET, 0))

    -- Teleport to gun
    pcall(function()
        rootPart.CFrame = targetCFrame
    end)

    task.wait(RETURN_DELAY)

    -- Pick up the gun
    pickupGun(gun)

    task.wait(RETURN_DELAY)

    -- Teleport back to original position
    if character.Parent and rootPart.Parent then
        pcall(function()
            rootPart.CFrame = originalCFrame
        end)
    end
end

-- Main loop
local connection = nil

local function startAutoPickup()
    if connection then return end

    connection = RunService.Heartbeat:Connect(function()
        if not AUTO_PICKUP_ENABLED then return end
        if hasGun() then return end

        local nearestGun = findNearestGun()
        if nearestGun then
            pcall(function()
                teleportAndPickup(nearestGun)
            end)
        end
    end)
end

local function stopAutoPickup()
    if connection then
        connection:Disconnect()
        connection = nil
    end
end

-- Toggle button
ToggleButton.MouseButton1Click:Connect(function()
    AUTO_PICKUP_ENABLED = not AUTO_PICKUP_ENABLED

    if AUTO_PICKUP_ENABLED then
        ToggleButton.Text = "AUTO PICKUP: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        startAutoPickup()
    else
        ToggleButton.Text = "AUTO PICKUP: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        stopAutoPickup()
    end
end)

-- Mobile-friendly drag support
local dragging = false
local dragInput = nil
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

MainFrame.InputBegan:Connect(function(input)
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

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or
       input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updateDrag(input)
    end
end)

-- Keep working after respawn
LocalPlayer.CharacterAdded:Connect(function()
    if AUTO_PICKUP_ENABLED then
        startAutoPickup()
    end
end)

print("Custom Auto Pickup (ProximityPrompt Detection) Loaded!")
