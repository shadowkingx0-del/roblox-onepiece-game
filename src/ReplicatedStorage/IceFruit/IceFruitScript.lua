print("🧪 ICE FRUIT SCRIPT BAŞLIYOR...")

local Tool = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

print("❄️ ICE FRUIT TOOL YÜKLENDI")

-- Stamina sistemi
local MAX_STAMINA = 200
local STAMINA_REGEN = 15
local stamina = MAX_STAMINA

wait(1)
local playerGui = player.PlayerGui
local mainUI = playerGui:WaitForChild("PlayerUI"):WaitForChild("MainFrame")

-- ORTAK STAMINA BAR KULLAN (Yumruk/Katana ile aynı)
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

-- Stamina yenileme
task.spawn(function()
	while true do
		task.wait(0.1)
		if stamina < MAX_STAMINA then
			stamina = math.min(MAX_STAMINA, stamina + (STAMINA_REGEN * 0.1))
			updateStaminaUI()
		end
	end
end)

-- Fruit Skill UI
local fruitSkillBar = mainUI:FindFirstChild("FruitSkillBar")
local skill1Frame = fruitSkillBar and fruitSkillBar:FindFirstChild("Skill1")
local skill2Frame = fruitSkillBar and fruitSkillBar:FindFirstChild("Skill2")
local skill3Frame = fruitSkillBar and fruitSkillBar:FindFirstChild("Skill3")

-- RemoteEvents
local getFruitInfoEvent = ReplicatedStorage:WaitForChild("GetFruitInfo")
local useFruitSkillEvent = ReplicatedStorage:WaitForChild("UseFruitSkill")

-- Meyve bilgisi
local activeFruit = nil
local fruitSkills = {}

-- Skill cooldown'ları
local skillCooldowns = {0, 0, 0}

local character
local humanoid

-- Meyve bilgisini al
local function loadFruitInfo()
	print("🔍 loadFruitInfo çağrıldı!")

	local success, fruitData = pcall(function()
		return getFruitInfoEvent:InvokeServer()
	end)

	print("🔍 pcall success: " .. tostring(success))

	if not success then
		print("❌ pcall HATASI: " .. tostring(fruitData))
		return
	end

	print("🔍 fruitData: " .. tostring(fruitData))

	if success and fruitData then
		activeFruit = fruitData
		fruitSkills = fruitData.Skills

		print("✅ Fruit yüklendi: " .. fruitData.DisplayName)
		print("✅ Skill sayısı: " .. #fruitData.Skills)

		-- Skill frame'lerini güncelle
		local skillFrames = {skill1Frame, skill2Frame, skill3Frame}
		for i, frame in pairs(skillFrames) do
			if frame and fruitSkills[i] then
				local skillName = frame:FindFirstChild("SkillName")
				if skillName then
					skillName.Text = fruitSkills[i].Name
					print("✅ Skill " .. i .. ": " .. fruitSkills[i].Name)
				end
			end
		end
	else
		print("❌ fruitData yok veya nil!")
	end
end

-- Yakındaki düşmanı bul
local function findNearestEnemy()
	if not character or not humanoid then return nil end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return nil end

	local nearestEnemy = nil
	local shortestDistance = 30

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

-- Skill kullan
local function useFruitSkill(skillIndex)
	print("🔍 useFruitSkill çağrıldı! Skill index: " .. skillIndex)

	if not activeFruit then
		print("❌ activeFruit YOK!")
		return
	end

	if not fruitSkills[skillIndex] then
		print("❌ fruitSkills[" .. skillIndex .. "] YOK!")
		print("fruitSkills toplam: " .. #fruitSkills)
		return
	end

	local skill = fruitSkills[skillIndex]

	print("✅ Skill bulundu: " .. skill.Name)

	-- Cooldown kontrolü
	if tick() - skillCooldowns[skillIndex] < skill.Cooldown then
		print("❌ " .. skill.Name .. " cooldown'da!")
		return
	end

	-- Stamina kontrolü
	if stamina < skill.StaminaCost then
		print("❌ Yetersiz stamina! Gereken: " .. skill.StaminaCost)
		return
	end

	-- Fruit stat kontrolü
	local playerData = player:FindFirstChild("PlayerData")
	if playerData then
		local stats = playerData:FindFirstChild("Stats")
		if stats then
			local fruitStat = stats:FindFirstChild("Fruit")
			if fruitStat and fruitStat.Value < skill.RequiredFruit then
				print("❌ " .. skill.RequiredFruit .. " Meyve Gücü gerekli!")
				return
			end
		end
	end

	print("🍇 " .. skill.Name .. " kullanılıyor!")

	-- Stamina harca
	stamina = stamina - skill.StaminaCost
	updateStaminaUI()

	skillCooldowns[skillIndex] = tick()

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Skill efektleri (basitleştirilmiş)
	local target = findNearestEnemy()

	if skill.Name == "Ice Spear" then
		if not target then
			print("❌ Hedef yok!")
			stamina = stamina + skill.StaminaCost
			updateStaminaUI()
			return
		end

		print("❄️ Ice Spear efekti!")

		local enemyRoot = target:FindFirstChild("HumanoidRootPart")
		if enemyRoot then
			local spear = Instance.new("Part")
			spear.Size = Vector3.new(0.5, 6, 0.5)
			spear.Color = Color3.fromRGB(150, 220, 255)
			spear.Material = Enum.Material.Ice
			spear.Anchored = true
			spear.CanCollide = false
			spear.CFrame = rootPart.CFrame * CFrame.new(0, 2, -3)
			spear.Parent = workspace

			game:GetService("TweenService"):Create(spear, TweenInfo.new(0.3), {
				CFrame = CFrame.new(enemyRoot.Position) * CFrame.Angles(math.rad(90), 0, 0)
			}):Play()

			task.wait(0.3)

			for i = 1, 10 do
				local ice = Instance.new("Part")
				ice.Size = Vector3.new(0.3, 0.3, 0.3)
				ice.Color = Color3.fromRGB(150, 220, 255)
				ice.Material = Enum.Material.Ice
				ice.Anchored = false
				ice.CanCollide = false
				ice.CFrame = enemyRoot.CFrame
				ice.Velocity = Vector3.new(math.random(-20, 20), math.random(5, 15), math.random(-20, 20))
				ice.Parent = workspace
				game:GetService("Debris"):AddItem(ice, 1)
			end

			game:GetService("Debris"):AddItem(spear, 0.5)
		end

	elseif skill.Name == "Ice Prison" then
		if not target then
			stamina = stamina + skill.StaminaCost
			updateStaminaUI()
			return
		end

		print("❄️ Ice Prison efekti!")

		local enemyRoot = target:FindFirstChild("HumanoidRootPart")
		if enemyRoot then
			for i = 1, 8 do
				local angle = (i / 8) * 360
				local bar = Instance.new("Part")
				bar.Size = Vector3.new(0.8, 8, 0.8)
				bar.Color = Color3.fromRGB(150, 220, 255)
				bar.Material = Enum.Material.Ice
				bar.Anchored = true
				bar.CanCollide = false
				bar.CFrame = enemyRoot.CFrame * CFrame.new(
					math.cos(math.rad(angle)) * 3,
					0,
					math.sin(math.rad(angle)) * 3
				)
				bar.Parent = workspace
				game:GetService("Debris"):AddItem(bar, 3)
			end
		end

	elseif skill.Name == "Ice Glacier" then
		print("❄️ Ice Glacier efekti!")

		local direction = rootPart.CFrame.LookVector
		local startPos = rootPart.Position + (direction * 5)

		for i = 1, 20 do
			task.spawn(function()
				task.wait(i * 0.05)

				local distance = i * 1.5
				local height = 2 + (i * 0.5)

				local glacier = Instance.new("Part")
				glacier.Size = Vector3.new(4, height, 4)
				glacier.Color = Color3.fromRGB(150, 220, 255)
				glacier.Material = Enum.Material.Ice
				glacier.Anchored = true
				glacier.CanCollide = false
				glacier.CFrame = CFrame.new(
					startPos.X + (direction.X * distance),
					startPos.Y - 3,
					startPos.Z + (direction.Z * distance)
				)
				glacier.Parent = workspace

				game:GetService("TweenService"):Create(glacier, TweenInfo.new(0.2), {
					CFrame = glacier.CFrame * CFrame.new(0, height / 2, 0)
				}):Play()

				game:GetService("Debris"):AddItem(glacier, 4)
			end)
		end

		target = startPos + (direction * 30)
	end

	-- Sunucuya gönder
	useFruitSkillEvent:FireServer(skill.Name, target)

	-- Cooldown UI
	local skillFrames = {skill1Frame, skill2Frame, skill3Frame}
	local frame = skillFrames[skillIndex]

	if frame then
		local cooldownFrame = frame:FindFirstChild("Cooldown")
		local cooldownText = cooldownFrame and cooldownFrame:FindFirstChild("CooldownText")

		if cooldownFrame then
			cooldownFrame.Visible = true

			for i = skill.Cooldown, 1, -1 do
				if cooldownText then
					cooldownText.Text = tostring(i)
				end
				task.wait(1)
			end

			cooldownFrame.Visible = false
		end
	end
end

-- Block sistemi
local isBlocking = false
local blockShield = nil
local blockEvent = ReplicatedStorage:WaitForChild("PlayerBlock")
local blockShieldUI = nil

local function createBlockShieldUI()
	if blockShieldUI then return end

	blockShieldUI = Instance.new("ScreenGui")
	blockShieldUI.Name = "BlockShieldUI_IceFruit"
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
		if shield then shield.Visible = true end
	end
end

local function hideBlockShield()
	if blockShieldUI then
		local shield = blockShieldUI:FindFirstChild("Shield")
		if shield then shield.Visible = false end
	end
end

local function startBlock()
	if isBlocking then return end
	if not character or not humanoid then return end

	isBlocking = true
	print("🛡️ Ice Fruit Block!")

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
	print("🛡️ Ice Fruit Block bitti!")

	blockEvent:FireServer(false)
	hideBlockShield()

	-- Block bar fullə
	if blockShieldUI then
		local shield = blockShieldUI:FindFirstChild("Shield")
		if shield then
			local barBG = shield:FindFirstChild("BarBG")
			if barBG then
				local fill = barBG:FindFirstChild("Fill")
				local text = barBG:FindFirstChild("Text")
				if fill and text then
					fill.Size = UDim2.new(1, 0, 1, 0)
					text.Text = "100"
				end
			end
		end
	end

	if humanoid then
		humanoid.WalkSpeed = 16
	end

	if blockShield then
		blockShield:Destroy()
		blockShield = nil
	end
end

-- Block hasar dinle
local blockDamageEvent = ReplicatedStorage:WaitForChild("BlockDamage")
blockDamageEvent.OnClientEvent:Connect(function(damage)
	if blockShieldUI then
		local shield = blockShieldUI:FindFirstChild("Shield")
		if shield then
			local barBG = shield:FindFirstChild("BarBG")
			if barBG then
				local fill = barBG:FindFirstChild("Fill")
				local text = barBG:FindFirstChild("Text")

				if fill and text then
					local currentHealth = tonumber(text.Text) or 100
					currentHealth = math.max(0, currentHealth - damage)

					local percentage = currentHealth / 100
					fill.Size = UDim2.new(1, 0, percentage, 0)
					text.Text = tostring(math.floor(currentHealth))
				end
			end
		end
	end

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

-- Tool Equipped
Tool.Equipped:Connect(function()
	print("🧪 Ice Fruit KUŞANILDI!")
	character = Tool.Parent
	humanoid = character:FindFirstChildOfClass("Humanoid")

	print("❄️ Ice Fruit kuşanıldı!")

	if fruitSkillBar then
		fruitSkillBar.Visible = true
		print("🎯 Fruit Skill UI gösterildi!")
	else
		print("❌ fruitSkillBar YOK!")
	end

	print("🔍 loadFruitInfo çağrılıyor...")
	loadFruitInfo()
end)

Tool.Unequipped:Connect(function()
	stopBlock()

	if fruitSkillBar then
		fruitSkillBar.Visible = false
		print("🎯 Fruit Skill UI gizlendi!")
	end

	character = nil
	humanoid = nil
end)

-- Tuş kontrolleri
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	print("🧪 TUŞ BASILDI: " .. tostring(input.KeyCode))

	if gameProcessed then 
		print("❌ gameProcessed = true")
		return 
	end

	if Tool.Parent ~= player.Character then 
		print("❌ Tool parent değil!")
		return 
	end

	if input.KeyCode == Enum.KeyCode.Z then
		print("✅ Z TUŞU - Skill 1!")
		useFruitSkill(1)
	elseif input.KeyCode == Enum.KeyCode.X then
		print("✅ X TUŞU - Skill 2!")
		useFruitSkill(2)
	elseif input.KeyCode == Enum.KeyCode.C then
		print("✅ C TUŞU - Skill 3!")
		useFruitSkill(3)
	elseif input.KeyCode == Enum.KeyCode.F then
		startBlock()
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.KeyCode == Enum.KeyCode.F then
		stopBlock()
	end
end)

print("✅ Ice Fruit Tool hazır!")