local Tool = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

print("=== YUMRUK + BLOCK + SKILL SİSTEMİ YÜKLENDI ===")

-- ==================== STAMINA SİSTEMİ ====================
local MAX_STAMINA = 200
local STAMINA_REGEN = 15

local stamina = MAX_STAMINA

-- Stamina UI
wait(1)
local playerGui = player.PlayerGui
local mainUI = playerGui:WaitForChild("PlayerUI"):WaitForChild("MainFrame")

-- Eski stamina bar'ı sil
local oldStaminaBar = mainUI:FindFirstChild("StaminaBar")
if oldStaminaBar then
	oldStaminaBar:Destroy()
end

-- Eski block bar'ı gizle
local oldBlockBar = mainUI:FindFirstChild("BlockBar")
if oldBlockBar then
	oldBlockBar.Visible = false
end

local staminaBar = Instance.new("Frame")
staminaBar.Name = "StaminaBar"
staminaBar.Position = UDim2.new(0, 10, 0, 175)
staminaBar.Size = UDim2.new(0, 280, 0, 25)
staminaBar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
staminaBar.BorderSizePixel = 0
staminaBar.Parent = mainUI

local staminaCorner = Instance.new("UICorner")
staminaCorner.CornerRadius = UDim.new(0, 8)
staminaCorner.Parent = staminaBar

local staminaFill = Instance.new("Frame")
staminaFill.Name = "Fill"
staminaFill.Size = UDim2.new(1, 0, 1, 0)
staminaFill.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
staminaFill.BorderSizePixel = 0
staminaFill.Parent = staminaBar

local staminaFillCorner = Instance.new("UICorner")
staminaFillCorner.CornerRadius = UDim.new(0, 8)
staminaFillCorner.Parent = staminaFill

local staminaText = Instance.new("TextLabel")
staminaText.Size = UDim2.new(1, 0, 1, 0)
staminaText.BackgroundTransparency = 1
staminaText.Text = "⚡ 200 / 200"
staminaText.TextColor3 = Color3.fromRGB(255, 255, 255)
staminaText.TextSize = 14
staminaText.Font = Enum.Font.GothamBold
staminaText.TextStrokeTransparency = 0.5
staminaText.Parent = staminaBar

-- Stamina UI güncelle
local function updateStaminaUI()
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

-- Stamina pasif yenileme
task.spawn(function()
	while true do
		task.wait(0.1)

		if stamina < MAX_STAMINA then
			stamina = math.min(MAX_STAMINA, stamina + (STAMINA_REGEN * 0.1))
			updateStaminaUI()
		end
	end
end)

updateStaminaUI()

-- ==================== KOMBO SİSTEMİ ====================
local COMBO_MAX = 4
local COMBO_TIMEOUT = 2
local COOLDOWN_AFTER_COMBO = 1.5
local PUNCH_RANGE = 10
local BASE_DAMAGE = 10

local comboCount = 0
local lastPunchTime = 0
local canPunch = true

-- Animasyonlar
local COMBO_ANIMATIONS = {
	"rbxassetid://140613123430687",
	"rbxassetid://137026546119765",
	"rbxassetid://133849548277297",
	"rbxassetid://129062407281330"
}

local punchAnimations = {}
local character
local humanoid

-- RemoteEvents
local dealDamageEvent = ReplicatedStorage:WaitForChild("DealDamage")
local stunEvent = ReplicatedStorage:WaitForChild("StunPlayer")

-- ==================== BLOCK SİSTEMİ ====================
local BASE_BLOCK_HEALTH = 100
local BLOCK_PER_DEFENSE = 15

local MAX_BLOCK_HEALTH = BASE_BLOCK_HEALTH
local BLOCK_BREAK_STUN = 2

-- Defense stat'ına göre max block hesapla
local function calculateMaxBlock()
	local playerData = player:FindFirstChild("PlayerData")
	if playerData then
		local stats = playerData:FindFirstChild("Stats")
		if stats then
			local defense = stats:FindFirstChild("Defense")
			if defense then
				MAX_BLOCK_HEALTH = BASE_BLOCK_HEALTH + (defense.Value * BLOCK_PER_DEFENSE)
				print("🛡️ Max Block: " .. MAX_BLOCK_HEALTH .. " (Defense: " .. defense.Value .. ")")
				return
			end
		end
	end
	MAX_BLOCK_HEALTH = BASE_BLOCK_HEALTH
end

calculateMaxBlock()

local blockHealth = MAX_BLOCK_HEALTH
local isBlocking = false
local blockBroken = false
local blockShield = nil

local blockEvent = ReplicatedStorage:WaitForChild("PlayerBlock")
local blockDamageEvent = ReplicatedStorage:WaitForChild("BlockDamage")

local comboUI = playerGui:FindFirstChild("ComboUI")
local comboLabel = comboUI and comboUI:FindFirstChild("ComboLabel")

-- Player Data
local playerData = player:WaitForChild("PlayerData")
local stats = playerData:WaitForChild("Stats")
local defense = stats:WaitForChild("Defense")

-- Defense değiştiğinde max block güncelle
defense.Changed:Connect(function()
	calculateMaxBlock()
	if blockHealth > MAX_BLOCK_HEALTH then
		blockHealth = MAX_BLOCK_HEALTH
	end
end)

-- ==================== BLOCK KALKAN UI ====================
local blockShieldUI = nil

local function createBlockShieldUI()
	if blockShieldUI then return end

	blockShieldUI = Instance.new("ScreenGui")
	blockShieldUI.Name = "BlockShieldUI"
	blockShieldUI.ResetOnSpawn = false
	blockShieldUI.Parent = playerGui

	-- Kalkan şekli
	local shield = Instance.new("Frame")
	shield.Name = "Shield"
	shield.AnchorPoint = Vector2.new(1, 0.5)
	shield.Position = UDim2.new(1, -50, 0.5, 0)
	shield.Size = UDim2.new(0, 120, 0, 140)
	shield.BackgroundTransparency = 1
	shield.Visible = false
	shield.Parent = blockShieldUI

	-- Kalkan ikon (Beyaz daire - basit kalkan)
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
	iconCorner.CornerRadius = UDim.new(1, 0)  -- Tam yuvarlak
	iconCorner.Parent = shieldIcon

	-- Kalkan sembolü (Ortada çarpı)
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

	-- Block bar (dikey - kalkanın altında)
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

	-- Fill (aşağıdan yukarı dolacak)
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

	-- Text
	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.Position = UDim2.new(0, -20, 1, -20)
	text.Size = UDim2.new(1, 40, 0, 20)
	text.BackgroundTransparency = 1
	text.Text = math.floor(MAX_BLOCK_HEALTH)
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.TextSize = 16
	text.Font = Enum.Font.GothamBold
	text.TextStrokeTransparency = 0
	text.Parent = barBG

	print("🛡️ Block shield UI oluşturuldu!")
end

local function updateBlockShieldUI()
	if not blockShieldUI then return end

	local shield = blockShieldUI:FindFirstChild("Shield")
	if not shield then return end

	local barBG = shield:FindFirstChild("BarBG")
	if not barBG then return end

	local fill = barBG:FindFirstChild("Fill")
	local text = barBG:FindFirstChild("Text")

	if fill and text then
		local percentage = blockHealth / MAX_BLOCK_HEALTH
		fill.Size = UDim2.new(1, 0, percentage, 0)
		text.Text = math.floor(blockHealth)
	end
end

local function showBlockShield()
	createBlockShieldUI()

	if blockShieldUI then
		local shield = blockShieldUI:FindFirstChild("Shield")
		if shield then
			shield.Visible = true
			updateBlockShieldUI()
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

-- ==================== BLOCK FONKSİYONLARI ====================
local function startBlock()
	if blockBroken then
		print("❌ Block kırık!")
		return
	end

	if isBlocking then return end
	if not character or not humanoid then return end

	isBlocking = true
	print("🛡️ BLOCK BAŞLADI!")

	blockEvent:FireServer(true)

	-- Kalkan UI'yi göster
	showBlockShield()

	-- Yavaşla
	humanoid.WalkSpeed = 8

	-- Shield (3D - Sağda, Beyaz)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		blockShield = Instance.new("Part")
		blockShield.Name = "BlockShield"
		blockShield.Size = Vector3.new(6, 6, 0.2)
		blockShield.Color = Color3.fromRGB(255, 255, 255)  -- Beyaz
		blockShield.Material = Enum.Material.ForceField
		blockShield.Transparency = 0.5
		blockShield.Anchored = false
		blockShield.CanCollide = false
		blockShield.CFrame = rootPart.CFrame * CFrame.new(2, 0, -2)  -- Sağda

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
	print("🛡️ BLOCK BİTTİ!")

	blockEvent:FireServer(false)

	-- Kalkan UI'yi gizle
	hideBlockShield()

	-- Block bar'ı ANINDA FULLƏ
	calculateMaxBlock()
	blockHealth = MAX_BLOCK_HEALTH
	print("✅ Block bar fulllendi: " .. MAX_BLOCK_HEALTH)

	if humanoid then
		humanoid.WalkSpeed = 16
	end

	if blockShield then
		blockShield:Destroy()
		blockShield = nil
	end
end

-- ==================== TOOL EVENTLERİ ====================

-- Skill UI
local skillUI = mainUI:FindFirstChild("SkillBar")
local skill1Frame = skillUI and skillUI:FindFirstChild("Skill1")
local skill2Frame = skillUI and skillUI:FindFirstChild("Skill2")

Tool.Equipped:Connect(function()
	character = Tool.Parent
	humanoid = character:FindFirstChildOfClass("Humanoid")

	print("✅ Yumruk kuşanıldı!")

	-- Skill UI'yi göster
	if skillUI then
		skillUI.Visible = true
		print("🎯 Skill UI gösterildi!")
	end

	if humanoid then
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
		end

		-- Animasyonları yükle
		punchAnimations = {}
		for i, animId in ipairs(COMBO_ANIMATIONS) do
			local animation = Instance.new("Animation")
			animation.AnimationId = animId
			punchAnimations[i] = animator:LoadAnimation(animation)
		end

		print("✅ Kombo animasyonları yüklendi!")
	end

	comboCount = 0
end)

Tool.Unequipped:Connect(function()
	stopBlock()

	-- Skill UI'yi gizle
	if skillUI then
		skillUI.Visible = false
		print("🎯 Skill UI gizlendi!")
	end

	character = nil
	humanoid = nil
end)

-- ==================== KOMBO SALDIRI ====================
Tool.Activated:Connect(function()
	if isBlocking then
		print("❌ Block yaparken saldıramazsın!")
		return
	end

	if not canPunch then 
		return 
	end

	if not character or not humanoid then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Kombo timeout
	local currentTime = tick()
	if currentTime - lastPunchTime > COMBO_TIMEOUT then
		comboCount = 0
	end

	comboCount = comboCount + 1
	if comboCount > COMBO_MAX then
		comboCount = 1
	end

	lastPunchTime = currentTime
	canPunch = false

	print("💥 KOMBO: " .. comboCount .. "/" .. COMBO_MAX)

	-- Kombo UI
	if comboLabel then
		comboLabel.Visible = true
		comboLabel.Text = comboCount .. " HIT COMBO!"
		comboLabel.TextSize = 30 + (comboCount * 5)
	end

	-- Animasyon
	if punchAnimations[comboCount] then
		punchAnimations[comboCount]:Play()
	end

	-- Ses
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://169445226"
	sound.Volume = 0.5 + (comboCount * 0.1)
	sound.Parent = rootPart
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 1)

	task.wait(0.2)

	-- Hasar ver
	for _, model in pairs(workspace:GetChildren()) do
		local enemyHumanoid = model:FindFirstChildOfClass("Humanoid")
		if enemyHumanoid and enemyHumanoid ~= humanoid and enemyHumanoid.Health > 0 then
			local enemyRoot = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")

			if enemyRoot then
				local distance = (rootPart.Position - enemyRoot.Position).Magnitude

				if distance <= PUNCH_RANGE then
					local comboDamage = BASE_DAMAGE + (comboCount * 2)

					-- Strength bonusu
					local playerData = player:FindFirstChild("PlayerData")
					if playerData then
						local stats = playerData:FindFirstChild("Stats")
						if stats then
							local strength = stats:FindFirstChild("Strength")
							if strength then
								comboDamage = comboDamage + (strength.Value * 2)
							end
						end
					end

					dealDamageEvent:FireServer(model, comboDamage)

					local stunDuration = 0.8 + (comboCount * 0.15)
					stunEvent:FireServer(model, stunDuration)

					print("💥 İsabet! Hasar: " .. comboDamage)

					-- 4. VURUŞTA GERİ İTME
					if comboCount == COMBO_MAX then
						print("🚀 4. VURUŞ - GERİ İTME!")

						local direction = (enemyRoot.Position - rootPart.Position).Unit

						local knockback = Instance.new("BodyVelocity")
						knockback.MaxForce = Vector3.new(100000, 50000, 100000)
						knockback.Velocity = direction * 80 + Vector3.new(0, 40, 0)
						knockback.Parent = enemyRoot
						game:GetService("Debris"):AddItem(knockback, 0.4)

						stunEvent:FireServer(model, 1.4)
					end

					-- Efekt
					local effectSize = 2 + (comboCount * 0.5)
					local part = Instance.new("Part")
					part.Size = Vector3.new(effectSize, effectSize, effectSize)
					part.Color = Color3.fromRGB(255, 150 - (comboCount * 20), 0)
					part.Material = Enum.Material.Neon
					part.Anchored = true
					part.CanCollide = false
					part.Shape = Enum.PartType.Ball
					part.CFrame = enemyRoot.CFrame
					part.Parent = workspace
					game:GetService("Debris"):AddItem(part, 0.5)

					-- Finisher
					if comboCount == COMBO_MAX then
						local explosion = Instance.new("Part")
						explosion.Size = Vector3.new(8, 8, 8)
						explosion.Color = Color3.fromRGB(255, 50, 0)
						explosion.Material = Enum.Material.Neon
						explosion.Anchored = true
						explosion.CanCollide = false
						explosion.Shape = Enum.PartType.Ball
						explosion.Transparency = 0.3
						explosion.CFrame = enemyRoot.CFrame
						explosion.Parent = workspace

						game:GetService("TweenService"):Create(explosion, TweenInfo.new(0.5), {
							Size = Vector3.new(15, 15, 15),
							Transparency = 1
						}):Play()

						game:GetService("Debris"):AddItem(explosion, 0.5)
					end
				end
			end
		end
	end

	-- Cooldown
	local cooldown = 0.4

	if comboCount >= COMBO_MAX then
		cooldown = COOLDOWN_AFTER_COMBO
		comboCount = 0

		task.wait(1)
		if comboLabel then
			comboLabel.Visible = false
		end
	end

	task.wait(cooldown)
	canPunch = true
end)

-- ==================== F TUŞU (BLOCK) ====================
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

-- ==================== BLOCK HASAR ====================
blockDamageEvent.OnClientEvent:Connect(function(damage)
	blockHealth = blockHealth - damage

	print("🛡️ Block hasar aldı: " .. damage .. " | Kalan: " .. blockHealth)

	updateBlockShieldUI()

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

	if blockHealth <= 0 then
		blockHealth = 0
		blockBroken = true

		print("💔 BLOCK KIRILDI!")

		stopBlock()
		stunEvent:FireServer(player.Character, BLOCK_BREAK_STUN)

		-- Kırılma efekti
		if character then
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				for i = 1, 12 do
					local shard = Instance.new("Part")
					shard.Size = Vector3.new(0.5, 0.5, 0.1)
					shard.Color = Color3.fromRGB(255, 255, 255)
					shard.Material = Enum.Material.Neon
					shard.Anchored = false
					shard.CanCollide = false
					shard.CFrame = rootPart.CFrame * CFrame.new(2, 0, -2)
					shard.Velocity = Vector3.new(math.random(-30, 30), math.random(10, 40), math.random(-30, 30))
					shard.Parent = workspace
					game:GetService("Debris"):AddItem(shard, 2)
				end
			end
		end

		-- Yenile
		task.wait(5)
		blockBroken = false
		calculateMaxBlock()
		blockHealth = MAX_BLOCK_HEALTH
		print("✅ Block yenilendi! Max: " .. MAX_BLOCK_HEALTH)
	end
end)

-- ==================== SKİLL SİSTEMİ ====================

local skill1Cooldown = 0
local skill2Cooldown = 0

local SKILL1_STAMINA = 45
local SKILL1_COOLDOWN = 8
local SKILL2_STAMINA = 110
local SKILL2_COOLDOWN = 10

local useSkillEvent = ReplicatedStorage:WaitForChild("UseSkill")

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
	if tick() - skill1Cooldown < SKILL1_COOLDOWN then 
		return 
	end

	if stamina < SKILL1_STAMINA then
		print("❌ Yetersiz stamina!")
		return
	end

	local playerData = player:FindFirstChild("PlayerData")
	if playerData then
		local stats = playerData:FindFirstChild("Stats")
		if stats then
			local strength = stats:FindFirstChild("Strength")
			if strength and strength.Value < 12 then
				print("❌ 12 Güç gerekli!")
				return
			end
		end
	end

	local target = findNearestEnemy()
	if not target then
		return
	end

	print("🔥 SERT YUMRUK!")

	stamina = stamina - SKILL1_STAMINA
	updateStaminaUI()

	skill1Cooldown = tick()

	if punchAnimations[4] then
		punchAnimations[4]:Play()
	end

	task.wait(0.2)
	useSkillEvent:FireServer("HeavyPunch", target)

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		local effect = Instance.new("Part")
		effect.Size = Vector3.new(5, 5, 5)
		effect.Color = Color3.fromRGB(255, 100, 0)
		effect.Material = Enum.Material.Neon
		effect.Anchored = true
		effect.CanCollide = false
		effect.Shape = Enum.PartType.Ball
		effect.Transparency = 0.5
		effect.CFrame = rootPart.CFrame * CFrame.new(0, 0, -3)
		effect.Parent = workspace

		game:GetService("TweenService"):Create(effect, TweenInfo.new(0.3), {
			Size = Vector3.new(10, 10, 10),
			Transparency = 1
		}):Play()

		game:GetService("Debris"):AddItem(effect, 0.3)
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
	if tick() - skill2Cooldown < SKILL2_COOLDOWN then 
		return 
	end

	if stamina < SKILL2_STAMINA then
		print("❌ Yetersiz stamina!")
		return
	end

	local playerData = player:FindFirstChild("PlayerData")
	if playerData then
		local stats = playerData:FindFirstChild("Stats")
		if stats then
			local strength = stats:FindFirstChild("Strength")
			if strength and strength.Value < 25 then
				print("❌ 25 Güç gerekli!")
				return
			end
		end
	end

	local target = findNearestEnemy()
	if not target then
		return
	end

	print("🔥 UPPERCUT!")

	stamina = stamina - SKILL2_STAMINA
	updateStaminaUI()

	skill2Cooldown = tick()

	if punchAnimations[3] then
		punchAnimations[3]:Play()
	end

	task.wait(0.2)
	useSkillEvent:FireServer("UpperCut", target)

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		local effect = Instance.new("Part")
		effect.Size = Vector3.new(3, 8, 3)
		effect.Color = Color3.fromRGB(255, 255, 0)
		effect.Material = Enum.Material.Neon
		effect.Anchored = true
		effect.CanCollide = false
		effect.CFrame = rootPart.CFrame * CFrame.new(0, 0, -3)
		effect.Parent = workspace

		game:GetService("TweenService"):Create(effect, TweenInfo.new(0.5), {
			Size = Vector3.new(1, 15, 1),
			Transparency = 1
		}):Play()

		game:GetService("Debris"):AddItem(effect, 0.5)
	end

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

print("✅ Yumruk + Block + Skill sistemi hazır!")