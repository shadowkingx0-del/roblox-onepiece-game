local Tool = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

print("⚔️ KATANA SCRIPT YÜKLENDI")

-- Stamina
local MAX_STAMINA = 200
local STAMINA_REGEN = 15
local stamina = MAX_STAMINA

wait(1)
local playerGui = player.PlayerGui
local mainUI = playerGui:WaitForChild("PlayerUI"):WaitForChild("MainFrame")

local staminaBar = mainUI:FindFirstChild("StaminaBar")
local staminaFill = staminaBar and staminaBar:FindFirstChild("Fill")
local staminaText = staminaBar and staminaBar:FindFirstChild("TextLabel")

local function updateStaminaUI()
	if not staminaFill or not staminaText then return end

	local percentage = stamina / MAX_STAMINA
	staminaFill.Size = UDim2.new(percentage, 0, 1, 0)
	staminaText.Text = "⚡ " .. math.floor(stamina) .. " / " .. MAX_STAMINA

	if percentage > 0.5 then
		staminaFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
	elseif percentage > 0.25 then
		staminaFill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
	else
		staminaFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	end
end

task.spawn(function()
	while true do
		task.wait(0.1)
		if stamina < MAX_STAMINA then
			stamina = math.min(MAX_STAMINA, stamina + (STAMINA_REGEN * 0.1))
			updateStaminaUI()
		end
	end
end)

-- Kombo
local COMBO_MAX = 3
local COMBO_TIMEOUT = 2
local COOLDOWN_AFTER_COMBO = 1.2
local SLASH_RANGE = 12
local BASE_DAMAGE = 18

local comboCount = 0
local lastSlashTime = 0
local canSlash = true

local SLASH_ANIMATIONS = {
	"rbxassetid://140613123430687",
	"rbxassetid://137026546119765",
	"rbxassetid://133849548277297"
}

local slashAnimations = {}
local character
local humanoid

local dealDamageEvent = ReplicatedStorage:WaitForChild("DealDamage")
local stunEvent = ReplicatedStorage:WaitForChild("StunPlayer")
local useSkillEvent = ReplicatedStorage:WaitForChild("UseSkill")

-- Block
local isBlocking = false
local blockShield = nil
local blockEvent = ReplicatedStorage:WaitForChild("PlayerBlock")
local blockShieldUI = nil

local function createBlockShieldUI()
	if blockShieldUI then return end

	blockShieldUI = Instance.new("ScreenGui")
	blockShieldUI.Name = "BlockShieldUI_Katana"
	blockShieldUI.ResetOnSpawn = false
	blockShieldUI.Parent = playerGui

	local shield = Instance.new("Frame")
	shield.Name = "Shield"
	shield.AnchorPoint = Vector2.new(1, 0.5)
	shield.Position = UDim2.new(1, -50, 0.5, 0)
	shield.Size = UDim2.new(0, 120, 0, 140)
	shield.BackgroundTransparency = 1
	shield.Visible = false
	shield.Parent = blockShieldUI

	local shieldIcon = Instance.new("Frame")
	shieldIcon.Name = "ShieldIcon"
	shieldIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	shieldIcon.Position = UDim2.new(0.5, 0, 0.4, 0)
	shieldIcon.Size = UDim2.new(0, 80, 0, 80)
	shieldIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	shieldIcon.BorderSizePixel = 3
	shieldIcon.BorderColor3 = Color3.fromRGB(200, 200, 200)
	shieldIcon.Parent = shield

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(1, 0)
	iconCorner.Parent = shieldIcon

	local cross1 = Instance.new("Frame")
	cross1.AnchorPoint = Vector2.new(0.5, 0.5)
	cross1.Position = UDim2.new(0.5, 0, 0.5, 0)
	cross1.Size = UDim2.new(0, 50, 0, 10)
	cross1.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	cross1.BorderSizePixel = 0
	cross1.Parent = shieldIcon

	local cross2 = Instance.new("Frame")
	cross2.AnchorPoint = Vector2.new(0.5, 0.5)
	cross2.Position = UDim2.new(0.5, 0, 0.5, 0)
	cross2.Size = UDim2.new(0, 10, 0, 50)
	cross2.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
	cross2.BorderSizePixel = 0
	cross2.Parent = shieldIcon

	local barBG = Instance.new("Frame")
	barBG.Name = "BarBG"
	barBG.AnchorPoint = Vector2.new(0.5, 0)
	barBG.Position = UDim2.new(0.5, 0, 0.75, 0)
	barBG.Size = UDim2.new(0, 30, 0, 100)
	barBG.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	barBG.BorderSizePixel = 0
	barBG.Parent = shield

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 8)
	barCorner.Parent = barBG

	local barFill = Instance.new("Frame")
	barFill.Name = "Fill"
	barFill.AnchorPoint = Vector2.new(0, 1)
	barFill.Position = UDim2.new(0, 0, 1, 0)
	barFill.Size = UDim2.new(1, 0, 1, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBG

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 8)
	fillCorner.Parent = barFill

	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.Position = UDim2.new(0, -20, 1, -20)
	text.Size = UDim2.new(1, 40, 0, 20)
	text.BackgroundTransparency = 1
	text.Text = "100"
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.TextSize = 16
	text.Font = Enum.Font.GothamBold
	text.TextStrokeTransparency = 0
	text.Parent = barBG
end

local function showBlockShield()
	createBlockShieldUI()
	if blockShieldUI then
		local shield = blockShieldUI:FindFirstChild("Shield")
		if shield then
			shield.Visible = true
		end
	end
end

local function hideBlockShield()
	if blockShieldUI then
		local shield = blockShieldUI:FindFirstChild("Shield")
		if shield then
			shield.Visible = false
		end
	end
end

local function startBlock()
	if isBlocking then return end
	if not character or not humanoid then return end

	isBlocking = true
	print("🛡️ Katana Block!")

	blockEvent:FireServer(true)
	humanoid.WalkSpeed = 8
	showBlockShield()

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		blockShield = Instance.new("Part")
		blockShield.Name = "BlockShield"
		blockShield.Size = Vector3.new(6, 6, 0.2)
		blockShield.Color = Color3.fromRGB(255, 255, 255)
		blockShield.Material = Enum.Material.ForceField
		blockShield.Transparency = 0.5
		blockShield.Anchored = false
		blockShield.CanCollide = false
		blockShield.CFrame = rootPart.CFrame * CFrame.new(2, 0, -2)

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = rootPart
		weld.Part1 = blockShield
		weld.Parent = blockShield

		blockShield.Parent = character
	end
end

local function stopBlock()
	if not isBlocking then return end

	isBlocking = false
	print("🛡️ Katana Block bitti!")

	blockEvent:FireServer(false)
	hideBlockShield()

	if humanoid then
		humanoid.WalkSpeed = 16
	end

	if blockShield then
		blockShield:Destroy()
		blockShield = nil
	end
end

-- Skill UI
local skillUI = mainUI:FindFirstChild("SkillBar")
local skill1Frame = skillUI and skillUI:FindFirstChild("Skill1")
local skill2Frame = skillUI and skillUI:FindFirstChild("Skill2")

-- Tool Equipped
Tool.Equipped:Connect(function()
	character = Tool.Parent
	humanoid = character:FindFirstChildOfClass("Humanoid")

	print("⚔️ Katana kuşanıldı!")

	if skillUI then
		skillUI.Visible = true
	end

	if humanoid then
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
		end

		slashAnimations = {}
		for i, animId in ipairs(SLASH_ANIMATIONS) do
			local animation = Instance.new("Animation")
			animation.AnimationId = animId
			slashAnimations[i] = animator:LoadAnimation(animation)
		end
	end

	comboCount = 0
end)

Tool.Unequipped:Connect(function()
	stopBlock()

	if skillUI then
		skillUI.Visible = false
	end

	character = nil
	humanoid = nil
end)

-- Slash Saldırı
Tool.Activated:Connect(function()
	print("🖱️ Katana tıklandı!")

	if isBlocking then 
		print("❌ Block yapıyorsun!")
		return 
	end

	if not canSlash then 
		print("❌ Cooldown!")
		return 
	end

	if not character or not humanoid then 
		print("❌ Character/Humanoid yok!")
		return 
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local currentTime = tick()
	if currentTime - lastSlashTime > COMBO_TIMEOUT then
		comboCount = 0
	end

	comboCount = comboCount + 1
	if comboCount > COMBO_MAX then
		comboCount = 1
	end

	lastSlashTime = currentTime
	canSlash = false

	print("⚔️ SLASH: " .. comboCount)

	if slashAnimations[comboCount] then
		slashAnimations[comboCount]:Play()
	end

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://158475221"
	sound.Volume = 0.6
	sound.Parent = rootPart
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 1)

	task.wait(0.15)

	for _, model in pairs(workspace:GetChildren()) do
		local enemyHumanoid = model:FindFirstChildOfClass("Humanoid")
		if enemyHumanoid and enemyHumanoid ~= humanoid and enemyHumanoid.Health > 0 then
			local enemyRoot = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")

			if enemyRoot then
				local distance = (rootPart.Position - enemyRoot.Position).Magnitude

				if distance <= SLASH_RANGE then
					local comboDamage = BASE_DAMAGE + (comboCount * 3)

					local playerData = player:FindFirstChild("PlayerData")
					if playerData then
						local stats = playerData:FindFirstChild("Stats")
						if stats then
							local swordStat = stats:FindFirstChild("Sword")
							if swordStat then
								comboDamage = comboDamage + (swordStat.Value * 3)
							end
						end
					end

					dealDamageEvent:FireServer(model, comboDamage)
					stunEvent:FireServer(model, 0.7 + (comboCount * 0.1))

					print("⚔️ Hasar: " .. comboDamage)

					for i = 1, 3 do
						local slash = Instance.new("Part")
						slash.Size = Vector3.new(0.2, 4, 0.2)
						slash.Color = Color3.fromRGB(255, 50, 50)
						slash.Material = Enum.Material.Neon
						slash.Anchored = true
						slash.CanCollide = false
						slash.CFrame = enemyRoot.CFrame * CFrame.Angles(0, 0, math.rad(45 * i))
						slash.Parent = workspace

						game:GetService("TweenService"):Create(slash, TweenInfo.new(0.3), {
							Size = Vector3.new(0.05, 6, 0.05),
							Transparency = 1
						}):Play()

						game:GetService("Debris"):AddItem(slash, 0.3)
					end

					if comboCount == COMBO_MAX then
						local explosion = Instance.new("Part")
						explosion.Size = Vector3.new(6, 6, 6)
						explosion.Color = Color3.fromRGB(255, 0, 0)
						explosion.Material = Enum.Material.Neon
						explosion.Anchored = true
						explosion.CanCollide = false
						explosion.Shape = Enum.PartType.Ball
						explosion.Transparency = 0.3
						explosion.CFrame = enemyRoot.CFrame
						explosion.Parent = workspace

						game:GetService("TweenService"):Create(explosion, TweenInfo.new(0.5), {
							Size = Vector3.new(12, 12, 12),
							Transparency = 1
						}):Play()

						game:GetService("Debris"):AddItem(explosion, 0.5)
					end
				end
			end
		end
	end

	local cooldown = 0.35

	if comboCount >= COMBO_MAX then
		cooldown = COOLDOWN_AFTER_COMBO
		comboCount = 0
	end

	task.wait(cooldown)
	canSlash = true
end)

-- F Tuşu Block
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if Tool.Parent ~= player.Character then return end

	if input.KeyCode == Enum.KeyCode.F then
		startBlock()
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.F then
		stopBlock()
	end
end)

-- Skill fonksiyonları
local skill1Cooldown = 0
local skill2Cooldown = 0
local SKILL1_STAMINA = 55
local SKILL1_COOLDOWN = 6
local SKILL2_STAMINA = 120
local SKILL2_COOLDOWN = 12

local function findNearestEnemy()
	if not character or not humanoid then return nil end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return nil end

	local nearestEnemy = nil
	local shortestDistance = 15

	for _, model in pairs(workspace:GetChildren()) do
		local enemyHumanoid = model:FindFirstChildOfClass("Humanoid")
		if enemyHumanoid and enemyHumanoid ~= humanoid and enemyHumanoid.Health > 0 then
			local enemyRoot = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")

			if enemyRoot then
				local distance = (rootPart.Position - enemyRoot.Position).Magnitude
				if distance < shortestDistance then
					shortestDistance = distance
					nearestEnemy = model
				end
			end
		end
	end

	return nearestEnemy
end

local function useSkill1()
	if isBlocking then return end
	if tick() - skill1Cooldown < SKILL1_COOLDOWN then return end
	if stamina < SKILL1_STAMINA then return end

	local playerData = player:FindFirstChild("PlayerData")
	if playerData then
		local stats = playerData:FindFirstChild("Stats")
		if stats then
			local swordStat = stats:FindFirstChild("Sword")
			if swordStat and swordStat.Value < 15 then return end
		end
	end

	print("🌀 SPINNING SLASH!")
	stamina = stamina - SKILL1_STAMINA
	updateStaminaUI()
	skill1Cooldown = tick()

	if not character or not humanoid then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local spinDuration = 0.5
	local startCFrame = rootPart.CFrame

	task.spawn(function()
		for i = 0, 360, 20 do
			if rootPart then
				rootPart.CFrame = startCFrame * CFrame.Angles(0, math.rad(i), 0)
			end
			task.wait(spinDuration / 18)
		end
	end)

	for i = 1, 12 do
		task.spawn(function()
			task.wait(i * (spinDuration / 12))
			local angle = (i / 12) * 360
			local slashEffect = Instance.new("Part")
			slashEffect.Size = Vector3.new(0.3, 8, 0.3)
			slashEffect.Color = Color3.fromRGB(200, 50, 50)
			slashEffect.Material = Enum.Material.Neon
			slashEffect.Anchored = true
			slashEffect.CanCollide = false
			slashEffect.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(angle), math.rad(45))
			slashEffect.Parent = workspace

			game:GetService("TweenService"):Create(slashEffect, TweenInfo.new(0.3), {
				Size = Vector3.new(0.1, 10, 0.1),
				Transparency = 1
			}):Play()

			game:GetService("Debris"):AddItem(slashEffect, 0.3)
		end)
	end

	task.wait(0.2)

	for _, model in pairs(workspace:GetChildren()) do
		local enemyHumanoid = model:FindFirstChildOfClass("Humanoid")
		if enemyHumanoid and enemyHumanoid ~= humanoid and enemyHumanoid.Health > 0 then
			local enemyRoot = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
			if enemyRoot then
				local distance = (rootPart.Position - enemyRoot.Position).Magnitude
				if distance <= 12 then
					useSkillEvent:FireServer("SpinningSlash", model)
				end
			end
		end
	end

	if skill1Frame then
		local cooldownFrame = skill1Frame:FindFirstChild("Cooldown")
		local cooldownText = cooldownFrame and cooldownFrame:FindFirstChild("CooldownText")

		if cooldownFrame then
			cooldownFrame.Visible = true
			for i = SKILL1_COOLDOWN, 1, -1 do
				if cooldownText then
					cooldownText.Text = tostring(i)
				end
				task.wait(1)
			end
			cooldownFrame.Visible = false
		end
	end
end

local function useSkill2()
	if isBlocking then return end
	if tick() - skill2Cooldown < SKILL2_COOLDOWN then return end
	if stamina < SKILL2_STAMINA then return end

	local playerData = player:FindFirstChild("PlayerData")
	if playerData then
		local stats = playerData:FindFirstChild("Stats")
		if stats then
			local swordStat = stats:FindFirstChild("Sword")
			if swordStat and swordStat.Value < 30 then return end
		end
	end

	print("🐉 DRAGON SLASH!")
	stamina = stamina - SKILL2_STAMINA
	updateStaminaUI()
	skill2Cooldown = tick()

	if not character or not humanoid then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	if slashAnimations[3] then
		slashAnimations[3]:Play()
	end

	local direction = rootPart.CFrame.LookVector
	local dragonWave = Instance.new("Part")
	dragonWave.Size = Vector3.new(8, 6, 2)
	dragonWave.Color = Color3.fromRGB(255, 50, 50)
	dragonWave.Material = Enum.Material.Neon
	dragonWave.Anchored = true
	dragonWave.CanCollide = false
	dragonWave.Transparency = 0.3
	dragonWave.CFrame = rootPart.CFrame * CFrame.new(0, 0, -5)
	dragonWave.Parent = workspace

	local travelDistance = 40
	local travelTime = 1.5

	game:GetService("TweenService"):Create(dragonWave, TweenInfo.new(travelTime), {
		CFrame = dragonWave.CFrame * CFrame.new(0, 0, -travelDistance)
	}):Play()

	task.spawn(function()
		for t = 0, travelTime, 0.1 do
			task.wait(0.1)
			if not dragonWave.Parent then break end

			for _, model in pairs(workspace:GetChildren()) do
				local enemyHumanoid = model:FindFirstChildOfClass("Humanoid")
				if enemyHumanoid and enemyHumanoid ~= humanoid and enemyHumanoid.Health > 0 then
					local enemyRoot = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
					if enemyRoot then
						local distance = (dragonWave.Position - enemyRoot.Position).Magnitude
						if distance <= 10 then
							useSkillEvent:FireServer("DragonSlash", model)

							local knockback = Instance.new("BodyVelocity")
							knockback.MaxForce = Vector3.new(100000, 100000, 100000)
							knockback.Velocity = direction * 60 + Vector3.new(0, 30, 0)
							knockback.Parent = enemyRoot
							game:GetService("Debris"):AddItem(knockback, 0.3)
							task.wait(0.5)
						end
					end
				end
			end
		end
		game:GetService("Debris"):AddItem(dragonWave, 0.5)
	end)

	if skill2Frame then
		local cooldownFrame = skill2Frame:FindFirstChild("Cooldown")
		local cooldownText = cooldownFrame and cooldownFrame:FindFirstChild("CooldownText")

		if cooldownFrame then
			cooldownFrame.Visible = true
			for i = SKILL2_COOLDOWN, 1, -1 do
				if cooldownText then
					cooldownText.Text = tostring(i)
				end
				task.wait(1)
			end
			cooldownFrame.Visible = false
		end
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if Tool.Parent ~= player.Character then return end

	if input.KeyCode == Enum.KeyCode.R then
		useSkill1()
	elseif input.KeyCode == Enum.KeyCode.T then
		useSkill2()
	end
end)

print("✅ Katana hazır!")

-- Block hasar dinle
local blockDamageEvent = ReplicatedStorage:WaitForChild("BlockDamage")

blockDamageEvent.OnClientEvent:Connect(function(damage)
	print("🛡️ Block hasar aldı: " .. damage)

	-- Block UI'yi güncelle
	if blockShieldUI then
		local shield = blockShieldUI:FindFirstChild("Shield")
		if shield then
			local barBG = shield:FindFirstChild("BarBG")
			if barBG then
				local fill = barBG:FindFirstChild("Fill")
				local text = barBG:FindFirstChild("Text")

				if fill and text then
					-- Örnek: Max 100, damage kadar azalt
					local currentHealth = tonumber(text.Text) or 100
					currentHealth = math.max(0, currentHealth - damage)

					local percentage = currentHealth / 100
					fill.Size = UDim2.new(1, 0, percentage, 0)
					text.Text = tostring(math.floor(currentHealth))

					print("🛡️ Yeni block health: " .. currentHealth)
				end
			end
		end
	end

	-- Shield titresin
	if blockShield then
		local originalPos = blockShield.CFrame
		for i = 1, 3 do
			if blockShield then
				blockShield.CFrame = originalPos * CFrame.new(math.random(-1, 1) * 0.1, 0, 0)
			end
			task.wait(0.05)
		end
		if blockShield then
			blockShield.CFrame = originalPos
		end
	end
end)