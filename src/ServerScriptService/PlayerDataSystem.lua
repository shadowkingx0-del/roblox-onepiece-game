local DataStoreService = game:GetService("DataStoreService")
local PlayerDataStore = DataStoreService:GetDataStore("PlayerData_v4")

local Players = game:GetService("Players")

print("🟢 PlayerDataSystem başlatıldı!")

-- Varsayılan veri
local function getDefaultData()
	return {
		Level = 1,
		XP = 0,
		XPRequired = 100,
		Money = 0,
		StatPoints = 0,
		Stats = {
			Strength = 0,
			Defense = 0,
			Fruit = 0,
			Sword = 0
		},
		Inventory = {
			HasKatana = false,
			ActiveFruit = ""
		}
	}
end

-- Veri yükle
local function loadPlayerData(player)
	local success, data = pcall(function()
		return PlayerDataStore:GetAsync("Player_" .. player.UserId)
	end)

	if success and data then
		print("✅ Veri yüklendi: " .. player.Name)

		if not data.Stats.Sword then
			data.Stats.Sword = 0
		end

		if not data.Inventory then
			data.Inventory = {
				HasKatana = false,
				ActiveFruit = ""
			}
		end

		return data
	else
		print("📝 Yeni oyuncu: " .. player.Name)
		return getDefaultData()
	end
end

-- Veri kaydet
local function savePlayerData(player)
	if not player:FindFirstChild("leaderstats") then return end
	if not player:FindFirstChild("PlayerData") then return end

	local hasKatana = false
	local activeFruit = ""

	-- Backpack ve Character'de Katana kontrol et
	if player.Backpack:FindFirstChild("Katana") or (player.Character and player.Character:FindFirstChild("Katana")) then
		hasKatana = true
	end

	-- Ice Fruit kontrol et
	if player.Backpack:FindFirstChild("IceFruit") or (player.Character and player.Character:FindFirstChild("IceFruit")) then
		activeFruit = "Ice"
	end

	-- PlayerData'dan da kontrol et
	local playerData = player.PlayerData
	local activeFruitValue = playerData:FindFirstChild("ActiveFruit")
	if activeFruitValue and activeFruitValue.Value ~= "" then
		activeFruit = activeFruitValue.Value
	end

	local data = {
		Level = player.leaderstats.Level.Value,
		XP = player.PlayerData.XP.Value,
		XPRequired = player.PlayerData.XPRequired.Value,
		Money = player.leaderstats["Para"].Value,
		StatPoints = player.PlayerData.StatPoints.Value,
		Stats = {
			Strength = player.PlayerData.Stats.Strength.Value,
			Defense = player.PlayerData.Stats.Defense.Value,
			Fruit = player.PlayerData.Stats.Fruit.Value,
			Sword = player.PlayerData.Stats.Sword.Value
		},
		Inventory = {
			HasKatana = hasKatana,
			ActiveFruit = activeFruit
		}
	}

	local success, err = pcall(function()
		PlayerDataStore:SetAsync("Player_" .. player.UserId, data)
	end)

	if success then
		print("💾 KAYIT: " .. player.Name .. " | Katana=" .. tostring(hasKatana) .. " | Fruit=" .. activeFruit)
	else
		warn("❌ Kayıt hatası: " .. tostring(err))
	end
end

-- Oyuncuya tool ver
local function giveTools(player)
	print("🎒 Tool veriliyor: " .. player.Name)

	local inventoryData = player:FindFirstChild("SavedInventory")
	if not inventoryData then
		warn("❌ SavedInventory yok!")
		return
	end

	local hasKatana = inventoryData:FindFirstChild("HasKatana")
	local savedFruit = inventoryData:FindFirstChild("ActiveFruit")

	-- Katana ver
	if hasKatana and hasKatana.Value then
		local katana = game.ReplicatedStorage:FindFirstChild("Katana")
		if katana then
			local clone = katana:Clone()
			clone.Parent = player.Backpack
			print("⚔️ Katana verildi!")
		else
			warn("❌ Katana bulunamadı ReplicatedStorage'da!")
		end
	end

	-- Fruit ver
	if savedFruit and savedFruit.Value == "Ice" then
		local iceFruit = game.ReplicatedStorage:FindFirstChild("IceFruit")
		if iceFruit then
			local clone = iceFruit:Clone()
			clone.Parent = player.Backpack
			print("❄️ Ice Fruit verildi!")
		else
			warn("❌ IceFruit bulunamadı ReplicatedStorage'da!")
		end
	end
end

-- Oyuncu katıldığında
Players.PlayerAdded:Connect(function(player)
	print("🎮 Oyuncu katıldı: " .. player.Name)

	local data = loadPlayerData(player)

	-- leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Value = data.Level
	level.Parent = leaderstats

	local money = Instance.new("IntValue")
	money.Name = "Para"
	money.Value = data.Money
	money.Parent = leaderstats

	-- PlayerData
	local playerData = Instance.new("Folder")
	playerData.Name = "PlayerData"
	playerData.Parent = player

	local xp = Instance.new("IntValue")
	xp.Name = "XP"
	xp.Value = data.XP
	xp.Parent = playerData

	local xpRequired = Instance.new("IntValue")
	xpRequired.Name = "XPRequired"
	xpRequired.Value = data.XPRequired
	xpRequired.Parent = playerData

	local statPoints = Instance.new("IntValue")
	statPoints.Name = "StatPoints"
	statPoints.Value = data.StatPoints
	statPoints.Parent = playerData

	-- Stats
	local stats = Instance.new("Folder")
	stats.Name = "Stats"
	stats.Parent = playerData

	local strength = Instance.new("IntValue")
	strength.Name = "Strength"
	strength.Value = data.Stats.Strength
	strength.Parent = stats

	local defense = Instance.new("IntValue")
	defense.Name = "Defense"
	defense.Value = data.Stats.Defense
	defense.Parent = stats

	local fruit = Instance.new("IntValue")
	fruit.Name = "Fruit"
	fruit.Value = data.Stats.Fruit
	fruit.Parent = stats

	local sword = Instance.new("IntValue")
	sword.Name = "Sword"
	sword.Value = data.Stats.Sword
	sword.Parent = stats

	-- ActiveFruit value
	local activeFruit = Instance.new("StringValue")
	activeFruit.Name = "ActiveFruit"
	activeFruit.Value = data.Inventory.ActiveFruit
	activeFruit.Parent = playerData

	-- Inventory'yi kaydet (respawn için)
	local savedInventory = Instance.new("Folder")
	savedInventory.Name = "SavedInventory"
	savedInventory.Parent = player

	local hasKatanaValue = Instance.new("BoolValue")
	hasKatanaValue.Name = "HasKatana"
	hasKatanaValue.Value = data.Inventory.HasKatana
	hasKatanaValue.Parent = savedInventory

	local activeFruitValue = Instance.new("StringValue")
	activeFruitValue.Name = "ActiveFruit"
	activeFruitValue.Value = data.Inventory.ActiveFruit
	activeFruitValue.Parent = savedInventory

	-- Level up sistemi
	xp.Changed:Connect(function()
		if xp.Value >= xpRequired.Value then
			xp.Value = xp.Value - xpRequired.Value
			level.Value = level.Value + 1
			xpRequired.Value = math.floor(xpRequired.Value * 1.5)
			statPoints.Value = statPoints.Value + 3

			print("🎉 LEVEL UP! " .. player.Name .. " → Level " .. level.Value)

			local character = player.Character
			if character then
				local rootPart = character:FindFirstChild("HumanoidRootPart")
				if rootPart then
					local effect = Instance.new("Part")
					effect.Size = Vector3.new(8, 8, 8)
					effect.Shape = Enum.PartType.Ball
					effect.Color = Color3.fromRGB(255, 255, 0)
					effect.Material = Enum.Material.Neon
					effect.Anchored = true
					effect.CanCollide = false
					effect.Transparency = 0.5
					effect.CFrame = rootPart.CFrame
					effect.Parent = workspace
					game:GetService("Debris"):AddItem(effect, 1)
				end
			end
		end
	end)

	-- CharacterAdded - Her respawn'da tool ver
	player.CharacterAdded:Connect(function(character)
		task.wait(2)
		giveTools(player)
	end)

	-- Otomatik kayıt
	task.spawn(function()
		while player.Parent do
			task.wait(120)
			savePlayerData(player)
		end
	end)
end)

-- Oyuncu çıktığında kaydet
Players.PlayerRemoving:Connect(function(player)
	print("👋 Oyuncu ayrılıyor: " .. player.Name)
	savePlayerData(player)
end)

-- Sunucu kapanırken kaydet
game:BindToClose(function()
	print("🔴 Sunucu kapanıyor...")
	for _, player in pairs(Players:GetPlayers()) do
		savePlayerData(player)
	end
	task.wait(3)
end)

print("✅ PlayerDataSystem hazır!")