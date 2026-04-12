-- Made by Claude ft. me lol

-- =====================================
-- CLEANUP
-- =====================================

for _, gui in ipairs(game.CoreGui:GetChildren()) do
	if gui.Name == "ProximityUI" then
		gui:Destroy()
	end
end

task.wait(0.1)

-- =====================================
-- SERVICES
-- =====================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
end)

local autoTrigger = false

-- =====================================
-- CORE FUNCTIONS
-- =====================================

local function getPartPosition(part)
	if part == nil then return nil end
	if part:IsA("BasePart") then
		return part.Position
	elseif part:IsA("Model") then
		local primary = part.PrimaryPart
		if primary then return primary.Position end
		for _, v in ipairs(part:GetDescendants()) do
			if v:IsA("BasePart") then return v.Position end
		end
	else
		local p = part.Parent
		while p and p ~= workspace do
			if p:IsA("BasePart") then return p.Position end
			if p:IsA("Model") and p.PrimaryPart then return p.PrimaryPart.Position end
			p = p.Parent
		end
	end
	return nil
end

local function getVisiblePrompt()
	local camera = workspace.CurrentCamera
	local screenSize = camera.ViewportSize
	local centerX = screenSize.X / 2
	local centerY = screenSize.Y / 2

	local closestPrompt = nil
	local closestDist = math.huge

	for _, prompt in ipairs(workspace:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") and prompt.Enabled then
			local pos = getPartPosition(prompt.Parent)
			if pos then
				local screenPos, onScreen = camera:WorldToScreenPoint(pos)
				if onScreen then
					local distFromCenter = Vector2.new(screenPos.X - centerX, screenPos.Y - centerY).Magnitude
					if distFromCenter < closestDist then
						closestDist = distFromCenter
						closestPrompt = prompt
					end
				end
			end
		end
	end

	return closestPrompt
end

local function sendNotif(title, message)
	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = title,
		Text = message,
		Duration = 3
	})
end

local function triggerNearestPrompt()
	local prompt = getVisiblePrompt()
	if prompt then
		pcall(fireproximityprompt, prompt)
		pcall(function() fireclickdetector(prompt) end)
		pcall(function() prompt.Triggered:Fire(player) end)

		sendNotif("✅ Triggered", prompt.ActionText)
		return true
	else
		sendNotif("❌ Not Found", "No visible prompt on screen")
	end
	return false
end

-- =====================================
-- GUI
-- =====================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ProximityUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = game.CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 230, 0, 160)
frame.Position = UDim2.new(0.5, -115, 1, 20)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 16)
frameCorner.Parent = frame

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 40)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 20)),
})
gradient.Rotation = 135
gradient.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(100, 80, 255)
stroke.Thickness = 1.5
stroke.Transparency = 0.4
stroke.Parent = frame

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 25, 55)
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 5
titleBar.Parent = frame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 16)
titleCorner.Parent = titleBar

local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 16)
titleFix.Position = UDim2.new(0, 0, 1, -16)
titleFix.BackgroundColor3 = Color3.fromRGB(30, 25, 55)
titleFix.BorderSizePixel = 0
titleFix.ZIndex = 5
titleFix.Parent = titleBar

local dot = Instance.new("Frame")
dot.Size = UDim2.new(0, 8, 0, 8)
dot.Position = UDim2.new(0, 14, 0.5, -4)
dot.BackgroundColor3 = Color3.fromRGB(120, 90, 255)
dot.BorderSizePixel = 0
dot.ZIndex = 6
dot.Parent = titleBar

local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = dot

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -60, 1, 0)
titleLabel.Position = UDim2.new(0, 30, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Proximity Trigger"
titleLabel.TextColor3 = Color3.fromRGB(220, 215, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 13
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 6
titleLabel.Parent = titleBar

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -34, 0.5, -14)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.BorderSizePixel = 0
closeBtn.ZIndex = 7
closeBtn.Parent = titleBar

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(1, 0)
closeBtnCorner.Parent = closeBtn

-- Status label
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 0, 48)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Idle"
statusLabel.TextColor3 = Color3.fromRGB(140, 130, 200)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

-- =====================================
-- BUTTONS
-- =====================================

local function createButton(text, color, posX)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 98, 0, 44)
	btn.Position = UDim2.new(0, posX, 0, 78)
	btn.BackgroundColor3 = color
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.BorderSizePixel = 0
	btn.Parent = frame

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = btn

	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(
			math.min(color.R * 255 + 40, 255),
			math.min(color.G * 255 + 30, 255),
			math.min(color.B * 255 + 40, 255)
		)),
		ColorSequenceKeypoint.new(1, color),
	})
	g.Rotation = 135
	g.Parent = btn

	return btn
end

local triggerBtn = createButton("⚡ Trigger", Color3.fromRGB(80, 60, 200), 12)
local autoBtn = createButton("🔁 Auto: OFF", Color3.fromRGB(160, 40, 40), 120)

-- Resize frame to fit input box
frame.Size = UDim2.new(0, 230, 0, 210)

-- Delay label
local delayLabel = Instance.new("TextLabel")
delayLabel.Size = UDim2.new(0, 100, 0, 20)
delayLabel.Position = UDim2.new(0, 12, 0, 132)
delayLabel.BackgroundTransparency = 1
delayLabel.Text = "Auto Delay (s):"
delayLabel.TextColor3 = Color3.fromRGB(140, 130, 200)
delayLabel.Font = Enum.Font.Gotham
delayLabel.TextSize = 11
delayLabel.TextXAlignment = Enum.TextXAlignment.Left
delayLabel.Parent = frame

-- Input box
local delayInput = Instance.new("TextBox")
delayInput.Size = UDim2.new(0, 206, 0, 36)
delayInput.Position = UDim2.new(0, 12, 0, 155)
delayInput.BackgroundColor3 = Color3.fromRGB(25, 22, 45)
delayInput.TextColor3 = Color3.fromRGB(220, 215, 255)
delayInput.PlaceholderText = "Enter delay e.g. 0.5"
delayInput.PlaceholderColor3 = Color3.fromRGB(80, 70, 120)
delayInput.Text = "0.5"
delayInput.Font = Enum.Font.GothamBold
delayInput.TextSize = 13
delayInput.BorderSizePixel = 0
delayInput.ClearTextOnFocus = false
delayInput.Parent = frame

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 10)
inputCorner.Parent = delayInput

local inputStroke = Instance.new("UIStroke")
inputStroke.Color = Color3.fromRGB(100, 80, 255)
inputStroke.Thickness = 1.2
inputStroke.Transparency = 0.5
inputStroke.Parent = delayInput

-- =====================================
-- HELPER FUNCTIONS
-- =====================================

local function animatePress(btn)
	TweenService:Create(btn, TweenInfo.new(0.08), {Size = UDim2.new(0, 93, 0, 40)}):Play()
	task.delay(0.08, function()
		TweenService:Create(btn, TweenInfo.new(0.12), {Size = UDim2.new(0, 98, 0, 44)}):Play()
	end)
end

local function setStatus(text, color)
	statusLabel.Text = "Status: " .. text
	TweenService:Create(statusLabel, TweenInfo.new(0.3), {
		TextColor3 = color
	}):Play()
end

local isClosing = false
local function closeUI()
	if isClosing then return end
	isClosing = true
	autoTrigger = false
	TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, -115, 1, 20)
	}):Play()
	task.delay(0.45, function()
		screenGui:Destroy()
	end)
end

-- =====================================
-- BUTTON LOGIC
-- =====================================

triggerBtn.Activated:Connect(function()
	animatePress(triggerBtn)
	local success = triggerNearestPrompt()
	if success then
		setStatus("Triggered!", Color3.fromRGB(100, 255, 140))
		task.delay(1.5, function()
			setStatus("Idle", Color3.fromRGB(140, 130, 200))
		end)
	else
		setStatus("None in range", Color3.fromRGB(255, 100, 100))
		task.delay(1.5, function()
			setStatus("Idle", Color3.fromRGB(140, 130, 200))
		end)
	end
end)

autoBtn.Activated:Connect(function()
	animatePress(autoBtn)
	autoTrigger = not autoTrigger
	if autoTrigger then
		autoBtn.Text = "🔁 Auto: ON"
		TweenService:Create(autoBtn, TweenInfo.new(0.3), {
			BackgroundColor3 = Color3.fromRGB(40, 160, 80)
		}):Play()
		setStatus("Auto ON", Color3.fromRGB(100, 255, 140))
	else
		autoBtn.Text = "🔁 Auto: OFF"
		TweenService:Create(autoBtn, TweenInfo.new(0.3), {
			BackgroundColor3 = Color3.fromRGB(160, 40, 40)
		}):Play()
		setStatus("Idle", Color3.fromRGB(140, 130, 200))
	end
end)

closeBtn.Activated:Connect(function()
	closeUI()
end)

-- =====================================
-- DRAGGING (Mobile Fixed)
-- =====================================

local dragging = false
local touchStartPos = nil
local frameStartPos = nil

titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		touchStartPos = Vector2.new(input.Position.X, input.Position.Y)
		frameStartPos = Vector2.new(frame.Position.X.Offset, frame.Position.Y.Offset)
	end
end)

titleBar.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseMove) then
		local delta = Vector2.new(input.Position.X, input.Position.Y) - touchStartPos
		frame.Position = UDim2.new(
			frame.Position.X.Scale,
			frameStartPos.X + delta.X,
			frame.Position.Y.Scale,
			frameStartPos.Y + delta.Y
		)
	end
end)

titleBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
		touchStartPos = nil
		frameStartPos = nil
	end
end)

-- =====================================
-- AUTO TRIGGER LOOP
-- =====================================

local ticker = 0
RunService.Heartbeat:Connect(function(dt)
	if autoTrigger then
		ticker += dt
		local delay = tonumber(delayInput.Text) or 0.5
		if ticker >= delay then
			ticker = 0
			local success = triggerNearestPrompt()
			if success then
				setStatus("Auto fired!", Color3.fromRGB(100, 255, 140))
			else
				setStatus("Searching...", Color3.fromRGB(200, 180, 100))
			end
		end
	end
end)

-- =====================================
-- ENTRANCE ANIMATION
-- =====================================

TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
	Position = UDim2.new(0.5, -115, 0.75, 0)
}):Play()
