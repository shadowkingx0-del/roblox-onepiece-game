local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("🟢 StatManager başlatıldı!")

-- RemoteEvent oluştur
local addStatEvent = Instance.new("RemoteEvent")
addStatEvent.Name = "AddStat"
addStatEvent.Parent = ReplicatedStorage
print("📡 AddStat RemoteEvent oluşturuldu!")

-- Stat ekleme
addStatEvent.OnServerEvent:Connect(function(player, statName)
	print("🎯 Stat ekleme isteği: " .. player.Name .. " → " .. statName)

	local playerData = player:FindFirstChild("PlayerData")
	if not playerData then 
		warn("❌ PlayerData bulunamadı!")
		return 
	end

	local statPoints = playerData:FindFirstChild("StatPoints")
	local stats = playerData:FindFirstChild("Stats")

	if not statPoints or not stats then
		warn("❌ StatPoints veya Stats bulunamadı!")
		return
	end

	if statPoints.Value <= 0 then
		warn("❌ Yeterli stat puanı yok!")
		return
	end

	local stat = stats:FindFirstChild(statName)
	if not stat then
		warn("❌ Geçersiz stat: " .. statName)
		return
	end

	-- Stat artır
	stat.Value = stat.Value + 1
	statPoints.Value = statPoints.Value - 1

	print("✅ " .. statName .. " artırıldı! Yeni değer: " .. stat.Value)
	print("⭐ Kalan puan: " .. statPoints.Value)

	-- Defense ise max canı artır
	if statName == "Defense" then
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.MaxHealth = 100 + (stat.Value * 5)
				humanoid.Health = humanoid.MaxHealth
				print("❤️ Max can: " .. humanoid.MaxHealth)
			end
		end
	end
end)

print("✅ StatManager hazır!")