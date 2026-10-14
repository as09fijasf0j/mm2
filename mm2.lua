-- Auto Pickup Gun Script for MM2
-- Mobile Friendly with Movable GUI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Configuration
local PICKUP_DISTANCE = 15 -- Studs
local AUTO_PICKUP_ENABLED = false

-- Create GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoPickupGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main Frame (Movable)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 150, 0, 50)
MainFrame.Position = UDim2.new(0.5, -75, 0.1, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)
MainFrame.Active = true
MainFrame.Draggable = true -- Makes it movable
MainFrame.Parent = ScreenGui

-- Toggle Button
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(1, 0, 1, 0)
ToggleButton.Position = UDim2.new(0, 0, 0, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleButton.BorderSizePixel = 0
ToggleButton.Text = "AUTO PICKUP: OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextScaled = true
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Parent = MainFrame

-- Rounded corners for better look
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Function to check if player has a gun
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

-- Function to find nearest gun on ground
local function findNearestGun()
    local character = LocalPlayer.Character
    if not character then return nil end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    
    local nearestGun = nil
    local shortestDistance = PICKUP_DISTANCE
    
    -- Check workspace for dropped tools
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Tool") then
            local handle = obj:FindFirstChild("Handle")
            if handle then
                local distance = (handle.Position - rootPart.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearestGun = obj
                end
            end
        end
    end
    
    return nearestGun
end

-- Function to pick up gun
local function pickupGun(gun)
    if not gun then return end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    -- Try to pick up the gun using the game's pickup system
    -- MM2 uses a ProximityPrompt or ClickDetector
    local handle = gun:FindFirstChild("Handle")
    if handle then
        -- Method 1: Fire ProximityPrompt
        local prompt = gun:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            fireproximityprompt(prompt)
            return
        end
        
        -- Method 2: Fire ClickDetector
        local clickDetector = gun:FindFirstChildOfClass("ClickDetector")
        if clickDetector then
            fireclickdetector(clickDetector)
            return
        end
        
        -- Method 3: Direct pickup (for some games)
        if gun.Parent == workspace then
            gun.Parent = character
        end
    end
end

-- Main loop
local connection = nil

local function startAutoPickup()
    if connection then return end
    
    connection = RunService.Heartbeat:Connect(function()
        if not AUTO_PICKUP_ENABLED then return end
        
        -- Don't pick up if already have a gun
        if hasGun() then return end
        
        -- Find and pick up nearest gun
        local nearestGun = findNearestGun()
        if nearestGun then
            pcall(function()
                pickupGun(nearestGun)
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

-- Toggle button functionality
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

-- Mobile touch support for dragging (enhanced)
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

-- Clean up on respawn
LocalPlayer.CharacterAdded:Connect(function()
    if AUTO_PICKUP_ENABLED then
        -- Keep auto pickup running after respawn
        startAutoPickup()
    end
end)

print("Auto Pickup Gun Script Loaded!")
print("Toggle the button to enable/disable auto pickup")
print("Drag the GUI to move it around")
