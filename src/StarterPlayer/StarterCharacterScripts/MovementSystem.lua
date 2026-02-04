local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

print("🏃 Movement System başlatıldı!")

-- ==================== SPRINT SİSTEMİ (W+W) ====================
local SPRINT_SPEED = 24
local NORMAL_SPEED = 16

local isSprinting = false
local lastWPress = 0
local wPressCount = 0

-- W tuşu ile sprint (W+W)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.W then
		local currentTime = tick()

		if currentTime - lastWPress < 0.3 then
			wPressCount = wPressCount + 1

			if wPressCount >= 2 then
				if not isSprinting then
					isSprinting = true
					humanoid.WalkSpeed = SPRINT_SPEED
					print("🏃 Sprint başladı!")
				end
				wPressCount = 0
			end
		else
			wPressCount = 1
		end

		lastWPress = currentTime
	end
end)

-- W bırakınca sprint bitsin
UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.W then
		if isSprinting then
			isSprinting = false
			humanoid.WalkSpeed = NORMAL_SPEED
			print("🚶 Sprint bitti!")
		end
	end
end)

-- ==================== DASH SİSTEMİ (Q) ====================
local DASH_DISTANCE = 15  -- Mesafe azaltıldı
local DASH_COOLDOWN = 3

local lastDash = 0
local isDashing = false

-- Dash fonksiyonu
local function dash()
	local currentTime = tick()

	if currentTime - lastDash < DASH_COOLDOWN then
		print("❌ Dash cooldown'da!")
		return
	end

	if isDashing then return end

	isDashing = true
	lastDash = currentTime

	print("💨 DASH!")

	-- Dash yönü (hareket yönüne göre)
	local moveDirection = humanoid.MoveDirection
	local direction

	if moveDirection.Magnitude > 0.1 then
		-- Hareket ediyorsa o yöne dash
		direction = moveDirection
	else
		-- Duruyor veya sadece bakıyorsa baktığı yöne dash
		direction = rootPart.CFrame.LookVector
	end

	-- Dash efekti
	local dashEffect = Instance.new("Part")
	dashEffect.Size = Vector3.new(3, 3, 3)
	dashEffect.Shape = Enum.PartType.Ball
	dashEffect.Color = Color3.fromRGB(0, 255, 255)
	dashEffect.Material = Enum.Material.Neon
	dashEffect.Anchored = true
	dashEffect.CanCollide = false
	dashEffect.Transparency = 0.5
	dashEffect.CFrame = rootPart.CFrame
	dashEffect.Parent = workspace

	game:GetService("TweenService"):Create(dashEffect, TweenInfo.new(0.3), {
		Size = Vector3.new(8, 8, 8),
		Transparency = 1
	}):Play()

	game:GetService("Debris"):AddItem(dashEffect, 0.3)

	-- Dash hareketi
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(100000, 0, 100000)
	bodyVelocity.Velocity = direction * (DASH_DISTANCE / 0.2)
	bodyVelocity.Parent = rootPart

	-- Dash sesi
	local dashSound = Instance.new("Sound")
	dashSound.SoundId = "rbxassetid://1177785010"
	dashSound.Volume = 0.5
	dashSound.Parent = rootPart
	dashSound:Play()
	game:GetService("Debris"):AddItem(dashSound, 1)

	-- Dash trail
	for i = 1, 5 do
		task.spawn(function()
			task.wait(i * 0.04)

			local trail = Instance.new("Part")
			trail.Size = Vector3.new(2, 4, 1)
			trail.Color = Color3.fromRGB(0, 200, 255)
			trail.Material = Enum.Material.Neon
			trail.Anchored = true
			trail.CanCollide = false
			trail.Transparency = 0.3 + (i * 0.1)
			trail.CFrame = rootPart.CFrame
			trail.Parent = workspace

			game:GetService("TweenService"):Create(trail, TweenInfo.new(0.5), {
				Transparency = 1,
				Size = Vector3.new(1, 2, 0.5)
			}):Play()

			game:GetService("Debris"):AddItem(trail, 0.5)
		end)
	end

	task.wait(0.2)
	bodyVelocity:Destroy()

	task.wait(0.1)
	isDashing = false
end

-- Q tuşu ile dash
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.Q then
		dash()
	end
end)

print("✅ Movement System hazır! (W+W: Sprint, Q: Dash - Hareket yönüne)")