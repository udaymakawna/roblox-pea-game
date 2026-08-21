--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:FindFirstChild("PeaRemotes")
if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "PeaRemotes"
	Remotes.Parent = ReplicatedStorage
end

local function getRemote(name)
	local r = Remotes:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = Remotes
	end
	return r
end

local EatAction = getRemote("EatAction")
local StateUpdate = getRemote("StateUpdate")
local ScoreUpdate = getRemote("ScoreUpdate")
local PlayerWon = getRemote("PlayerWon")
local PlayerCaught = getRemote("PlayerCaught")

local GAME_STATE = "Safe" -- "Safe" or "Danger"
local GameStateValue = Instance.new("StringValue")
GameStateValue.Name = "GameState"
GameStateValue.Value = GAME_STATE
GameStateValue.Parent = ReplicatedStorage

local ExecutionInProgress = Instance.new("BoolValue")
ExecutionInProgress.Name = "ExecutionInProgress"
ExecutionInProgress.Value = false
ExecutionInProgress.Parent = ReplicatedStorage

local PeasEaten = {} -- dictionary of player UserId to number

local SoundService = game:GetService("SoundService")

-- Initialize Horror Ambience Drone
local voidDrone = SoundService:FindFirstChild("HorrorAmbience")
if not voidDrone then
	voidDrone = Instance.new("Sound")
	voidDrone.Name = "HorrorAmbience"
	voidDrone.SoundId = "rbxassetid://1846999567" -- Verified Creepy Night Horror Atmosphere
	voidDrone.Volume = 0.5
	voidDrone.Looped = true
	voidDrone.Parent = SoundService
	voidDrone:Play()
end

local function playGlobalSound(soundName)
	local map = Workspace:FindFirstChild("PeaGameMap")
	if map then
		local sound = map:FindFirstChild(soundName)
		if sound then sound:Play() end
	end
end

-- Hide ReaderNPC floating nametag
local map = Workspace:FindFirstChild("PeaGameMap")
if map then
	local reader = map:FindFirstChild("ReaderNPC")
	if reader then
		local readerHum = reader:FindFirstChildOfClass("Humanoid")
		if readerHum then
			readerHum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			readerHum.DisplayName = ""
		end
	end
end

-- Initialize all peas to be totally static and non-collidable
for i = 1, 5 do
	local station = Workspace:FindFirstChild(tostring(i))
	if station then
		local peaFolder = station:FindFirstChild("Peas")
		if peaFolder then
			for _, pea in pairs(peaFolder:GetChildren()) do
				if pea:IsA("BasePart") then
					pea.Anchored = true
					pea.CanCollide = false
				end
			end
		end
	end
end



-- Handle player click to eat 1 pea
EatAction.OnServerEvent:Connect(function(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	
	if GAME_STATE == "Danger" then
		-- Ignore clicks if the newspaper guy is already busy executing someone else!
		if ExecutionInProgress.Value == true then
			return
		end
		
		-- Player caught eating while dangerous!
		humanoid.BreakJointsOnDeath = false
		ExecutionInProgress.Value = true
		PlayerCaught:FireAllClients(player)
		
		-- Wait 5.0 seconds for the "Omae Wa Mou Shindeiru" anime sequence to play before execution!
		task.wait(5.0)
		
		if humanoid.Health > 0 then
			humanoid.Health = 0
			local map = Workspace:FindFirstChild("PeaGameMap")
			if map then
				local gun = map:FindFirstChild("GunshotSound")
				if not gun then
					gun = Instance.new("Sound")
					gun.Name = "GunshotSound"
					gun.SoundId = "rbxassetid://73850426408333" -- Custom Pew Pew Sound
					gun.Volume = 4
					gun.Parent = map
				end
				gun:Play()
			end
			print(player.Name .. " was caught eating by the newspaper guy!")
		end
		ExecutionInProgress.Value = false
		return
	end
	
	-- Safe to eat 1 pea!
	PeasEaten[player.UserId] = (PeasEaten[player.UserId] or 0) + 1
	local score = PeasEaten[player.UserId]
	ScoreUpdate:FireClient(player, score)
	
	-- Hide physical peas (1 pea every 5 clicks)
	local stationVal = player:FindFirstChild("AssignedStation")
	if stationVal and stationVal.Value then
		local peaFolder = stationVal.Value:FindFirstChild("Peas")
		if peaFolder then
			local peas = peaFolder:GetChildren()
			-- Every 5 score, hide the next pea
			local hideIndex = math.floor(score / 5)
			if hideIndex > 0 and hideIndex <= #peas and peas[hideIndex] then
				peas[hideIndex].Transparency = 1
			end
		end
	end
	
	-- Win Condition
	if score >= 100 then
		PlayerWon:FireAllClients(player.Name)
		print(player.Name .. " has eaten all the peas and WON!")
		-- Reset everyone's score and peas
		for uid, _ in pairs(PeasEaten) do
			PeasEaten[uid] = 0
			local p = Players:GetPlayerByUserId(uid)
			if p then 
				ScoreUpdate:FireClient(p, 0) 
				local sv = p:FindFirstChild("AssignedStation")
				if sv and sv.Value and sv.Value:FindFirstChild("Peas") then
					for _, pea in pairs(sv.Value.Peas:GetChildren()) do
						pea.Transparency = 0
					end
				end
			end
		end
	end
end)

-- Initialize and cleanup player data
Players.CharacterAutoLoads = false

Players.PlayerAdded:Connect(function(player)
	PeasEaten[player.UserId] = 0
	
	-- Assign a Random Available Station
	local assignedStation = nil
	local usedStations = {}
	for _, p in pairs(Players:GetPlayers()) do
		local val = p:FindFirstChild("AssignedStation")
		if val and val.Value then
			usedStations[val.Value] = true
		end
	end
	
	local available = {}
	for i = 1, 5 do
		local station = Workspace:FindFirstChild(tostring(i))
		if station and not usedStations[station] then
			table.insert(available, station)
		end
	end
	
	if #available > 0 then
		assignedStation = available[math.random(1, #available)]
		print("DEBUG: Player " .. player.Name .. " was successfully assigned to Group: " .. assignedStation.Name)
	else
		print("DEBUG: ERROR - Player " .. player.Name .. " was NOT assigned to any group! Available stations: 0")
	end
	
	local val = Instance.new("ObjectValue")
	val.Name = "AssignedStation"
	val.Value = assignedStation
	val.Parent = player
	
	player.CharacterAdded:Connect(function(char)
		PeasEaten[player.UserId] = 0
		ScoreUpdate:FireClient(player, 0)
		StateUpdate:FireClient(player, GAME_STATE)
		
		if assignedStation then
			
			local spawnLoc = assignedStation:FindFirstChild("PlayerSpawn")
			if spawnLoc then
				task.defer(function()
					task.wait(0.1)
					char:PivotTo(spawnLoc.CFrame * CFrame.new(0, 3, 0))
					
					-- Disable jumping so they cannot get up from the chair!
					local humanoid = char:FindFirstChild("Humanoid")
					if humanoid then
						humanoid.UseJumpPower = true
						humanoid.JumpPower = 0
					end
				end)
			end
			
			local peaFolder = assignedStation:FindFirstChild("Peas")
			if peaFolder then
				local peasList = peaFolder:GetChildren()
				print("DEBUG: Found Peas folder for Group " .. assignedStation.Name .. " containing " .. #peasList .. " peas.")
				for _, pea in pairs(peasList) do
					pea.Transparency = 0
				end
			else
				print("DEBUG: WARNING - Group " .. assignedStation.Name .. " does NOT have a 'Peas' folder inside it!")
			end
		end
	end)
	
	-- Load their character into the game exactly once!
	player:LoadCharacter()
end)

Players.PlayerRemoving:Connect(function(player)
	PeasEaten[player.UserId] = nil
end)

-- Main State Machine Loop
task.spawn(function()
	while true do
		-- Safe duration (Newspaper UP)
		local safeTime = math.random(3, 7)
		GAME_STATE = "Safe"
		GameStateValue.Value = GAME_STATE
		StateUpdate:FireAllClients(GAME_STATE)
		playGlobalSound("RustleSound")
		print("State: Safe (Newspaper UP)")
		
		task.wait(safeTime)
		
		-- Danger duration (Newspaper DOWN)
		local dangerTime = math.random(2, 4)
		GAME_STATE = "Danger"
		GameStateValue.Value = GAME_STATE
		StateUpdate:FireAllClients(GAME_STATE)
		playGlobalSound("RustleSound")
		print("State: Danger (Newspaper DOWN)")
		
		task.wait(dangerTime)
		
		-- Pause the game loop if a cinematic execution is happening!
		while ExecutionInProgress.Value == true do
			task.wait(0.1)
		end
	end
end)
