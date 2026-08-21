local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("PeaRemotes")
local EatAction = Remotes:WaitForChild("EatAction")
local StateUpdate = Remotes:WaitForChild("StateUpdate")
local ScoreUpdate = Remotes:WaitForChild("ScoreUpdate")
local PlayerWon = Remotes:WaitForChild("PlayerWon")

local isEating = false
local currentState = "Safe"
local crunchSound = nil

-- UI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PeaGameUI"
screenGui.Parent = Player:WaitForChild("PlayerGui")

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, 400, 0, 50)
statusLabel.Position = UDim2.new(0.5, -200, 0, 50)
statusLabel.TextSize = 35
statusLabel.Font = Enum.Font.FredokaOne
statusLabel.Text = "SAFE (NEWSPAPER UP)"
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
statusLabel.TextStrokeTransparency = 0
statusLabel.BackgroundTransparency = 1
statusLabel.Parent = screenGui

local progressBg = Instance.new("Frame")
progressBg.Size = UDim2.new(0, 400, 0, 30)
progressBg.Position = UDim2.new(0.5, -200, 1, -100)
progressBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
progressBg.BorderSizePixel = 2
progressBg.Parent = screenGui

local progressFill = Instance.new("Frame")
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
progressFill.BorderSizePixel = 0
progressFill.Parent = progressBg

local progressText = Instance.new("TextLabel")
progressText.Size = UDim2.new(1, 0, 1, 0)
progressText.BackgroundTransparency = 1
progressText.Text = "0 / 100 Peas"
progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
progressText.TextStrokeTransparency = 0
progressText.Font = Enum.Font.FredokaOne
progressText.TextSize = 20
progressText.Parent = progressBg

local function getNPCJoints()
	local map = Workspace:FindFirstChild("PeaGameMap")
	if map then
		local npc = map:FindFirstChild("ReaderNPC")
		if npc then
			local torso = npc:FindFirstChild("Torso")
			if torso then
				return torso:FindFirstChild("Left Shoulder"), torso:FindFirstChild("Right Shoulder")
			end
		end
	end
	return nil, nil
end

local function animateNPC(isSafe)
	local leftShoulder, rightShoulder = getNPCJoints()
	if not leftShoulder or not rightShoulder then return end
	
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	
	local leftTarget, rightTarget
	if isSafe then
		-- SAFE: Left Arm UP (reading newspaper), Right Arm DOWN (resting gun)
		leftTarget = CFrame.new(-1, 0.5, 0) * CFrame.Angles(math.rad(90), -math.pi/2, 0)
		rightTarget = CFrame.new(1, 0.5, 0) * CFrame.Angles(0, math.pi/2, 0)
	else
		-- DANGER: Left Arm DOWN (slammed on table), Right Arm UP (aiming gun)
		leftTarget = CFrame.new(-1, 0.5, 0) * CFrame.Angles(0, -math.pi/2, 0)
		rightTarget = CFrame.new(1, 0.5, 0) * CFrame.Angles(math.rad(90), math.pi/2, 0)
	end
	
	TweenService:Create(leftShoulder, tweenInfo, {C0 = leftTarget}):Play()
	TweenService:Create(rightShoulder, tweenInfo, {C0 = rightTarget}):Play()
end

local eatingAnim = Instance.new("Animation")
eatingAnim.AnimationId = "rbxassetid://507770677" -- Official Roblox Cheer Anim (Placeholder)
local eatingTrack = nil

local function setEating(state)
	local character = Player.Character
	if isEating == state then return end
	if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health <= 0 then
		state = false
	end

	isEating = state
	
	if not crunchSound then
		local map = Workspace:FindFirstChild("PeaGameMap")
		if map then
			crunchSound = map:FindFirstChild("CrunchSound")
		end
	end
	
	local humanoid = character and character:FindFirstChild("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator") or (humanoid and humanoid:FindFirstChild("Animator"))
	
	if isEating then
		if animator and not eatingTrack then
			eatingTrack = animator:LoadAnimation(eatingAnim)
		end
		if eatingTrack then
			eatingTrack:Play()
		end
		
		if crunchSound then
			crunchSound.Looped = true
			crunchSound:Play()
		end
	else
		if eatingTrack then
			eatingTrack:Stop()
		end
		
		if crunchSound then
			crunchSound:Stop()
		end
	end
end

local Mouse = Player:GetMouse()
local RunService = game:GetService("RunService")
local lastClickTime = 0

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local stationVal = Player:FindFirstChild("AssignedStation")
		local assignedStation = stationVal and stationVal.Value
		local myPlate = assignedStation and assignedStation:FindFirstChild("Plate", true)
		
		if myPlate then
			local target = Mouse.Target
			-- Allow clicking the plate itself, or any Pea inside the assigned station
			if target == myPlate or (target and target.Name == "Pea" and target:IsDescendantOf(assignedStation)) then
				lastClickTime = os.clock()
				EatAction:FireServer()
			else
				-- If they are clicking something else (e.g. another plate), ignore it
			end
		end
	end
end)

RunService.RenderStepped:Connect(function()
	-- Keep eating animation playing if they clicked recently (within 0.4 seconds)
	if os.clock() - lastClickTime < 0.4 then
		setEating(true)
	else
		setEating(false)
	end
end)

StateUpdate.OnClientEvent:Connect(function(newState)
	currentState = newState
	animateNPC(newState == "Safe")
	if newState == "Safe" then
		statusLabel.Text = "SAFE (NEWSPAPER UP)"
		statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
	else
		statusLabel.Text = "DANGER (NEWSPAPER DOWN)"
		statusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
	end
end)

ScoreUpdate.OnClientEvent:Connect(function(score)
	local percent = math.clamp(score / 100, 0, 1)
	TweenService:Create(progressFill, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Size = UDim2.new(percent, 0, 1, 0)}):Play()
	progressText.Text = tostring(score) .. " / 100 Peas"
end)

PlayerWon.OnClientEvent:Connect(function(winnerName)
	statusLabel.Text = winnerName .. " WON!"
	statusLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
	setEating(false)
end)
local PlayerCaught = Remotes:WaitForChild("PlayerCaught")

local defaultNPCCFrame = nil

PlayerCaught.OnClientEvent:Connect(function(caughtPlayer)
	local map = Workspace:FindFirstChild("PeaGameMap")
	local npc = map and map:FindFirstChild("ReaderNPC")
	if not npc then return end
	
	local root = npc:IsA("Model") and npc.PrimaryPart or npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("BasePart")
	if not root then return end
	
	if not defaultNPCCFrame then
		defaultNPCCFrame = root.CFrame
	end
	
	local targetChar = caughtPlayer:IsA("Player") and caughtPlayer.Character or caughtPlayer
	local targetHead = targetChar and (targetChar:FindFirstChild("Head") or targetChar:FindFirstChild("HumanoidRootPart"))
	
	if targetHead then
		-- Swivel on Y-axis only
		local lookPos = Vector3.new(targetHead.Position.X, root.Position.Y, targetHead.Position.Z)
		local targetCFrame = CFrame.lookAt(root.Position, lookPos)
		
		TweenService:Create(root, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetCFrame}):Play()
		
		-- == MEME SEQUENCE (SINGLE AUDIO FILE) ==
		local memeSound = Instance.new("Sound")
		memeSound.SoundId = "rbxassetid://74930156127990" -- Custom Anime Meme Sound
		memeSound.Volume = 2
		memeSound.Parent = root
		
		memeSound:Play()
		
		-- TIMING SETUP: Adjust this number to exactly match when "Nani!?" happens in your MP3!
		local secondsUntilNani = 3.0 -- Guessing Nani happens around 3 seconds in your 5 second clip
		task.wait(secondsUntilNani)
		
		-- Flash eyes red (exactly when Nani plays)
		local head = npc:FindFirstChild("Head") or root
		local eyeBaseCFrame = head and head.CFrame or root.CFrame
		
		local leftEye = Instance.new("Part")
		leftEye.Size = Vector3.new(0.38, 0.38, 0.38)
		leftEye.Shape = Enum.PartType.Ball
		leftEye.Color = Color3.fromRGB(255, 0, 0)
		leftEye.Material = Enum.Material.Neon
		leftEye.CanCollide = false
		leftEye.Anchored = true
		leftEye.CFrame = eyeBaseCFrame * CFrame.new(-0.28, 0.0, -0.52)
		leftEye.Parent = Workspace
		
		local rightEye = leftEye:Clone()
		rightEye.CFrame = eyeBaseCFrame * CFrame.new(0.28, 0.0, -0.52)
		rightEye.Parent = Workspace
		
		-- Intense menacing red glow lights
		local glowLight = Instance.new("PointLight")
		glowLight.Name = "EyeGlow"
		glowLight.Color = Color3.fromRGB(255, 20, 20)
		glowLight.Range = 10
		glowLight.Brightness = 4.5
		glowLight.Shadows = false
		glowLight.Parent = leftEye
		
		local glowLight2 = glowLight:Clone()
		glowLight2.Parent = rightEye
		
		-- Wait for the rest of the 5-second audio to finish
		task.wait(5.0 - secondsUntilNani) 
		
		-- Cleanup visual/audio
		leftEye:Destroy()
		rightEye:Destroy()
		memeSound:Destroy()
		
		task.delay(1.5, function()
			TweenService:Create(root, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = defaultNPCCFrame}):Play()
		end)
	end
end)
Player.CharacterAdded:Connect(function(char)
	isEating = false
	if crunchSound then crunchSound:Stop() end
end)

-- Robust initial NPC setup
task.spawn(function()
	local map = Workspace:WaitForChild("PeaGameMap")
	local npc = map:WaitForChild("ReaderNPC")
	local torso = npc:WaitForChild("Torso")
	torso:WaitForChild("Left Shoulder")
	torso:WaitForChild("Right Shoulder")
	
	local stateVal = ReplicatedStorage:WaitForChild("GameState")
	currentState = stateVal.Value
	
	if currentState == "Safe" then
		statusLabel.Text = "SAFE (NEWSPAPER UP)"
		statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
	else
		statusLabel.Text = "DANGER (NEWSPAPER DOWN)"
		statusLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
	end
	
	animateNPC(currentState == "Safe")
end)
