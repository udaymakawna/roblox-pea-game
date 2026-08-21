--!strict
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- We want to spawn R15 dummies on any unoccupied seats when the game starts.
task.spawn(function()
	task.wait(2) -- Wait for the map and initial players to load

	local spawns = {}
	for i = 1, 5 do
		local group = Workspace:FindFirstChild(tostring(i))
		if group then
			local spawnLoc = group:FindFirstChild("PlayerSpawn")
			if spawnLoc then
				table.insert(spawns, {loc = spawnLoc, group = group})
			end
		end
	end

	local userIds = {1, 2362544, 261, 13, 20} -- Builderman, shedletsky, etc.
	local dummyCount = 1

	for _, spawnData in ipairs(spawns) do
		local spawnLoc = spawnData.loc
		local group = spawnData.group
		
		-- Check if a real player was assigned to this group (checks data instead of physical bodies)
		local occupied = false
		for _, player in ipairs(Players:GetPlayers()) do
			local val = player:FindFirstChild("AssignedStation")
			if val and val.Value == group then
				occupied = true
				break
			end
		end

		if not occupied then
			-- Fetch an avatar from Roblox servers
			local success, desc = pcall(function()
				return Players:GetHumanoidDescriptionFromUserId(userIds[dummyCount])
			end)
			
			if success and desc then
				-- Guarantee R15 rig
				local dummy = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
				dummy.Name = "R15_Dummy_" .. dummyCount
				
				local humanoid = dummy:FindFirstChild("Humanoid") :: Humanoid
				if humanoid then
					humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
					humanoid.DisplayName = ""
				end
				local animator = Instance.new("Animator")
				animator.Parent = humanoid
				
				-- Standard R15 Sit Animation
				local anim = Instance.new("Animation")
				anim.AnimationId = "rbxassetid://2506281703"
				local sitTrack = animator:LoadAnimation(anim)
				sitTrack.Priority = Enum.AnimationPriority.Action
				sitTrack.Looped = true
				
				-- When physics drops them onto the Seat, trigger the animation!
				humanoid.Seated:Connect(function(active)
					if active then
						sitTrack:Play()
						print(dummy.Name .. " sat down successfully!")
					else
						sitTrack:Stop()
					end
				end)
				
				-- Find the seat for this station
				local seat = group:FindFirstChildWhichIsA("Seat", true)
				if seat then
					dummy:PivotTo(seat.CFrame + Vector3.new(0, 1.5, 0))
				else
					dummy:PivotTo(spawnLoc.CFrame + Vector3.new(0, 2, 0))
				end
				dummy.Parent = Workspace
				print("Successfully spawned " .. dummy.Name .. " at the table.")

				-- Explicitly weld dummy to seat to guarantee proper elevation and prevent sinking
				if seat and humanoid then
					seat:Sit(humanoid)
					sitTrack:Play()
				end
				
				-- Dummy AI Loop (Clicker Style)
				task.spawn(function()
					local stateVal = ReplicatedStorage:WaitForChild("GameState")
					local remotes = ReplicatedStorage:WaitForChild("PeaRemotes")
					local playerCaughtRemote = remotes:WaitForChild("PlayerCaught")
					local score = 0
					
					-- Standard Eat Anim
					local eatAnim = Instance.new("Animation")
					eatAnim.AnimationId = "rbxassetid://507770677"
					local eatTrack = animator:LoadAnimation(eatAnim)
					eatTrack.Priority = Enum.AnimationPriority.Action4
					
					local lastClickTime = 0
					
					-- Animation loop (similar to client)
					task.spawn(function()
						while humanoid.Health > 0 do
							task.wait(0.1)
							if os.clock() - lastClickTime < 0.4 then
								if not eatTrack.IsPlaying then eatTrack:Play() end
							else
								if eatTrack.IsPlaying then eatTrack:Stop() end
							end
						end
					end)
					
					while humanoid.Health > 0 and score < 100 do
						-- Dummies click fast (2-4 times a second)
						task.wait(math.random(25, 50) / 100)
						
						local isSafe = stateVal.Value == "Safe"
						local willClick = false
						
						if isSafe then
							willClick = math.random() < 0.85
						else
							-- 3% chance to make a mistake and click during danger!
							willClick = math.random() < 0.03
						end
						
						if willClick then
							lastClickTime = os.clock()
							
							-- If they click while dangerous, they die!
							if stateVal.Value == "Danger" then
								local execVal = ReplicatedStorage:FindFirstChild("ExecutionInProgress")
								-- If newspaper guy is busy executing someone, ignore this dummy's mistake!
								if execVal and execVal.Value == true then
									continue
								end
								
								humanoid.BreakJointsOnDeath = false
								if execVal then execVal.Value = true end
								
								playerCaughtRemote:FireAllClients(dummy)
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
									print(dummy.Name .. " was caught eating!")
								end
								if execVal then execVal.Value = false end
								break
							end
							
							-- Otherwise, increment score and hide peas
							score = score + 1
							if group then
								local peaFolder = group:FindFirstChild("Peas")
								if peaFolder then
									local peas = peaFolder:GetChildren()
									local hideIndex = math.floor(score / 5)
									if hideIndex > 0 and hideIndex <= #peas and peas[hideIndex] then
										peas[hideIndex].Transparency = 1
									end
								end
							end
						end
					end
				end)
				
				dummyCount = dummyCount + 1
				if dummyCount > #userIds then dummyCount = 1 end
			end
		end
	end
end)
