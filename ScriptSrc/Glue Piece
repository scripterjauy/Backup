local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- settings
local SIZE = Vector3.new(60, 60, 60)
local DELAY = 0.1
local TOOL_NAME = nil -- weapon name, nil = first tool found
local TP_DIST = 8     -- default distance from the NPC (the slider changes this)
local NPC_LIST = {"Thug", "Evil Thug", "King Slime", "Elite Noob", "Cutie Noob", "Snake", "Slime"}
local BOSS_LIST = {"Unknown Boss", "Sword Master", "Sans", "Nooby", "Duck Boss", "King Noob", "Kyo", "Chara", "Cutie Boss"}
local ISLAND_LIST = {
    "Safe Zone Island", "Starter Island", "Second Island", "Third Island", "Fourth Island",
    "Fifth Island", "Nine Island", "Cutie Noob Island", "Judgement Island", "Duck Island",
    "Sans Island", "Sand Island", "Kyo Island", "Sky Island", "Tiny Statue Island", "Sword Master Island",
}
local STATS = {
    {label = "Sword",      stat = "Melee"}, -- label is what you see, stat is what gets sent
    {label = "Strength",   stat = "Strength"},
    {label = "Defense",    stat = "Defense"},
    {label = "DevilFruit", stat = "DevilFruit"},
}
local STAT_DELAY = 0

-- kill the previous run of this script
local env = (getgenv and getgenv()) or _G
if env.ThugHubCleanup then pcall(env.ThugHubCleanup) end

local OLD = {"ThugHub", "AutoAttack", "HitboxToggle", "SwordToggle"}
local function clearOld(container)
    if not container then return end
    for _, n in ipairs(OLD) do
        local g = container:FindFirstChild(n)
        if g then g:Destroy() end
    end
end
pcall(function() clearOld(gethui and gethui()) end)
pcall(function() clearOld(game:GetService("CoreGui")) end)
pcall(function() clearOld(player:FindFirstChild("PlayerGui")) end)

-- state
local alive = true
local farming, hitbox = false, false
local sliding = false -- true while dragging the distance slider
local MODES = {"Behind", "Above", "Below"}
local modeIndex = 1
local selectedNpc = NPC_LIST[1]
local selectedBosses = {} -- set of selected boss names (multi-select)
local selectedIsland = nil -- island picked in the Teleport tab
local statOn = {}
local originals = {}
local conns = {}

local function getNpcFolder()
    if not selectedNpc then return nil end
    local npcs = workspace:FindFirstChild("NPCs")
    return npcs and npcs:FindFirstChild(selectedNpc) or nil
end

-- list of folders/models for every selected boss that currently exists
local function getBossFolders()
    local out = {}
    local npcs = workspace:FindFirstChild("NPCs")
    local bosses = npcs and npcs:FindFirstChild("Boss")
    if not bosses then return out end
    for _, name in ipairs(BOSS_LIST) do
        if selectedBosses[name] then
            local f = bosses:FindFirstChild(name)
            if f then table.insert(out, f) end
        end
    end
    return out
end

local function restore()
    for part, data in pairs(originals) do
        if part and part.Parent then
            part.Size = data.Size
            part.Transparency = data.Transparency
            part.CanCollide = data.CanCollide
        end
    end
    originals = {}
end

-- UI
local gui = Instance.new("ScreenGui")
gui.Name = "ThugHub"
gui.ResetOnSpawn = false
local ok = pcall(function() gui.Parent = gethui and gethui() or game:GetService("CoreGui") end)
if not ok or not gui.Parent then gui.Parent = player:WaitForChild("PlayerGui") end

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 270)
frame.Position = UDim2.new(0.5, -120, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 26)
title.BackgroundTransparency = 1
title.Text = "Glue Piece"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.Parent = frame

-- tabs
local pages, tabBtns = {}, {}
local function makePage(name)
    local p = Instance.new("Frame")
    p.Size = UDim2.new(1, 0, 1, -62)
    p.Position = UDim2.new(0, 0, 0, 62)
    p.BackgroundTransparency = 1
    p.Visible = false
    p.Parent = frame
    pages[name] = p
    return p
end

local function showTab(name)
    for n, p in pairs(pages) do p.Visible = (n == name) end
    for n, b in pairs(tabBtns) do
        b.BackgroundColor3 = (n == name) and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(40, 40, 40)
    end
end

local function makeTab(name, index)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 53, 0, 28)
    b.Position = UDim2.new(0, 8 + (index - 1) * 57, 0, 28)
    b.Text = name
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextScaled = true
    Instance.new("UITextSizeConstraint", b).MaxTextSize = 13
    b.Parent = frame
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    tabBtns[name] = b
    b.MouseButton1Click:Connect(function() showTab(name) end)
end

local mainPage = makePage("Main")
local npcPage = makePage("NPC")
local statsPage = makePage("Stats")
local teleportPage = makePage("Teleport")
makeTab("Main", 1)
makeTab("NPC", 2)
makeTab("Stats", 3)
makeTab("Teleport", 4)

local function makeToggle(parent, text, y, onChange)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -16, 0, 32)
    b.Position = UDim2.new(0, 8, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(170, 50, 50)
    b.Text = text .. ": OFF"
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    local state = false
    b.MouseButton1Click:Connect(function()
        state = not state
        b.Text = text .. ": " .. (state and "ON" or "OFF")
        b.BackgroundColor3 = state and Color3.fromRGB(50, 170, 80) or Color3.fromRGB(170, 50, 50)
        onChange(state)
    end)
end

-- MAIN tab
makeToggle(mainPage, "Auto Farm", 4, function(s) farming = s end)
makeToggle(mainPage, "Hitbox", 42, function(s)
    hitbox = s
    if not s then restore() end
end)

local modeBtn = Instance.new("TextButton")
modeBtn.Size = UDim2.new(1, -16, 0, 32)
modeBtn.Position = UDim2.new(0, 8, 0, 80)
modeBtn.BackgroundColor3 = Color3.fromRGB(50, 90, 170)
modeBtn.Text = "Pos: " .. MODES[modeIndex]
modeBtn.TextColor3 = Color3.new(1, 1, 1)
modeBtn.Font = Enum.Font.GothamBold
modeBtn.TextSize = 14
modeBtn.Parent = mainPage
Instance.new("UICorner", modeBtn).CornerRadius = UDim.new(0, 6)
modeBtn.MouseButton1Click:Connect(function()
    modeIndex = modeIndex % #MODES + 1
    modeBtn.Text = "Pos: " .. MODES[modeIndex]
end)

-- Haki (Main tab)
local haki = false

local function fireHaki()
    local char = player.Character
    local tool = player.Backpack:FindFirstChild("Busoshoku") or (char and char:FindFirstChild("Busoshoku"))
    local remote = tool and tool:FindFirstChild("Remote") and tool.Remote:FindFirstChild("Haki_Event")
    if remote then pcall(function() remote:FireServer() end) end
end

makeToggle(mainPage, "Haki", 118, function(s)
    haki = s
    if s then fireHaki() end -- turn on now
end)

-- Distance slider (Main tab) - how close you stay to the target
local MIN_D, MAX_D = 2, 30

local sliderLabel = Instance.new("TextLabel")
sliderLabel.Size = UDim2.new(1, -16, 0, 18)
sliderLabel.Position = UDim2.new(0, 8, 0, 156)
sliderLabel.BackgroundTransparency = 1
sliderLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
sliderLabel.Font = Enum.Font.Gotham
sliderLabel.TextSize = 13
sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
sliderLabel.Parent = mainPage

local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, -32, 0, 8)
bar.Position = UDim2.new(0, 16, 0, 184)
bar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
bar.BorderSizePixel = 0
bar.Parent = mainPage
Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

local fill = Instance.new("Frame")
fill.BackgroundColor3 = Color3.fromRGB(50, 90, 170)
fill.BorderSizePixel = 0
fill.Parent = bar
Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

local knob = Instance.new("Frame")
knob.Size = UDim2.new(0, 18, 0, 18)
knob.AnchorPoint = Vector2.new(0.5, 0.5)
knob.BackgroundColor3 = Color3.new(1, 1, 1)
knob.BorderSizePixel = 0
knob.Parent = bar
Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

-- bigger invisible touch area so it's easy to grab on mobile
local hit = Instance.new("Frame")
hit.Size = UDim2.new(1, 0, 0, 30)
hit.Position = UDim2.new(0, 0, 0.5, -15)
hit.BackgroundTransparency = 1
hit.Parent = bar

local function setDist(alpha)
    alpha = math.clamp(alpha, 0, 1)
    TP_DIST = math.floor(MIN_D + (MAX_D - MIN_D) * alpha + 0.5)
    local a = (TP_DIST - MIN_D) / (MAX_D - MIN_D)
    fill.Size = UDim2.new(a, 0, 1, 0)
    knob.Position = UDim2.new(a, 0, 0.5, 0)
    sliderLabel.Text = "Distance: " .. TP_DIST
end
setDist((TP_DIST - MIN_D) / (MAX_D - MIN_D))

local function sliderFromInput(input)
    setDist((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X)
end

hit.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        sliding = true
        sliderFromInput(input)
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then sliding = false end
        end)
    end
end)
table.insert(conns, UIS.InputChanged:Connect(function(input)
    if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        sliderFromInput(input)
    end
end))

-- NPC tab dropdowns
local openLists = {}

local function makeLabelAndButton(parent, labelText, y)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -16, 0, 20)
    lbl.Position = UDim2.new(0, 8, 0, y)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -16, 0, 32)
    btn.Position = UDim2.new(0, 8, 0, y + 22)
    btn.BackgroundColor3 = Color3.fromRGB(50, 90, 170)
    btn.Text = "Select  v"
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local function makeListFrame(parent, y, rowCount, maxH)
    local lst = Instance.new("ScrollingFrame")
    lst.Size = UDim2.new(1, -16, 0, math.min(rowCount * 30, maxH))
    lst.Position = UDim2.new(0, 8, 0, y + 56)
    lst.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    lst.BorderSizePixel = 0
    lst.Visible = false
    lst.Active = true
    lst.ZIndex = 5
    lst.ScrollBarThickness = 4
    lst.CanvasSize = UDim2.new(0, 0, 0, rowCount * 30)
    lst.Parent = parent
    Instance.new("UICorner", lst).CornerRadius = UDim.new(0, 6)
    Instance.new("UIListLayout", lst).Padding = UDim.new(0, 2)
    table.insert(openLists, lst)
    return lst
end

local function makeRow(lst, text)
    local o = Instance.new("TextButton")
    o.Size = UDim2.new(1, -6, 0, 28)
    o.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    o.Text = text
    o.TextColor3 = Color3.new(1, 1, 1)
    o.Font = Enum.Font.Gotham
    o.TextSize = 14
    o.ZIndex = 6
    o.Parent = lst
    Instance.new("UICorner", o).CornerRadius = UDim.new(0, 6)
    return o
end

local function toggleList(lst)
    local show = not lst.Visible
    for _, l in ipairs(openLists) do l.Visible = false end
    lst.Visible = show
end

-- single-select dropdown (NPCs), with a "None" row
local function makeDropdown(parent, labelText, y, items, maxH, onPick)
    local btn = makeLabelAndButton(parent, labelText, y)
    local lst = makeListFrame(parent, y, #items + 1, maxH)
    local none = makeRow(lst, "None")
    none.MouseButton1Click:Connect(function()
        lst.Visible = false
        onPick(nil)
    end)
    for _, name in ipairs(items) do
        local o = makeRow(lst, name)
        o.MouseButton1Click:Connect(function()
            lst.Visible = false
            onPick(name)
        end)
    end
    btn.MouseButton1Click:Connect(function() toggleList(lst) end)
    return btn
end

-- multi-select dropdown (bosses): tap rows to toggle, list stays open
local function makeMultiDropdown(parent, labelText, y, items, maxH, set, onChange)
    local btn = makeLabelAndButton(parent, labelText, y)
    local lst = makeListFrame(parent, y, #items + 1, maxH)
    local rowBtns = {}

    local function refresh()
        local names = {}
        for _, n in ipairs(items) do
            local on = set[n] == true
            rowBtns[n].Text = (on and "[x] " or "[ ] ") .. n
            rowBtns[n].BackgroundColor3 = on and Color3.fromRGB(50, 130, 80) or Color3.fromRGB(55, 55, 55)
            if on then table.insert(names, n) end
        end
        if #names == 0 then
            btn.Text = "Select  v"
        elseif #names == 1 then
            btn.Text = names[1] .. "  v"
        else
            btn.Text = #names .. " selected  v"
        end
    end

    local clear = makeRow(lst, "Clear all")
    clear.MouseButton1Click:Connect(function()
        for _, n in ipairs(items) do set[n] = nil end
        refresh()
        onChange()
    end)

    for _, name in ipairs(items) do
        local o = makeRow(lst, name)
        rowBtns[name] = o
        o.MouseButton1Click:Connect(function()
            set[name] = (not set[name]) or nil
            refresh()
            onChange()
        end)
    end

    btn.MouseButton1Click:Connect(function() toggleList(lst) end)
    refresh()
    return btn
end

local npcBtn
npcBtn = makeDropdown(npcPage, "Select NPCs for farm", 4, NPC_LIST, 112, function(name)
    selectedNpc = name
    npcBtn.Text = (name or "Select") .. "  v"
    restore() -- put old targets back to normal size
end)
npcBtn.Text = selectedNpc .. "  v"

makeMultiDropdown(npcPage, "Select Boss for farm", 62, BOSS_LIST, 88, selectedBosses, function()
    restore()
end)

-- TELEPORT tab
-- finds a safe spot on top of an island: bounding box of its parts, then raycast down from above its center
local function getIslandSpot(island)
    local minX, minY, minZ, maxX, maxY, maxZ
    local function add(p)
        local h = p.Size / 2
        local pos = p.Position
        minX = minX and math.min(minX, pos.X - h.X) or (pos.X - h.X)
        minY = minY and math.min(minY, pos.Y - h.Y) or (pos.Y - h.Y)
        minZ = minZ and math.min(minZ, pos.Z - h.Z) or (pos.Z - h.Z)
        maxX = maxX and math.max(maxX, pos.X + h.X) or (pos.X + h.X)
        maxY = maxY and math.max(maxY, pos.Y + h.Y) or (pos.Y + h.Y)
        maxZ = maxZ and math.max(maxZ, pos.Z + h.Z) or (pos.Z + h.Z)
    end
    if island:IsA("BasePart") then add(island) end
    for _, d in ipairs(island:GetDescendants()) do
        if d:IsA("BasePart") then add(d) end
    end
    if not minX then return nil end

    local cx, cz = (minX + maxX) / 2, (minZ + maxZ) / 2
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {player.Character}
    local result = workspace:Raycast(
        Vector3.new(cx, maxY + 50, cz),
        Vector3.new(0, -((maxY - minY) + 200), 0),
        params
    )
    if result then
        return result.Position + Vector3.new(0, 5, 0)
    end
    return Vector3.new(cx, maxY + 10, cz)
end

local function teleportToIsland()
    if not selectedIsland then return false, "Pick an island first" end
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local map = workspace:FindFirstChild("Map")
    local island = map and map:FindFirstChild(selectedIsland)
    if not (root and island) then return false, "Island not found" end
    local spot = getIslandSpot(island)
    if not spot then return false, "Island not found" end
    root.CFrame = CFrame.new(spot)
    root.AssemblyLinearVelocity = Vector3.zero
    return true, "Teleported!"
end

local islandBtn
islandBtn = makeDropdown(teleportPage, "Select Island to teleport", 4, ISLAND_LIST, 130, function(name)
    selectedIsland = name
    islandBtn.Text = (name or "Select") .. "  v"
end)

local tpBtn = Instance.new("TextButton")
tpBtn.Size = UDim2.new(1, -16, 0, 32)
tpBtn.Position = UDim2.new(0, 8, 0, 64)
tpBtn.BackgroundColor3 = Color3.fromRGB(50, 170, 80)
tpBtn.Text = "Teleport"
tpBtn.TextColor3 = Color3.new(1, 1, 1)
tpBtn.Font = Enum.Font.GothamBold
tpBtn.TextSize = 14
tpBtn.Parent = teleportPage
Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 6)
tpBtn.MouseButton1Click:Connect(function()
    local _, msg = teleportToIsland()
    tpBtn.Text = msg
    task.delay(1, function()
        if tpBtn.Parent then tpBtn.Text = "Teleport" end
    end)
end)

-- STATS tab (label = what you see, stat = what gets sent)
for i, s in ipairs(STATS) do
    statOn[s.stat] = false
    makeToggle(statsPage, s.label, 4 + (i - 1) * 38, function(on) statOn[s.stat] = on end)
end

showTab("Main")

-- open/close button
local openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.new(0, 40, 0, 40)
openBtn.Position = UDim2.new(0, 10, 0.4, 0)
openBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
openBtn.Text = "-"
openBtn.TextColor3 = Color3.new(1, 1, 1)
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 22
openBtn.Parent = gui
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 8)
openBtn.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
    openBtn.Text = frame.Visible and "-" or "+"
end)

-- cleanup (runs automatically next time you execute the script)
local function cleanup()
    alive = false
    farming, hitbox, haki = false, false, false
    for k in pairs(statOn) do statOn[k] = false end
    restore()
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    gui:Destroy()
end
env.ThugHubCleanup = cleanup

-- drag helper (menu + open button); menu doesn't move while using the slider
local function makeDraggable(obj)
    local dragging, dragStart, startPos
    obj.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = obj.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    table.insert(conns, UIS.InputChanged:Connect(function(input)
        if sliding then return end
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                     startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))
end
makeDraggable(frame)
makeDraggable(openBtn)

-- auto farm: attack loop
local function getTool()
    local char = player.Character
    if not char then return end
    return (TOOL_NAME and (char:FindFirstChild(TOOL_NAME) or player.Backpack:FindFirstChild(TOOL_NAME)))
        or char:FindFirstChildOfClass("Tool")
        or player.Backpack:FindFirstChildOfClass("Tool")
end

task.spawn(function()
    while alive do
        if farming then
            local tool = getTool()
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if tool and hum then
                if tool.Parent ~= char then hum:EquipTool(tool) end
                pcall(function() tool:Activate() end)
            end
        end
        task.wait(DELAY)
    end
end)

-- stats loop
local function getStatRemote()
    local r = ReplicatedStorage:FindFirstChild("Remote")
    r = r and r:FindFirstChild("RemoteEvent")
    return r and r:FindFirstChild("UI_Event")
end

task.spawn(function()
    while alive do
        local remote = getStatRemote()
        if remote then
            for _, s in ipairs(STATS) do
                if statOn[s.stat] then
                    pcall(function() remote:FireServer("Add Stats", s.stat, "1") end)
                end
            end
        end
        task.wait(STAT_DELAY)
    end
end)

-- hitbox loop (applies to every selected boss AND the selected NPC)
local function applyHitbox(folder)
    if not folder then return end
    for _, v in ipairs(folder:GetDescendants()) do
        if v.Name == "HumanoidRootPart" and v:IsA("BasePart") then
            if not originals[v] then
                originals[v] = {
                    Size = v.Size,
                    Transparency = v.Transparency,
                    CanCollide = v.CanCollide,
                }
            end
            v.Size = SIZE
            v.Transparency = 0.8
            v.CanCollide = false
        end
    end
end

task.spawn(function()
    while alive do
        if hitbox then
            for _, f in ipairs(getBossFolders()) do applyHitbox(f) end
            applyHitbox(getNpcFolder())
        end
        task.wait(0.5)
    end
end)

-- keep collision off every physics step (stops the flinging)
table.insert(conns, RunService.Stepped:Connect(function()
    if not hitbox then return end
    for part in pairs(originals) do
        if part.Parent then part.CanCollide = false end
    end
end))

-- auto farm target: nearest living selected boss first, otherwise nearest living NPC
local function nearestAlive(folder, root)
    if not folder then return nil end
    local best, bestDist
    for _, v in ipairs(folder:GetDescendants()) do
        if v.Name == "HumanoidRootPart" and v:IsA("BasePart") then
            local hum = v.Parent:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local d = (v.Position - root.Position).Magnitude
                if not bestDist or d < bestDist then
                    best, bestDist = v, d
                end
            end
        end
    end
    return best, bestDist
end

local function getTarget()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local best, bestDist
    for _, folder in ipairs(getBossFolders()) do
        local p, d = nearestAlive(folder, root)
        if p and (not bestDist or d < bestDist) then
            best, bestDist = p, d
        end
    end
    if best then return best end

    return (nearestAlive(getNpcFolder(), root))
end

table.insert(conns, RunService.Heartbeat:Connect(function()
    if not farming then return end
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local target = getTarget()
    if not (root and target) then return end

    local tp = target.Position
    local mode = MODES[modeIndex]
    if mode == "Behind" then
        local pos = (target.CFrame * CFrame.new(0, 0, TP_DIST)).Position
        root.CFrame = CFrame.lookAt(pos, Vector3.new(tp.X, pos.Y, tp.Z))
    elseif mode == "Above" then
        root.CFrame = CFrame.lookAt(tp + Vector3.new(0, TP_DIST, 0), tp, Vector3.new(0, 0, 1))
    else
        root.CFrame = CFrame.lookAt(tp - Vector3.new(0, TP_DIST, 0), tp, Vector3.new(0, 0, 1))
    end
    root.AssemblyLinearVelocity = Vector3.zero
end))

-- re-enable haki after every respawn
table.insert(conns, player.CharacterAdded:Connect(function()
    if not haki then return end
    local bp = player:WaitForChild("Backpack")
    bp:WaitForChild("Busoshoku", 10) -- wait for the tool to load in
    task.wait(1)
    if haki and alive then fireHaki() end
end))
