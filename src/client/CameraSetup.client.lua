--!strict
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local function setupCharacter(character)
	-- Lock to First-Person with natural wide FOV
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	workspace.CurrentCamera.FieldOfView = 75 -- Natural wide POV
	
	local humanoid = character:WaitForChild("Humanoid")
	-- Position camera at comfortable sitting eye level with full table view
	humanoid.CameraOffset = Vector3.new(0, 0.2, -0.4)
	humanoid.Died:Connect(function()
		-- Unlock camera when they die
		player.CameraMode = Enum.CameraMode.Classic
		
		-- Force the camera to pop backward so they instantly see their ragdoll
		player.CameraMinZoomDistance = 12
		task.wait(0.1)
		-- Reset the minimum zoom so they can zoom back in if they want
		player.CameraMinZoomDistance = 0.5
	end)
end

if player then
	if player.Character then
		setupCharacter(player.Character)
	end
	player.CharacterAdded:Connect(setupCharacter)
end
