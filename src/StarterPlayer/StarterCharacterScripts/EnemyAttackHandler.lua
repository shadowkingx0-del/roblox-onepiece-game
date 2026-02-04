local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

print("🎬 Enemy Attack Handler başlatıldı!")

-- Düşman animasyon ID'leri (senin yaptığın animasyonlar)
local ENEMY_COMBO_ANIMATIONS = {
	"rbxassetid://140613123430687",
	"rbxassetid://137026546119765",
	"rbxassetid://133849548277297",
	"rbxassetid://129062407281330"
}

-- Yüklü animasyonları sakla
local enemyAnimations = {}

-- Düşman için animasyon yükle
local function loadAnimationsForEnemy(enemy)
	if enemyAnimations[enemy] then return end

	local humanoid = enemy:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	enemyAnimations[enemy] = {}

	for i, animId in ipairs(ENEMY_COMBO_ANIMATIONS) do
		local animation = Instance.new("Animation")
		animation.AnimationId = animId
		enemyAnimations[enemy][i] = animator:LoadAnimation(animation)
	end

	print("✅ Animasyonlar yüklendi: " .. enemy.Name)
end

-- Saldırı eventi
local enemyAttackEvent = ReplicatedStorage:WaitForChild("EnemyAttack")
local stunEvent = ReplicatedStorage:WaitForChild("StunPlayer")

enemyAttackEvent.OnClientEvent:Connect(function(enemy, target, comboNumber)
	if not enemy or not target then return end

	-- Bu client'ın karakteri mi hedef?
	if target ~= player.Character then return end

	print("⚔️ " .. enemy.Name .. " kombo " .. comboNumber .. "/4")

	-- Animasyonları yükle
	loadAnimationsForEnemy(enemy)

	-- Kombo numarasına göre animasyon oynat
	local animations = enemyAnimations[enemy]
	if animations and animations[comboNumber] then
		animations[comboNumber]:Play()
	end

	-- Ses efekti (kombo ile ses yükselsin)
	local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
	if enemyRoot then
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://169445226"
		sound.Volume = 0.3 + (comboNumber * 0.1)
		sound.PlaybackSpeed = 0.9 + (comboNumber * 0.05)
		sound.Parent = enemyRoot
		sound:Play()
		game:GetService("Debris"):AddItem(sound, 1)
	end

	-- Hasar efekti (kombo ile büyüsün)
	local playerRoot = target:FindFirstChild("HumanoidRootPart")
	if playerRoot then
		local effectSize = 1.5 + (comboNumber * 0.3)
		local hitEffect = Instance.new("Part")
		hitEffect.Size = Vector3.new(effectSize, effectSize, effectSize)
		hitEffect.Color = Color3.fromRGB(255, 150 - (comboNumber * 20), 0)
		hitEffect.Material = Enum.Material.Neon
		hitEffect.Anchored = true
		hitEffect.CanCollide = false
		hitEffect.Shape = Enum.PartType.Ball
		hitEffect.CFrame = playerRoot.CFrame
		hitEffect.Parent = workspace
		game:GetService("Debris"):AddItem(hitEffect, 0.3)

		-- Finisher efekti
		if comboNumber == 4 then
			print("🔥 DÜŞMAN FİNİSHER!")

			local explosion = Instance.new("Part")
			explosion.Size = Vector3.new(6, 6, 6)
			explosion.Color = Color3.fromRGB(255, 50, 0)
			explosion.Material = Enum.Material.Neon
			explosion.Anchored = true
			explosion.CanCollide = false
			explosion.Shape = Enum.PartType.Ball
			explosion.Transparency = 0.3
			explosion.CFrame = playerRoot.CFrame
			explosion.Parent = workspace

			game:GetService("TweenService"):Create(explosion, TweenInfo.new(0.5), {
				Size = Vector3.new(12, 12, 12),
				Transparency = 1
			}):Play()

			game:GetService("Debris"):AddItem(explosion, 0.5)
		end
	end

	task.wait(0.2)

	-- Oyuncuya hasar ver
	local playerHumanoid = target:FindFirstChildOfClass("Humanoid")
	if playerHumanoid and playerHumanoid.Health > 0 then
		local dealDamageToPlayer = ReplicatedStorage:FindFirstChild("DealDamageToPlayer")
		if not dealDamageToPlayer then
			dealDamageToPlayer = Instance.new("RemoteEvent")
			dealDamageToPlayer.Name = "DealDamageToPlayer"
			dealDamageToPlayer.Parent = ReplicatedStorage
		end

		-- Kombo hasarı (her vuruşta artar)
		local damage = 12 + (comboNumber * 2)
		dealDamageToPlayer:FireServer(enemy, damage)

		-- Oyuncuyu stunla (sadece ilk 3 vuruşta)
		if comboNumber < 4 then
			stunEvent:FireServer(target, 0.6)
		else
			-- Finisher'da daha uzun stun
			stunEvent:FireServer(target, 1.2)
		end
	end
end)

-- Workspace'teki düşmanlar için animasyon yükle
task.wait(2)

for _, obj in pairs(workspace:GetChildren()) do
	if obj.Name:find("Pirate") and obj:IsA("Model") then
		loadAnimationsForEnemy(obj)
	end
end

workspace.ChildAdded:Connect(function(child)
	if child.Name:find("Pirate") and child:IsA("Model") then
		task.wait(0.5)
		loadAnimationsForEnemy(child)
	end
end)

print("✅ Enemy Attack Handler hazır!")