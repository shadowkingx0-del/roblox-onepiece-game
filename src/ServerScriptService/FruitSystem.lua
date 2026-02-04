local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🍇 Fruit System başlatıldı!")

-- Meyve tanımları
local FRUITS = {
	Ice = {
		Name = "Ice-Ice Fruit (Hie Hie no Mi)",
		DisplayName = "Buz Meyvesi",
		Rarity = "Rare",
		Description = "Buzları kontrol et, düşmanları dondur!",
		RespawnTime = 300,  -- 5 dakika
		Skills = {
			{
				Name = "Ice Spear",
				Key = "Z",
				Damage = 12,  -- DÜŞÜRÜLDÜ (yumruk gibi)
				Cooldown = 5,
				StaminaCost = 60,
				RequiredFruit = 10,
				Description = "Buz mızrak fırlat, düşmanı dondurur"
			},
			{
				Name = "Ice Prison",
				Key = "X",
				Damage = 15,  -- DÜŞÜRÜLDÜ
				Cooldown = 8,
				StaminaCost = 80,
				RequiredFruit = 20,
				Description = "Düşmanı buz kafese hapse, 3 saniye donuk"
			},
			{
				Name = "Ice Glacier",  -- YENİ SKİLL (eski Ice Age yerine)
				Key = "C",
				Damage = 18,  -- DÜŞÜRÜLDÜ
				Cooldown = 12,
				StaminaCost = 120,
				RequiredFruit = 35,
				Description = "Yere basarak ilerleyen buz yığını, yukarı fırlatır"
			}
		}
	}
}

-- Fruit spawn takibi
local fruitSpawns = {
	IceFruitSpawn = {
		IsAvailable = true,
		FruitType = "Ice"
	}
}

-- RemoteEvents
local eatFruitEvent = ReplicatedStorage:FindFirstChild("EatFruit")
if not eatFruitEvent then
	eatFruitEvent = Instance.new("RemoteEvent")
	eatFruitEvent.Name = "EatFruit"
	eatFruitEvent.Parent = ReplicatedStorage
end

local useFruitSkillEvent = ReplicatedStorage:FindFirstChild("UseFruitSkill")
if not useFruitSkillEvent then
	useFruitSkillEvent = Instance.new("RemoteEvent")
	useFruitSkillEvent.Name = "UseFruitSkill"
	useFruitSkillEvent.Parent = ReplicatedStorage
end

local getFruitInfoEvent = ReplicatedStorage:FindFirstChild("GetFruitInfo")
if not getFruitInfoEvent then
	getFruitInfoEvent = Instance.new("RemoteFunction")
	getFruitInfoEvent.Name = "GetFruitInfo"
	getFruitInfoEvent.Parent = ReplicatedStorage
end

-- Oyuncu meyve yediğinde
eatFruitEvent.OnServerEvent:Connect(function(player, fruitName)
	print("📩 " .. player.Name .. " → " .. fruitName .. " isteği")

	local fruit = FRUITS[fruitName]
	if not fruit then
		warn("❌ Geçersiz meyve: " .. tostring(fruitName))
		return
	end

	-- Spawn mevcut mu?
	local spawnName = fruitName .. "FruitSpawn"
	local spawnData = fruitSpawns[spawnName]

	if not spawnData then
		warn("❌ Spawn data bulunamadı: " .. spawnName)
		return
	end

	if not spawnData.IsAvailable then
		print("❌ " .. fruitName .. " şu anda mevcut değil!")
		return
	end

	-- Zaten meyvesi var mı?
	local playerData = player:FindFirstChild("PlayerData")
	if not playerData then 
		warn("❌ PlayerData bulunamadı!")
		return 
	end

	local activeFruit = playerData:FindFirstChild("ActiveFruit")
	if activeFruit and activeFruit.Value ~= "" then
		print("❌ " .. player.Name .. " zaten bir meyveye sahip: " .. activeFruit.Value)
		return
	end

	-- Meyveyi ver
	activeFruit.Value = fruitName

	print("✅✅✅ " .. player.Name .. " → " .. fruit.DisplayName .. " KAZANDI!")

	-- Spawn'u gizle
	spawnData.IsAvailable = false

	local fruitObject = workspace:FindFirstChild(spawnName)
	if fruitObject then
		print("🔒 " .. spawnName .. " gizleniyor...")
		fruitObject.Transparency = 1

		local billboard = fruitObject:FindFirstChild("BillboardGui")
		if billboard then
			billboard.Enabled = false
		end

		local clickDetector = fruitObject:FindFirstChild("ClickDetector")
		if clickDetector then
			clickDetector.MaxActivationDistance = 0
		end
	end

	-- Görsel efekt
	local character = player.Character
	if character then
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			print("✨ Efektler oluşturuluyor...")
			for i = 1, 20 do
				local particle = Instance.new("Part")
				particle.Size = Vector3.new(0.5, 0.5, 0.5)
				particle.Color = Color3.fromRGB(100, 200, 255)
				particle.Material = Enum.Material.Neon
				particle.Anchored = false
				particle.CanCollide = false
				particle.CFrame = rootPart.CFrame * CFrame.new(
					math.random(-3, 3),
					math.random(0, 5),
					math.random(-3, 3)
				)
				particle.Velocity = Vector3.new(
					math.random(-10, 10),
					math.random(10, 20),
					math.random(-10, 10)
				)
				particle.Parent = workspace
				game:GetService("Debris"):AddItem(particle, 2)
			end
		end
	end

	-- Respawn
	task.spawn(function()
		print("⏰ " .. fruitName .. " " .. fruit.RespawnTime .. " saniye sonra gelecek")
		task.wait(fruit.RespawnTime)

		spawnData.IsAvailable = true

		if fruitObject then
			print("✅ " .. spawnName .. " yeniden spawn!")
			fruitObject.Transparency = 0

			local billboard = fruitObject:FindFirstChild("BillboardGui")
			if billboard then
				billboard.Enabled = true
			end

			local clickDetector = fruitObject:FindFirstChild("ClickDetector")
			if clickDetector then
				clickDetector.MaxActivationDistance = 32
			end
		end
	end)
end)

-- Meyve bilgisi gönder
getFruitInfoEvent.OnServerInvoke = function(player)
	print("📡 GetFruitInfo çağrıldı: " .. player.Name)  -- DEBUG ekle

	local playerData = player:FindFirstChild("PlayerData")
	if not playerData then 
		print("❌ PlayerData yok!")
		return nil 
	end

	local activeFruit = playerData:FindFirstChild("ActiveFruit")
	if not activeFruit or activeFruit.Value == "" then
		print("❌ ActiveFruit yok veya boş!")
		return nil
	end

	print("✅ Active Fruit: " .. activeFruit.Value)

	local fruitData = FRUITS[activeFruit.Value]
	if not fruitData then 
		print("❌ FruitData bulunamadı!")
		return nil 
	end

	print("✅ FruitData bulundu: " .. fruitData.DisplayName)

	return {
		FruitId = activeFruit.Value,
		Name = fruitData.Name,
		DisplayName = fruitData.DisplayName,
		Skills = fruitData.Skills
	}
end

-- Meyve skill kullanımı
useFruitSkillEvent.OnServerEvent:Connect(function(player, skillName, targetOrPosition)
	print("🍇 " .. player.Name .. " " .. skillName .. " kullanıyor!")

	local playerData = player:FindFirstChild("PlayerData")
	if not playerData then return end

	local activeFruit = playerData:FindFirstChild("ActiveFruit")
	if not activeFruit or activeFruit.Value == "" then
		warn("❌ Oyuncunun meyvesi yok!")
		return
	end

	local fruit = FRUITS[activeFruit.Value]
	if not fruit then return end

	-- Skill'i bul
	local skillData = nil
	for _, skill in pairs(fruit.Skills) do
		if skill.Name == skillName then
			skillData = skill
			break
		end
	end

	if not skillData then
		warn("❌ Skill bulunamadı: " .. skillName)
		return
	end

	-- Hasar hesapla
	local damage = skillData.Damage
	local stats = playerData:FindFirstChild("Stats")
	if stats then
		local fruitStat = stats:FindFirstChild("Fruit")
		if fruitStat then
			damage = damage + (fruitStat.Value * 2)
		end
	end

	-- Skill efektleri
	if skillName == "Ice Spear" then
				if targetOrPosition and targetOrPosition:IsA("Model") then
					local humanoid = targetOrPosition:FindFirstChildOfClass("Humanoid")
					local rootPart = targetOrPosition:FindFirstChild("HumanoidRootPart")

					if humanoid and rootPart then
						humanoid:TakeDamage(damage)
						print("❄️ Ice Spear hasar: " .. damage)

						-- DONMA EFEKTİ: Düşmanı buza dönüştür
						local iceBlock = Instance.new("Part")
						iceBlock.Name = "IceBlock"
						iceBlock.Size = rootPart.Size + Vector3.new(1, 1, 1)
						iceBlock.Color = Color3.fromRGB(150, 220, 255)
						iceBlock.Material = Enum.Material.Ice
						iceBlock.Anchored = false
						iceBlock.CanCollide = false
						iceBlock.Transparency = 0.4
						iceBlock.CFrame = rootPart.CFrame

						local weld = Instance.new("WeldConstraint")
						weld.Part0 = rootPart
						weld.Part1 = iceBlock
						weld.Parent = iceBlock

						iceBlock.Parent = targetOrPosition

						-- Yavaşlama + Stun
						local oldSpeed = humanoid.WalkSpeed
						humanoid.WalkSpeed = 0
						humanoid.JumpPower = 0

						-- Stun efekti
						local stunEvent = ReplicatedStorage:WaitForChild("StunPlayer")
						stunEvent:FireAllClients(targetOrPosition, 2)

						task.wait(2)  -- 2 saniye donuk

						-- Buz kırılsın
						if iceBlock and iceBlock.Parent then
							iceBlock:Destroy()
						end

						if humanoid then
							humanoid.WalkSpeed = oldSpeed
							humanoid.JumpPower = 50
						end
					end
				end

			elseif skillName == "Ice Prison" then
				if targetOrPosition and targetOrPosition:IsA("Model") then
					local humanoid = targetOrPosition:FindFirstChildOfClass("Humanoid")
					local rootPart = targetOrPosition:FindFirstChild("HumanoidRootPart")

					if humanoid and rootPart then
						humanoid:TakeDamage(damage)
						print("❄️ Ice Prison hasar: " .. damage)

						-- Buz blok (tam donma)
						local iceBlock = Instance.new("Part")
						iceBlock.Name = "IceBlock"
						iceBlock.Size = rootPart.Size + Vector3.new(1.5, 1.5, 1.5)
						iceBlock.Color = Color3.fromRGB(150, 220, 255)
						iceBlock.Material = Enum.Material.Ice
						iceBlock.Anchored = false
						iceBlock.CanCollide = false
						iceBlock.Transparency = 0.3
						iceBlock.CFrame = rootPart.CFrame

						local weld = Instance.new("WeldConstraint")
						weld.Part0 = rootPart
						weld.Part1 = iceBlock
						weld.Parent = iceBlock

						iceBlock.Parent = targetOrPosition

						-- Hareketsiz
						local oldSpeed = humanoid.WalkSpeed
						humanoid.WalkSpeed = 0
						humanoid.JumpPower = 0

						local stunEvent = ReplicatedStorage:WaitForChild("StunPlayer")
						stunEvent:FireAllClients(targetOrPosition, 3)

						task.wait(3)  -- 3 saniye hapiste

						if iceBlock and iceBlock.Parent then
							iceBlock:Destroy()
						end

						if humanoid then
							humanoid.WalkSpeed = oldSpeed
							humanoid.JumpPower = 50
						end
					end
				end

			elseif skillName == "Ice Glacier" then
				-- Yeni skill - sadece düşmana hasar
				if targetOrPosition and targetOrPosition:IsA("Model") then
					local humanoid = targetOrPosition:FindFirstChildOfClass("Humanoid")
					local rootPart = targetOrPosition:FindFirstChild("HumanoidRootPart")

					if humanoid and rootPart then
						humanoid:TakeDamage(damage)
						print("❄️ Ice Glacier hasar: " .. damage)

						-- Kısa donma (0.5 saniye)
						local iceBlock = Instance.new("Part")
						iceBlock.Name = "IceBlock"
						iceBlock.Size = rootPart.Size + Vector3.new(0.5, 0.5, 0.5)
						iceBlock.Color = Color3.fromRGB(150, 220, 255)
						iceBlock.Material = Enum.Material.Ice
						iceBlock.Anchored = false
						iceBlock.CanCollide = false
						iceBlock.Transparency = 0.5
						iceBlock.CFrame = rootPart.CFrame

						local weld = Instance.new("WeldConstraint")
						weld.Part0 = rootPart
						weld.Part1 = iceBlock
						weld.Parent = iceBlock

						iceBlock.Parent = targetOrPosition

						task.wait(0.5)

						if iceBlock and iceBlock.Parent then
							iceBlock:Destroy()
						end
					end
				end
		end
	end
end)

print("✅ Fruit System hazır!")