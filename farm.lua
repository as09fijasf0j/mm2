-- SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")

-- VARIABLES
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

local visitedPositions = {}
local isActive = false
local flySpeed = 15
local collected = 0
local roundCollected = 0   -- NEW: resets every round
local startTime = 0
local antiAFK = false
local ROUND_CAP = 50       -- change if the cap isn't 50
local RESET_DELAY = 3      -- NEW: seconds to wait after hitting 50 before resetting

player.CharacterAdded:Connect(function(char)
	character = char
	rootPart = char:WaitForChild("HumanoidRootPart")
	visitedPositions = {}
	roundCollected = 0   -- NEW: reset round counter on respawn
end)

-- SOUND
local collectSound = Instance.new("Sound", rootPart)
collectSound.SoundId = "rbxassetid://12221967"
collectSound.Volume = 1

-- HALLOWEEN PALETTE
local COLOR_BG = Color3.fromRGB(18, 14, 24)
local COLOR_ACCENT = Color3.fromRGB(255, 120, 20)
local COLOR_ACCENT_DIM = Color3.fromRGB(60, 40, 70)
local COLOR_BTN = Color3.fromRGB(40, 28, 48)
local COLOR_BTN_HOVER = Color3.fromRGB(60, 42, 70)
local COLOR_ON = Color3.fromRGB(255, 140, 0)
local COLOR_TEXT = Color3.fromRGB(255, 225, 180)
local COLOR_TEXT_DIM = Color3.fromRGB(190, 160, 140)

-- GUI
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "MM2AutofarmGui"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 290, 0, 310)
frame.Position = UDim2.new(0.5, -145, 0.3, 0)
frame.BackgroundColor3 = COLOR_BG
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)
local stroke = Instance.new("UIStroke", frame)
stroke.Color = COLOR_ACCENT
stroke.Thickness = 2

local header = Instance.new("Frame", frame)
header.Size = UDim2.new(1, 0, 0, 44)
header.BackgroundColor3 = COLOR_ACCENT_DIM
header.BorderSizePixel = 0
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 14)

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1, -20, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.Text = "🎃 MM2 Autofarm"
title.TextColor3 = COLOR_TEXT
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left

local credit = Instance.new("TextLabel", frame)
credit.Size = UDim2.new(1, -20, 0, 18)
credit.Position = UDim2.new(0, 10, 1, -20)
credit.Text = "Made by LunaScripts"
credit.TextColor3 = COLOR_TEXT_DIM
credit.BackgroundTransparency = 1
credit.Font = Enum.Font.Gotham
credit.TextSize = 12
credit.TextXAlignment = Enum.TextXAlignment.Right

local hideBtn = Instance.new("TextButton", gui)
hideBtn.Size = UDim2.new(0, 110, 0, 35)
hideBtn.Position = UDim2.new(1, -120, 1, -45)
hideBtn.Text = "👻 Hide GUI"
hideBtn.BackgroundColor3 = COLOR_BTN
hideBtn.TextColor3 = COLOR_TEXT
hideBtn.Font = Enum.Font.GothamBold
hideBtn.TextSize = 14
Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(0, 8)

hideBtn.MouseEnter:Connect(function() hideBtn.BackgroundColor3 = COLOR_BTN_HOVER end)
hideBtn.MouseLeave:Connect(function() hideBtn.BackgroundColor3 = COLOR_BTN end)
hideBtn.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
	hideBtn.Text = frame.Visible and "👻 Hide GUI" or "👻 Show GUI"
end)

local function makeButton(y, text)
	local btn = Instance.new("TextButton", frame)
	btn.Size = UDim2.new(0, 250, 0, 32)
	btn.Position = UDim2.new(0.5, -125, 0, y)
	btn.Text = text
	btn.BackgroundColor3 = COLOR_BTN
	btn.TextColor3 = COLOR_TEXT
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	btn.MouseEnter:Connect(function() btn.BackgroundColor3 = COLOR_BTN_HOVER end)
	btn.MouseLeave:Connect(function()
		if btn:GetAttribute("locked") then return end
		btn.BackgroundColor3 = COLOR_BTN
	end)
	return btn
end

local function makeLabel(y, text)
	local lbl = Instance.new("TextLabel", frame)
	lbl.Size = UDim2.new(0, 250, 0, 20)
	lbl.Position = UDim2.new(0.5, -125, 0, y)
	lbl.Text = text
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = COLOR_TEXT_DIM
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 14
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	return lbl
end

local toggleBtn = makeButton(58, "🎃 Auto Farm: OFF")
local afkBtn = makeButton(96, "🕯 Anti-AFK: OFF")
local speedBtn = makeButton(134, "🦇 Tween Speed: 15")
local counterLabel = makeLabel(172, "Collected: 0 (Round: 0/50)")
local timerLabel = makeLabel(195, "Time Active: 0s")
local rateLabel = makeLabel(218, "Est. Coins/Hour: 0")
local resetBtn = makeButton(245, "🔄 Reset Counter")

resetBtn.MouseButton1Click:Connect(function()
	collected = 0
	roundCollected = 0
	startTime = tick()
	counterLabel.Text = "Collected: 0 (Round: 0/" .. ROUND_CAP .. ")"
	timerLabel.Text = "Time Active: 0s"
	rateLabel.Text = "Est. Coins/Hour: 0"
end)

afkBtn.MouseButton1Click:Connect(function()
	antiAFK = not antiAFK
	afkBtn.Text = antiAFK and "🕯 Anti-AFK: ON" or "🕯 Anti-AFK: OFF"
	afkBtn.BackgroundColor3 = antiAFK and COLOR_ON or COLOR_BTN
	afkBtn:SetAttribute("locked", antiAFK)
end)

player.Idled:Connect(function()
	if antiAFK then
		VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
		task.wait(1)
		VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
	end
end)

speedBtn.MouseButton1Click:Connect(function()
	flySpeed += 1
	if flySpeed > 25 then flySpeed = 10 end
	speedBtn.Text = "🦇 Tween Speed: " .. flySpeed
end)

local function flyTo(pos, speed)
	if not rootPart then return end
	local duration = (pos - rootPart.Position).Magnitude / speed
	local tween = TweenService:Create(rootPart, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)})
	tween:Play()
	tween.Completed:Wait()
end

toggleBtn.MouseButton1Click:Connect(function()
	isActive = not isActive
	toggleBtn.Text = isActive and "🎃 Auto Farm: ON" or "🎃 Auto Farm: OFF"
	toggleBtn.BackgroundColor3 = isActive and COLOR_ON or COLOR_BTN
	toggleBtn:SetAttribute("locked", isActive)

	if isActive then
		collected = 0
		roundCollected = 0
		startTime = tick()
		visitedPositions = {}

		task.spawn(function()
			while isActive do
				local elapsed = tick() - startTime
				timerLabel.Text = "Time Active: " .. math.floor(elapsed) .. "s"
				rateLabel.Text = "Est. Coins/Hour: " .. (elapsed > 0 and math.floor((collected / elapsed) * 3600) or 0)
				task.wait(0.1)
			end
		end)

		task.spawn(function()
			while isActive do
				character = player.Character or player.CharacterAdded:Wait()
				rootPart = character:FindFirstChild("HumanoidRootPart")
				if rootPart then
					local closest, shortest = nil, math.huge
					for _, obj in ipairs(workspace:GetDescendants()) do
						if obj:IsA("BasePart") and obj.Name == "Coin_Server" and not visitedPositions[obj] then
							local dist = (obj.Position - rootPart.Position).Magnitude
							if dist < shortest and dist < 250 then
								closest = obj
								shortest = dist
							end
						end
					end

					if closest and closest.Parent and closest:IsDescendantOf(workspace) then
						flyTo(closest.Position, flySpeed)
						if closest.Parent then
							visitedPositions[closest] = true
							collected += 1
							roundCollected += 1
							collectSound:Play()
							counterLabel.Text = "Collected: " .. collected .. " (Round: " .. roundCollected .. "/" .. ROUND_CAP .. ")"

							-- NEW: 3-second delay before reset after reaching the cap
							if roundCollected >= ROUND_CAP then
								counterLabel.Text = "🎃 50 reached! Resetting in " .. RESET_DELAY .. "s..."
								-- count down so you can see it
								for i = RESET_DELAY, 1, -1 do
									counterLabel.Text = "🎃 50 reached! Resetting in " .. i .. "s..."
									task.wait(1)
									if not isActive then break end
								end
								if isActive then
									local hum = character and character:FindFirstChildOfClass("Humanoid")
									if hum and hum.Health > 0 then
										local oldChar = character
										hum.Health = 0
										repeat task.wait(0.2) until player.Character ~= oldChar
										task.wait(0.5)
									end
								end
							end
						end
					end
				end
				task.wait(0.1)
			end
		end)
	end
end)
