local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("🔥 Skill System başlatıldı!")

-- Skill tanımları
local SKILLS = {
	HeavyPunch = {
		Name = "Sert Yumruk",
		Key = "R",
		Damage = 25,
		Cooldown = 8,
		RequiredStrength = 12,
		Description = "Güçlü tek yumruk, düşmanı geri iter"
	},

	UpperCut = {
		Name = "Çene Vuruşu",
		Key = "T",
		Damage = 30,
		Cooldown = 10,
		RequiredStrength = 25,
		Description = "Havaya fırlatan uppercut"
	},

	SpinningSlash = {
		Name = "Dönen Kesim",
		Key = "R",
		Damage = 35,
		Cooldown = 6,
		RequiredSword = 15,
		Description = "360° AOE saldırı"
	},

	DragonSlash = {
		Name = "Ejderha Kılıcı",
		Key = "T",
		Damage = 50,
		Cooldown = 12,
		RequiredSword = 30,
		Description = "İleriye giden güçlü dalga"
	}
}

-- RemoteEvent
local useSkillEvent = ReplicatedStorage:FindFirstChild("UseSkill")
if not useSkillEvent then
	useSkillEvent = Instance.new("RemoteEvent")
	useSkillEvent.Name = "UseSkill"
	useSkillEvent.Parent = ReplicatedStorage
	print("📡 UseSkill RemoteEvent oluşturuldu!")
end

-- Skill kullanımı
useSkillEvent.OnServerEvent:Connect(function(player, skillName, targetModel)
	local skill = SKILLS[skillName]
	if not skill then
		warn("❌ Geçersiz skill: " .. tostring(skillName))
		return
	end

	print("🔥 " .. player.Name .. " " .. skill.Name .. " kullandı!")

	-- Hedef kontrol
	if not targetModel or not targetModel:IsA("Model") then
		warn("❌ Geçersiz hedef!")
		return
	end

	local targetHumanoid = targetModel:FindFirstChildOfClass("Humanoid")
	if not targetHumanoid or targetHumanoid.Health <= 0 then
		warn("❌ Hedef ölü veya humanoid yok!")
		return
	end

	-- Hasar ver
	local damage = skill.Damage

	-- Strength/Sword bonusu ekle
	local playerData = player:FindFirstChild("PlayerData")
	if playerData then
		local stats = playerData:FindFirstChild("Stats")
		if stats then
			if skillName:find("Punch") or skillName == "UpperCut" then
				-- Yumruk skill'leri - Strength bonusu
				local strength = stats:FindFirstChild("Strength")
				if strength then
					damage = damage + (strength.Value * 2)
				end
			elseif skillName:find("Slash") then
				-- Kılıç skill'leri - Sword bonusu
				local sword = stats:FindFirstChild("Sword")
				if sword then
					damage = damage + (sword.Value * 3)
				end
			end
		end
	end

	targetHumanoid.Health = targetHumanoid.Health - damage
	print("💥 Skill hasarı: " .. damage)

	-- Skill özel efektleri
	if skillName == "HeavyPunch" then
		-- Geri itme
		local targetRoot = targetModel:FindFirstChild("HumanoidRootPart")
		local character = player.Character
		local playerRoot = character and character:FindFirstChild("HumanoidRootPart")

		if targetRoot and playerRoot then
			local direction = (targetRoot.Position - playerRoot.Position).Unit
			local knockback = Instance.new("BodyVelocity")
			knockback.MaxForce = Vector3.new(100000, 100000, 100000)
			knockback.Velocity = direction * 50 + Vector3.new(0, 20, 0)
			knockback.Parent = targetRoot
			game:GetService("Debris"):AddItem(knockback, 0.2)
		end

		-- Stun
		local stunEvent = ReplicatedStorage:WaitForChild("StunPlayer")
		stunEvent:FireAllClients(targetModel, 1)

	elseif skillName == "UpperCut" then
		-- Havaya fırlat
		local targetRoot = targetModel:FindFirstChild("HumanoidRootPart")

		if targetRoot then
			local uppercut = Instance.new("BodyVelocity")
			uppercut.MaxForce = Vector3.new(100000, 100000, 100000)
			uppercut.Velocity = Vector3.new(0, 80, 0)
			uppercut.Parent = targetRoot
			game:GetService("Debris"):AddItem(uppercut, 0.3)
		end

		-- Stun
		local stunEvent = ReplicatedStorage:WaitForChild("StunPlayer")
		stunEvent:FireAllClients(targetModel, 1.5)
	end
end)

print("✅ Skill System hazır!")