local player = game.Players.LocalPlayer
local ts = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Run = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local WEBHOOK_FILE = "void_webhook.txt"

local function saveWebhook(url)
    _G.SavedWebhook = url
    pcall(function()
        writefile(WEBHOOK_FILE, url)
    end)
end

local function loadWebhook()
    if _G.SavedWebhook and _G.SavedWebhook ~= "" then
        return _G.SavedWebhook
    end
    local ok, data = pcall(function()
        return readfile(WEBHOOK_FILE)
    end)
    if ok and data and data ~= "" then
        return data
    end
    return ""
end

local webhookUrl = loadWebhook()

local function getRoot() return player.Character and player.Character:FindFirstChild("HumanoidRootPart") end
local function getHumanoid() return player.Character and player.Character:FindFirstChildOfClass("Humanoid") end

-- NOTIFIER

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local DETECT_RADIUS = 90
local CARD_HEIGHT = 100
local CARD_GAP = 6

local BONE_NAMES = {
    "SaintsRightLeg",
    "SaintsRightArm",
    "SaintsRibcage",
    "SaintsLeftLeg",
    "SaintsLeftArm",
    "SaintsHeart",
}

local SPAWNS = {
    { name = "Waterfall",      pos = Vector3.new(-1756.30,  58.40, -2983.90) },
    { name = "Death Valley",   pos = Vector3.new(-4413.67,  45.26, -1976.08) },
    { name = "Ncantu Canyons", pos = Vector3.new(-4012.15,  45.00, -2796.99) },
    { name = "Finely",         pos = Vector3.new(-4193.25,  46.35, -3996.52) },
    { name = "Abandoned Town", pos = Vector3.new(-4112.13,  64.75, -4981.27) },
    { name = "Outlaw Hills",   pos = Vector3.new(-3805.14, 242.55, -6008.41) },
    { name = "Bridge",         pos = Vector3.new(-7776.41,  46.77, -4476.99) },
    { name = "Greenlands",     pos = Vector3.new(-7962.14,  58.91, -3255.20) },
    { name = "Greenlands",     pos = Vector3.new(-8022.02,  67.38, -2838.21) },
}

local BONE_LABELS = {
    SaintsRightLeg = "Saints Right Leg",
    SaintsRightArm = "Saints Right Arm",
    SaintsRibcage  = "Saints Ribcage",
    SaintsLeftLeg  = "Saints Left Leg",
    SaintsLeftArm  = "Saints Left Arm",
    SaintsHeart    = "Saints Heart",
}

local function sendToDiscord(boneName, spawnName)
    if webhookUrl == "" then return end

    local boneLabel = BONE_LABELS[boneName] or boneName

    local data = {
        username = "Bone Notifier",
        embeds = {
            {
                title = "Corpse Found",
                color = 0xF0B132,
                fields = {
                    { name = "Bone", value = boneLabel, inline = true },
                    { name = "Location", value = spawnName, inline = true },
                },
                footer = { text = "VOID UI • Bone Notifier" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
    }

    local jsonData = HttpService:JSONEncode(data)
    local headers = {["Content-Type"] = "application/json"}

    task.spawn(function()
        pcall(function()
            local request = syn and syn.request or http_request or request
            if request then
                request({ Url = webhookUrl, Method = "POST", Headers = headers, Body = jsonData })
            end
        end)
    end)
end

local function sendTestWebhook()
    if webhookUrl == "" then return end

    local data = {
        username = "Bone Notifier",
        embeds = {
            {
                title = "Bone!",
                color = 0x2ECC71,
                footer = { text = "VOID UI • Bone Notifier" },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
    }

    local jsonData = HttpService:JSONEncode(data)
    local headers = {["Content-Type"] = "application/json"}

    task.spawn(function()
        pcall(function()
            local request = syn and syn.request or http_request or request
            if request then
                request({ Url = webhookUrl, Method = "POST", Headers = headers, Body = jsonData })
            end
        end)
    end)
end

if playerGui:FindFirstChild("CorpseNotifier") then
    playerGui:FindFirstChild("CorpseNotifier"):Destroy()
end

local sg = Instance.new("ScreenGui")
sg.Name = "CorpseNotifier"
sg.ResetOnSpawn = false
sg.Parent = playerGui

local activeNotifs = {}
local notifOrder = {}

local function rebuildPositions()
    for i, key in ipairs(notifOrder) do
        local data = activeNotifs[key]
        if data and data.frame then
            data.frame.Position = UDim2.new(0, 12, 0, 12 + (i - 1) * (CARD_HEIGHT + CARD_GAP))
        end
    end
end

local function getBillboardParent(obj)
    if obj:IsA("BasePart") then return obj end
    if obj:IsA("Model") then
        if obj.PrimaryPart then return obj.PrimaryPart end
        for _, child in ipairs(obj:GetChildren()) do
            if child:IsA("BasePart") then return child end
        end
    end
    return nil
end

local function removeCard(key)
    local data = activeNotifs[key]
    if not data then return end
    if data.frame then data.frame:Destroy() end
    if data.espGui then pcall(function() data.espGui:Destroy() end) end
    if data.connection then data.connection:Disconnect() end
    activeNotifs[key] = nil
    for i, k in ipairs(notifOrder) do
        if k == key then
            table.remove(notifOrder, i)
            break
        end
    end
    rebuildPositions()
end

local seen = {}

local function createCard(boneName, spawnName, bonePos, boneObj)
    local key = spawnName .. "|" .. boneName
    if seen[key] then return end
	sendToDiscord(boneName, spawnName)
    seen[key] = true

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 240, 0, CARD_HEIGHT)
    frame.Position = UDim2.new(0, 12, 0, 12)
    frame.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.Parent = sg

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 10)
    frameCorner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(180, 180, 180)
    stroke.Thickness = 2
    stroke.Parent = frame

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -16, 0, 22)
    titleLbl.Position = UDim2.new(0, 10, 0, 6)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "CORPSE"
    titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLbl.TextSize = 14
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = frame

    local boneLbl = Instance.new("TextLabel")
    boneLbl.Size = UDim2.new(1, -16, 0, 18)
    boneLbl.Position = UDim2.new(0, 10, 0, 30)
    boneLbl.BackgroundTransparency = 1
    boneLbl.Text = (BONE_LABELS[boneName] or boneName)
    boneLbl.TextColor3 = Color3.fromRGB(210, 210, 210)
    boneLbl.TextSize = 12
    boneLbl.Font = Enum.Font.GothamBold
    boneLbl.TextXAlignment = Enum.TextXAlignment.Left
    boneLbl.Parent = frame

    local locLbl = Instance.new("TextLabel")
    locLbl.Size = UDim2.new(1, -16, 0, 18)
    locLbl.Position = UDim2.new(0, 10, 0, 50)
    locLbl.BackgroundTransparency = 1
    locLbl.Text = spawnName
    locLbl.TextColor3 = Color3.fromRGB(140, 140, 140)
    locLbl.TextSize = 11
    locLbl.Font = Enum.Font.Gotham
    locLbl.TextXAlignment = Enum.TextXAlignment.Left
    locLbl.Parent = frame

    local tpBtn = Instance.new("TextButton")
    tpBtn.Size = UDim2.new(0, 60, 0, 22)
    tpBtn.Position = UDim2.new(0, 10, 0, 70)
    tpBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    tpBtn.BorderSizePixel = 0
    tpBtn.Text = "TP"
    tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    tpBtn.TextSize = 12
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.Parent = frame

    local tpCorner = Instance.new("UICorner")
    tpCorner.CornerRadius = UDim.new(0, 6)
    tpCorner.Parent = tpBtn

    local bottomLine = Instance.new("Frame")
    bottomLine.Size = UDim2.new(1, -12, 0, 2)
    bottomLine.Position = UDim2.new(0, 6, 1, -5)
    bottomLine.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    bottomLine.BorderSizePixel = 0
    bottomLine.Parent = frame

    local bottomLineCorner = Instance.new("UICorner")
    bottomLineCorner.CornerRadius = UDim.new(1, 0)
    bottomLineCorner.Parent = bottomLine

    tpBtn.MouseButton1Click:Connect(function()
        local character = player.Character
        if character then
            local root = character:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = CFrame.new(bonePos + Vector3.new(0, 5, 0))
            end
        end
    end)

    local espGui = nil
    local billboardParent = getBillboardParent(boneObj)
    if billboardParent then
        espGui = Instance.new("BillboardGui")
        espGui.Size = UDim2.new(0, 140, 0, 28)
        espGui.StudsOffset = Vector3.new(0, 4, 0)
        espGui.AlwaysOnTop = true
        espGui.Parent = billboardParent

        local espLabel = Instance.new("TextLabel")
        espLabel.Size = UDim2.new(1, 0, 1, 0)
        espLabel.BackgroundTransparency = 1
        espLabel.Text = (BONE_LABELS[boneName] or boneName)
        espLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
        espLabel.TextStrokeTransparency = 0
        espLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        espLabel.TextSize = 14
        espLabel.Font = Enum.Font.GothamBold
        espLabel.Parent = espGui
    end

    local connection = boneObj.AncestryChanged:Connect(function(_, newParent)
        if newParent == nil then
            seen[key] = nil
            removeCard(key)
        end
    end)

    activeNotifs[key] = { frame = frame, espGui = espGui, connection = connection }
    table.insert(notifOrder, key)
    rebuildPositions()
end

local boneSet = {}
for _, v in ipairs(BONE_NAMES) do
    boneSet[v] = true
end

local function getPos(obj)
    local ok, result = pcall(function()
        if obj:IsA("BasePart") then
            return obj.Position
        elseif obj:IsA("Model") then
            if obj.PrimaryPart then
                return obj.PrimaryPart.Position
            end
            return obj:GetModelCFrame().Position
        end
        return nil
    end)
    if ok then return result end
    return nil
end

local function onDescendantAdded(obj)
    if not boneSet[obj.Name] then return end
    local p = getPos(obj)
    if not p then return end
    for _, sp in ipairs(SPAWNS) do
        if (p - sp.pos).Magnitude <= DETECT_RADIUS then
            createCard(obj.Name, sp.name, p, obj)
        end
    end
end

workspace.DescendantAdded:Connect(onDescendantAdded)

for _, obj in ipairs(workspace:GetDescendants()) do
    if boneSet[obj.Name] then
        onDescendantAdded(obj)
    end
end

-- NOTIFIER 

local P = {
    base = Color3.fromRGB(6,6,6),
    surface = Color3.fromRGB(14,14,14),
    elevated = Color3.fromRGB(22,22,22),
    border = Color3.fromRGB(38,38,38),
    borderHi = Color3.fromRGB(80,80,80),
    white = Color3.fromRGB(255,255,255),
    offWhite = Color3.fromRGB(200,200,200),
    muted = Color3.fromRGB(90,90,90),
    dim = Color3.fromRGB(50,50,50),
    accentBg = Color3.fromRGB(28,28,28),
    red = Color3.fromRGB(220,70,70),
    redBg = Color3.fromRGB(28,10,10),
}
local W, H = 320, 800
local function tw(obj, props, t, style, dir)
    ts:Create(obj, TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out), props):Play()
end
local function applyStroke(parent, col, thick)
    local s = parent:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
    s.Color = col or P.border
    s.Thickness = thick or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end
local function setStroke(parent, col, thick)
    local s = parent:FindFirstChildOfClass("UIStroke")
    if s then
        s.Color = col
        if thick then s.Thickness = thick end
    end
end
local function applyCorner(obj, r)
    local c = obj:FindFirstChildOfClass("UICorner") or Instance.new("UICorner", obj)
    c.CornerRadius = UDim.new(0, r or 8)
    return c
end
local binds = {}
local bindLabels = {}
local btnActions = {}
local bindingBtn = nil
local bindTimerThread = nil
local function stopBinding()
    if not bindingBtn then return end
    local btn = bindingBtn
    bindingBtn = nil
    if bindTimerThread then task.cancel(bindTimerThread) bindTimerThread = nil end
    local bl = bindLabels[btn]
    if bl then
        local key = binds[btn]
        bl.Text = key and key or ""
        tw(bl, {TextColor3 = key and P.offWhite or P.muted, BackgroundColor3 = P.elevated}, 0.15)
        setStroke(bl, P.border, 1)
    end
end
local function startBind(btn)
    if bindingBtn then stopBinding() end
    bindingBtn = btn
    local bl = bindLabels[btn]
    if bl then
        bl.Text = "?"
        tw(bl, {TextColor3 = P.white, BackgroundColor3 = P.accentBg}, 0.15)
        setStroke(bl, P.white, 1.5)
    end
    bindTimerThread = task.delay(10, function()
        if bindingBtn == btn then stopBinding() end
    end)
end
local function addBindLabel(btn)
    local bl = Instance.new("TextLabel")
    bl.Size = UDim2.new(0, 30, 0, 20)
    bl.Position = UDim2.new(1, -82, 0.5, -10)
    bl.BackgroundColor3 = P.elevated
    bl.Text = ""
    bl.TextColor3 = P.muted
    bl.TextSize = 9
    bl.Font = Enum.Font.GothamBold
    bl.ZIndex = 5
    bl.BorderSizePixel = 0
    bl.Parent = btn
    applyCorner(bl, 4)
    applyStroke(bl, P.border, 1)
    bindLabels[btn] = bl
    return bl
end
local screen = Instance.new("ScreenGui")
screen.Name = "VoidUI"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = player:WaitForChild("PlayerGui")
local sfx = Instance.new("Sound")
sfx.SoundId = "rbxassetid://9113675181"
sfx.Volume = 0.4
sfx.Parent = screen
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, W, 0, 46)
main.Position = UDim2.new(0.5, -160, 0.5, -400)
main.BackgroundColor3 = P.base
main.BackgroundTransparency = 1
main.ClipsDescendants = true
main.BorderSizePixel = 0
main.Parent = screen
applyCorner(main, 12)
applyStroke(main, P.border, 1.5)
local accentLine = Instance.new("Frame")
accentLine.Size = UDim2.new(1, 0, 0, 1)
accentLine.Position = UDim2.new(0, 0, 0, 0)
accentLine.BackgroundColor3 = P.white
accentLine.BorderSizePixel = 0
accentLine.ZIndex = 6
accentLine.Parent = main
task.spawn(function()
    task.wait(0.05)
    tw(main, {Size = UDim2.new(0, W, 0, H), BackgroundTransparency = 0}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end)
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 46)
header.BackgroundColor3 = P.surface
header.BorderSizePixel = 0
header.Parent = main
applyCorner(header, 12)
local hDiv = Instance.new("Frame")
hDiv.Size = UDim2.new(1, 0, 0, 1)
hDiv.Position = UDim2.new(0, 0, 1, -1)
hDiv.BackgroundColor3 = P.border
hDiv.BorderSizePixel = 0
hDiv.Parent = header
local dot = Instance.new("Frame")
dot.Size = UDim2.new(0, 5, 0, 5)
dot.Position = UDim2.new(0, 14, 0.5, -2.5)
dot.BackgroundColor3 = P.white
dot.BorderSizePixel = 0
dot.Parent = header
applyCorner(dot, 99)
task.spawn(function()
    while true do
        tw(dot, {BackgroundTransparency = 0.75}, 0.9, Enum.EasingStyle.Sine)
        task.wait(0.9)
        tw(dot, {BackgroundTransparency = 0}, 0.9, Enum.EasingStyle.Sine)
        task.wait(0.9)
    end
end)
local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, -100, 1, 0)
titleLbl.Position = UDim2.new(0, 24, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "VOID"
titleLbl.TextColor3 = P.white
titleLbl.TextSize = 14
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = header
local subLbl = Instance.new("TextLabel")
subLbl.Size = UDim2.new(1, -100, 1, 0)
subLbl.Position = UDim2.new(0, 52, 0, 0)
subLbl.BackgroundTransparency = 1
subLbl.Text = "· UI"
subLbl.TextColor3 = P.muted
subLbl.TextSize = 14
subLbl.Font = Enum.Font.Gotham
subLbl.TextXAlignment = Enum.TextXAlignment.Left
subLbl.Parent = header
local function makeHeaderBtn(text, xOff, parent)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 28, 0, 28)
    b.Position = UDim2.new(1, xOff, 0.5, -14)
    b.BackgroundColor3 = P.elevated
    b.Text = text
    b.TextColor3 = P.muted
    b.TextSize = 13
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.Parent = parent or header
    applyCorner(b, 6)
    applyStroke(b, P.border, 1)
    b.MouseEnter:Connect(function() tw(b, {TextColor3 = P.white, BackgroundColor3 = P.accentBg}, 0.12) end)
    b.MouseLeave:Connect(function() tw(b, {TextColor3 = P.muted, BackgroundColor3 = P.elevated}, 0.12) end)
    return b
end
local minimizeBtn = makeHeaderBtn("−", -38)
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -16, 0, 32)
tabBar.Position = UDim2.new(0, 8, 0, 52)
tabBar.BackgroundColor3 = P.surface
tabBar.BorderSizePixel = 0
tabBar.Parent = main
applyCorner(tabBar, 7)
applyStroke(tabBar, P.border, 1)
local tabLayout = Instance.new("UIListLayout", tabBar)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 2)
local tabPad = Instance.new("UIPadding", tabBar)
tabPad.PaddingLeft = UDim.new(0, 3)
tabPad.PaddingRight = UDim.new(0, 3)
tabPad.PaddingTop = UDim.new(0, 3)
tabPad.PaddingBottom = UDim.new(0, 3)
local function makeTab(name)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.25, -2, 1, 0)
    b.BackgroundColor3 = P.elevated
    b.Text = name
    b.TextColor3 = P.muted
    b.TextSize = 11
    b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0
    b.Parent = tabBar
    applyCorner(b, 5)
    return b
end
local tabLocations = makeTab("LOCATIONS")
local tabFarm = makeTab("FARM")
local tabTools = makeTab("TOOLS")
local tabMore = Instance.new("TextButton")
tabMore.Size = UDim2.new(0.25, -2, 1, 0)
tabMore.BackgroundColor3 = P.elevated
tabMore.Text = "···"
tabMore.TextColor3 = P.muted
tabMore.TextSize = 13
tabMore.Font = Enum.Font.GothamBold
tabMore.BorderSizePixel = 0
tabMore.Parent = tabBar
applyCorner(tabMore, 5)
local CONTENT_Y = 91
local CONTENT_H_OFFSET = -170
local locPage = Instance.new("Frame")
locPage.Size = UDim2.new(1, -16, 1, CONTENT_H_OFFSET)
locPage.Position = UDim2.new(0, 8, 0, CONTENT_Y)
locPage.BackgroundTransparency = 1
locPage.BorderSizePixel = 0
locPage.Parent = main
local locScroll = Instance.new("ScrollingFrame", locPage)
locScroll.Size = UDim2.new(1, 0, 1, 0)
locScroll.BackgroundTransparency = 1
locScroll.ScrollBarThickness = 2
locScroll.ScrollBarImageColor3 = P.dim
locScroll.BorderSizePixel = 0
local locLayout = Instance.new("UIListLayout", locScroll)
locLayout.Padding = UDim.new(0, 4)
local locPad = Instance.new("UIPadding", locScroll)
locPad.PaddingTop = UDim.new(0, 6)
locPad.PaddingBottom = UDim.new(0, 6)
locPad.PaddingRight = UDim.new(0, 4)
local gyroFrame = Instance.new("Frame")
gyroFrame.Size = UDim2.new(1, -16, 0, 42)
gyroFrame.Position = UDim2.new(0, 8, 0, H - 52)
gyroFrame.BackgroundTransparency = 1
gyroFrame.BorderSizePixel = 0
gyroFrame.Parent = main
local gyroBtn = Instance.new("TextButton")
gyroBtn.Size = UDim2.new(1, 0, 1, 0)
gyroBtn.BackgroundColor3 = P.elevated
gyroBtn.Text = ""
gyroBtn.BorderSizePixel = 0
gyroBtn.Parent = gyroFrame
applyCorner(gyroBtn, 8)
applyStroke(gyroBtn, P.borderHi, 1)
local gyroBar = Instance.new("Frame")
gyroBar.Size = UDim2.new(0, 2, 0.6, 0)
gyroBar.Position = UDim2.new(0, 8, 0.2, 0)
gyroBar.BackgroundColor3 = P.white
gyroBar.BorderSizePixel = 0
gyroBar.Parent = gyroBtn
applyCorner(gyroBar, 2)
local gyroLbl = Instance.new("TextLabel")
gyroLbl.Size = UDim2.new(1, -32, 1, 0)
gyroLbl.Position = UDim2.new(0, 18, 0, 0)
gyroLbl.BackgroundTransparency = 1
gyroLbl.Text = "Gyro"
gyroLbl.TextColor3 = P.white
gyroLbl.TextSize = 13
gyroLbl.Font = Enum.Font.GothamBold
gyroLbl.TextXAlignment = Enum.TextXAlignment.Left
gyroLbl.Parent = gyroBtn
local gyroChev = Instance.new("TextLabel")
gyroChev.Size = UDim2.new(0, 18, 1, 0)
gyroChev.Position = UDim2.new(1, -22, 0, 0)
gyroChev.BackgroundTransparency = 1
gyroChev.Text = "›"
gyroChev.TextColor3 = P.offWhite
gyroChev.TextSize = 18
gyroChev.Font = Enum.Font.GothamBold
gyroChev.Parent = gyroBtn
gyroBtn.MouseEnter:Connect(function()
    tw(gyroBtn, {BackgroundColor3 = P.accentBg}, 0.1)
    tw(gyroLbl, {TextColor3 = P.white}, 0.1)
end)
gyroBtn.MouseLeave:Connect(function()
    tw(gyroBtn, {BackgroundColor3 = P.elevated}, 0.1)
    tw(gyroLbl, {TextColor3 = P.white}, 0.1)
end)
gyroBtn.MouseButton1Click:Connect(function()
    sfx:Play()
    tw(gyroBtn, {BackgroundColor3 = P.accentBg}, 0.08)
    setStroke(gyroBtn, P.white, 1.5)
    task.delay(0.35, function()
        tw(gyroBtn, {BackgroundColor3 = P.elevated}, 0.25)
        setStroke(gyroBtn, P.borderHi, 1)
    end)
    local character = player.Character or player.CharacterAdded:Wait()
    local npc = game:GetService("Workspace").NPC["Bridger Zeppeli"]
    if npc and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.CFrame = npc.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
    end
end)
local farmPage = Instance.new("Frame")
farmPage.Size = UDim2.new(1, -16, 1, CONTENT_H_OFFSET)
farmPage.Position = UDim2.new(0, 8, 0, CONTENT_Y)
farmPage.BackgroundTransparency = 1
farmPage.BorderSizePixel = 0
farmPage.Visible = false
farmPage.Parent = main
local farmScroll = Instance.new("ScrollingFrame", farmPage)
farmScroll.Size = UDim2.new(1, 0, 1, 0)
farmScroll.BackgroundTransparency = 1
farmScroll.ScrollBarThickness = 2
farmScroll.ScrollBarImageColor3 = P.dim
farmScroll.BorderSizePixel = 0
local farmLayout = Instance.new("UIListLayout", farmScroll)
farmLayout.Padding = UDim.new(0, 4)
local farmPad = Instance.new("UIPadding", farmScroll)
farmPad.PaddingTop = UDim.new(0, 6)
farmPad.PaddingBottom = UDim.new(0, 6)
farmPad.PaddingRight = UDim.new(0, 4)
local toolPage = Instance.new("Frame")
toolPage.Size = UDim2.new(1, -16, 1, CONTENT_H_OFFSET)
toolPage.Position = UDim2.new(0, 8, 0, CONTENT_Y)
toolPage.BackgroundTransparency = 1
toolPage.BorderSizePixel = 0
toolPage.Visible = false
toolPage.Parent = main
local morePage = Instance.new("Frame")
morePage.Size = UDim2.new(1, -16, 1, CONTENT_H_OFFSET)
morePage.Position = UDim2.new(0, 8, 0, CONTENT_Y)
morePage.BackgroundTransparency = 1
morePage.BorderSizePixel = 0
morePage.Visible = false
morePage.Parent = main
local activeTab = "LOCATIONS"
local function selectTab(name)
    activeTab = name
    local map = {LOCATIONS = tabLocations, FARM = tabFarm, TOOLS = tabTools, MORE = tabMore}
    for k, btn in pairs(map) do
        if k == name then
            tw(btn, {BackgroundColor3 = P.accentBg, TextColor3 = P.white}, 0.15)
        else
            tw(btn, {BackgroundColor3 = P.elevated, TextColor3 = P.muted}, 0.15)
        end
    end
    locPage.Visible = (name == "LOCATIONS")
    farmPage.Visible = (name == "FARM")
    toolPage.Visible = (name == "TOOLS")
    morePage.Visible = (name == "MORE")
    gyroFrame.Visible = (name == "LOCATIONS")
end
tabLocations.MouseButton1Click:Connect(function() selectTab("LOCATIONS") end)
tabFarm.MouseButton1Click:Connect(function() selectTab("FARM") end)
tabTools.MouseButton1Click:Connect(function() selectTab("TOOLS") end)
tabMore.MouseButton1Click:Connect(function() selectTab("MORE") end)
selectTab("LOCATIONS")
local function makeTeleportRow(parent, name, pos, isFeatured)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, 38)
    row.BackgroundTransparency = 1
    row.BorderSizePixel = 0
    row.Parent = parent
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundColor3 = isFeatured and P.elevated or P.surface
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.Parent = row
    applyCorner(btn, 8)
    applyStroke(btn, isFeatured and P.borderHi or P.border, 1)
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 2, 0.6, 0)
    bar.Position = UDim2.new(0, 8, 0.2, 0)
    bar.BackgroundColor3 = isFeatured and P.white or P.dim
    bar.BorderSizePixel = 0
    bar.Parent = btn
    applyCorner(bar, 2)
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, -32, 1, 0)
    nameLbl.Position = UDim2.new(0, 18, 0, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = name
    nameLbl.TextColor3 = isFeatured and P.white or P.offWhite
    nameLbl.TextSize = 13
    nameLbl.Font = isFeatured and Enum.Font.GothamBold or Enum.Font.Gotham
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.Parent = btn
    local chev = Instance.new("TextLabel")
    chev.Size = UDim2.new(0, 18, 1, 0)
    chev.Position = UDim2.new(1, -22, 0, 0)
    chev.BackgroundTransparency = 1
    chev.Text = "›"
    chev.TextColor3 = P.dim
    chev.TextSize = 18
    chev.Font = Enum.Font.GothamBold
    chev.Parent = btn
    if not isFeatured then
        btn.MouseEnter:Connect(function()
            tw(btn, {BackgroundColor3 = P.elevated}, 0.1)
            tw(nameLbl, {TextColor3 = P.white}, 0.1)
            tw(bar, {BackgroundColor3 = P.white}, 0.1)
            tw(chev, {TextColor3 = P.offWhite}, 0.1)
        end)
        btn.MouseLeave:Connect(function()
            tw(btn, {BackgroundColor3 = P.surface}, 0.1)
            tw(nameLbl, {TextColor3 = P.offWhite}, 0.1)
            tw(bar, {BackgroundColor3 = P.dim}, 0.1)
            tw(chev, {TextColor3 = P.dim}, 0.1)
        end)
    end
    btn.MouseButton1Click:Connect(function()
        sfx:Play()
        local root = getRoot()
        if root then
            tw(btn, {BackgroundColor3 = P.accentBg}, 0.08)
            setStroke(btn, P.white, 1.5)
            task.delay(0.35, function()
                tw(btn, {BackgroundColor3 = isFeatured and P.elevated or P.surface}, 0.25)
                setStroke(btn, isFeatured and P.borderHi or P.border, 1)
            end)
            root.CFrame = CFrame.new(pos)
        end
    end)
end
local locations = {
    {"SAFE ZONE", Vector3.new(-5145.84, 45.00, -2101.92), true},
    {"Watch Tower", Vector3.new(-2190.24853515625, 269.4361267089844, -3368.840087890625), false},
    {"Waterfall", Vector3.new(-1756.296630859375, 58.399959564208984, -2983.903076171875), false},
    {"Island", Vector3.new(-2419.345703125, 65.7674789428711, -3972.93408203125), false},
    {"Pit of Doom", Vector3.new(-7040.9404296875, -201.1247100830078, -5335.8837890625), false},
    {"Finely", Vector3.new(-4193.24609375, 46.349239349365234, -3996.523681640625), false},
    {"1 Death Valley", Vector3.new(-2995.90234375, 73.22758483886719, -1723.4041748046875), false},
    {"2 Death Valley", Vector3.new(-4413.66796875, 45.263832092285156, -1976.084228515625), false},
    {"Ncantu Canyons", Vector3.new(-4012.1474609375, 44.999996185302734, -2796.994873046875), false},
    {"Uphill", Vector3.new(-5743.13134765625, 98.16923522949219, -3252.07568359375), false},
    {"1 Greenlands", Vector3.new(-7962.14794921875, 58.91941833496094, -3255.2001953125), false},
    {"2 Greenlands", Vector3.new(-8022.02001953125, 67.38140106201172, -2838.209716796875), false},
    {"Bridge", Vector3.new(-7776.4072265625, 46.77117919921875, -4476.99462890625), false},
    {"1 Outlaw Hills", Vector3.new(-3805.138916015625, 242.54742431640625, -6008.412109375), false},
    {"2 Outlaw Hills", Vector3.new(-3938.622314453125, 206.17367553710938, -5596.25830078125), false},
    {"3 Outlaw Hills", Vector3.new(-4345.6318359375, 180.96636962890625, -4845.73388671875), false},
    {"Abandoned Town", Vector3.new(-4112.12744140625, 64.75139617919922, -4981.26953125), false},
    {"Witch", Vector3.new(-2411.829833984375, 41.210044860839844, -5185.50341796875), false},
    {"Tackle Bait", Vector3.new(-3156.328369140625, 45.29399871826172, -3604.431884765625), false},
    {"Ridge B. County", Vector3.new(-5463.25732421875, 101.36617279052734, -4109.87939453125), false},
    {"Red Corner", Vector3.new(-2202.52978515625, 113.49989318847656, -3522.83251953125), false},
    {"Swamp", Vector3.new(-1743.0748291015625, 43.211673736572266, -4775.3017578125), false},
    {"Rock", Vector3.new(-3285.218994140625, 45.23649215698242, -5199.431640625), false},
    {"Sand Hole", Vector3.new(-5883.18115234375, -112.45435333251953, -2018.3060302734375), false},
}
for _, loc in ipairs(locations) do
    makeTeleportRow(locScroll, loc[1], loc[2], loc[3])
end
locScroll.CanvasSize = UDim2.new(0, 0, 0, #locations * 42 + 16)
local function makeToggleRow(parent, labelText, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -4, 0, 44)
    row.BackgroundTransparency = 1
    row.BorderSizePixel = 0
    row.LayoutOrder = order or 0
    row.Parent = parent
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundColor3 = P.surface
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.Parent = row
    applyCorner(btn, 9)
    applyStroke(btn, P.border, 1)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -80, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = P.offWhite
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = btn
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(0, 36, 0, 20)
    status.Position = UDim2.new(1, -42, 0.5, -10)
    status.BackgroundColor3 = P.elevated
    status.Text = "OFF"
    status.TextColor3 = P.muted
    status.TextSize = 9
    status.Font = Enum.Font.GothamBold
    status.Parent = btn
    applyCorner(status, 4)
    applyStroke(status, P.border, 1)
    return btn, lbl, status
end
local autoChestBtn, autoChestLbl, autoChestStatus = makeToggleRow(farmScroll, "Auto Chests", 1)
farmScroll.CanvasSize = UDim2.new(0, 0, 0, 60)
local autoChestEnabled = false
local autoChestThread = nil
local function runAutoChest()
    local cam = Workspace.CurrentCamera
    local char = player.Character or player.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")
    local savedCFrame = root.CFrame
    local savedCamType = cam.CameraType
    cam.CameraType = Enum.CameraType.Scriptable
    local function updateCam()
        cam.CFrame = CFrame.new(root.Position + Vector3.new(0, 2, 0), root.Position + Vector3.new(0, -10, 0))
    end
    local function collectChest(chest)
        local prompt = chest:FindFirstChild("ProximityPrompt", true)
        local mainPart = chest:FindFirstChild("Main") or chest:FindFirstChildWhichIsA("BasePart")
        if not prompt or not mainPart then return true end
        if not prompt.Enabled then return true end
        prompt.MaxActivationDistance = 100
        prompt.HoldDuration = 0
        root.CFrame = CFrame.new(mainPart.Position + Vector3.new(0, 0, 0)) * CFrame.Angles(math.rad(90), 0, 0)
        updateCam()
        task.wait(0.05)
        fireproximityprompt(prompt)
        task.wait(0.15)
        fireproximityprompt(prompt)
        task.wait(0.2)
        return not prompt.Enabled
    end
    while autoChestEnabled do
        char = player.Character or player.CharacterAdded:Wait()
        root = char:WaitForChild("HumanoidRootPart")
        local allChests = Workspace:WaitForChild("Chests"):GetChildren()
        local skipped = {}
        local lastCollectTime = tick()
        for _, chest in pairs(allChests) do
            if not autoChestEnabled then break end
            if chest and chest.Parent then
                local done = collectChest(chest)
                if done then
                    lastCollectTime = tick()
                else
                    table.insert(skipped, chest)
                end
                if tick() - lastCollectTime >= 3 then
                    root.CFrame = savedCFrame
                    cam.CameraType = savedCamType
                    break
                end
                task.wait(0.2)
            end
        end
        for _, chest in pairs(skipped) do
            if not autoChestEnabled then break end
            if chest and chest.Parent then
                local done = collectChest(chest)
                if done then lastCollectTime = tick() end
                if tick() - lastCollectTime >= 3 then
                    root.CFrame = savedCFrame
                    cam.CameraType = savedCamType
                    break
                end
                task.wait(0.2)
            end
        end
        if autoChestEnabled then
            root.CFrame = savedCFrame
            cam.CameraType = savedCamType
            task.wait(3)
            savedCFrame = root.CFrame
            cam.CameraType = Enum.CameraType.Scriptable
        end
    end
    root.CFrame = savedCFrame
    cam.CameraType = savedCamType
end
local function setAutoChest(on)
    autoChestEnabled = on
    if on then
        tw(autoChestBtn, {BackgroundColor3 = P.accentBg}, 0.2)
        setStroke(autoChestBtn, P.white, 1.5)
        tw(autoChestLbl, {TextColor3 = P.white}, 0.2)
        autoChestStatus.Text = "ON"
        tw(autoChestStatus, {BackgroundColor3 = P.accentBg, TextColor3 = P.white}, 0.15)
        autoChestThread = task.spawn(runAutoChest)
    else
        autoChestEnabled = false
        if autoChestThread then task.cancel(autoChestThread) autoChestThread = nil end
        tw(autoChestBtn, {BackgroundColor3 = P.surface}, 0.2)
        setStroke(autoChestBtn, P.border, 1)
        tw(autoChestLbl, {TextColor3 = P.offWhite}, 0.2)
        autoChestStatus.Text = "OFF"
        tw(autoChestStatus, {BackgroundColor3 = P.elevated, TextColor3 = P.muted}, 0.15)
        local cam = Workspace.CurrentCamera
        cam.CameraType = Enum.CameraType.Custom
    end
end
autoChestBtn.MouseButton1Click:Connect(function()
    sfx:Play()
    setAutoChest(not autoChestEnabled)
end)
local toolLayout = Instance.new("UIListLayout", toolPage)
toolLayout.Padding = UDim.new(0, 5)
local toolPad = Instance.new("UIPadding", toolPage)
toolPad.PaddingTop = UDim.new(0, 6)
toolPad.PaddingRight = UDim.new(0, 4)
local function makeSectionLabel(parent, text, order)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 20)
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.LayoutOrder = order or 0
    f.Parent = parent
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = P.muted
    l.TextSize = 10
    l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left
    return f
end
local function makeToggleRowTool(parent, labelText, order)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundTransparency = 1
    row.BorderSizePixel = 0
    row.LayoutOrder = order or 0
    row.Parent = parent
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundColor3 = P.surface
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.Parent = row
    applyCorner(btn, 9)
    applyStroke(btn, P.border, 1)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -80, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = P.offWhite
    lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = btn
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(0, 36, 0, 20)
    status.Position = UDim2.new(1, -42, 0.5, -10)
    status.BackgroundColor3 = P.elevated
    status.Text = "OFF"
    status.TextColor3 = P.muted
    status.TextSize = 9
    status.Font = Enum.Font.GothamBold
    status.Parent = btn
    applyCorner(status, 4)
    applyStroke(status, P.border, 1)
    return btn, lbl, status
end
makeSectionLabel(toolPage, "MOVEMENT", 1)
local noclipBtn, noclipLbl, noclipStatus = makeToggleRowTool(toolPage, "Noclip", 2)
local freezeBtn, freezeLbl, freezeStatus = makeToggleRowTool(toolPage, "Freeze", 3)
local infJumpBtn, infJumpLbl, infJumpStatus = makeToggleRowTool(toolPage, "Inf Jump", 4)
local espBtn, espLbl, espStatus = makeToggleRowTool(toolPage, "ESP", 5)
addBindLabel(noclipBtn)
addBindLabel(freezeBtn)
addBindLabel(infJumpBtn)
addBindLabel(espBtn)
local espNamesBtn = Instance.new("TextButton")
espNamesBtn.Size = UDim2.new(0, 26, 0, 20)
espNamesBtn.Position = UDim2.new(1, -116, 0.5, -10)
espNamesBtn.BackgroundColor3 = P.elevated
espNamesBtn.Text = "X"
espNamesBtn.TextColor3 = P.muted
espNamesBtn.TextSize = 9
espNamesBtn.Font = Enum.Font.GothamBold
espNamesBtn.ZIndex = 5
espNamesBtn.BorderSizePixel = 0
espNamesBtn.Parent = espBtn
applyCorner(espNamesBtn, 4)
applyStroke(espNamesBtn, P.border, 1)
local holeRowF = Instance.new("Frame")
holeRowF.Size = UDim2.new(1, 0, 0, 44)
holeRowF.BackgroundTransparency = 1
holeRowF.BorderSizePixel = 0
holeRowF.LayoutOrder = 6
holeRowF.Parent = toolPage
local holeBtn = Instance.new("TextButton")
holeBtn.Size = UDim2.new(1, 0, 1, 0)
holeBtn.BackgroundColor3 = P.elevated
holeBtn.Text = ""
holeBtn.BorderSizePixel = 0
holeBtn.AutoButtonColor = false
holeBtn.Parent = holeRowF
applyCorner(holeBtn, 9)
applyStroke(holeBtn, P.border, 1)
local holeLbl = Instance.new("TextLabel")
holeLbl.Size = UDim2.new(1, -90, 1, 0)
holeLbl.Position = UDim2.new(0, 14, 0, 0)
holeLbl.BackgroundTransparency = 1
holeLbl.Text = "Hole"
holeLbl.TextColor3 = P.dim
holeLbl.TextSize = 13
holeLbl.Font = Enum.Font.GothamBold
holeLbl.TextXAlignment = Enum.TextXAlignment.Left
holeLbl.Parent = holeBtn
local holeNote = Instance.new("TextLabel")
holeNote.Size = UDim2.new(1, -20, 1, 0)
holeNote.Position = UDim2.new(0, 14, 0, 0)
holeNote.BackgroundTransparency = 1
holeNote.Text = "(Noclip)"
holeNote.TextColor3 = P.dim
holeNote.TextSize = 9
holeNote.Font = Enum.Font.Gotham
holeNote.TextXAlignment = Enum.TextXAlignment.Right
holeNote.Parent = holeBtn
addBindLabel(holeBtn)
local tpSection = Instance.new("Frame")
tpSection.Size = UDim2.new(1, -16, 0, 140)
tpSection.Position = UDim2.new(0, 8, 1, -150)
tpSection.BackgroundTransparency = 1
tpSection.BorderSizePixel = 0
tpSection.Parent = toolPage
local tpDiv = Instance.new("Frame")
tpDiv.Size = UDim2.new(1, 0, 0, 1)
tpDiv.Position = UDim2.new(0, 0, 0, 0)
tpDiv.BackgroundColor3 = P.border
tpDiv.BorderSizePixel = 0
tpDiv.Parent = tpSection
local tpHeader = Instance.new("TextLabel")
tpHeader.Size = UDim2.new(1, 0, 0, 18)
tpHeader.Position = UDim2.new(0, 2, 0, 4)
tpHeader.BackgroundTransparency = 1
tpHeader.Text = "TP TO PLAYER"
tpHeader.TextColor3 = P.muted
tpHeader.TextSize = 10
tpHeader.Font = Enum.Font.GothamBold
tpHeader.TextXAlignment = Enum.TextXAlignment.Left
tpHeader.Parent = tpSection
local tpListOuter = Instance.new("Frame")
tpListOuter.Size = UDim2.new(1, 0, 0, 100)
tpListOuter.Position = UDim2.new(0, 0, 0, 26)
tpListOuter.BackgroundColor3 = P.surface
tpListOuter.BorderSizePixel = 0
tpListOuter.ClipsDescendants = true
tpListOuter.Parent = tpSection
applyCorner(tpListOuter, 8)
applyStroke(tpListOuter, P.border, 1)
local tpListScroll = Instance.new("ScrollingFrame", tpListOuter)
tpListScroll.Size = UDim2.new(1, 0, 1, 0)
tpListScroll.BackgroundTransparency = 1
tpListScroll.ScrollBarThickness = 2
tpListScroll.ScrollBarImageColor3 = P.dim
tpListScroll.BorderSizePixel = 0
local tpLayout = Instance.new("UIListLayout", tpListScroll)
tpLayout.Padding = UDim.new(0, 3)
local tpPad = Instance.new("UIPadding", tpListScroll)
tpPad.PaddingLeft = UDim.new(0, 4)
tpPad.PaddingTop = UDim.new(0, 4)
tpPad.PaddingRight = UDim.new(0, 4)
local tpStatus = Instance.new("TextLabel")
tpStatus.Size = UDim2.new(1, 0, 0, 14)
tpStatus.Position = UDim2.new(0, 2, 1, -18)
tpStatus.BackgroundTransparency = 1
tpStatus.Text = ""
tpStatus.TextColor3 = P.muted
tpStatus.TextSize = 10
tpStatus.Font = Enum.Font.Gotham
tpStatus.TextXAlignment = Enum.TextXAlignment.Left
tpStatus.Parent = tpSection
local noclipEnabled = false
local noclipConn = nil
local function startNoclip()
    if noclipConn then noclipConn:Disconnect() end
    noclipConn = Run.Stepped:Connect(function()
        local c = player.Character
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end)
end
local function stopNoclip()
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    local c = player.Character
    if c then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                p.CanCollide = true
            end
        end
    end
end
local function setNoclip(on)
    noclipEnabled = on
    if on then
        tw(noclipBtn, {BackgroundColor3 = P.accentBg}, 0.2)
        setStroke(noclipBtn, P.white, 1.5)
        tw(noclipLbl, {TextColor3 = P.white}, 0.2)
        noclipStatus.Text = "ON"
        tw(noclipStatus, {BackgroundColor3 = P.accentBg, TextColor3 = P.white}, 0.15)
        startNoclip()
    else
        tw(noclipBtn, {BackgroundColor3 = P.surface}, 0.2)
        setStroke(noclipBtn, P.border, 1)
        tw(noclipLbl, {TextColor3 = P.offWhite}, 0.2)
        noclipStatus.Text = "OFF"
        tw(noclipStatus, {BackgroundColor3 = P.elevated, TextColor3 = P.muted}, 0.15)
        stopNoclip()
    end
end
local freezeEnabled = false
local freezeConn = nil
local function setFreeze(on)
    freezeEnabled = on
    if on then
        tw(freezeBtn, {BackgroundColor3 = P.accentBg}, 0.2)
        setStroke(freezeBtn, P.white, 1.5)
        tw(freezeLbl, {TextColor3 = P.white}, 0.2)
        freezeStatus.Text = "ON"
        tw(freezeStatus, {BackgroundColor3 = P.accentBg, TextColor3 = P.white}, 0.15)
        local char = player.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid then return end
        humanoid.PlatformStand = true
        local frozenCFrame = root.CFrame
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
                part.Velocity = Vector3.new(0, 0, 0)
            end
        end
        freezeConn = Run.Heartbeat:Connect(function()
            if root and root.Parent then
                root.CFrame = frozenCFrame
                root.Velocity = Vector3.new(0, 0, 0)
                root.RotVelocity = Vector3.new(0, 0, 0)
            end
        end)
    else
        tw(freezeBtn, {BackgroundColor3 = P.surface}, 0.2)
        setStroke(freezeBtn, P.border, 1)
        tw(freezeLbl, {TextColor3 = P.offWhite}, 0.2)
        freezeStatus.Text = "OFF"
        tw(freezeStatus, {BackgroundColor3 = P.elevated, TextColor3 = P.muted}, 0.15)
        if freezeConn then freezeConn:Disconnect() freezeConn = nil end
        local char = player.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.PlatformStand = false end
        end
    end
end
local infJumpEnabled = false
local infJumpConn = nil
local function startInfJump()
    if infJumpConn then infJumpConn:Disconnect() end
    infJumpConn = UIS.JumpRequest:Connect(function()
        local h = getHumanoid()
        if h and h:GetState() ~= Enum.HumanoidStateType.Dead then
            h:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end
local function setInfJump(on)
    infJumpEnabled = on
    if on then
        tw(infJumpBtn, {BackgroundColor3 = P.accentBg}, 0.2)
        setStroke(infJumpBtn, P.white, 1.5)
        tw(infJumpLbl, {TextColor3 = P.white}, 0.2)
        infJumpStatus.Text = "ON"
        tw(infJumpStatus, {BackgroundColor3 = P.accentBg, TextColor3 = P.white}, 0.15)
        startInfJump()
    else
        tw(infJumpBtn, {BackgroundColor3 = P.surface}, 0.2)
        setStroke(infJumpBtn, P.border, 1)
        tw(infJumpLbl, {TextColor3 = P.offWhite}, 0.2)
        infJumpStatus.Text = "OFF"
        tw(infJumpStatus, {BackgroundColor3 = P.elevated, TextColor3 = P.muted}, 0.15)
        if infJumpConn then infJumpConn:Disconnect() infJumpConn = nil end
    end
end
local espEnabled = false
local espNamesEnabled = false
local espHighlights = {}
local espNameTags = {}
local espCharConns = {}
local function removeESPName(p)
    if espNameTags[p] then
        espNameTags[p]:Destroy()
        espNameTags[p] = nil
    end
end
local function addESPName(p)
    if p == player then return end
    if not espNamesEnabled or not espEnabled then return end
    local char = p.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    if espNameTags[p] and espNameTags[p].Parent then return end
    removeESPName(p)
    local bb = Instance.new("BillboardGui")
    bb.Name = "ESPName"
    bb.Size = UDim2.new(0, 100, 0, 20)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.Parent = head
    local tl = Instance.new("TextLabel", bb)
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.Text = p.Name
    tl.TextColor3 = Color3.fromRGB(255, 255, 255)
    tl.TextSize = 11
    tl.Font = Enum.Font.GothamBold
    tl.TextStrokeTransparency = 0.4
    espNameTags[p] = bb
end
local function removeESPHighlight(p)
    if espHighlights[p] then
        espHighlights[p]:Destroy()
        espHighlights[p] = nil
    end
    removeESPName(p)
    if espCharConns[p] then
        espCharConns[p]:Disconnect()
        espCharConns[p] = nil
    end
end
local function applyESPToChar(p)
    if p == player then return end
    if not espEnabled then return end
    local char = p.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Dead then return end
    if espHighlights[p] then espHighlights[p]:Destroy() espHighlights[p] = nil end
    removeESPName(p)
    local h = Instance.new("Highlight")
    h.FillColor = Color3.fromRGB(255, 0, 0)
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.FillTransparency = 0.5
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = char
    espHighlights[p] = h
    addESPName(p)
    humanoid.Died:Connect(function()
        if espHighlights[p] then espHighlights[p]:Destroy() espHighlights[p] = nil end
        removeESPName(p)
    end)
end
local function addESPHighlight(p)
    if p == player then return end
    if not espEnabled then return end
    applyESPToChar(p)
    if espCharConns[p] then espCharConns[p]:Disconnect() end
    espCharConns[p] = p.CharacterAdded:Connect(function()
        task.wait(0.2)
        applyESPToChar(p)
    end)
end
local function setESPNames(on)
    espNamesEnabled = on
    if on then
        tw(espNamesBtn, {BackgroundColor3 = P.accentBg, TextColor3 = P.white}, 0.15)
        setStroke(espNamesBtn, P.white, 1.5)
        if espEnabled then
            for _, p in Players:GetPlayers() do addESPName(p) end
        end
    else
        tw(espNamesBtn, {BackgroundColor3 = P.elevated, TextColor3 = P.muted}, 0.15)
        setStroke(espNamesBtn, P.border, 1)
        for p in pairs(espNameTags) do removeESPName(p) end
    end
end
espNamesBtn.MouseButton1Click:Connect(function()
    if not espEnabled then return end
    sfx:Play()
    setESPNames(not espNamesEnabled)
end)
local function setESP(on)
    espEnabled = on
    if on then
        tw(espBtn, {BackgroundColor3 = P.accentBg}, 0.2)
        setStroke(espBtn, P.white, 1.5)
        tw(espLbl, {TextColor3 = P.white}, 0.2)
        espStatus.Text = "ON"
        tw(espStatus, {BackgroundColor3 = P.accentBg, TextColor3 = P.white}, 0.15)
        if espNamesEnabled then
            tw(espNamesBtn, {BackgroundColor3 = P.accentBg, TextColor3 = P.white}, 0.15)
            setStroke(espNamesBtn, P.white, 1.5)
        end
        for _, p in Players:GetPlayers() do
            addESPHighlight(p)
        end
        Players.PlayerAdded:Connect(function(p)
            if not espEnabled then return end
            addESPHighlight(p)
        end)
        Players.PlayerRemoving:Connect(removeESPHighlight)
        task.spawn(function()
            while espEnabled do
                for _, p in Players:GetPlayers() do
                    if p ~= player then
                        local char = p.Character
                        local isAlive = char and char:FindFirstChildOfClass("Humanoid")
                            and char:FindFirstChildOfClass("Humanoid"):GetState() ~= Enum.HumanoidStateType.Dead
                        if isAlive then
                            if not espHighlights[p] or not espHighlights[p].Parent then
                                applyESPToChar(p)
                            end
                            if espNamesEnabled and (not espNameTags[p] or not espNameTags[p].Parent) then
                                addESPName(p)
                            end
                        else
                            if espHighlights[p] then espHighlights[p]:Destroy() espHighlights[p] = nil end
                            removeESPName(p)
                        end
                    end
                end
                task.wait(1)
            end
        end)
    else
        tw(espBtn, {BackgroundColor3 = P.surface}, 0.2)
        setStroke(espBtn, P.border, 1)
        tw(espLbl, {TextColor3 = P.offWhite}, 0.2)
        espStatus.Text = "OFF"
        tw(espStatus, {BackgroundColor3 = P.elevated, TextColor3 = P.muted}, 0.15)
        for p in pairs(espHighlights) do removeESPHighlight(p) end
        for p in pairs(espNameTags) do removeESPName(p) end
        if espNamesEnabled then
            tw(espNamesBtn, {BackgroundColor3 = P.elevated, TextColor3 = P.muted}, 0.15)
            setStroke(espNamesBtn, P.border, 1)
        end
    end
end
local function doHoleDrop()
    if not noclipEnabled then return end
    local root = getRoot()
    if root then root.CFrame = root.CFrame * CFrame.new(0, -5, 0) end
end
btnActions[noclipBtn] = function() sfx:Play() setNoclip(not noclipEnabled) end
btnActions[freezeBtn] = function() sfx:Play() setFreeze(not freezeEnabled) end
btnActions[infJumpBtn] = function() sfx:Play() setInfJump(not infJumpEnabled) end
btnActions[espBtn] = function() sfx:Play() setESP(not espEnabled) end
btnActions[holeBtn] = function()
    if not noclipEnabled then return end
    sfx:Play()
    doHoleDrop()
    tw(holeBtn, {BackgroundColor3 = P.accentBg}, 0.1)
    task.delay(0.25, function() tw(holeBtn, {BackgroundColor3 = P.surface}, 0.2) end)
end
noclipBtn.MouseButton1Click:Connect(function() btnActions[noclipBtn]() end)
freezeBtn.MouseButton1Click:Connect(function() btnActions[freezeBtn]() end)
infJumpBtn.MouseButton1Click:Connect(function() btnActions[infJumpBtn]() end)
espBtn.MouseButton1Click:Connect(function() btnActions[espBtn]() end)
holeBtn.MouseButton1Click:Connect(function() btnActions[holeBtn]() end)
noclipBtn.MouseButton2Click:Connect(function() startBind(noclipBtn) end)
freezeBtn.MouseButton2Click:Connect(function() startBind(freezeBtn) end)
infJumpBtn.MouseButton2Click:Connect(function() startBind(infJumpBtn) end)
espBtn.MouseButton2Click:Connect(function() startBind(espBtn) end)
holeBtn.MouseButton2Click:Connect(function() startBind(holeBtn) end)
UIS.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if bindingBtn then
        local btn = bindingBtn
        if input.KeyCode == Enum.KeyCode.Escape then
            binds[btn] = nil
            stopBinding()
            return
        end
        local keyName = input.KeyCode.Name
        if keyName == "Unknown" then return end
        binds[btn] = keyName
        stopBinding()
        return
    end
    if gameProcessed then return end
    local keyName = input.KeyCode.Name
    for btn, key in pairs(binds) do
        if key == keyName then
            local action = btnActions[btn]
            if action then action() end
        end
    end
end)
local function refreshTpList()
    for _, c in ipairs(tpListScroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    local count = 0
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p ~= player then
            count += 1
            local pb = Instance.new("TextButton")
            pb.Size = UDim2.new(1, 0, 0, 30)
            pb.BackgroundColor3 = P.elevated
            pb.Text = p.Name
            pb.TextColor3 = P.offWhite
            pb.TextSize = 12
            pb.Font = Enum.Font.Gotham
            pb.BorderSizePixel = 0
            pb.Parent = tpListScroll
            applyCorner(pb, 6)
            applyStroke(pb, P.border, 1)
            pb.MouseEnter:Connect(function() tw(pb, {BackgroundColor3 = P.accentBg, TextColor3 = P.white}, 0.1) end)
            pb.MouseLeave:Connect(function() tw(pb, {BackgroundColor3 = P.elevated, TextColor3 = P.offWhite}, 0.1) end)
            pb.MouseButton1Click:Connect(function()
                local root = getRoot()
                local tr = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                if root and tr then
                    sfx:Play()
                    root.CFrame = tr.CFrame * CFrame.new(3, 0, 0)
                    tpStatus.Text = "→ " .. p.Name
                    tpStatus.TextColor3 = P.white
                end
            end)
        end
    end
    tpListScroll.CanvasSize = UDim2.new(0, 0, 0, count * 33 + 8)
end
game.Players.PlayerAdded:Connect(refreshTpList)
game.Players.PlayerRemoving:Connect(refreshTpList)
player.CharacterAdded:Connect(function() task.wait(1) refreshTpList() end)
task.delay(1, refreshTpList)
local moreLayout = Instance.new("UIListLayout", morePage)
moreLayout.Padding = UDim.new(0, 5)
local morePad = Instance.new("UIPadding", morePage)
morePad.PaddingTop = UDim.new(0, 6)
morePad.PaddingRight = UDim.new(0, 4)
local snifferSection = Instance.new("Frame")
snifferSection.Size = UDim2.new(1, 0, 0, 20)
snifferSection.BackgroundTransparency = 1
snifferSection.BorderSizePixel = 0
snifferSection.LayoutOrder = 1
snifferSection.Parent = morePage
local snifferSectionLbl = Instance.new("TextLabel", snifferSection)
snifferSectionLbl.Size = UDim2.new(1, 0, 1, 0)
snifferSectionLbl.BackgroundTransparency = 1
snifferSectionLbl.Text = "SNIFFER"
snifferSectionLbl.TextColor3 = P.muted
snifferSectionLbl.TextSize = 10
snifferSectionLbl.Font = Enum.Font.GothamBold
snifferSectionLbl.TextXAlignment = Enum.TextXAlignment.Left
local snifferRow = Instance.new("Frame")
snifferRow.Size = UDim2.new(1, 0, 0, 44)
snifferRow.BackgroundTransparency = 1
snifferRow.BorderSizePixel = 0
snifferRow.LayoutOrder = 2
snifferRow.Parent = morePage
local snifferBtn = Instance.new("TextButton")
snifferBtn.Size = UDim2.new(1, 0, 1, 0)
snifferBtn.BackgroundColor3 = P.surface
snifferBtn.Text = ""
snifferBtn.BorderSizePixel = 0
snifferBtn.Parent = snifferRow
applyCorner(snifferBtn, 9)
applyStroke(snifferBtn, P.border, 1)
local snifferLbl = Instance.new("TextLabel")
snifferLbl.Size = UDim2.new(1, -80, 1, 0)
snifferLbl.Position = UDim2.new(0, 14, 0, 0)
snifferLbl.BackgroundTransparency = 1
snifferLbl.Text = "Sniffer"
snifferLbl.TextColor3 = P.offWhite
snifferLbl.TextSize = 13
snifferLbl.Font = Enum.Font.GothamBold
snifferLbl.TextXAlignment = Enum.TextXAlignment.Left
snifferLbl.Parent = snifferBtn
local snifferStatus = Instance.new("TextLabel")
snifferStatus.Size = UDim2.new(0, 36, 0, 20)
snifferStatus.Position = UDim2.new(1, -42, 0.5, -10)
snifferStatus.BackgroundColor3 = P.elevated
snifferStatus.Text = "OFF"
snifferStatus.TextColor3 = P.muted
snifferStatus.TextSize = 9
snifferStatus.Font = Enum.Font.GothamBold
snifferStatus.Parent = snifferBtn
applyCorner(snifferStatus, 4)
applyStroke(snifferStatus, P.border, 1)
local snifferEnabled = false
local snifferThread = nil
local SNIFF_TARGETS = {
    ["Dogbane Herb"] = true,
}
local function isSniffTarget(name)
    if SNIFF_TARGETS[name] then return true end
    if string.find(name, "Moolah Bundle", 1, true) then return true end
    return false
end
local function runSniffer()
    local savedCFrame = nil
    while snifferEnabled do
        local root = getRoot()
        if not root then task.wait(0.5) continue end
        local herbs = {}
        for _, obj in ipairs(game:GetService("Workspace"):GetChildren()) do
            if isSniffTarget(obj.Name) then
                table.insert(herbs, obj)
            end
        end
        if #herbs > 0 then
            savedCFrame = root.CFrame
            for _, herb in ipairs(herbs) do
                if not snifferEnabled then break end
                if herb and herb.Parent then
                    local herbPart = herb:IsA("BasePart") and herb
                        or herb:FindFirstChildWhichIsA("BasePart")
                    if herbPart then
                        root = getRoot()
                        if root then
                            root.CFrame = CFrame.new(herbPart.Position + Vector3.new(0, 3, 0))
                            task.wait(0.4)
                        end
                    end
                end
            end
            root = getRoot()
            if root and savedCFrame then
                root.CFrame = savedCFrame
                savedCFrame = nil
            end
            task.wait(1)
        else
            task.wait(0.3)
        end
    end
    local root = getRoot()
    if root and savedCFrame then root.CFrame = savedCFrame end
    savedCFrame = nil
end
local function setSniffer(on)
    snifferEnabled = on
    if on then
        tw(snifferBtn, {BackgroundColor3 = P.accentBg}, 0.2)
        setStroke(snifferBtn, P.white, 1.5)
        tw(snifferLbl, {TextColor3 = P.white}, 0.2)
        snifferStatus.Text = "ON"
        tw(snifferStatus, {BackgroundColor3 = P.accentBg, TextColor3 = P.white}, 0.15)
        snifferThread = task.spawn(runSniffer)
    else
        snifferEnabled = false
        if snifferThread then task.cancel(snifferThread) snifferThread = nil end
        tw(snifferBtn, {BackgroundColor3 = P.surface}, 0.2)
        setStroke(snifferBtn, P.border, 1)
        tw(snifferLbl, {TextColor3 = P.offWhite}, 0.2)
        snifferStatus.Text = "OFF"
        tw(snifferStatus, {BackgroundColor3 = P.elevated, TextColor3 = P.muted}, 0.15)
    end
end
snifferBtn.MouseEnter:Connect(function() tw(snifferBtn, {BackgroundColor3 = snifferEnabled and P.accentBg or P.elevated}, 0.1) end)
snifferBtn.MouseLeave:Connect(function() tw(snifferBtn, {BackgroundColor3 = snifferEnabled and P.accentBg or P.surface}, 0.1) end)
snifferBtn.MouseButton1Click:Connect(function() sfx:Play() setSniffer(not snifferEnabled) end)
local autoClickSection = Instance.new("Frame")
autoClickSection.Size = UDim2.new(1, 0, 0, 20)
autoClickSection.BackgroundTransparency = 1
autoClickSection.BorderSizePixel = 0
autoClickSection.LayoutOrder = 3
autoClickSection.Parent = morePage
local autoClickSectionLbl = Instance.new("TextLabel", autoClickSection)
autoClickSectionLbl.Size = UDim2.new(1, 0, 1, 0)
autoClickSectionLbl.BackgroundTransparency = 1
autoClickSectionLbl.Text = "AUTO CLICKER"
autoClickSectionLbl.TextColor3 = P.muted
autoClickSectionLbl.TextSize = 10
autoClickSectionLbl.Font = Enum.Font.GothamBold
autoClickSectionLbl.TextXAlignment = Enum.TextXAlignment.Left
local autoClickRow = Instance.new("Frame")
autoClickRow.Size = UDim2.new(1, 0, 0, 44)
autoClickRow.BackgroundTransparency = 1
autoClickRow.BorderSizePixel = 0
autoClickRow.LayoutOrder = 4
autoClickRow.Parent = morePage
local autoClickBtn = Instance.new("TextButton")
autoClickBtn.Size = UDim2.new(1, 0, 1, 0)
autoClickBtn.BackgroundColor3 = P.surface
autoClickBtn.Text = ""
autoClickBtn.BorderSizePixel = 0
autoClickBtn.Parent = autoClickRow
applyCorner(autoClickBtn, 9)
applyStroke(autoClickBtn, P.border, 1)
local autoClickLbl = Instance.new("TextLabel")
autoClickLbl.Size = UDim2.new(1, -80, 1, 0)
autoClickLbl.Position = UDim2.new(0, 14, 0, 0)
autoClickLbl.BackgroundTransparency = 1
autoClickLbl.Text = "Auto Clicker"
autoClickLbl.TextColor3 = P.offWhite
autoClickLbl.TextSize = 13
autoClickLbl.Font = Enum.Font.GothamBold
autoClickLbl.TextXAlignment = Enum.TextXAlignment.Left
autoClickLbl.Parent = autoClickBtn
local autoClickStatus = Instance.new("TextLabel")
autoClickStatus.Size = UDim2.new(0, 36, 0, 20)
autoClickStatus.Position = UDim2.new(1, -42, 0.5, -10)
autoClickStatus.BackgroundColor3 = P.elevated
autoClickStatus.Text = "OFF"
autoClickStatus.TextColor3 = P.muted
autoClickStatus.TextSize = 9
autoClickStatus.Font = Enum.Font.GothamBold
autoClickStatus.Parent = autoClickBtn
applyCorner(autoClickStatus, 4)
applyStroke(autoClickStatus, P.border, 1)
addBindLabel(autoClickBtn)
local autoClickEnabled = false
local autoClickThread = nil
local function setAutoClicker(on)
    autoClickEnabled = on
    if on then
        tw(autoClickBtn, {BackgroundColor3 = P.accentBg}, 0.2)
        setStroke(autoClickBtn, P.white, 1.5)
        tw(autoClickLbl, {TextColor3 = P.white}, 0.2)
        autoClickStatus.Text = "ON"
        tw(autoClickStatus, {BackgroundColor3 = P.accentBg, TextColor3 = P.white}, 0.15)
        autoClickThread = task.spawn(function()
            local mouse = player:GetMouse()
            while autoClickEnabled do
                mouse1click()
                task.wait(0.06)
            end
        end)
    else
        autoClickEnabled = false
        if autoClickThread then task.cancel(autoClickThread) autoClickThread = nil end
        tw(autoClickBtn, {BackgroundColor3 = P.surface}, 0.2)
        setStroke(autoClickBtn, P.border, 1)
        tw(autoClickLbl, {TextColor3 = P.offWhite}, 0.2)
        autoClickStatus.Text = "OFF"
        tw(autoClickStatus, {BackgroundColor3 = P.elevated, TextColor3 = P.muted}, 0.15)
    end
end
btnActions[autoClickBtn] = function() sfx:Play() setAutoClicker(not autoClickEnabled) end
autoClickBtn.MouseButton1Click:Connect(function() btnActions[autoClickBtn]() end)
autoClickBtn.MouseButton2Click:Connect(function() startBind(autoClickBtn) end)
local spectateSection = Instance.new("Frame")
spectateSection.Size = UDim2.new(1, 0, 0, 20)
spectateSection.BackgroundTransparency = 1
spectateSection.BorderSizePixel = 0
spectateSection.LayoutOrder = 5
spectateSection.Parent = morePage
local spectateSectionLbl = Instance.new("TextLabel", spectateSection)
spectateSectionLbl.Size = UDim2.new(1, 0, 1, 0)
spectateSectionLbl.BackgroundTransparency = 1
spectateSectionLbl.Text = "SPECTATE"
spectateSectionLbl.TextColor3 = P.muted
spectateSectionLbl.TextSize = 10
spectateSectionLbl.Font = Enum.Font.GothamBold
spectateSectionLbl.TextXAlignment = Enum.TextXAlignment.Left
local spectateRow = Instance.new("Frame")
spectateRow.Size = UDim2.new(1, 0, 0, 110)
spectateRow.BackgroundTransparency = 1
spectateRow.BorderSizePixel = 0
spectateRow.LayoutOrder = 6
spectateRow.Parent = morePage
local spectateOuter = Instance.new("Frame")
spectateOuter.Size = UDim2.new(1, 0, 1, 0)
spectateOuter.BackgroundColor3 = P.surface
spectateOuter.BorderSizePixel = 0
spectateOuter.ClipsDescendants = true
spectateOuter.Parent = spectateRow
applyCorner(spectateOuter, 8)
applyStroke(spectateOuter, P.border, 1)
local spectateScroll = Instance.new("ScrollingFrame", spectateOuter)
spectateScroll.Size = UDim2.new(1, 0, 1, 0)
spectateScroll.BackgroundTransparency = 1
spectateScroll.ScrollBarThickness = 2
spectateScroll.ScrollBarImageColor3 = P.dim
spectateScroll.BorderSizePixel = 0
local spectateLayout = Instance.new("UIListLayout", spectateScroll)
spectateLayout.Padding = UDim.new(0, 3)
local spectatePad = Instance.new("UIPadding", spectateScroll)
spectatePad.PaddingLeft = UDim.new(0, 4)
spectatePad.PaddingTop = UDim.new(0, 4)
spectatePad.PaddingRight = UDim.new(0, 4)
local spectateStatus = Instance.new("TextLabel")
spectateStatus.Size = UDim2.new(1, 0, 0, 14)
spectateStatus.BackgroundTransparency = 1
spectateStatus.Text = ""
spectateStatus.TextColor3 = P.muted
spectateStatus.TextSize = 10
spectateStatus.Font = Enum.Font.Gotham
spectateStatus.TextXAlignment = Enum.TextXAlignment.Left
spectateStatus.LayoutOrder = 6
spectateStatus.Parent = morePage
local spectateTarget = nil
local spectateConn = nil
local spectateFreezeConn = nil

local function spectateUnfreezeLocal()
    if spectateFreezeConn then spectateFreezeConn:Disconnect() spectateFreezeConn = nil end
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
            hum.PlatformStand = false
        end
    end
end

local function spectateFreezeLocal()
    spectateUnfreezeLocal()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end
    hum.WalkSpeed = 0
    hum.JumpPower = 0
    hum.PlatformStand = true
    local frozenCF = root.CFrame
    spectateFreezeConn = Run.Heartbeat:Connect(function()
        if root and root.Parent then
            root.CFrame = frozenCF
            root.Velocity = Vector3.new(0,0,0)
            root.RotVelocity = Vector3.new(0,0,0)
        end
    end)
end

local function stopSpectate()
    if spectateConn then spectateConn:Disconnect() spectateConn = nil end
    spectateTarget = nil
    spectateUnfreezeLocal()
    local cam = workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Custom
    cam.CameraSubject = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    spectateStatus.Text = ""
    spectateStatus.TextColor3 = P.muted
end

local function startSpectate(target)
    stopSpectate()
    spectateTarget = target
    local cam = workspace.CurrentCamera
    cam.CameraType = Enum.CameraType.Custom
    local function attachCam()
        local char = target.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            cam.CameraSubject = hum
            spectateStatus.Text = ">> " .. target.Name
            spectateStatus.TextColor3 = P.white
        end
    end
    attachCam()
    spectateFreezeLocal()
    spectateConn = target.CharacterAdded:Connect(function()
        task.wait(0.2)
        attachCam()
    end)
end

player.CharacterAdded:Connect(function()
    if spectateTarget then
        task.wait(0.3)
        spectateFreezeLocal()
    end
end)
local function refreshSpectateList()
    for _, c in ipairs(spectateScroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    local count = 0
    for _, p in ipairs(game.Players:GetPlayers()) do
        if p ~= player then
            count += 1
            local isActive = (spectateTarget == p)
            local pb = Instance.new("TextButton")
            pb.Size = UDim2.new(1, 0, 0, 30)
            pb.BackgroundColor3 = isActive and P.accentBg or P.elevated
            pb.Text = p.Name
            pb.TextColor3 = isActive and P.white or P.offWhite
            pb.TextSize = 12
            pb.Font = Enum.Font.Gotham
            pb.BorderSizePixel = 0
            pb.Parent = spectateScroll
            applyCorner(pb, 6)
            applyStroke(pb, isActive and P.white or P.border, isActive and 1.5 or 1)
            pb.MouseEnter:Connect(function()
                if spectateTarget ~= p then
                    tw(pb, {BackgroundColor3 = P.accentBg, TextColor3 = P.white}, 0.1)
                end
            end)
            pb.MouseLeave:Connect(function()
                if spectateTarget ~= p then
                    tw(pb, {BackgroundColor3 = P.elevated, TextColor3 = P.offWhite}, 0.1)
                end
            end)
            pb.MouseButton1Click:Connect(function()
                sfx:Play()
                if spectateTarget == p then
                    stopSpectate()
                    tw(pb, {BackgroundColor3 = P.elevated, TextColor3 = P.offWhite}, 0.15)
                    setStroke(pb, P.border, 1)
                else
                    for _, c2 in ipairs(spectateScroll:GetChildren()) do
                        if c2:IsA("TextButton") and c2 ~= pb then
                            tw(c2, {BackgroundColor3 = P.elevated, TextColor3 = P.offWhite}, 0.1)
                            setStroke(c2, P.border, 1)
                        end
                    end
                    startSpectate(p)
                    tw(pb, {BackgroundColor3 = P.accentBg, TextColor3 = P.white}, 0.15)
                    setStroke(pb, P.white, 1.5)
                end
            end)
        end
    end
    spectateScroll.CanvasSize = UDim2.new(0, 0, 0, count * 33 + 8)
end
game.Players.PlayerAdded:Connect(function()
    refreshSpectateList()
end)
game.Players.PlayerRemoving:Connect(function(p)
    if spectateTarget == p then stopSpectate() end
    task.wait(0.05)
    refreshSpectateList()
end)
task.delay(1, refreshSpectateList)

local webhookSection = Instance.new("Frame")
webhookSection.Size = UDim2.new(1, 0, 0, 20)
webhookSection.BackgroundTransparency = 1
webhookSection.BorderSizePixel = 0
webhookSection.LayoutOrder = 7
webhookSection.Parent = morePage
local webhookSectionLbl = Instance.new("TextLabel", webhookSection)
webhookSectionLbl.Size = UDim2.new(1, 0, 1, 0)
webhookSectionLbl.BackgroundTransparency = 1
webhookSectionLbl.Text = "WEBHOOK"
webhookSectionLbl.TextColor3 = P.muted
webhookSectionLbl.TextSize = 10
webhookSectionLbl.Font = Enum.Font.GothamBold
webhookSectionLbl.TextXAlignment = Enum.TextXAlignment.Left

local webhookRow = Instance.new("Frame")
webhookRow.Size = UDim2.new(1, 0, 0, 44)
webhookRow.BackgroundTransparency = 1
webhookRow.BorderSizePixel = 0
webhookRow.LayoutOrder = 8
webhookRow.Parent = morePage

local webhookBg = Instance.new("Frame")
webhookBg.Size = UDim2.new(1, 0, 1, 0)
webhookBg.BackgroundColor3 = P.surface
webhookBg.BorderSizePixel = 0
webhookBg.Parent = webhookRow
applyCorner(webhookBg, 9)
applyStroke(webhookBg, P.border, 1)

local webhookIcon = Instance.new("TextLabel")
webhookIcon.Size = UDim2.new(0, 55, 1, 0)
webhookIcon.Position = UDim2.new(0, 8, 0, 0)
webhookIcon.BackgroundTransparency = 1
webhookIcon.Text = "Webhook"
webhookIcon.TextColor3 = P.offWhite
webhookIcon.TextSize = 12
webhookIcon.Font = Enum.Font.GothamBold
webhookIcon.TextXAlignment = Enum.TextXAlignment.Left
webhookIcon.Parent = webhookBg

local webhookInput = Instance.new("TextBox")
webhookInput.Size = UDim2.new(0, 170, 0, 28)
webhookInput.Position = UDim2.new(0, 75, 0.5, -14)
webhookInput.BackgroundColor3 = P.elevated
webhookInput.Text = ""
webhookInput.PlaceholderText = "Webhook URL"
webhookInput.PlaceholderColor3 = P.muted
webhookInput.TextColor3 = P.white
webhookInput.TextSize = 10
webhookInput.Font = Enum.Font.Gotham
webhookInput.BorderSizePixel = 0
webhookInput.ClearTextOnFocus = false
webhookInput.ClipsDescendants = true
webhookInput.TextXAlignment = Enum.TextXAlignment.Left
webhookInput.Parent = webhookBg
applyCorner(webhookInput, 5)
applyStroke(webhookInput, P.border, 1)
local webhookInputPad = Instance.new("UIPadding")
webhookInputPad.PaddingLeft = UDim.new(0, 6)
webhookInputPad.PaddingRight = UDim.new(0, 6)
webhookInputPad.Parent = webhookInput

local webhookStatus = Instance.new("TextLabel")
webhookStatus.Size = UDim2.new(0, 30, 0, 28)
webhookStatus.Position = UDim2.new(1, -38, 0.5, -14)
webhookStatus.BackgroundColor3 = P.elevated
webhookStatus.Text = "*"
webhookStatus.TextColor3 = P.muted
webhookStatus.TextSize = 18
webhookStatus.Font = Enum.Font.GothamBold
webhookStatus.TextXAlignment = Enum.TextXAlignment.Center
webhookStatus.Parent = webhookBg
applyCorner(webhookStatus, 5)
applyStroke(webhookStatus, P.border, 1)

webhookInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local url = webhookInput.Text
        if url ~= "" and (string.find(url, "discord.com/api/webhooks") or string.find(url, "discordapp.com/api/webhooks")) then
            webhookUrl = url
            saveWebhook(url)
            webhookStatus.Text = "*"
            webhookStatus.BackgroundColor3 = P.accentBg
            webhookStatus.TextColor3 = P.white
            setStroke(webhookStatus, P.white, 1.5)
            sendTestWebhook()
        else
            webhookUrl = ""
            saveWebhook("")
            webhookStatus.Text = "*"
            webhookStatus.BackgroundColor3 = P.elevated
            webhookStatus.TextColor3 = P.muted
            setStroke(webhookStatus, P.border, 1)
        end
    end
end)

if webhookUrl ~= "" then
    webhookStatus.Text = "*"
    webhookStatus.BackgroundColor3 = P.accentBg
    webhookStatus.TextColor3 = P.white
    setStroke(webhookStatus, P.white, 1.5)
end

local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
local minimized = false
local origSize = UDim2.new(0, W, 0, H)
local function toggleMinimize()
    minimized = not minimized
    if minimized then
        task.spawn(function()
            tw(main, {Size = UDim2.new(0, W, 0, 46)}, 0.25)
            task.wait(0.28)
            locPage.Visible = false
            farmPage.Visible = false
            toolPage.Visible = false
            morePage.Visible = false
            tabBar.Visible = false
            gyroFrame.Visible = false
        end)
    else
        task.spawn(function()
            main.Size = UDim2.new(0, W, 0, 46)
            tw(main, {Size = origSize}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            task.wait(0.38)
            tabBar.Visible = true
            locPage.Visible = (activeTab == "LOCATIONS")
            farmPage.Visible = (activeTab == "FARM")
            toolPage.Visible = (activeTab == "TOOLS")
            morePage.Visible = (activeTab == "MORE")
            gyroFrame.Visible = (activeTab == "LOCATIONS")
        end)
    end
end
minimizeBtn.MouseButton1Click:Connect(function() sfx:Play() toggleMinimize() end)
