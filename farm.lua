-- SERVICIOS DE ROBLOX
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

-- CONFIGURACIÓN SEGURA
local AutofarmActivo = false
local AntiAfkActivo = true
local VELOCIDAD_SEGURA = 19
local MonedasRonda = 0
local MonedasTotales = 0

-- ANTI-AFK
LocalPlayer.Idled:Connect(function()
    if AntiAfkActivo then
        VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
    end
end)

-- INTERFAZ VISUAL HALLOWEEN 🎃
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MM2_Halloween_Farm"
ScreenGui.ResetOnSpawn = false

pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Marco Principal
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 220, 0, 180)
MainFrame.Position = UDim2.new(0.5, -110, 0.4, -90)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 15, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 10)
FrameCorner.Parent = MainFrame

-- Título
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(230, 90, 0)
Title.Text = "🎃 MM2 HALLOWEEN 🦇"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

-- Botón 1: Farm
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 180, 0, 35)
ToggleButton.Position = UDim2.new(0, 20, 0, 50)
ToggleButton.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
ToggleButton.Text = "👻 Farm: APAGADO"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 14
ToggleButton.Parent = MainFrame

local BtnCorner1 = Instance.new("UICorner")
BtnCorner1.CornerRadius = UDim.new(0, 6)
BtnCorner1.Parent = ToggleButton

-- Botón 2: Anti-AFK
local AfkButton = Instance.new("TextButton")
AfkButton.Name = "AfkButton"
AfkButton.Size = UDim2.new(0, 180, 0, 35)
AfkButton.Position = UDim2.new(0, 20, 0, 95)
AfkButton.BackgroundColor3 = Color3.fromRGB(40, 140, 50)
AfkButton.Text = "🛡️ Anti-AFK: ACTIVADO"
AfkButton.TextColor3 = Color3.fromRGB(255, 255, 255)
AfkButton.Font = Enum.Font.SourceSansBold
AfkButton.TextSize = 14
AfkButton.Parent = MainFrame

local BtnCorner2 = Instance.new("UICorner")
BtnCorner2.CornerRadius = UDim.new(0, 6)
BtnCorner2.Parent = AfkButton

-- Texto de Monedas Recolectadas
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Size = UDim2.new(0, 180, 0, 25)
StatusLabel.Position = UDim2.new(0, 20, 0, 140)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "🍬 Recolectadas: 0"
StatusLabel.TextColor3 = Color3.fromRGB(255, 170, 0)
StatusLabel.Font = Enum.Font.SourceSansBold
StatusLabel.TextSize = 14
StatusLabel.Parent = MainFrame

-- Botón Cerrar (X)
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 25, 0, 25)
CloseButton.Position = UDim2.new(1, -30, 0, 7)
CloseButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseButton.Text = "✖"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.TextSize = 12
CloseButton.Parent = MainFrame

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(1, 0)
CloseCorner.Parent = CloseButton

-- Botón Flotante para reabrir
local OpenButton = Instance.new("TextButton")
OpenButton.Name = "OpenButton"
OpenButton.Size = UDim2.new(0, 60, 0, 30)
OpenButton.Position = UDim2.new(0, 10, 0, 10)
OpenButton.BackgroundColor3 = Color3.fromRGB(230, 90, 0)
OpenButton.Text = "🎃 Abrir"
OpenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenButton.Font = Enum.Font.SourceSansBold
OpenButton.TextSize = 12
OpenButton.Visible = false
OpenButton.Parent = ScreenGui

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(0, 6)
OpenCorner.Parent = OpenButton

-- BÚSQUEDA DE MONEDAS EN CARPETAS REALES DE MM2
local function obtenerMonedas()
    local monedas = {}
    local contenedores = {
        Workspace:FindFirstChild("Normal"),
        Workspace:FindFirstChild("Map"),
        Workspace
    }
    
    for _, contenedor in pairs(contenedores) do
        if contenedor then
            for _, obj in pairs(contenedor:GetDescendants()) do
                if (obj.Name == "Coin_Token" or obj.Name == "Coin" or obj.Name == "Candy_Token") and obj:IsA("BasePart") then
                    table.insert(monedas, obj)
                end
            end
        end
    end
    return monedas
end

-- BUCLE PRINCIPAL DE RECOLECCIÓN
task.spawn(function()
    while true do
        task.wait(0.1)
        if AutofarmActivo then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            
            if char and root and hum and hum.Health > 0 then
                local lista = obtenerMonedas()
                
                if #lista > 0 then
                    for _, coin in pairs(lista) do
                        if not AutofarmActivo then break end
                        if MonedasRonda >= 50 then break end
                        
                        if coin and coin.Parent then
                            -- Movimiento directo a la moneda
                            while coin and coin.Parent and AutofarmActivo and hum.Health > 0 do
                                local posMoneda = coin.Position
                                local dist = (root.Position - posMoneda).Magnitude
                                
                                if dist <= 3.5 then
                                    MonedasRonda = MonedasRonda + 1
                                    MonedasTotales = MonedasTotales + 1
                                    StatusLabel.Text = "🍬 Recolectadas: " .. MonedasTotales
                                    break
                                end
                                
                                local dir = (posMoneda - root.Position).Unit
                                root.CFrame = CFrame.new(root.Position + (dir * (VELOCIDAD_SEGURA * 0.03)), posMoneda)
                                RunService.Heartbeat:Wait()
                            end
                        end
                    end
                end
                
                -- RESPAWN AUTOMÁTICO AL LLEGAR A 50 EN LA RONDA
                if MonedasRonda >= 50 and hum.Health > 0 then
                    MonedasRonda = 0
                    hum.Health = 0
                    repeat task.wait() until LocalPlayer.Character ~= char
                end
            end
        end
    end
end)

-- RESETEAR CONTADOR DE RONDA AL RESPAWNEAR
LocalPlayer.CharacterAdded:Connect(function()
    MonedasRonda = 0
end)

-- INTERACCIÓN DE BOTONES
ToggleButton.MouseButton1Click:Connect(function()
    AutofarmActivo = not AutofarmActivo
    if AutofarmActivo then
        ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 140, 50)
        ToggleButton.Text = "🎃 Farm: ENCENDIDO"
    else
        ToggleButton.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
        ToggleButton.Text = "👻 Farm: APAGADO"
    end
end)

AfkButton.MouseButton1Click:Connect(function()
    AntiAfkActivo = not AntiAfkActivo
    if AntiAfkActivo then
        AfkButton.BackgroundColor3 = Color3.fromRGB(40, 140, 50)
        AfkButton.Text = "🛡️ Anti-AFK: ACTIVADO"
    else
        AfkButton.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
        AfkButton.Text = "🛡️ Anti-AFK: DESACTIVADO"
    end
end)

CloseButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    OpenButton.Visible = true
end)

OpenButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = true
    OpenButton.Visible = false
end)