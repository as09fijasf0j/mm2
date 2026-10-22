-- MM2 Autoplay Script v0.8.0

if game.PlaceId ~= 142823291 then
    return
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")
local Stats = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
while not player do
    task.wait()
    player = Players.LocalPlayer
end

local function setupJoinMenu()
    local starterGui = game:GetService("StarterGui")
    local playerGui = player:WaitForChild("PlayerGui")
    local execName = (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or "your executor"

    local function handleButton(button)
        if button and button.Visible then
            if typeof(getconnections) == "function" then
                for _, connection in ipairs(getconnections(button.MouseButton1Click)) do
                    local fn = connection.Function
                    if fn then
                        task.spawn(fn)
                    else
                        pcall(function() connection:Fire() end)
                    end
                end

                pcall(function()
                    starterGui:SetCore("SendNotification", {
                        Title = "nice executor",
                        Text = "your executor, " .. execName .. ", supports getconnections",
                        Duration = 5
                    })
                end)
            else
                local join = playerGui:FindFirstChild("Join")
                if join then join.Enabled = false end
                local loading = playerGui:FindFirstChild("Loading")
                if loading then loading.Enabled = false end

                pcall(function()
                    starterGui:SetCore("SendNotification", {
                        Title = "bad executor",
                        Text = "your executor, " .. execName .. ", does not support getconnections. get a better executor buddy",
                        Duration = 30
                    })
                end)
            end
        end
    end

    local join = playerGui:FindFirstChild("Join")
    local playButton = join and join:FindFirstChild("Friends") and join.Friends:FindFirstChild("Play")

    if playButton and playButton.Visible then
        handleButton(playButton)
    else
        local connection
        connection = playerGui.DescendantAdded:Connect(function(descendant)
            if descendant.Name == "Play" and descendant:IsA("TextButton") then
                task.spawn(function()
                    repeat task.wait() until descendant.Visible
                    handleButton(descendant)
                    connection:Disconnect()
                end)
            end
        end)
    end
end
task.spawn(setupJoinMenu)

local camera = workspace.CurrentCamera
while not camera do
    task.wait()
    camera = workspace.CurrentCamera
end

task.wait(1.5)

local VERSION = "v0.8.0"
local enabled = true
local running = true
local alive = false

local targetCoin = nil
local isTargetingGun = false
local route = nil
local routeIndex = 1
local pendingRoute = nil
local pendingTargetCoin = nil
local pendingUpcomingCoins = {}
local isCalculatingPath = false
local stuckTimer = 0
local lastVelocityCheck = 0
local lastJumpTime = 0
local lastRouteUpdate = 0
local unreachableCoins = {}
local lastUnreachableClear = 0
local lastStuckPos = Vector3.new()
local lastOpportunisticCheck = 0

local noPathTimer = 0
local isWandering = false
local wanderRoute = nil
local wanderRouteIndex = 1
local isCalculatingWander = false

local lastRoundState = false

local upcomingCoins = {}

local myRole = "Innocent"
local myWeapon = nil
local knownMurderer = nil
local knownSheriff = nil
local suspectList = {}
local murderTarget = nil
local lastShootTime = 0
local lastThrowTime = 0
local lastChasePlan = 0
local chaseRoute = nil
local chaseRouteIndex = 1
local currentlyEvading = false

local autoVoteMap = true
local hasVotedCurrentMap = false
local isCalculatingVotePath = false
local voteRoute = nil
local voteRouteIndex = 1
local currentVoteMapName = nil
local currentVoteTargetPad = nil
local voteHoldTimer = 0

local WP_DIST = 3.25

local MAP_PRIORITIES = {
    [1] = "Workplace",
    [2] = "Mil Base",
    [3] = "Mansion 2",
    [4] = "House 2",
    [5] = "Bank 2",
    [6] = "Police Station",
    [7] = "Research Facility"
}

local THEME = {
    bg = Color3.fromRGB(8, 9, 12),
    panel = Color3.fromRGB(12, 14, 18),
    surface = Color3.fromRGB(17, 19, 25),
    hover = Color3.fromRGB(26, 29, 38),
    border = Color3.fromRGB(30, 34, 44),
    borderStrong = Color3.fromRGB(52, 58, 72),
    off = Color3.fromRGB(38, 42, 54),
    knobOff = Color3.fromRGB(150, 156, 172),
    text = Color3.fromRGB(226, 229, 236),
    muted = Color3.fromRGB(119, 126, 142),
    accent = Color3.fromRGB(104, 138, 255),
    good = Color3.fromRGB(96, 200, 142),
    bad = Color3.fromRGB(236, 104, 104),
    warn = Color3.fromRGB(230, 180, 92),
}

local CHOICES = {
    basicMode = {"Just coins", "Just reset"},
    murdererMode = {"Just coins", "Coins + kill nearby", "Full hunt", "Just reset"},
    bagBasic = {"Stand", "Wander", "Reset", "Server hop"},
    bagMurderer = {"Hunt", "Stand", "Wander", "Reset", "Server hop"},
    hopMethod = {"MM2", "Public servers"},
    huntPriority = {"Sheriff first", "Nearest"},
}

local CHOICE_KEYS = {
    innocentMode = "basicMode",
    sheriffMode = "basicMode",
    murdererMode = "murdererMode",
    innocentBagFull = "bagBasic",
    sheriffBagFull = "bagBasic",
    murdererBagFull = "bagMurderer",
    hopMethod = "hopMethod",
    huntPriority = "huntPriority",
}

local NUM_RANGES = {
    detectRange = {20, 200},
    evadeDistance = {10, 60},
    wanderRadius = {20, 120},
    engageRange = {15, 35},
    sheriffRange = {30, 150},
    aimDelay = {0, 1},
    hopTargetMin = {2, 12},
    hopTargetMax = {2, 12},
    hopPingLimit = {100, 600},
    uiScale = {0.6, 1.6},
    nearbyRadius = {5, 40},
    maxCoinDist = {50, 2000},
    stabRange = {6, 15},
    sheriffKeepDist = {10, 40},
    giveUpTime = {4, 60},
    pathCandidates = {1, 5},
    huntMemory = {0, 10},
}

local S = {
    roundStartClock = os.clock(),
    roundActionDone = false,
    aimStart = nil,
    hopping = false,
    hopCancel = false,
    lastHopTry = 0,
    bagFull = false,
    bagCheckClock = 0,
    settleTime = 4,
    uiConns = {},
    coinContainer = nil,
    coinContainerCheck = 0,
    coinList = {},
    coinListT = 0,
    gunDrop = nil,
    gunDropCheck = 0,
    roundCacheValue = false,
    roundCacheT = 0,
    roundScanValue = false,
    roundScanT = 0,
    voteCache = nil,
    voteCacheT = 0,
    lastScan = 0,
    lastEsp = 0,
    forcedCoin = nil,
    nextPlanTime = 0,
    shootRemote = nil,
    throwRemote = nil,
    blacklist = setmetatable({}, {__mode = "k"}),
    knifeSeen = setmetatable({}, {__mode = "k"}),
    huntSeen = setmetatable({}, {__mode = "k"}),
    lastCombatT = 0,
    lastHolster = 0,
    hintCoin = nil,
    hintT = 0,
    watchTarget = nil,
    watchBest = math.huge,
    watchProgressT = 0,
    huntTarget = nil,
    huntBest = math.huge,
    huntProgressT = 0,
}

local settingsFile = "mm2-autoplay.json"
local DEFAULT_SETTINGS = {
    botEnabled = true,
    autoVoteMap = true,
    playerEsp = true,
    coinEsp = true,
    gunEsp = true,
    pathEsp = true,
    debugRays = false,
    autoJump = true,
    autoHopPing = false,
    hopForPlayers = false,
    hopIfAlone = false,
    hopPingLimit = 200,
    hopMethod = "MM2",
    hopTargetMin = 2,
    hopTargetMax = 5,
    innocentMode = "Just coins",
    innocentBagFull = "Stand",
    innocentStandRun = true,
    pickupGun = true,
    sheriffMode = "Just coins",
    sheriffBagFull = "Stand",
    sheriffStandRun = true,
    sheriffShoot = true,
    sheriffRange = 80,
    sheriffKeepDist = 22,
    aimDelay = 0.25,
    murdererMode = "Full hunt",
    murdererBagFull = "Hunt",
    engageRange = 25,
    stabRange = 12,
    throwKnife = true,
    huntPriority = "Sheriff first",
    planAhead = true,
    giveUpTime = 10,
    pathCandidates = 3,
    huntMemory = 4,
    grabNearby = true,
    nearbyRadius = 14,
    maxCoinDist = 2000,
    avoidMurdererCoins = true,
    detectRange = 70,
    evadeDistance = 26,
    wanderRadius = 40,
    uiScale = 1,
    uiKey = "K",
    hideOnLoad = false,
}

local botSettings = {}
for k, v in pairs(DEFAULT_SETTINGS) do
    botSettings[k] = v
end

local function saveSettings()
    if writefile then
        pcall(function()
            writefile(settingsFile, HttpService:JSONEncode(botSettings))
        end)
    end
end

local function sanitizeSettings()
    for key, listKey in pairs(CHOICE_KEYS) do
        if not table.find(CHOICES[listKey], botSettings[key]) then
            botSettings[key] = DEFAULT_SETTINGS[key]
        end
    end
    for key, range in pairs(NUM_RANGES) do
        local v = tonumber(botSettings[key])
        if not v then v = DEFAULT_SETTINGS[key] end
        botSettings[key] = math.clamp(v, range[1], range[2])
    end
    if type(botSettings.uiKey) ~= "string" or not pcall(function() return Enum.KeyCode[botSettings.uiKey] end) then
        botSettings.uiKey = DEFAULT_SETTINGS.uiKey
    end
end

local function loadSettings()
    if isfile and isfile(settingsFile) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(settingsFile))
        end)
        if success and type(data) == "table" then
            for k, v in pairs(data) do
                if DEFAULT_SETTINGS[k] ~= nil then
                    botSettings[k] = v
                end
            end
        end
    end
    sanitizeSettings()
    botSettings.botEnabled = true
    enabled = true
    running = true
    autoVoteMap = botSettings.autoVoteMap
end

loadSettings()

local visFolder = workspace:FindFirstChild("RobotPath")
if not visFolder then
    visFolder = Instance.new("Folder")
    visFolder.Name = "RobotPath"
    visFolder.Parent = workspace
end

local debugFolder = workspace:FindFirstChild("RobotDebugRays")
if not debugFolder then
    debugFolder = Instance.new("Folder")
    debugFolder.Name = "RobotDebugRays"
    debugFolder.Parent = workspace
end

local function getCharacter()
    if not player or not player.Parent then return nil, nil end
    local char = player.Character
    if not char then return nil, nil end
    local hum = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if hum and root and hum.Health > 0 then return hum, root end
    return nil, nil
end

local function restoreCameraMode()
    pcall(function()
        player.CameraMode = Enum.CameraMode.Classic
        player.DevComputerCameraMode = Enum.DevComputerCameraMode.UserChoice
    end)
end

local function setFirstPersonCamera()
    pcall(function()
        player.CameraMode = Enum.CameraMode.LockFirstPerson
    end)
end

local function clearRoute()
    route = nil
    routeIndex = 1
    targetCoin = nil
    pendingRoute = nil
    pendingTargetCoin = nil
    pendingUpcomingCoins = {}
    upcomingCoins = {}
    isTargetingGun = false
    isCalculatingPath = false
    stuckTimer = 0
    pcall(function()
        for _, v in ipairs(visFolder:GetChildren()) do
            if v.Name == "PathDot" or v.Name == "ChaseDot" or v.Name == "VoteDot" or v.Name == "UpcomingPathDot" or v.Name == "WanderDot" then
                v:Destroy()
            end
        end
    end)
end

local fullUnload
local performServerHop
local setBotEnabled

local function buildUI()
    local FONT = Enum.Font.GothamMedium
    local FONT_BOLD = Enum.Font.GothamBold
    local WIN_W, WIN_H = 560, 410
    local ui = {}
    local orderCounter = 0

    local function nextOrder()
        orderCounter = orderCounter + 1
        return orderCounter
    end

    local function create(class, props, parent)
        local inst = Instance.new(class)
        for k, v in pairs(props) do
            inst[k] = v
        end
        if parent then inst.Parent = parent end
        return inst
    end

    local function round(parent, radius)
        return create("UICorner", {CornerRadius = UDim.new(0, radius or 6)}, parent)
    end

    local function outline(parent, color)
        return create("UIStroke", {
            Color = color or THEME.border,
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        }, parent)
    end

    local function padding(parent, top, right, bottom, left)
        return create("UIPadding", {
            PaddingTop = UDim.new(0, top),
            PaddingRight = UDim.new(0, right),
            PaddingBottom = UDim.new(0, bottom),
            PaddingLeft = UDim.new(0, left),
        }, parent)
    end

    local function listLayout(parent, gap)
        return create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, gap or 0),
        }, parent)
    end

    local function tween(inst, props, t)
        TweenService:Create(inst, TweenInfo.new(t or 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
    end

    local function listen(signal, fn)
        local c = signal:Connect(fn)
        table.insert(S.uiConns, c)
        return c
    end

    local function textLabel(parent, props)
        local p = {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            TextSize = 12,
            TextColor3 = THEME.text,
            Font = FONT,
            TextXAlignment = Enum.TextXAlignment.Left,
        }
        for k, v in pairs(props) do
            p[k] = v
        end
        return create("TextLabel", p, parent)
    end

    local function isPress(input)
        return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
    end

    local function isMove(input)
        return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
    end

    local guiContainer = (typeof(gethui) == "function" and gethui()) or CoreGui
    local old = guiContainer:FindFirstChild("MM2AutoplayUI")
    if old then old:Destroy() end

    local gui = create("ScreenGui", {
        Name = "MM2AutoplayUI",
        ResetOnSpawn = false,
        DisplayOrder = 9999,
        IgnoreGuiInset = true,
    }, guiContainer)
    ui.gui = gui

    local window = create("Frame", {
        Name = "Window",
        Size = UDim2.fromOffset(WIN_W, WIN_H),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundColor3 = THEME.bg,
        BorderSizePixel = 0,
        Active = true,
    }, gui)
    round(window, 10)
    outline(window, THEME.border)
    ui.window = window

    local scale = create("UIScale", {Scale = 1}, window)

    local function applyScale(v)
        local vp = camera and camera.ViewportSize or Vector2.new(1280, 720)
        local fit = math.min(vp.X * 0.96 / WIN_W, vp.Y * 0.96 / WIN_H)
        scale.Scale = math.max(0.5, math.min(v, fit))
    end
    applyScale(botSettings.uiScale)

    local titleBar = create("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, window)

    textLabel(titleBar, {
        Size = UDim2.new(1, -200, 1, 0),
        Position = UDim2.fromOffset(16, 0),
        Text = "MM2 Autoplay  <font color=\"#777E8E\">" .. VERSION .. "</font>",
        RichText = true,
        TextSize = 14,
        Font = FONT_BOLD,
    })

    local statusPill = textLabel(titleBar, {
        Size = UDim2.fromOffset(90, 20),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -68, 0.5, 0),
        Text = "Running",
        TextXAlignment = Enum.TextXAlignment.Right,
        TextColor3 = THEME.good,
    })

    local hideBtn = create("TextButton", {
        Text = "Hide",
        Font = FONT,
        TextSize = 12,
        TextColor3 = THEME.muted,
        AutoButtonColor = false,
        BackgroundColor3 = THEME.surface,
        Size = UDim2.fromOffset(46, 22),
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        BorderSizePixel = 0,
    }, titleBar)
    round(hideBtn, 5)
    outline(hideBtn, THEME.border)
    listen(hideBtn.MouseEnter, function() tween(hideBtn, {BackgroundColor3 = THEME.hover}) end)
    listen(hideBtn.MouseLeave, function() tween(hideBtn, {BackgroundColor3 = THEME.surface}) end)
    listen(hideBtn.MouseButton1Click, function() window.Visible = false end)

    create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.fromOffset(0, 38),
        BackgroundColor3 = THEME.border,
        BorderSizePixel = 0,
    }, window)

    function ui.setBadge(state)
        statusPill.Text = state and "Running" or "Stopped"
        statusPill.TextColor3 = state and THEME.good or THEME.bad
    end

    local dragging, dragStart, startPos = false, nil, nil
    listen(titleBar.InputBegan, function(input)
        if isPress(input) then
            dragging = true
            dragStart = input.Position
            startPos = window.Position
        end
    end)
    listen(UserInputService.InputChanged, function(input)
        if dragging and isMove(input) then
            local delta = input.Position - dragStart
            local s = scale.Scale
            window.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X / s,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y / s
            )
        end
    end)
    listen(UserInputService.InputEnded, function(input)
        if isPress(input) then dragging = false end
    end)

    local sidebar = create("Frame", {
        Size = UDim2.new(0, 132, 1, -39),
        Position = UDim2.fromOffset(0, 39),
        BackgroundColor3 = THEME.panel,
        BorderSizePixel = 0,
    }, window)
    round(sidebar, 10)
    create("Frame", {
        Size = UDim2.new(1, 0, 0, 12),
        BackgroundColor3 = THEME.panel,
        BorderSizePixel = 0,
    }, sidebar)
    create("Frame", {
        Size = UDim2.new(0, 12, 1, 0),
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = THEME.panel,
        BorderSizePixel = 0,
    }, sidebar)

    local sideList = create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, sidebar)
    padding(sideList, 10, 8, 8, 8)
    listLayout(sideList, 2)

    create("Frame", {
        Size = UDim2.new(0, 1, 1, -39),
        Position = UDim2.fromOffset(132, 39),
        BackgroundColor3 = THEME.border,
        BorderSizePixel = 0,
    }, window)

    local content = create("Frame", {
        Size = UDim2.new(1, -133, 1, -39),
        Position = UDim2.fromOffset(133, 39),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, window)

    local pages = {}
    local tabs = {}

    local function selectTab(name)
        for n, page in pairs(pages) do
            page.Visible = (n == name)
        end
        for n, t in pairs(tabs) do
            local active = (n == name)
            t.button.BackgroundTransparency = active and 0 or 1
            t.label.TextColor3 = active and THEME.text or THEME.muted
            t.bar.Visible = active
        end
    end

    local function addPage(name, index)
        local btn = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = THEME.surface,
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Text = "",
            BorderSizePixel = 0,
            LayoutOrder = index,
        }, sideList)
        round(btn, 6)
        local lbl = textLabel(btn, {
            Size = UDim2.new(1, -16, 1, 0),
            Position = UDim2.fromOffset(14, 0),
            Text = name,
            TextSize = 13,
            TextColor3 = THEME.muted,
        })
        local bar = create("Frame", {
            Size = UDim2.fromOffset(2, 14),
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 4, 0.5, 0),
            BackgroundColor3 = THEME.accent,
            BorderSizePixel = 0,
            Visible = false,
        }, btn)
        round(bar, 1)
        tabs[name] = {button = btn, label = lbl, bar = bar}
        listen(btn.MouseButton1Click, function() selectTab(name) end)

        local page = create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = THEME.borderStrong,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Visible = false,
        }, content)
        padding(page, 6, 14, 14, 12)
        listLayout(page, 4)
        pages[name] = page
        return page
    end

    local function section(page, title)
        textLabel(page, {
            Size = UDim2.new(1, 0, 0, 24),
            Text = string.upper(title),
            TextSize = 11,
            TextColor3 = THEME.muted,
            Font = FONT_BOLD,
            TextYAlignment = Enum.TextYAlignment.Bottom,
            LayoutOrder = nextOrder(),
        })
        local card = create("Frame", {
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = THEME.surface,
            BorderSizePixel = 0,
            LayoutOrder = nextOrder(),
        }, page)
        round(card, 8)
        outline(card, THEME.border)
        padding(card, 3, 0, 3, 0)
        listLayout(card, 0)
        return card
    end

    local function makeRow(parent, height)
        local count = parent:GetAttribute("rowCount") or 0
        parent:SetAttribute("rowCount", count + 1)
        local row = create("Frame", {
            Size = UDim2.new(1, 0, 0, height or 34),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            LayoutOrder = nextOrder(),
        }, parent)
        if count > 0 then
            create("Frame", {
                Size = UDim2.new(1, -24, 0, 1),
                Position = UDim2.fromOffset(12, 0),
                BackgroundColor3 = THEME.border,
                BorderSizePixel = 0,
            }, row)
        end
        return row
    end

    local function addToggle(parent, text, key, onChange)
        local row = makeRow(parent, 34)
        textLabel(row, {Size = UDim2.new(1, -70, 1, 0), Position = UDim2.fromOffset(12, 0), Text = text})
        local track = create("TextButton", {
            Text = "",
            AutoButtonColor = false,
            Size = UDim2.fromOffset(34, 18),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -12, 0.5, 0),
            BackgroundColor3 = THEME.off,
            BorderSizePixel = 0,
        }, row)
        round(track, 9)
        local knob = create("Frame", {
            Size = UDim2.fromOffset(12, 12),
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 3, 0.5, 0),
            BackgroundColor3 = THEME.knobOff,
            BorderSizePixel = 0,
        }, track)
        round(knob, 6)

        local function render(animate)
            local on = botSettings[key] == true
            local trackGoal = {BackgroundColor3 = on and THEME.accent or THEME.off}
            local knobGoal = {
                Position = UDim2.new(0, on and 19 or 3, 0.5, 0),
                BackgroundColor3 = on and Color3.new(1, 1, 1) or THEME.knobOff,
            }
            if animate then
                tween(track, trackGoal)
                tween(knob, knobGoal)
            else
                for k, v in pairs(trackGoal) do track[k] = v end
                for k, v in pairs(knobGoal) do knob[k] = v end
            end
        end

        listen(track.MouseButton1Click, function()
            botSettings[key] = not botSettings[key]
            saveSettings()
            render(true)
            if onChange then onChange(botSettings[key]) end
        end)
        render(false)
        return {row = row, render = render}
    end

    local function addCheckbox(parent, text, key)
        local row = makeRow(parent, 32)
        local box = create("TextButton", {
            Text = "",
            AutoButtonColor = false,
            Size = UDim2.fromOffset(16, 16),
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 12, 0.5, 0),
            BackgroundColor3 = THEME.bg,
            BorderSizePixel = 0,
        }, row)
        round(box, 4)
        local boxStroke = outline(box, THEME.borderStrong)
        local short = create("Frame", {
            Size = UDim2.fromOffset(2, 5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromOffset(4.7, 9.2),
            Rotation = -45,
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
        }, box)
        local long = create("Frame", {
            Size = UDim2.fromOffset(2, 9),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromOffset(9.7, 7.8),
            Rotation = 45,
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
        }, box)
        textLabel(row, {Size = UDim2.new(1, -44, 1, 0), Position = UDim2.fromOffset(36, 0), Text = text})

        local function render()
            local on = botSettings[key] == true
            box.BackgroundColor3 = on and THEME.accent or THEME.bg
            boxStroke.Color = on and THEME.accent or THEME.borderStrong
            short.Visible = on
            long.Visible = on
        end
        listen(box.MouseButton1Click, function()
            botSettings[key] = not botSettings[key]
            saveSettings()
            render()
        end)
        render()
        return {row = row}
    end

    local function addDropdown(parent, text, key, options, onChange)
        local container = makeRow(parent, 34)
        container.AutomaticSize = Enum.AutomaticSize.Y
        local bottomPad = create("UIPadding", {PaddingBottom = UDim.new(0, 0)}, container)

        local header = create("Frame", {
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, container)
        textLabel(header, {Size = UDim2.new(1, -190, 1, 0), Position = UDim2.fromOffset(12, 0), Text = text})

        local button = create("TextButton", {
            Text = "",
            AutoButtonColor = false,
            Size = UDim2.fromOffset(162, 24),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -12, 0.5, 0),
            BackgroundColor3 = THEME.panel,
            BorderSizePixel = 0,
            Font = FONT,
            TextSize = 12,
            TextColor3 = THEME.text,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, header)
        round(button, 5)
        local buttonStroke = outline(button, THEME.border)

        local list = create("Frame", {
            Position = UDim2.fromOffset(12, 36),
            Size = UDim2.new(1, -24, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = THEME.panel,
            BorderSizePixel = 0,
            Visible = false,
        }, container)
        round(list, 6)
        outline(list, THEME.border)
        padding(list, 3, 3, 3, 3)
        listLayout(list, 2)

        local optionButtons = {}
        local function refresh()
            button.Text = "  " .. tostring(botSettings[key])
            for name, b in pairs(optionButtons) do
                local selected = (name == botSettings[key])
                b.TextColor3 = selected and THEME.accent or THEME.text
                b.BackgroundTransparency = selected and 0 or 1
            end
        end
        local function setOpen(open)
            list.Visible = open
            bottomPad.PaddingBottom = UDim.new(0, open and 8 or 0)
            buttonStroke.Color = open and THEME.accent or THEME.border
        end

        for i, name in ipairs(options) do
            local ob = create("TextButton", {
                Size = UDim2.new(1, 0, 0, 26),
                AutoButtonColor = false,
                Text = "  " .. name,
                Font = FONT,
                TextSize = 12,
                TextColor3 = THEME.text,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundColor3 = THEME.hover,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                LayoutOrder = i,
            }, list)
            round(ob, 4)
            optionButtons[name] = ob
            listen(ob.MouseButton1Click, function()
                botSettings[key] = name
                saveSettings()
                refresh()
                setOpen(false)
                if onChange then onChange(name) end
            end)
        end

        listen(button.MouseButton1Click, function()
            setOpen(not list.Visible)
        end)
        refresh()
        return {row = container}
    end

    local function addSlider(parent, text, key, step, fmt, onChange)
        local range = NUM_RANGES[key]
        local minV, maxV = range[1], range[2]
        local row = makeRow(parent, 48)
        textLabel(row, {Size = UDim2.new(1, -110, 0, 22), Position = UDim2.fromOffset(12, 5), Text = text})
        local valueLbl = textLabel(row, {
            Size = UDim2.fromOffset(96, 22),
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -12, 0, 5),
            TextXAlignment = Enum.TextXAlignment.Right,
            TextColor3 = THEME.muted,
            Text = "",
        })
        local track = create("Frame", {
            Size = UDim2.new(1, -24, 0, 4),
            Position = UDim2.fromOffset(12, 34),
            BackgroundColor3 = THEME.off,
            BorderSizePixel = 0,
        }, row)
        round(track, 2)
        local fill = create("Frame", {
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = THEME.accent,
            BorderSizePixel = 0,
        }, track)
        round(fill, 2)
        local knob = create("Frame", {
            Size = UDim2.fromOffset(12, 12),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
        }, track)
        round(knob, 6)
        local hit = create("TextButton", {
            Text = "",
            AutoButtonColor = false,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -16, 0, 26),
            Position = UDim2.fromOffset(8, 24),
            BorderSizePixel = 0,
        }, row)

        local function render()
            local v = botSettings[key]
            local rel = (v - minV) / (maxV - minV)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, 0, 0.5, 0)
            valueLbl.Text = fmt and string.format(fmt, v) or tostring(v)
        end

        local sliding = false
        local function setFromX(x)
            local rel = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
            local v = minV + (maxV - minV) * rel
            v = math.floor(v / step + 0.5) * step
            v = math.clamp(tonumber(string.format("%.3f", v)), minV, maxV)
            if v ~= botSettings[key] then
                botSettings[key] = v
                render()
                if onChange then onChange(v) end
            end
        end

        listen(hit.InputBegan, function(input)
            if isPress(input) then
                sliding = true
                setFromX(input.Position.X)
            end
        end)
        listen(UserInputService.InputChanged, function(input)
            if sliding and isMove(input) then
                setFromX(input.Position.X)
            end
        end)
        listen(UserInputService.InputEnded, function(input)
            if sliding and isPress(input) then
                sliding = false
                saveSettings()
            end
        end)
        render()
        return {row = row}
    end

    local function addButton(parent, text, onClick, danger)
        local row = makeRow(parent, 40)
        local btn = create("TextButton", {
            Text = text,
            Font = FONT,
            TextSize = 12,
            TextColor3 = danger and THEME.bad or THEME.text,
            AutoButtonColor = false,
            BackgroundColor3 = THEME.panel,
            Size = UDim2.new(1, -24, 0, 26),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BorderSizePixel = 0,
        }, row)
        round(btn, 5)
        outline(btn, danger and Color3.fromRGB(92, 42, 46) or THEME.border)
        listen(btn.MouseEnter, function() tween(btn, {BackgroundColor3 = THEME.hover}) end)
        listen(btn.MouseLeave, function() tween(btn, {BackgroundColor3 = THEME.panel}) end)
        listen(btn.MouseButton1Click, onClick)
        return btn
    end

    local function addKeybind(parent, text)
        local row = makeRow(parent, 34)
        textLabel(row, {Size = UDim2.new(1, -190, 1, 0), Position = UDim2.fromOffset(12, 0), Text = text})
        local button = create("TextButton", {
            Text = "",
            AutoButtonColor = false,
            Size = UDim2.fromOffset(162, 24),
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -12, 0.5, 0),
            BackgroundColor3 = THEME.panel,
            BorderSizePixel = 0,
            Font = FONT,
            TextSize = 12,
            TextColor3 = THEME.text,
        }, row)
        round(button, 5)
        local buttonStroke = outline(button, THEME.border)

        local listening = false
        local function refresh()
            button.Text = listening and "Press a key..." or botSettings.uiKey
            buttonStroke.Color = listening and THEME.accent or THEME.border
        end
        listen(button.MouseButton1Click, function()
            listening = true
            refresh()
        end)
        listen(UserInputService.InputBegan, function(input, processed)
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            if listening then
                listening = false
                if input.KeyCode ~= Enum.KeyCode.Escape and input.KeyCode ~= Enum.KeyCode.Unknown then
                    botSettings.uiKey = input.KeyCode.Name
                    saveSettings()
                end
                refresh()
                return
            end
            if processed then return end
            local ok, key = pcall(function() return Enum.KeyCode[botSettings.uiKey] end)
            if ok and key and input.KeyCode == key then
                window.Visible = not window.Visible
            end
        end)
        refresh()
        return {row = row}
    end

    local controlPage = addPage("Control", 1)
    local rolesPage = addPage("Roles", 2)
    local coinsPage = addPage("Coins", 3)
    local tuningPage = addPage("Tuning", 4)
    local visualsPage = addPage("Visuals", 5)
    local serverPage = addPage("Server", 6)
    local settingsPage = addPage("Settings", 7)

    local statusCard = section(controlPage, "Status")
    local function statusRow(text, color)
        local lbl = textLabel(statusCard, {
            Size = UDim2.new(1, 0, 0, 22),
            Text = text,
            TextColor3 = color or THEME.text,
            LayoutOrder = nextOrder(),
        })
        padding(lbl, 0, 0, 0, 12)
        return lbl
    end
    ui.statusLbl = statusRow("State: Running", THEME.text)
    ui.roleLbl = statusRow("Role: Innocent", THEME.accent)
    ui.murderLbl = statusRow("Murderer: Unknown", THEME.muted)
    ui.mapVoteStatusLbl = statusRow("Map Vote: Idle", THEME.muted)
    ui.bagLbl = statusRow("Bag: Not full", THEME.muted)

    local behaviorCard = section(controlPage, "Behavior")
    addToggle(behaviorCard, "Bot enabled", "botEnabled", function(v) setBotEnabled(v) end)
    addToggle(behaviorCard, "Auto vote map", "autoVoteMap")
    addToggle(behaviorCard, "Auto jump", "autoJump")

    local logCard = section(controlPage, "Event log")
    local logHolder = makeRow(logCard, 150)
    local logScroller = create("ScrollingFrame", {
        Size = UDim2.new(1, -16, 1, -12),
        Position = UDim2.fromOffset(8, 6),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = THEME.borderStrong,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, logHolder)
    listLayout(logScroller, 2)

    local logCount = 0
    function ui.addLog(msg, color)
        logCount = logCount + 1
        textLabel(logScroller, {
            Size = UDim2.new(1, -6, 0, 14),
            Text = "[" .. os.date("%H:%M:%S") .. "] " .. tostring(msg),
            TextColor3 = color or THEME.muted,
            Font = Enum.Font.Code,
            TextSize = 11,
            TextTruncate = Enum.TextTruncate.AtEnd,
            LayoutOrder = logCount,
        })
        if logCount > 80 then
            local oldest = nil
            for _, c in ipairs(logScroller:GetChildren()) do
                if c:IsA("TextLabel") and (not oldest or c.LayoutOrder < oldest.LayoutOrder) then
                    oldest = c
                end
            end
            if oldest then oldest:Destroy() end
        end
        task.defer(function()
            pcall(function()
                logScroller.CanvasPosition = Vector2.new(0, logScroller.AbsoluteCanvasSize.Y)
            end)
        end)
    end

    local innCard = section(rolesPage, "Innocent (no weapon)")
    addDropdown(innCard, "Play style", "innocentMode", CHOICES.basicMode)
    addToggle(innCard, "Pick up dropped gun", "pickupGun")
    local innStand
    addDropdown(innCard, "When bag is full", "innocentBagFull", CHOICES.bagBasic, function(v)
        innStand.row.Visible = (v == "Stand")
    end)
    innStand = addCheckbox(innCard, "Run from murderer", "innocentStandRun")
    innStand.row.Visible = (botSettings.innocentBagFull == "Stand")

    local shCard = section(rolesPage, "Sheriff / Survivor (holds a gun)")
    addDropdown(shCard, "Play style", "sheriffMode", CHOICES.basicMode)
    addToggle(shCard, "Shoot murderer on sight", "sheriffShoot")
    addSlider(shCard, "Aim time before shot", "aimDelay", 0.05, "%.2f s")
    addSlider(shCard, "Shoot range", "sheriffRange", 5, "%.0f studs")
    addSlider(shCard, "Keep distance from murderer", "sheriffKeepDist", 1, "%.0f studs")
    local shStand
    addDropdown(shCard, "When bag is full", "sheriffBagFull", CHOICES.bagBasic, function(v)
        shStand.row.Visible = (v == "Stand")
    end)
    shStand = addCheckbox(shCard, "Run from murderer", "sheriffStandRun")
    shStand.row.Visible = (botSettings.sheriffBagFull == "Stand")

    local muCard = section(rolesPage, "Murderer / Zombie (holds a knife)")
    addDropdown(muCard, "Play style", "murdererMode", CHOICES.murdererMode)
    addDropdown(muCard, "Target priority", "huntPriority", CHOICES.huntPriority)
    addToggle(muCard, "Throw knife", "throwKnife")
    addSlider(muCard, "Engage range", "engageRange", 1, "%.0f studs")
    addSlider(muCard, "Stab range", "stabRange", 1, "%.0f studs")
    addDropdown(muCard, "When bag is full", "murdererBagFull", CHOICES.bagMurderer)

    local planCard = section(coinsPage, "Routing")
    addToggle(planCard, "Plan next coin ahead", "planAhead")
    addToggle(planCard, "Skip coins near murderer", "avoidMurdererCoins")
    addSlider(planCard, "Max coin distance", "maxCoinDist", 50, "%.0f studs")
    addSlider(planCard, "Compare walking paths of nearest coins", "pathCandidates", 1, "%.0f")
    local nearCard = section(coinsPage, "Nearby coins")
    addToggle(nearCard, "Grab coins that appear near me", "grabNearby")
    addSlider(nearCard, "Nearby coin radius", "nearbyRadius", 1, "%.0f studs")

    local awareCard = section(tuningPage, "Awareness")
    addSlider(awareCard, "Murderer detection range", "detectRange", 5, "%.0f studs")
    addSlider(awareCard, "Evade distance", "evadeDistance", 1, "%.0f studs")
    addSlider(awareCard, "Chase memory after losing sight", "huntMemory", 1, "%.0f s")
    local moveCard = section(tuningPage, "Movement")
    addSlider(moveCard, "Wander radius", "wanderRadius", 5, "%.0f studs")
    addSlider(moveCard, "Give up if not getting closer", "giveUpTime", 1, "%.0f s")

    local visCard = section(visualsPage, "Overlays")
    addToggle(visCard, "Player ESP", "playerEsp")
    addToggle(visCard, "Coin ESP", "coinEsp")
    addToggle(visCard, "Gun ESP", "gunEsp")
    addToggle(visCard, "Path ESP", "pathEsp", function(v)
        if not v then clearRoute() end
    end)
    addToggle(visCard, "Debug rays", "debugRays", function(v)
        if not v then debugFolder:ClearAllChildren() end
    end)

    local hopCard = section(serverPage, "Server hop")
    addDropdown(hopCard, "Hop method", "hopMethod", CHOICES.hopMethod)
    addToggle(hopCard, "Hop for players", "hopForPlayers")
    addSlider(hopCard, "Min players", "hopTargetMin", 1, "%.0f")
    addSlider(hopCard, "Max players", "hopTargetMax", 1, "%.0f")
    addToggle(hopCard, "Hop if alone", "hopIfAlone")
    addToggle(hopCard, "Hop on high ping", "autoHopPing")
    addSlider(hopCard, "Ping limit", "hopPingLimit", 25, "%.0f ms")
    addButton(hopCard, "Hop now", function() performServerHop() end, false)

    local uiCard = section(settingsPage, "Interface")
    addKeybind(uiCard, "Show / hide key")
    addToggle(uiCard, "Hide UI on load", "hideOnLoad")
    addSlider(uiCard, "UI scale", "uiScale", 0.05, "%.2fx", function(v) applyScale(v) end)
    local scriptCard = section(settingsPage, "Script")
    addButton(scriptCard, "Unload script", function() fullUnload() end, true)

    selectTab("Control")
    if botSettings.hideOnLoad then
        window.Visible = false
    end
    return ui
end

local UI = buildUI()
local statusLbl = UI.statusLbl
local roleLbl = UI.roleLbl
local murderLbl = UI.murderLbl
local mapVoteStatusLbl = UI.mapVoteStatusLbl
local bagLbl = UI.bagLbl
local addLog = UI.addLog

addLog("Script " .. VERSION .. " initialized and active.", THEME.good)

local heartbeatConnection = nil
local serverHopThread = nil

local antiAfkThread = task.spawn(function()
    while task.wait(300) do
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            addLog("Anti-AFK: Simulating spacebar press.", THEME.warn)
        end)
    end
end)

function setBotEnabled(state)
    enabled = state
    running = state
    botSettings.botEnabled = state
    saveSettings()
    UI.setBadge(state)

    if state then
        statusLbl.Text = "State: Running"
        unreachableCoins = {}
        knownMurderer = nil
        knownSheriff = nil
        suspectList = {}
        myRole = "Innocent"
        myWeapon = nil
        S.roundActionDone = false
        S.aimStart = nil
        clearRoute()
        chaseRoute = nil
        wanderRoute = nil
        wanderRouteIndex = 1
        noPathTimer = 0
        isWandering = false
        addLog("Bot started.", THEME.good)
    else
        statusLbl.Text = "State: Idle"
        roleLbl.Text = "Role: Innocent"
        murderLbl.Text = "Murderer: Unknown"
        mapVoteStatusLbl.Text = "Map Vote: Idle"
        clearRoute()
        chaseRoute = nil
        wanderRoute = nil
        wanderRouteIndex = 1
        restoreCameraMode()
        noPathTimer = 0
        isWandering = false
        addLog("Bot stopped.", THEME.bad)
    end
end

function fullUnload()
    enabled = false
    running = false
    S.hopCancel = true
    if heartbeatConnection then pcall(function() heartbeatConnection:Disconnect() end) end
    if serverHopThread then pcall(function() task.cancel(serverHopThread) end) end
    if antiAfkThread then pcall(function() task.cancel(antiAfkThread) end) end

    restoreCameraMode()

    for _, c in ipairs(S.uiConns) do
        pcall(function() c:Disconnect() end)
    end
    S.uiConns = {}

    pcall(function() if UI.gui then UI.gui:Destroy() end end)

    pcall(function()
        if visFolder then visFolder:Destroy() end
        if debugFolder then debugFolder:Destroy() end
    end)

    pcall(function()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name == "PlayerESP" or obj.Name == "DroppedGunESP" or obj.Name == "BotMarker" or obj.Name == "UpcomingMarker" then
                obj:Destroy()
            end
        end
    end)
    pcall(function() script:Destroy() end)
end

local VISITED_FILE = "MM2VisitedServers.json"
local HOP_HOSTS = {"games.roblox.com", "games.roproxy.com"}

local function httpGetRaw(url)
    local lastErr = "no HTTP function available"

    local function getRequestFn()
        if typeof(request) == "function" then return request end
        if typeof(http_request) == "function" then return http_request end
        if typeof(syn) == "table" and typeof(syn.request) == "function" then return syn.request end
        return nil
    end

    local attempts = {
        function() return game:HttpGet(url) end,
        function() return game:HttpGet(url, true) end,
        function()
            local req = getRequestFn()
            if not req then error("no request function") end
            local res = req({Url = url, Method = "GET", Headers = {["Accept"] = "application/json"}})
            if type(res) ~= "table" then error("bad response") end
            if res.StatusCode and res.StatusCode ~= 200 then
                error("HTTP " .. tostring(res.StatusCode) .. " " .. tostring(res.StatusMessage or ""))
            end
            return res.Body
        end,
    }

    for _, attempt in ipairs(attempts) do
        local ok, result = pcall(attempt)
        if ok and type(result) == "string" and #result > 0 then
            return result, nil
        end
        if not ok then lastErr = tostring(result) end
    end
    return nil, lastErr
end

local function fetchServers(host, cursor)
    local url = "https://" .. host .. "/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&excludeFullGames=true&limit=100"
    if cursor ~= "" then
        url = url .. "&cursor=" .. cursor
    end

    local body, err = httpGetRaw(url)
    if not body then return nil, err end

    local ok, decoded = pcall(function() return HttpService:JSONDecode(body) end)
    if not ok or type(decoded) ~= "table" then
        return nil, "unreadable response: " .. string.sub(body, 1, 60)
    end
    if type(decoded.data) ~= "table" then
        local first = type(decoded.errors) == "table" and decoded.errors[1]
        local msg = type(first) == "table" and first.message or string.sub(body, 1, 60)
        return nil, tostring(msg)
    end
    return decoded, nil
end

local function loadVisited()
    local bucket = math.floor(os.time() / 3600)
    local data = {bucket = bucket, ids = {}}
    if isfile and readfile and isfile(VISITED_FILE) then
        local ok, decoded = pcall(function() return HttpService:JSONDecode(readfile(VISITED_FILE)) end)
        if ok and type(decoded) == "table" and decoded.bucket == bucket and type(decoded.ids) == "table" then
            data = decoded
        end
    end
    return data
end

local function saveVisited(data)
    if writefile then
        while #data.ids > 400 do table.remove(data.ids, 1) end
        pcall(function() writefile(VISITED_FILE, HttpService:JSONEncode(data)) end)
    end
end

local function hopViaMM2()
    pcall(function()
        local teleportEvent = ReplicatedStorage:FindFirstChild("Remotes")
            and ReplicatedStorage.Remotes:FindFirstChild("Extras")
            and ReplicatedStorage.Remotes.Extras:FindFirstChild("RequestTeleport")

        if teleportEvent then
            teleportEvent:InvokeServer("Standard")
        else
            TeleportService:Teleport(game.PlaceId, player)
        end
    end)
end

local function hopPublicServers()
    if S.hopping then return end
    S.hopping = true
    S.hopCancel = false

    task.spawn(function()
        local minPlayers = math.min(botSettings.hopTargetMin, botSettings.hopTargetMax)
        local maxPlayers = math.max(botSettings.hopTargetMin, botSettings.hopTargetMax)

        local visited = loadVisited()
        local seen = {}
        for _, id in ipairs(visited.ids) do seen[id] = true end
        seen[game.JobId] = true

        local failedTeleport = false
        local failConn = TeleportService.TeleportInitFailed:Connect(function()
            failedTeleport = true
        end)

        local cursor = ""
        local failures = 0
        local totalFailures = 0
        local cycles = 0
        local hostIndex = 1
        local fellBack = false

        while not S.hopCancel and totalFailures < 12 and cycles < 3 do
            local host = HOP_HOSTS[hostIndex]
            local data, err = fetchServers(host, cursor)

            if not data then
                failures = failures + 1
                totalFailures = totalFailures + 1
                addLog("Server list failed (" .. host .. "): " .. string.sub(tostring(err), 1, 70), THEME.warn)

                hostIndex = (hostIndex % #HOP_HOSTS) + 1
                cursor = ""

                if failures >= 4 then
                    addLog("Server list unavailable, using the MM2 hop instead.", THEME.warn)
                    hopViaMM2()
                    fellBack = true
                    break
                end

                local waitTime = 4
                local lowered = string.lower(tostring(err))
                if string.find(lowered, "429", 1, true) or string.find(lowered, "too many", 1, true) then
                    waitTime = 12
                end
                task.wait(waitTime)
            else
                failures = 0

                local candidates = {}
                for _, srv in ipairs(data.data) do
                    local id = tostring(srv.id)
                    local playing = tonumber(srv.playing) or 0
                    local capacity = tonumber(srv.maxPlayers) or 0
                    if not seen[id] and playing >= minPlayers and playing <= maxPlayers and playing < capacity then
                        table.insert(candidates, srv)
                    end
                end

                for i = #candidates, 2, -1 do
                    local j = math.random(i)
                    candidates[i], candidates[j] = candidates[j], candidates[i]
                end

                for _, srv in ipairs(candidates) do
                    if S.hopCancel then break end
                    local id = tostring(srv.id)
                    seen[id] = true
                    table.insert(visited.ids, id)
                    saveVisited(visited)

                    failedTeleport = false
                    addLog("Joining server with " .. tostring(srv.playing) .. " players...", THEME.warn)
                    pcall(function()
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, id, player)
                    end)

                    local started = os.clock()
                    while os.clock() - started < 5 and not failedTeleport and not S.hopCancel do
                        task.wait(0.25)
                    end
                    if not S.hopCancel then
                        addLog("Still in this server, trying the next one...", THEME.warn)
                    end
                end

                local nextCursor = data.nextPageCursor
                if type(nextCursor) == "string" and nextCursor ~= "" then
                    cursor = nextCursor
                else
                    cursor = ""
                    cycles = cycles + 1
                    task.wait(5)
                end
            end
        end

        pcall(function() failConn:Disconnect() end)
        if not S.hopCancel and not fellBack then
            addLog("No server with " .. minPlayers .. "-" .. maxPlayers .. " players found. Try again later.", THEME.bad)
        end
        S.hopping = false
    end)
end

function performServerHop()
    statusLbl.Text = "State: Hopping Servers..."
    addLog("Requesting server hop (" .. botSettings.hopMethod .. ")...", THEME.warn)

    if botSettings.hopMethod == "Public servers" then
        hopPublicServers()
        return
    end

    hopViaMM2()
end

local highPingTimer = 0

serverHopThread = task.spawn(function()
    task.wait(8)
    while task.wait(1) do
        if not botSettings.botEnabled or not enabled then
            highPingTimer = 0
            continue
        end

        if S.hopping then
            continue
        end

        local shouldHop = false

        local playerCount = #Players:GetPlayers()
        if botSettings.hopIfAlone and playerCount <= 1 then
            shouldHop = true
            addLog("Alone in the server", THEME.warn)
        elseif botSettings.hopForPlayers then
            local lo = math.min(botSettings.hopTargetMin, botSettings.hopTargetMax)
            local hi = math.max(botSettings.hopTargetMin, botSettings.hopTargetMax)
            if playerCount < lo or playerCount > hi then
                shouldHop = true
                addLog("Server has " .. playerCount .. " players, wanted " .. lo .. "-" .. hi, THEME.warn)
            end
        end

        if botSettings.autoHopPing then
            local pingItem = Stats.Network.ServerStatsItem:FindFirstChild("Data Ping")
            local pingVal = pingItem and pingItem:GetValue()

            if pingVal and pingVal > botSettings.hopPingLimit then
                highPingTimer = highPingTimer + 1
                if highPingTimer >= 5 then
                    shouldHop = true
                    addLog("High network latency (> " .. botSettings.hopPingLimit .. "ms for 5s)", THEME.warn)
                    highPingTimer = 0
                end
            else
                highPingTimer = 0
            end
        else
            highPingTimer = 0
        end

        if shouldHop and not S.hopping then
            performServerHop()
            task.wait(8)
        end
    end
end)

local function getLobbyFolder()
    local regLobby = workspace:FindFirstChild("RegularLobby")
    if regLobby then return regLobby end
    local lobby = workspace:FindFirstChild("Lobby")
    if lobby then return lobby end
    return nil
end

local function getObjectPosition(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then
        return obj.Position
    elseif obj:IsA("Model") then
        local pivot = pcall(function() return obj:GetPivot() end)
        if pivot then
            return obj:GetPivot().Position
        end
        if obj.PrimaryPart then
            return obj.PrimaryPart.Position
        end
        local part = obj:FindFirstChildWhichIsA("BasePart", true)
        if part then return part.Position end
    else
        local part = obj:FindFirstChildWhichIsA("BasePart", true)
        if part then return part.Position end
    end
    return nil
end

local function getMapNameFromPad(pad)
    if not pad then return nil end
    for _, descendant in ipairs(pad:GetDescendants()) do
        if descendant:IsA("TextLabel") then
            local text = descendant.Text
            if text and text ~= "" and text ~= "None" and not text:find("Waiting") and not text:find("Votes") and #text > 2 then
                return text
            end
        end
    end
    return nil
end

local function findBestVoteMap()
    local lobby = getLobbyFolder()
    local searchScope = lobby or workspace

    local pads = {}
    for i = 1, 3 do
        local pad = searchScope:FindFirstChild("VotePad" .. i, true)
            or searchScope:FindFirstChild("Pad" .. i, true)
            or (i == 1 and searchScope:FindFirstChild("VotePad", true))
        if pad then
            table.insert(pads, {index = i, pad = pad})
        end
    end

    if #pads == 0 then
        local votePadsFolder = searchScope:FindFirstChild("VotePads", true)
        if votePadsFolder then
            for _, child in ipairs(votePadsFolder:GetChildren()) do
                table.insert(pads, {index = #pads + 1, pad = child})
            end
        end
    end

    local detected = {}
    for _, entry in ipairs(pads) do
        local mapName = getMapNameFromPad(entry.pad)
        if mapName and mapName ~= "" and mapName ~= "None" and not mapName:find("Waiting") then
            table.insert(detected, {padObj = entry.pad, name = mapName})
        end
    end

    if #detected == 0 then
        return nil, nil, 99
    end

    local bestPadObj = nil
    local bestName = nil
    local bestPriorityIndex = math.huge

    for _, entry in ipairs(detected) do
        local lowerDetected = entry.name:lower()
        for prioIdx, prioName in ipairs(MAP_PRIORITIES) do
            local lowerPrio = prioName:lower()
            if lowerDetected:find(lowerPrio, 1, true) or (lowerPrio == "mil base" and lowerDetected:find("military")) then
                if prioIdx < bestPriorityIndex then
                    bestPriorityIndex = prioIdx
                    bestPadObj = entry.padObj
                    bestName = entry.name
                end
            end
        end
    end

    if not bestPadObj and #detected > 0 then
        bestPadObj = detected[1].padObj
        bestName = detected[1].name
        bestPriorityIndex = 99
    end

    return bestPadObj, bestName, bestPriorityIndex
end

local function findBestVoteMapCached()
    local now = os.clock()
    if S.voteCache and now - S.voteCacheT < 0.5 then
        local c = S.voteCache
        if not c.pad or c.pad.Parent then
            return c.pad, c.name, c.prio
        end
    end
    local pad, name, prio = findBestVoteMap()
    S.voteCache = {pad = pad, name = name, prio = prio}
    S.voteCacheT = now
    return pad, name, prio
end

local function isCoin(obj)
    if not obj then return false end
    local name = obj.Name:lower()
    return name:find("coin") or name == "coin_server" or name == "gold"
end

local function getCoinContainer()
    local c = S.coinContainer
    if c and c.Parent then return c end
    S.coinContainer = nil
    local now = os.clock()
    if now - S.coinContainerCheck >= 1 then
        S.coinContainerCheck = now
        S.coinContainer = workspace:FindFirstChild("CoinContainer", true)
    end
    return S.coinContainer
end

local function getCoins()
    local now = os.clock()
    local container = getCoinContainer()
    local interval = container and 0.3 or 1.5
    if now - S.coinListT >= interval then
        S.coinListT = now
        local list = {}
        for _, item in ipairs((container or workspace):GetDescendants()) do
            if isCoin(item) and item:IsA("PVInstance") then
                list[#list + 1] = item
            end
        end
        S.coinList = list
    end
    return S.coinList
end

local function getGunDropInstance()
    local g = S.gunDrop
    if g and g.Parent then return g end
    S.gunDrop = nil
    local now = os.clock()
    if now - S.gunDropCheck >= 0.5 then
        S.gunDropCheck = now
        S.gunDrop = workspace:FindFirstChild("GunDrop", true)
    end
    return S.gunDrop
end

local function findRemote(cacheKey, name)
    local cached = S[cacheKey]
    if cached and cached.Parent then return cached end
    S[cacheKey] = nil
    local now = os.clock()
    if now - (S[cacheKey .. "T"] or 0) < 2 then return nil end
    S[cacheKey .. "T"] = now
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v.Name == name and (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) then
            S[cacheKey] = v
            return v
        end
    end
    return nil
end

local function getShootRemote()
    return findRemote("shootRemote", "Shoot")
end

local function getThrowRemote()
    return findRemote("throwRemote", "KnifeThrown")
end

local function blacklistInstance(inst, seconds)
    S.blacklist[inst] = os.clock() + seconds
end

local function isBlacklisted(inst)
    local t = S.blacklist[inst]
    if not t then return false end
    if os.clock() >= t then
        S.blacklist[inst] = nil
        return false
    end
    return true
end

local function groundBelow(pos)
    local ignore = {visFolder, debugFolder}
    if player.Character then table.insert(ignore, player.Character) end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignore
    local hit = workspace:Raycast(pos, Vector3.new(0, -40, 0), params)
    if hit and (pos.Y - hit.Position.Y) > 3.5 then
        return hit.Position + Vector3.new(0, 1.5, 0), pos.Y - hit.Position.Y
    end
    return pos, 0
end

local wallParams = RaycastParams.new()
wallParams.FilterType = Enum.RaycastFilterType.Exclude
wallParams.RespectCanCollide = true

local function isBlockedByWall(fromPos, toPos)
    local ignore = {visFolder, debugFolder}
    if player.Character then table.insert(ignore, player.Character) end
    wallParams.FilterDescendantsInstances = ignore
    local hit = workspace:Raycast(fromPos, toPos - fromPos, wallParams)
    if not hit then return false end
    local inst = hit.Instance
    if isCoin(inst) or (inst.Parent and isCoin(inst.Parent)) then return false end
    return true
end

local function drawRoute(waypoints, customName, customColor)
    customName = customName or "PathDot"

    for _, v in ipairs(visFolder:GetChildren()) do
        if v.Name == customName then v:Destroy() end
    end

    if not botSettings.pathEsp or not waypoints then return end

    for i = 2, #waypoints do
        local wpPos = typeof(waypoints[i]) == "Vector3" and waypoints[i] or waypoints[i].Position
        local p = Instance.new("Part")
        p.Name = customName
        p.Shape, p.Material = Enum.PartType.Ball, Enum.Material.Neon
        p.CanCollide, p.CanQuery, p.Anchored = false, false, true
        p.Size = Vector3.new(0.5, 0.5, 0.5)
        p.Color = customColor or (isTargetingGun and Color3.fromRGB(0, 220, 255) or THEME.good)
        p.Position = wpPos + Vector3.new(0, 0.5, 0)
        p.Parent = visFolder
    end
end

local function drawUpcomingCoinPaths(startPos, candidateCoins)
    for _, v in ipairs(visFolder:GetChildren()) do
        if v.Name == "UpcomingPathDot" then v:Destroy() end
    end

    if not botSettings.pathEsp or #candidateCoins < 2 then return end

    local currentFrom = startPos
    local maxCoins = math.min(#candidateCoins, 3)

    for cIdx = 2, maxCoins do
        local coinObj = candidateCoins[cIdx]
        local cPos = coinObj and ((coinObj:IsA("BasePart") and coinObj.Position) or (coinObj:FindFirstChildWhichIsA("BasePart") and coinObj:FindFirstChildWhichIsA("BasePart").Position))

        if cPos then
            local dir = (cPos - currentFrom)
            local dist = dir.Magnitude
            local steps = math.floor(dist / 3)

            for i = 1, steps do
                local dotPos = currentFrom + (dir.Unit * (i * 3))
                local p = Instance.new("Part")
                p.Name = "UpcomingPathDot"
                p.Shape, p.Material = Enum.PartType.Ball, Enum.Material.Neon
                p.CanCollide, p.CanQuery, p.Anchored = false, false, true
                p.Size = Vector3.new(0.4, 0.4, 0.4)
                p.Color = Color3.fromRGB(120, 120, 120)
                p.Position = dotPos + Vector3.new(0, 0.5, 0)
                p.Parent = visFolder
            end
            currentFrom = cPos
        end
    end
end

local function drawDebugRay(origin, direction, hit, color)
    if not botSettings.debugRays then return end
    local length = direction.Magnitude
    local part = Instance.new("Part")
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.Material = Enum.Material.Neon
    part.Color = hit and Color3.fromRGB(255, 60, 60) or color
    part.Size = Vector3.new(0.1, 0.1, length)
    part.CFrame = CFrame.new(origin, origin + direction) * CFrame.new(0, 0, -length / 2)
    part.Parent = debugFolder
    Debris:AddItem(part, 0.15)
end

local function updatePlayerESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local char = p.Character
            local hl = char:FindFirstChild("PlayerESP")

            if botSettings.playerEsp then
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = "PlayerESP"
                    hl.Parent = char
                end

                if p == knownMurderer then
                    hl.FillColor = THEME.bad
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.FillTransparency = 0.2
                elseif p == knownSheriff then
                    hl.FillColor = THEME.accent
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.FillTransparency = 0.3
                elseif suspectList[p] then
                    hl.FillColor = THEME.warn
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.FillTransparency = 0.5
                else
                    hl.FillColor = Color3.fromRGB(150, 150, 150)
                    hl.OutlineColor = Color3.fromRGB(200, 200, 200)
                    hl.FillTransparency = 0.75
                end
            elseif hl then
                hl:Destroy()
            end
        end
    end
end

local function availablePosition(item)
    if not item or not item.Parent then return nil end
    if item:IsA("BasePart") and item.Transparency < 0.8 then return item.Position end
    for _, v in ipairs(item:GetDescendants()) do
        if v:IsA("BasePart") and v.Transparency < 0.8 then return v.Position end
    end
    return nil
end

local function isCoinClaimedByOthers(coinObj)
    if not coinObj or not coinObj.Parent then return true end
    local coinPos = availablePosition(coinObj)
    if not coinPos then return true end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local pRoot = p.Character:FindFirstChild("HumanoidRootPart")
            if pRoot then
                local distToCoin = (pRoot.Position - coinPos).Magnitude
                if distToCoin < 3.2 then
                    return true
                end
            end
        end
    end
    return false
end

local function updateDroppedGunESP()
    local gunDrop = getGunDropInstance()
    if gunDrop then
        local hl = gunDrop:FindFirstChild("DroppedGunESP")
        if botSettings.gunEsp then
            if not hl then
                hl = Instance.new("Highlight")
                hl.Name = "DroppedGunESP"
                hl.FillColor = Color3.fromRGB(0, 220, 255)
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.FillTransparency = 0.2
                hl.Parent = gunDrop
            end
        elseif hl then
            hl:Destroy()
        end
    end
end

local function updateCoinMarkers()
    for _, item in ipairs(getCoins()) do
        if item.Parent and item:IsA("PVInstance") then
            local marker = item:FindFirstChild("BotMarker")
            if botSettings.coinEsp and not unreachableCoins[item] then
                if not marker then
                    marker = Instance.new("BoxHandleAdornment")
                    marker.Name = "BotMarker"
                    marker.Size = Vector3.new(1.5, 1.5, 1.5)
                    marker.ZIndex = 0
                    marker.AlwaysOnTop = true
                    marker.Adornee = item
                    marker.Parent = item
                end

                if item == targetCoin then
                    marker.Color3 = Color3.fromRGB(255, 0, 0)
                    marker.Transparency = 0.2
                elseif upcomingCoins[2] == item or upcomingCoins[3] == item then
                    marker.Color3 = Color3.fromRGB(180, 180, 180)
                    marker.Transparency = 0.4
                else
                    marker.Color3 = Color3.fromRGB(255, 255, 0)
                    marker.Transparency = 0.6
                end
            elseif marker then
                marker:Destroy()
            end
        end
    end
end

local function isGun(tool)
    if not tool or not tool:IsA("Tool") then return false end
    local name = tool.Name:lower()
    if name:find("gun") or name:find("revolver") or name:find("blaster") or name:find("pistol") or name:find("rifle") or name:find("shotgun") or name:find("luger") or name:find("laser") or name:find("bow") then return true end
    if tool:FindFirstChild("GunClient") or tool:FindFirstChild("GunServer") or tool:FindFirstChild("GunScript") or tool:FindFirstChild("Shoot") then return true end
    return false
end

local function isKnife(tool)
    if not tool or not tool:IsA("Tool") then return false end
    local name = tool.Name:lower()
    if name:find("knife") or name:find("blade") or name:find("saw") or name:find("sword") or name:find("scythe") or name:find("bat") or name:find("dagger") or name:find("slicer") or name:find("fang") or name:find("axe") or name:find("sickle") or name:find("cleaver") then return true end
    if tool:FindFirstChild("KnifeClient") or tool:FindFirstChild("KnifeServer") or tool:FindFirstChild("KnifeScript") or tool:FindFirstChild("KnifeLocal") or tool:FindFirstChild("Knife") or tool:FindFirstChild("Stab") then return true end
    return false
end

local function isRoundActive()
    if myRole == "Murderer" or myRole == "Sheriff" then
        return true
    end

    local now = os.clock()
    if now - S.roundCacheT < 0.25 then
        return S.roundCacheValue
    end
    S.roundCacheT = now

    local result = false

    if getCoinContainer() then
        result = true
    elseif getGunDropInstance() then
        result = true
    else
        if now - S.roundScanT >= 2 then
            S.roundScanT = now
            S.roundScanValue = false
            for _, desc in ipairs(workspace:GetDescendants()) do
                if isCoin(desc) then
                    S.roundScanValue = true
                    break
                end
            end
        end

        if S.roundScanValue then
            result = true
        else
            local alivePlayersCount = 0
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        alivePlayersCount = alivePlayersCount + 1
                    end
                end
            end

            local lobby = getLobbyFolder()
            local inLobby = false
            local _, root = getCharacter()
            if root and lobby then
                local lobbyPos = getObjectPosition(lobby)
                if lobbyPos and (root.Position - lobbyPos).Magnitude < 150 then
                    inLobby = true
                end
            end

            if alivePlayersCount > 1 and not inLobby then
                result = true
            end
        end
    end

    S.roundCacheValue = result
    return result
end

local function getDroppedGun()
    local gunDrop = getGunDropInstance()
    if gunDrop then
        local pos = availablePosition(gunDrop)
        if pos then return gunDrop, pos end
    end
    return nil, nil
end

local function getTorso(char)
    if not char then return nil end
    return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
end

local function hasLineOfSight(origin, targetPos, ignoreChar)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local myChar = player and player.Character
    local filterList = {myChar, visFolder, debugFolder}
    if ignoreChar then
        table.insert(filterList, ignoreChar)
    end
    rayParams.FilterDescendantsInstances = filterList

    local dir = (targetPos - origin)
    local hit = workspace:Raycast(origin, dir, rayParams)

    drawDebugRay(origin, dir, hit ~= nil, Color3.fromRGB(0, 255, 255))

    if hit then
        if hit.Instance and hit.Instance:IsDescendantOf(ignoreChar) then
            return true
        end
        return false
    end
    return true
end

local knifeHolderCount = 0

local function resetTracking()
    S.knifeSeen = setmetatable({}, {__mode = "k"})
    S.huntSeen = setmetatable({}, {__mode = "k"})
end

local function scanPlayers(dt)
    if not player or not player.Parent then return end

    local previousRole = myRole
    local tools = {}

    local char = player.Character
    if char then
        for _, t in ipairs(char:GetChildren()) do table.insert(tools, t) end
    end
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, t in ipairs(backpack:GetChildren()) do table.insert(tools, t) end
    end

    local foundKnife, foundGun = false, false
    for _, tool in ipairs(tools) do
        if isKnife(tool) then foundKnife = tool end
        if isGun(tool) then foundGun = tool end
    end

    if foundKnife then
        myRole = "Murderer"
        myWeapon = foundKnife
    elseif foundGun then
        myRole = "Sheriff"
        myWeapon = foundGun
    else
        myRole = "Innocent"
        myWeapon = nil
    end

    if myRole ~= previousRole then
        roleLbl.Text = "Role: " .. myRole
        addLog("Role: " .. myRole, THEME.accent)
        clearRoute()
        chaseRoute = nil
        wanderRoute = nil
        currentlyEvading = false
        noPathTimer = 0
        isWandering = false
        if myRole ~= "Sheriff" then
            restoreCameraMode()
        end
    end

    local activeRound = isRoundActive()

    if activeRound and not lastRoundState then
        S.roundStartClock = os.clock()
        S.roundActionDone = false
        S.aimStart = nil
    end

    if lastRoundState and not activeRound then
        S.roundActionDone = false
        S.aimStart = nil
        clearRoute()
        chaseRoute = nil
        wanderRoute = nil
        currentlyEvading = false
        stuckTimer = 0
        lastJumpTime = 0
        voteRoute = nil
        voteRouteIndex = 1
        hasVotedCurrentMap = false
        isCalculatingVotePath = false
        noPathTimer = 0
        isWandering = false
        restoreCameraMode()
        addLog("Round ended: Reset internal state.", THEME.warn)
    end
    lastRoundState = activeRound

    if not activeRound then
        if next(S.knifeSeen) or next(S.huntSeen) then resetTracking() end
        knownMurderer = nil
        knownSheriff = nil
        suspectList = {}
        knifeHolderCount = 0
        murderLbl.Text = "Murderer: Waiting for Round..."
        murderLbl.TextColor3 = Color3.fromRGB(180, 180, 190)
        restoreCameraMode()
        return
    end

    knifeHolderCount = 0
    local primaryMurdererCandidate = nil
    local primaryDist = math.huge
    local _, myRootDet = getCharacter()

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p and p.Character then
            local pChar = p.Character
            local pHum = pChar:FindFirstChild("Humanoid")
            local isAlive = pHum and pHum.Health > 0
            local pRootDet = pChar:FindFirstChild("HumanoidRootPart")
            local inRange = false
            if pRootDet and myRootDet then
                inRange = (pRootDet.Position - myRootDet.Position).Magnitude <= botSettings.detectRange
            end

            if isAlive and inRange then
                for _, child in ipairs(pChar:GetChildren()) do
                    if isKnife(child) then
                        knifeHolderCount = knifeHolderCount + 1
                        S.knifeSeen[p] = true
                    elseif isGun(child) then
                        if knownSheriff ~= p then knownSheriff = p end
                    end
                end

                if S.knifeSeen[p] then
                    local dd = (pRootDet.Position - myRootDet.Position).Magnitude
                    if not primaryMurdererCandidate or dd < primaryDist then
                        primaryMurdererCandidate = p
                        primaryDist = dd
                    end
                end
            end
        end
    end

    if primaryMurdererCandidate then
        if knownMurderer ~= primaryMurdererCandidate then
            knownMurderer = primaryMurdererCandidate
            addLog("Murderer confirmed: " .. primaryMurdererCandidate.Name .. (knifeHolderCount > 1 and " (multiple knives)" or ""), THEME.bad)
        end
    else
        knownMurderer = nil
    end

    if knownMurderer then
        murderLbl.Text = "Murderer: " .. knownMurderer.Name .. (knifeHolderCount > 1 and " [Multi-Knife]" or " (CONFIRMED)")
        murderLbl.TextColor3 = THEME.bad
    else
        murderLbl.Text = "Murderer: Unknown"
        murderLbl.TextColor3 = Color3.fromRGB(180, 180, 190)
    end
end

local function checkLadderInFront(root)
    local char = player and player.Character
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {char, visFolder, debugFolder}

    local lookDir = root.CFrame.LookVector * 2.8
    local origin = root.Position
    local hit = workspace:Raycast(origin, lookDir, rayParams)

    drawDebugRay(origin, lookDir, hit ~= nil, Color3.fromRGB(255, 180, 0))

    if hit and hit.Instance then
        local inst = hit.Instance
        local name = inst.Name:lower()
        if inst:IsA("TrussPart") or name:find("ladder") or name:find("truss") or name:find("climb") then
            return true, hit.Instance
        end
    end
    return false, nil
end

local function shouldJump(hum, root)
    if not botSettings.autoJump then return false end
    if hum:GetState() == Enum.HumanoidStateType.Jumping or hum:GetState() == Enum.HumanoidStateType.Freefall then return false end
    if os.clock() - lastJumpTime < 0.55 then return false end

    if targetCoin and route and routeIndex >= #route - 1 then
        local coinPos = availablePosition(targetCoin)
        if coinPos and (root.Position - coinPos).Magnitude < 4.5 then
            return false
        end
    end

    local isLadder, _ = checkLadderInFront(root)
    if isLadder or hum:GetState() == Enum.HumanoidStateType.Climbing then
        return false
    end

    local vel = root.AssemblyLinearVelocity
    local flatVel = Vector3.new(vel.X, 0, vel.Z)
    local moveDir

    if flatVel.Magnitude > 0.5 then
        moveDir = flatVel.Unit
    elseif hum.MoveDirection.Magnitude > 0.1 then
        moveDir = hum.MoveDirection.Unit
    else
        return false
    end

    local char = player and player.Character
    local feetY = root.Position.Y - (hum.HipHeight + (root.Size.Y / 2))
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {char, visFolder, debugFolder}

    local direction = moveDir * 4
    local lowOrigin = Vector3.new(root.Position.X, feetY + 1.2, root.Position.Z)
    local highOrigin = Vector3.new(root.Position.X, feetY + 5.2, root.Position.Z)

    local lowHit = workspace:Raycast(lowOrigin, direction, rayParams)
    local highHit = workspace:Raycast(highOrigin, direction, rayParams)

    drawDebugRay(lowOrigin, direction, lowHit ~= nil, Color3.fromRGB(60, 255, 60))
    drawDebugRay(highOrigin, direction, highHit ~= nil, Color3.fromRGB(60, 150, 255))

    if lowHit and lowHit.Instance and lowHit.Instance.CanCollide then
        if not highHit or (highHit.Instance and not highHit.Instance.CanCollide) then
            return true
        end
    end
    return false
end

local function executeAutoJump(hum, root, isNearEnd)
    if isNearEnd then return end
    if shouldJump(hum, root) then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
        hum.Jump = true
        lastJumpTime = os.clock()
    end
end

local buildRouteAsync

local function doStuckCheck(hum, root, dt, noRebuild)
    if os.clock() - lastVelocityCheck > 0.4 then
        lastVelocityCheck = os.clock()
        if hum.FloorMaterial ~= Enum.Material.Air and hum:GetState() ~= Enum.HumanoidStateType.Freefall then
            if hum.MoveDirection.Magnitude > 0 then
                local vel = root.AssemblyLinearVelocity
                local flatVel = Vector3.new(vel.X, 0, vel.Z).Magnitude
                local distMoved = (root.Position - lastStuckPos).Magnitude
                lastStuckPos = root.Position

                if flatVel < 2.0 or distMoved < 0.8 then
                    stuckTimer = stuckTimer + 0.4
                    if stuckTimer > 0.8 then
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                        hum.Jump = true
                        lastJumpTime = os.clock()
                    end
                    if stuckTimer > 1.5 then
                        if targetCoin and not isTargetingGun then
                            unreachableCoins[targetCoin] = true
                        end
                        clearRoute()
                        chaseRoute = nil
                        wanderRoute = nil
                        stuckTimer = 0
                        if not noRebuild then buildRouteAsync() end
                    end
                else
                    stuckTimer = 0
                end
            else
                stuckTimer = 0
            end
        end
    end
end

local function isPathSafeFromKnife(pos)
    if not knownMurderer or not knownMurderer.Character then return true end
    local mRoot = knownMurderer.Character:FindFirstChild("HumanoidRootPart")
    if not mRoot then return true end
    if (pos - mRoot.Position).Magnitude < botSettings.evadeDistance then return false end
    return true
end

local function isRouteBlockedByMurderer(waypoints, startIdx)
    if not waypoints then return false end
    startIdx = startIdx or 1
    for i = startIdx, math.min(#waypoints, startIdx + 8) do
        local wpPos = (typeof(waypoints[i]) == "Vector3" and waypoints[i] or waypoints[i].Position)
        if not isPathSafeFromKnife(wpPos) then
            return true
        end
    end
    return false
end

local function pathLength(waypoints)
    local len = 0
    for i = 2, #waypoints do
        len = len + (waypoints[i].Position - waypoints[i - 1].Position).Magnitude
    end
    return len
end

local function getBestCoins(origin, count, exclude)
    count = count or 3
    local originPos = origin.Position

    local candidates = {}
    for _, item in ipairs(getCoins()) do
        if item.Parent and not unreachableCoins[item] and not isBlacklisted(item) and item ~= targetCoin and item ~= pendingTargetCoin and item ~= exclude then
            local pos = availablePosition(item)
            if pos then
                local horizontalDist = Vector3.new(pos.X - originPos.X, 0, pos.Z - originPos.Z).Magnitude
                local verticalDist = math.abs(pos.Y - originPos.Y)
                local effectiveDist = horizontalDist + (verticalDist > 8 and (verticalDist * 2.5) or verticalDist)

                if effectiveDist < botSettings.maxCoinDist and (not botSettings.avoidMurdererCoins or isPathSafeFromKnife(pos)) then
                    table.insert(candidates, {coin = item, dist = effectiveDist, pos = pos})
                end
            end
        end
    end

    if #candidates == 0 and next(unreachableCoins) then
        unreachableCoins = {}
        return getBestCoins(origin, count, exclude)
    end

    table.sort(candidates, function(a, b) return a.dist < b.dist end)

    local eye = originPos + Vector3.new(0, 1.5, 0)
    for i = 1, math.min(#candidates, 8) do
        local c = candidates[i]
        if isBlockedByWall(eye, c.pos) then
            c.dist = c.dist * 2.2
        end
    end
    table.sort(candidates, function(a, b) return a.dist < b.dist end)

    local result = {}
    for _, c in ipairs(candidates) do
        if #result >= count then break end
        if not isCoinClaimedByOthers(c.coin) then
            table.insert(result, c.coin)
        end
    end
    return result
end

local function pickCoinByPath(startPos, pool, k)
    local results = {}
    local pendingJobs = 0
    local limit = math.min(k, #pool)

    for i = 1, limit do
        local coin = pool[i]
        local cPos = availablePosition(coin)
        if cPos then
            pendingJobs = pendingJobs + 1
            task.spawn(function()
                local path = PathfindingService:CreatePath({
                    AgentRadius = 1.4,
                    AgentHeight = 5,
                    AgentCanJump = true,
                    AgentCanClimb = true,
                    WaypointSpacing = 3
                })
                local goal = groundBelow(cPos)
                local ok = pcall(function() path:ComputeAsync(startPos, goal) end)
                if ok and path.Status == Enum.PathStatus.Success then
                    local wps = path:GetWaypoints()
                    if #wps > 0 then
                        results[i] = {coin = coin, wps = wps, len = pathLength(wps), pos = cPos}
                    end
                end
                pendingJobs = pendingJobs - 1
            end)
        end
    end

    local started = os.clock()
    while pendingJobs > 0 and os.clock() - started < 2 do
        task.wait()
    end

    local best = nil
    for i = 1, limit do
        local r = results[i]
        if r and (not best or r.len < best.len) then
            best = r
        end
    end
    return best
end

local function checkOpportunisticCoins(root)
    if not botSettings.grabNearby then return end
    if isTargetingGun or isCalculatingPath then return end
    if os.clock() - lastOpportunisticCheck < 0.2 then return end
    lastOpportunisticCheck = os.clock()

    local radius = botSettings.nearbyRadius
    local best = nil
    local bestDist = math.huge
    local eye = root.Position + Vector3.new(0, 1.5, 0)

    for _, item in ipairs(getCoins()) do
        if item.Parent and item ~= targetCoin and item ~= pendingTargetCoin and not unreachableCoins[item] and not isBlacklisted(item) then
            local cPos = availablePosition(item)
            if cPos then
                local d = (cPos - root.Position).Magnitude
                if d < radius and d < bestDist and math.abs(cPos.Y - root.Position.Y) < 8 then
                    if isPathSafeFromKnife(cPos) and not isBlockedByWall(eye, cPos) and not isCoinClaimedByOthers(item) then
                        best = item
                        bestDist = d
                    end
                end
            end
        end
    end

    if not best then return end

    local targetPos = targetCoin and availablePosition(targetCoin)
    local currentDist = targetPos and (root.Position - targetPos).Magnitude or math.huge

    if bestDist + 3 < currentDist then
        S.forcedCoin = best
        targetCoin = nil
        route = nil
        routeIndex = 1
        pendingRoute = nil
        pendingTargetCoin = nil
        pendingUpcomingCoins = {}
        buildRouteAsync()
    end
end

buildRouteAsync = function()
    if isCalculatingPath then return end
    local _, root = getCharacter()
    if not root then return end

    isCalculatingPath = true

    task.spawn(function()
        local planningAhead = route ~= nil and targetCoin ~= nil and targetCoin.Parent ~= nil and not isTargetingGun
        local planTarget = targetCoin
        local startPos = root.Position
        if planningAhead then
            startPos = groundBelow(availablePosition(targetCoin) or root.Position)
        end

        local chosenTarget = nil
        local chosenPos = nil
        local targetingGun = false
        local waypoints = nil
        local plannedCoins = nil

        if not planningAhead and myRole == "Innocent" and botSettings.pickupGun and not route then
            local gObj, gPos = getDroppedGun()
            if gObj and gPos and not isBlacklisted(gObj) and isPathSafeFromKnife(gPos) then
                chosenTarget = gObj
                chosenPos = gPos
                targetingGun = true
            end
        end

        local forced = S.forcedCoin
        S.forcedCoin = nil

        if chosenTarget then
            plannedCoins = getBestCoins({Position = startPos}, 3)
        elseif forced and not planningAhead and forced.Parent and not unreachableCoins[forced] and not isBlacklisted(forced) and not isCoinClaimedByOthers(forced) then
            plannedCoins = getBestCoins({Position = startPos}, 2, forced)
            table.insert(plannedCoins, 1, forced)
            chosenTarget = forced
            chosenPos = availablePosition(forced)
        else
            local k = math.floor(botSettings.pathCandidates)
            local pool = getBestCoins({Position = startPos}, math.max(k, 3))

            if k > 1 and #pool > 1 then
                local best = pickCoinByPath(startPos, pool, k)
                if best then
                    chosenTarget = best.coin
                    chosenPos = best.pos
                    waypoints = best.wps
                    plannedCoins = {best.coin}
                    for _, c in ipairs(pool) do
                        if c ~= best.coin and #plannedCoins < 3 then
                            table.insert(plannedCoins, c)
                        end
                    end
                end
            end

            if not chosenTarget then
                plannedCoins = pool
                if pool[1] then
                    chosenTarget = pool[1]
                    chosenPos = availablePosition(pool[1])
                end
            end
        end

        if not chosenTarget or not chosenPos then
            isCalculatingPath = false
            if planningAhead then
                S.nextPlanTime = os.clock() + 0.75
            else
                noPathTimer = noPathTimer + 0.5
            end
            return
        end

        local success = true
        local pathStatus = Enum.PathStatus.Success
        if not waypoints then
            local path = PathfindingService:CreatePath({
                AgentRadius = 1.4,
                AgentHeight = 5,
                AgentCanJump = true,
                AgentCanClimb = true,
                WaypointSpacing = 3
            })
            local goalPos = groundBelow(chosenPos)
            success = pcall(function() path:ComputeAsync(startPos, goalPos) end)
            pathStatus = path.Status
            if success and (pathStatus == Enum.PathStatus.Success or pathStatus == Enum.PathStatus.ClosestNoPath) then
                waypoints = path:GetWaypoints()
            end
        end

        if planningAhead and (route == nil or targetCoin ~= planTarget) then
            isCalculatingPath = false
            return
        end
        if not planningAhead and route ~= nil and targetCoin ~= nil and targetCoin.Parent ~= nil and not isTargetingGun then
            isCalculatingPath = false
            return
        end

        if success and waypoints and #waypoints > 0 and not isRouteBlockedByMurderer(waypoints, 1) then
            if planningAhead then
                pendingRoute = waypoints
                pendingTargetCoin = chosenTarget
                pendingUpcomingCoins = plannedCoins
            else
                noPathTimer = 0
                isWandering = false
                wanderRoute = nil
                route = waypoints
                routeIndex = 1
                targetCoin = chosenTarget
                upcomingCoins = plannedCoins
                isTargetingGun = targetingGun
                lastRouteUpdate = os.clock()
                S.hintCoin = nil
                drawRoute(route)

                if not targetingGun then
                    drawUpcomingCoinPaths(chosenPos, plannedCoins)
                end
                updateCoinMarkers()
            end
        else
            if planningAhead then
                S.nextPlanTime = os.clock() + 1.5
            else
                noPathTimer = noPathTimer + 0.5
                if not targetingGun then targetCoin = chosenTarget end
            end
        end

        isCalculatingPath = false
    end)
end

local function evadeMurderer(hum, root)
    if myRole == "Murderer" then
        currentlyEvading = false
        return false
    end
    if not knownMurderer or not knownMurderer.Character then
        currentlyEvading = false
        return false
    end

    local mRoot = knownMurderer.Character:FindFirstChild("HumanoidRootPart")
    if not mRoot then
        currentlyEvading = false
        return false
    end

    local dist = (root.Position - mRoot.Position).Magnitude

    if currentlyEvading then
        if dist > botSettings.evadeDistance + 16 then
            currentlyEvading = false
            chaseRoute = nil
            addLog("Escaped Murderer! Resuming tasks.", THEME.good)
            return false
        end
    else
        if dist < botSettings.evadeDistance then
            currentlyEvading = true
            addLog("Evading Murderer!", THEME.bad)
        else
            return false
        end
    end

    statusLbl.Text = "State: EVADING MURDERER"
    clearRoute()

    local awayVector = (root.Position - mRoot.Position).Unit
    local bestDir = awayVector
    local bestScore = -math.huge
    local char = player and player.Character
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char, visFolder, knownMurderer.Character}

    for i = 1, 16 do
        local angle = math.pi * 2 * (i / 16)
        local dir = CFrame.Angles(0, angle, 0) * awayVector
        local hit = workspace:Raycast(root.Position, dir * 25, params)
        local openDist = hit and (hit.Position - root.Position).Magnitude or 25
        local score = openDist + (dir:Dot(awayVector) * 10)

        if score > bestScore then
            bestScore = score
            bestDir = dir
        end
    end

    local evadePos = root.Position + (bestDir * 18)

    if bestScore < 15 then
        if os.clock() - lastChasePlan > 0.5 then
            lastChasePlan = os.clock()
            local path = PathfindingService:CreatePath({AgentRadius=1.4, AgentHeight=5, AgentCanJump=true, AgentCanClimb=true})
            pcall(function() path:ComputeAsync(root.Position, evadePos) end)

            if path.Status == Enum.PathStatus.Success then
                chaseRoute = {}
                for _, w in ipairs(path:GetWaypoints()) do table.insert(chaseRoute, w.Position) end
                chaseRouteIndex = 1
                drawRoute(chaseRoute, "ChaseDot", Color3.fromRGB(255, 120, 0))
            end
        end

        if chaseRoute and chaseRouteIndex <= #chaseRoute then
            local targetWp = chaseRoute[chaseRouteIndex]
            hum:MoveTo(targetWp)
            executeAutoJump(hum, root, false)
            local flat = Vector3.new(targetWp.X - root.Position.X, 0, targetWp.Z - root.Position.Z).Magnitude
            if flat <= WP_DIST then chaseRouteIndex = chaseRouteIndex + 1 end
        end
    else
        chaseRoute = nil
        hum:MoveTo(evadePos)
        executeAutoJump(hum, root, false)
    end

    return true
end

local function ensureToolEquipped(tool)
    if not tool or not tool.Parent then return false end
    local char = player and player.Character
    if not char then return false end

    if tool.Parent ~= char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:EquipTool(tool)
            task.wait(0.05)
        end
    end
    return tool.Parent == char
end

local function triggerWeaponAttack(tool, targetPos)
    if not tool or not ensureToolEquipped(tool) then return end

    if tool:FindFirstChild("Activate") then
        pcall(function() tool:Activate() end)
    end

    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)

    if myRole == "Sheriff" or isGun(tool) then
        local shootRem = getShootRemote()
        if shootRem and targetPos then
            pcall(function()
                if shootRem:IsA("RemoteEvent") then
                    shootRem:FireServer(targetPos)
                elseif shootRem:IsA("RemoteFunction") then
                    shootRem:InvokeServer(targetPos)
                end
            end)
        end
    end
end

local function orientCameraToTarget(targetPos)
    if not targetPos then return end
    setFirstPersonCamera()

    local camPos = camera.CFrame.Position
    local aimCFrame = CFrame.lookAt(camPos, targetPos)
    camera.CFrame = aimCFrame

    pcall(function()
        local screenPoint, onScreen = camera:WorldToViewportPoint(targetPos)
        if onScreen then
            VirtualInputManager:SendMouseMoveEvent(screenPoint.X, screenPoint.Y, game)
        end
    end)
end

local function computeWanderPath(hum, root)
    if isCalculatingWander then return end
    isCalculatingWander = true

    task.spawn(function()
        local rx = (math.random() - 0.5) * 2 * botSettings.wanderRadius
        local rz = (math.random() - 0.5) * 2 * botSettings.wanderRadius
        local targetWanderPos = root.Position + Vector3.new(rx, 0, rz)

        local path = PathfindingService:CreatePath({
            AgentRadius = 1.4,
            AgentHeight = 5,
            AgentCanJump = true,
            AgentCanClimb = true,
            WaypointSpacing = 3
        })

        local success, _ = pcall(function() path:ComputeAsync(root.Position, targetWanderPos) end)

        if success and path.Status == Enum.PathStatus.Success then
            wanderRoute = path:GetWaypoints()
            wanderRouteIndex = 1
            drawRoute(wanderRoute, "WanderDot", THEME.warn)
        else
            wanderRoute = nil
        end
        isCalculatingWander = false
    end)
end

local function handleWanderingSearch(hum, root)
    if noPathTimer >= 10 then
        if not isWandering then
            isWandering = true
            wanderRoute = nil
            wanderRouteIndex = 1
            addLog("No path found for >10s. Wandering via pathfinding...", THEME.warn)
        end
        statusLbl.Text = "State: Wandering & Searching Path"

        if (not wanderRoute or wanderRouteIndex > #wanderRoute) and not isCalculatingWander then
            computeWanderPath(hum, root)
        end

        if wanderRoute and wanderRouteIndex <= #wanderRoute then
            local wp = wanderRoute[wanderRouteIndex]
            local wpPos = typeof(wp) == "Vector3" and wp or wp.Position
            local flatDist = Vector3.new(root.Position.X - wpPos.X, 0, root.Position.Z - wpPos.Z).Magnitude

            hum:MoveTo(wpPos)
            executeAutoJump(hum, root, wanderRouteIndex >= #wanderRoute - 1)

            if flatDist < WP_DIST then
                wanderRouteIndex = wanderRouteIndex + 1
            end
        end

        if not isCalculatingPath then
            buildRouteAsync()
        end
        return true
    end
    return false
end

local function holdsKnife(char)
    for _, c in ipairs(char:GetChildren()) do
        if isKnife(c) then return true end
    end
    return false
end

local function reachJump(hum, root, targetPos, isGun)
    if os.clock() - lastJumpTime < 0.7 then return end
    local flat = Vector3.new(targetPos.X - root.Position.X, 0, targetPos.Z - root.Position.Z).Magnitude
    local dy = targetPos.Y - root.Position.Y
    if flat < 6 and (dy > 2 or (isGun and flat < 5)) then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
        hum.Jump = true
        lastJumpTime = os.clock()
    end
end

local function promotePendingRoute()
    if not pendingRoute or not pendingTargetCoin then
        pendingRoute = nil
        pendingTargetCoin = nil
        pendingUpcomingCoins = {}
        return false
    end

    local coin = pendingTargetCoin
    if not coin.Parent or unreachableCoins[coin] or isBlacklisted(coin) or isCoinClaimedByOthers(coin) then
        pendingRoute = nil
        pendingTargetCoin = nil
        pendingUpcomingCoins = {}
        return false
    end

    route = pendingRoute
    targetCoin = pendingTargetCoin
    upcomingCoins = pendingUpcomingCoins
    routeIndex = 1
    isTargetingGun = false
    stuckTimer = 0
    pendingRoute = nil
    pendingTargetCoin = nil
    pendingUpcomingCoins = {}
    drawRoute(route)
    updateCoinMarkers()

    local humNow, rootNow = getCharacter()
    if humNow and rootNow then
        while routeIndex < #route do
            local w = route[routeIndex]
            local wPos = typeof(w) == "Vector3" and w or w.Position
            local flat = Vector3.new(rootNow.Position.X - wPos.X, 0, rootNow.Position.Z - wPos.Z).Magnitude
            if flat < WP_DIST then
                routeIndex = routeIndex + 1
            else
                break
            end
        end
        local w = route[routeIndex]
        humNow:MoveTo(typeof(w) == "Vector3" and w or w.Position)
    end
    return true
end

local function maybePlanAhead()
    if pendingRoute or isCalculatingPath or not route or isTargetingGun then return end
    if os.clock() < S.nextPlanTime then return end
    if not botSettings.planAhead and routeIndex < math.max(1, #route - 3) then return end
    S.nextPlanTime = os.clock() + 0.25
    buildRouteAsync()
end

local function isBagFull()
    local ok, result = pcall(function()
        local gui = player:FindFirstChild("PlayerGui")
        local container = gui and gui:FindFirstChild("MainGUI")
        container = container and container:FindFirstChild("Game")
        container = container and container:FindFirstChild("CoinBags")
        container = container and container:FindFirstChild("Container")
        if not container then return false end
        for _, bag in ipairs(container:GetChildren()) do
            local full = bag:FindFirstChild("Full")
            if full and full:IsA("GuiObject") and full.Visible then
                if not bag:IsA("GuiObject") or bag.Visible then
                    return true
                end
            end
        end
        return false
    end)
    return ok and result == true
end

local function updateBagState()
    if os.clock() - S.bagCheckClock >= 0.25 then
        S.bagCheckClock = os.clock()
        local full = isBagFull()
        if full ~= S.bagFull then
            S.bagFull = full
            bagLbl.Text = full and "Bag: Full" or "Bag: Not full"
            bagLbl.TextColor3 = full and THEME.warn or THEME.muted
            addLog(full and "Coin bag is full." or "Coin bag is no longer full.", full and THEME.warn or THEME.muted)
        end
    end
    return S.bagFull
end

local function doReset(hum, reason)
    addLog("Resetting character (" .. reason .. ")", THEME.warn)
    pcall(function()
        local char = player.Character
        if hum then hum.Health = 0 end
        if char then char:BreakJoints() end
    end)
end

local function getRolePlan()
    if myRole == "Murderer" then
        return botSettings.murdererMode, botSettings.murdererBagFull, false
    elseif myRole == "Sheriff" then
        return botSettings.sheriffMode, botSettings.sheriffBagFull, botSettings.sheriffStandRun
    end
    return botSettings.innocentMode, botSettings.innocentBagFull, botSettings.innocentStandRun
end

local function standStill(hum, root)
    if route or chaseRoute or wanderRoute or targetCoin then
        clearRoute()
        chaseRoute = nil
        wanderRoute = nil
    end
    statusLbl.Text = "State: Standing (bag full)"
    hum:MoveTo(root.Position)
end

local function runWanderStep(hum, root)
    if (not wanderRoute or wanderRouteIndex > #wanderRoute) and not isCalculatingWander then
        computeWanderPath(hum, root)
    end
    if wanderRoute and wanderRouteIndex <= #wanderRoute then
        local wp = wanderRoute[wanderRouteIndex]
        local wpPos = typeof(wp) == "Vector3" and wp or wp.Position
        local flatDist = Vector3.new(root.Position.X - wpPos.X, 0, root.Position.Z - wpPos.Z).Magnitude

        hum:MoveTo(wpPos)
        executeAutoJump(hum, root, wanderRouteIndex >= #wanderRoute - 1)

        if flatDist < WP_DIST then
            wanderRouteIndex = wanderRouteIndex + 1
        end
    end
end

local function sheriffCombat(hum, root, allowMove)
    if not botSettings.sheriffShoot or not myWeapon or not knownMurderer or not knownMurderer.Character then
        S.aimStart = nil
        restoreCameraMode()
        return false
    end

    local mTorso = getTorso(knownMurderer.Character)
    if not mTorso then
        S.aimStart = nil
        restoreCameraMode()
        return false
    end

    local distToM = (mTorso.Position - root.Position).Magnitude
    if distToM > botSettings.sheriffRange then
        S.aimStart = nil
        restoreCameraMode()
        return false
    end

    local visible = hasLineOfSight(camera.CFrame.Position, mTorso.Position, knownMurderer.Character)

    if visible then
        S.lastCombatT = os.clock()
        ensureToolEquipped(myWeapon)
        orientCameraToTarget(mTorso.Position)
        if not S.aimStart then S.aimStart = os.clock() end
        statusLbl.Text = "State: Aiming at murderer"

        if (os.clock() - S.aimStart) >= botSettings.aimDelay and (os.clock() - lastShootTime) > 0.35 then
            lastShootTime = os.clock()
            S.aimStart = nil
            triggerWeaponAttack(myWeapon, mTorso.Position)
        end
    else
        S.aimStart = nil
        restoreCameraMode()
    end

    if not allowMove then return true end

    local away = root.Position - mTorso.Position
    if away.Magnitude < 0.1 then return true end
    local awayDir = away.Unit

    if distToM < botSettings.sheriffKeepDist then
        hum:MoveTo(root.Position + awayDir * 15)
        executeAutoJump(hum, root, false)
        return true
    elseif distToM <= 45 and visible then
        local strafeDir = CFrame.Angles(0, math.rad(90), 0) * awayDir
        hum:MoveTo(root.Position + strafeDir * 10)
        executeAutoJump(hum, root, false)
        return true
    end
    return false
end

local function runMurdererHunt(hum, root, dt, maxRange)
    local now = os.clock()
    local eye = root.Position + Vector3.new(0, 1.5, 0)
    local seeRange = math.min(maxRange, botSettings.detectRange)

    local bestScore = math.huge
    local bestRaw = math.huge
    local bestPos = nil
    local bestVisible = false
    murderTarget = nil

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local pChar = p.Character
            local pRoot = pChar:FindFirstChild("HumanoidRootPart")
            local pHum = pChar:FindFirstChild("Humanoid")
            local hasFF = pChar:FindFirstChildOfClass("ForceField") ~= nil

            if pRoot and pHum and pHum.Health > 0 and not hasFF and not isBlacklisted(p)
                and not (S.knifeSeen[p] or holdsKnife(pChar)) then
                local pos = pRoot.Position
                local seenPos = nil
                local visibleNow = false

                if (pos - root.Position).Magnitude <= seeRange and hasLineOfSight(eye, pos, pChar) then
                    visibleNow = true
                    seenPos = pos
                    S.huntSeen[p] = {pos = pos, t = now}
                else
                    local mem = S.huntSeen[p]
                    if mem and now - mem.t <= botSettings.huntMemory then
                        seenPos = mem.pos
                    end
                end

                if seenPos then
                    local hDist = Vector3.new(seenPos.X - root.Position.X, 0, seenPos.Z - root.Position.Z).Magnitude
                    local vDist = math.abs(seenPos.Y - root.Position.Y)
                    local score = hDist + (vDist > 6 and vDist * 3 or vDist)
                    local charTool = pChar:FindFirstChildOfClass("Tool")
                    if botSettings.huntPriority == "Sheriff first" and charTool and isGun(charTool) then score = score * 0.2 end
                    if score < bestScore then
                        murderTarget = p
                        bestScore = score
                        bestRaw = (seenPos - root.Position).Magnitude
                        bestPos = seenPos
                        bestVisible = visibleNow
                    end
                end
            end
        end
    end

    if not murderTarget or not murderTarget.Character or not bestPos then
        if maxRange ~= math.huge then return false end
        statusLbl.Text = "State: Wandering (Searching Victims)"
        runWanderStep(hum, root)
        return true
    end

    if S.huntTarget ~= murderTarget then
        S.huntTarget = murderTarget
        S.huntBest = bestRaw
        S.huntProgressT = now
    elseif bestRaw < S.huntBest - 2 then
        S.huntBest = bestRaw
        S.huntProgressT = now
    elseif now - S.huntProgressT > botSettings.giveUpTime and bestRaw >= botSettings.stabRange then
        addLog("Gave up chasing " .. murderTarget.Name .. " (not getting closer)", THEME.warn)
        blacklistInstance(murderTarget, 20)
        S.huntTarget = nil
        chaseRoute = nil
        return maxRange == math.huge
    end

    statusLbl.Text = bestVisible and "State: Hunting (Murderer)" or "State: Hunting (last seen position)"
    doStuckCheck(hum, root, dt, true)

    if now - lastChasePlan > 0.4 then
        lastChasePlan = now
        local path = PathfindingService:CreatePath({AgentRadius = 1.4, AgentHeight = 5, AgentCanJump = true, AgentCanClimb = true})
        local success, _ = pcall(function() path:ComputeAsync(root.Position, bestPos) end)

        if success and path.Status == Enum.PathStatus.Success then
            chaseRoute = path:GetWaypoints()
            chaseRouteIndex = 1
            drawRoute(chaseRoute, "ChaseDot", THEME.bad)
        else
            chaseRoute = nil
        end
    end

    if chaseRoute and chaseRouteIndex <= #chaseRoute then
        local wp = chaseRoute[chaseRouteIndex]
        local wpPos = typeof(wp) == "Vector3" and wp or wp.Position
        hum:MoveTo(wpPos)
        executeAutoJump(hum, root, false)
        local flat = Vector3.new(wpPos.X - root.Position.X, 0, wpPos.Z - root.Position.Z).Magnitude
        if flat < WP_DIST then chaseRouteIndex = chaseRouteIndex + 1 end
    else
        statusLbl.Text = "State: Wandering (Unreachable Victim)"
        runWanderStep(hum, root)
    end

    local tTorso = getTorso(murderTarget.Character)
    if myWeapon and bestVisible and tTorso and math.abs(bestPos.Y - root.Position.Y) <= 5 and bestRaw <= botSettings.engageRange then
        S.lastCombatT = now
        ensureToolEquipped(myWeapon)
        if bestRaw < botSettings.stabRange then
            triggerWeaponAttack(myWeapon, tTorso.Position)
        elseif botSettings.throwKnife and os.clock() - lastThrowTime > 0.8
            and hasLineOfSight(eye, tTorso.Position, murderTarget.Character) then
            lastThrowTime = os.clock()
            local throwRem = getThrowRemote()
            if throwRem then
                pcall(function()
                    if throwRem:IsA("RemoteEvent") then
                        throwRem:FireServer(tTorso.Position)
                    elseif throwRem:IsA("RemoteFunction") then
                        throwRem:InvokeServer(tTorso.Position)
                    end
                end)
            end
        end
    end
    return true
end

local function step(dt)
    camera = workspace.CurrentCamera or camera
    local hum, root = getCharacter()
    if not hum or not root then return end
    alive = hum.Health > 0
    if not (running and enabled and alive) then return end

    if os.clock() - S.lastScan >= 0.1 then
        S.lastScan = os.clock()
        scanPlayers(dt)
    end
    if os.clock() - S.lastEsp >= 0.25 then
        S.lastEsp = os.clock()
        updatePlayerESP()
    end

    if os.clock() - S.lastCombatT > 1.5 and os.clock() - S.lastHolster > 0.5 then
        S.lastHolster = os.clock()
        local ch = player.Character
        local h = ch and ch:FindFirstChildOfClass("Humanoid")
        if h and ch:FindFirstChildOfClass("Tool") then
            pcall(function() h:UnequipTools() end)
        end
    end

    if os.clock() - lastUnreachableClear > 10 then
        unreachableCoins = {}
        lastUnreachableClear = os.clock()
    end

    local activeRound = isRoundActive()

    if not activeRound and not isCoin(targetCoin) and not getDroppedGun() then
        if botSettings.autoVoteMap then
            statusLbl.Text = "State: Lobby / Voting Phase"
            local bestPad, bestName = findBestVoteMapCached()

            if bestPad and bestName then
                local detPos = getObjectPosition(bestPad)
                if detPos then
                    mapVoteStatusLbl.Text = "Map Vote: " .. bestName
                    mapVoteStatusLbl.TextColor3 = THEME.good

                    if currentVoteTargetPad ~= bestPad then
                        currentVoteTargetPad = bestPad
                        currentVoteMapName = bestName
                        hasVotedCurrentMap = false
                        voteHoldTimer = 0
                        voteRoute = nil
                        voteRouteIndex = 1
                        isCalculatingVotePath = false
                        addLog("Targeting Map: " .. bestName, THEME.accent)
                    end

                    local distToPad = (root.Position - detPos).Magnitude

                    if distToPad <= 3.5 then
                        voteHoldTimer = voteHoldTimer + dt
                        if voteHoldTimer >= 1.0 then
                            hasVotedCurrentMap = true
                            voteRoute = nil
                            clearRoute()
                            mapVoteStatusLbl.Text = "Map Vote: Voted (" .. bestName .. ")"
                        end
                    end

                    if not hasVotedCurrentMap then
                        if (not voteRoute or #voteRoute == 0) and not isCalculatingVotePath then
                            isCalculatingVotePath = true
                            task.spawn(function()
                                local path = PathfindingService:CreatePath({AgentRadius=1.4, AgentHeight=5, AgentCanJump=true, AgentCanClimb=true})
                                local success, _ = pcall(function() path:ComputeAsync(root.Position, detPos) end)
                                if success and path.Status == Enum.PathStatus.Success then
                                    voteRoute = path:GetWaypoints()
                                    voteRouteIndex = 1
                                    drawRoute(voteRoute, "VoteDot", THEME.accent)
                                end
                                isCalculatingVotePath = false
                            end)
                        end

                        if voteRoute and voteRouteIndex <= #voteRoute then
                            local wp = voteRoute[voteRouteIndex]
                            local wpPos = wp.Position
                            local flatDist = Vector3.new(root.Position.X - wpPos.X, 0, root.Position.Z - wpPos.Z).Magnitude

                            hum:MoveTo(wpPos)
                            executeAutoJump(hum, root, voteRouteIndex >= #voteRoute - 1)
                            if flatDist < WP_DIST then voteRouteIndex = voteRouteIndex + 1 end
                        else
                            hum:MoveTo(detPos)
                            executeAutoJump(hum, root, false)
                        end
                    else
                        hum:MoveTo(root.Position)
                    end
                    return
                end
            else
                mapVoteStatusLbl.Text = "Map Vote: Lobby Exploring"
                mapVoteStatusLbl.TextColor3 = THEME.warn
                hum:MoveTo(Vector3.new(math.sin(os.clock()) * 15, root.Position.Y, math.cos(os.clock()) * 15))
                executeAutoJump(hum, root, false)
                return
            end
        else
            mapVoteStatusLbl.Text = "Map Vote: Disabled"
            mapVoteStatusLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
    else
        if mapVoteStatusLbl.Text ~= "Map Vote: Round Active" and mapVoteStatusLbl.Text ~= "Map Vote: Disabled" then
            currentVoteTargetPad = nil
            currentVoteMapName = nil
            voteRoute = nil
            voteHoldTimer = 0
            mapVoteStatusLbl.Text = "Map Vote: Round Active"
            mapVoteStatusLbl.TextColor3 = THEME.accent
        end
    end

    local playMode, bagAction, standRun = getRolePlan()
    local bagFull = updateBagState()
    local settled = (os.clock() - S.roundStartClock) >= S.settleTime
    local action = nil
    if activeRound and bagFull and settled then
        action = bagAction
    end

    if activeRound then
        if playMode == "Just reset" then
            statusLbl.Text = "State: Reset pending"
            if settled and not S.roundActionDone then
                S.roundActionDone = true
                doReset(hum, "play style")
            end
            return
        end

        if action == "Reset" then
            statusLbl.Text = "State: Bag full, resetting"
            if not S.roundActionDone then
                S.roundActionDone = true
                doReset(hum, "bag full")
            end
            return
        elseif action == "Server hop" then
            statusLbl.Text = "State: Bag full, hopping servers"
            hum:MoveTo(root.Position)
            if not S.hopping and os.clock() - S.lastHopTry > 15 then
                S.lastHopTry = os.clock()
                performServerHop()
            end
            return
        end

        if myRole == "Murderer" then
            local fullHunt = (playMode == "Full hunt") or (action == "Hunt")
            local nearOnly = (playMode == "Coins + kill nearby") and (action == nil)
            if fullHunt then
                runMurdererHunt(hum, root, dt, math.huge)
                return
            elseif nearOnly then
                if runMurdererHunt(hum, root, dt, botSettings.engageRange) then return end
            end
        end

        if myRole == "Sheriff" then
            local standNoRun = (action == "Stand") and not standRun
            if sheriffCombat(hum, root, not standNoRun) then return end
        else
            restoreCameraMode()
        end

        if action == "Stand" then
            if standRun and evadeMurderer(hum, root) then return end
            standStill(hum, root)
            return
        elseif action == "Wander" then
            if evadeMurderer(hum, root) then return end
            statusLbl.Text = "State: Wandering (bag full)"
            doStuckCheck(hum, root, dt, true)
            runWanderStep(hum, root)
            return
        end
    end

    if evadeMurderer(hum, root) then
        return
    end

    updateDroppedGunESP()
    checkOpportunisticCoins(root)
    doStuckCheck(hum, root, dt)

    if handleWanderingSearch(hum, root) then
        return
    end

    if route and targetCoin and targetCoin.Parent then
        local tPos = availablePosition(targetCoin)
        if tPos then
            local d = (tPos - root.Position).Magnitude
            if S.watchTarget ~= targetCoin then
                S.watchTarget = targetCoin
                S.watchBest = d
                S.watchProgressT = os.clock()
            elseif d < S.watchBest - 2 then
                S.watchBest = d
                S.watchProgressT = os.clock()
            elseif os.clock() - S.watchProgressT > botSettings.giveUpTime then
                addLog((isTargetingGun and "Gave up on the gun" or "Gave up on a coin") .. " (not getting closer)", THEME.warn)
                blacklistInstance(targetCoin, 90)
                S.watchTarget = nil
                clearRoute()
                chaseRoute = nil
                return
            end
        end
    else
        S.watchTarget = nil
    end

    if not route or not targetCoin or not targetCoin.Parent or isCoinClaimedByOthers(targetCoin) then
        statusLbl.Text = isTargetingGun and "State: Retrieving Gun" or "State: Collecting Coins"
        if route then
            if not promotePendingRoute() then
                clearRoute()
            end
        end
        if not route and not isCalculatingPath then
            buildRouteAsync()
        end

        if not route then
            if os.clock() - S.hintT > 0.25 then
                S.hintT = os.clock()
                if not S.hintCoin or not S.hintCoin.Parent then
                    S.hintCoin = getBestCoins(root, 1)[1]
                end
            end
            local hint = S.hintCoin
            if hint and hint.Parent then
                local hp = availablePosition(hint)
                if hp then hum:MoveTo(hp) end
            end
        else
            S.hintCoin = nil
        end
    else
        statusLbl.Text = isTargetingGun and "State: Retrieving Gun" or "State: Collecting Coins"

        maybePlanAhead()

        local coinPos = availablePosition(targetCoin)
        if coinPos and (routeIndex >= #route - 1 or routeIndex > #route) then
            local distToCoinCenter = Vector3.new(root.Position.X - coinPos.X, 0, root.Position.Z - coinPos.Z).Magnitude
            local dy = coinPos.Y - root.Position.Y

            if pendingRoute and not isTargetingGun and distToCoinCenter < 2.2 and math.abs(dy) < 3 then
                local oldTarget = targetCoin
                if promotePendingRoute() then
                    blacklistInstance(oldTarget, 3)
                    return
                end
            end

            hum:MoveTo(coinPos)
            reachJump(hum, root, coinPos, isTargetingGun)

            local arrived
            if isTargetingGun then
                arrived = not targetCoin.Parent
            else
                arrived = (distToCoinCenter < 1.4 and math.abs(dy) < 4.5) or not targetCoin.Parent
            end

            if distToCoinCenter < 3 and dy > 9 then
                addLog("Target is too high to jump to, skipping it", THEME.warn)
                blacklistInstance(targetCoin, 90)
                clearRoute()
            elseif arrived then
                if targetCoin and targetCoin.Parent then
                    blacklistInstance(targetCoin, 20)
                end
                if not promotePendingRoute() then
                    clearRoute()
                    if not isCalculatingPath then
                        buildRouteAsync()
                    end
                end
            end
        else
            if routeIndex <= #route then
                local wp = route[routeIndex]
                local wpPos = typeof(wp) == "Vector3" and wp or wp.Position
                local flatDist = Vector3.new(root.Position.X - wpPos.X, 0, root.Position.Z - wpPos.Z).Magnitude

                hum:MoveTo(wpPos)
                executeAutoJump(hum, root, routeIndex >= #route - 1)

                if flatDist < WP_DIST then
                    routeIndex = routeIndex + 1
                end
            else
                if not promotePendingRoute() then
                    clearRoute()
                    if not isCalculatingPath then
                        buildRouteAsync()
                    end
                end
            end
        end
    end
end

local stepBusy = false
local lastStepError = 0
heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
    if stepBusy then return end
    stepBusy = true
    local ok, err = pcall(step, dt)
    stepBusy = false
    if not ok and os.clock() - lastStepError > 5 then
        lastStepError = os.clock()
        addLog("Error: " .. tostring(err), THEME.bad)
        warn("[MM2Autoplay] " .. tostring(err))
    end
end)
