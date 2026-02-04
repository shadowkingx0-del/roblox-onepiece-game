local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("🟢 Block System başlatıldı!")

-- Block durumları
local blockingPlayers = {}
local blockHealth = {} -- Block'un sağlığı

local MAX_BLOCK_HEALTH = 100 -- Block'un maksimum sağlığı

-- RemoteEvents
local blockEvent = ReplicatedStorage:FindFirstChild("PlayerBlock")
if not blockEvent then
	blockEvent = Instance.new("RemoteEvent")
	blockEvent.Name = "PlayerBlock"
	blockEvent.Parent = ReplicatedStorage
end

local blockDamageEvent = ReplicatedStorage:FindFirstChild("BlockDamage")
if not blockDamageEvent then
	blockDamageEvent = Instance.new("RemoteEvent")
	blockDamageEvent.Name = "BlockDamage"
	blockDamageEvent.Parent = ReplicatedStorage
end

local dealDamageToPlayer = ReplicatedStorage:FindFirstChild("DealDamageToPlayer")
if not dealDamageToPlayer then
	dealDamageToPlayer = Instance.new("RemoteEvent")
	dealDamageToPlayer.Name = "DealDamageToPlayer"
	dealDamageToPlayer.Parent = ReplicatedStorage
end

-- Oyuncu giriş yaptığında
Players.PlayerAdded:Connect(function(player)
	blockHealth[player] = MAX_BLOCK_HEALTH
	print("✅ Oyuncu eklendi: " .. player.Name)
end)

Players.PlayerRemoving:Connect(function(player)
	blockingPlayers[player] = nil
	blockHealth[player] = nil
end)

-- Block başladı/bitti
blockEvent.OnServerEvent:Connect(function(player, isBlocking)
	blockingPlayers[player] = isBlocking

	-- Block başlarken sağlığı yenile
	if isBlocking then
		blockHealth[player] = MAX_BLOCK_HEALTH
	end

	print("🛡️ " .. player.Name .. " block: " .. tostring(isBlocking))
end)

-- Hasar sistemi
dealDamageToPlayer.OnServerEvent:Connect(function(player, enemy, damage)
	print("⚔️ " .. tostring(enemy) .. " → " .. player.Name .. " | Hasar: " .. damage)

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	-- Block yapıyor mu?
	if blockingPlayers[player] then
		print("🛡️ BLOCK YAPILIYOR! Hasar bloke edildi: " .. damage)

		-- Block'un sağlığını azalt
		blockHealth[player] = blockHealth[player] - damage
		print("🛡️ Block Sağlığı: " .. blockHealth[player] .. "/" .. MAX_BLOCK_HEALTH)

		-- Block kırıldı mı?
		if blockHealth[player] <= 0 then
			print("💥 Block Kırıldı!")
			blockingPlayers[player] = false
			blockHealth[player] = MAX_BLOCK_HEALTH
		end

		-- Client'a block hasar bilgisini gönder (UI güncellemesi için)
		blockDamageEvent:FireClient(player, damage, blockHealth[player])
		return
	end

	-- Block yapmıyorsa normal hasar ver
	print("💔 Block YOK, hasar veriliyor!")

	-- Defense stat hesapla
	local finalDamage = damage
	local playerData = player:FindFirstChild("PlayerData")
	if playerData then
		local stats = playerData:FindFirstChild("Stats")
		if stats then
			local defense = stats:FindFirstChild("Defense")
			if defense then
				local reduction = defense.Value * 0.02
				finalDamage = damage * (1 - reduction)
				print("🛡️ Defense: " .. damage .. " → " .. finalDamage)
			end
		end
	end

	humanoid:TakeDamage(finalDamage)
	print("❤️ Hasar: " .. math.floor(finalDamage) .. " | Kalan can: " .. humanoid.Health)
end)

print("✅ Block System hazır!")