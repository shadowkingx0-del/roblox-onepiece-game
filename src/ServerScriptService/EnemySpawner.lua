print("🔵 ENEMY SPAWNER SCRIPT BAŞLADI!")

local ServerStorage = game:GetService("ServerStorage")

print("ServerStorage bulundu")

local enemies = ServerStorage:FindFirstChild("Enemies")
print("Enemies klasörü: " .. tostring(enemies))

local pirateTemplate = enemies and enemies:FindFirstChild("Pirate")
print("Pirate template: " .. tostring(pirateTemplate))

if not pirateTemplate then
	warn("❌ Pirate template bulunamadı!")
	return
end

print("✅ Pirate template bulundu!")

-- QuestGiver pozisyonu
wait(2)

local questGiver1 = workspace:FindFirstChild("QuestGiver_1")
if not questGiver1 then
	warn("❌ QuestGiver_1 bulunamadı!")
	return
end

print("✅ QuestGiver_1 bulundu!")

local qgRoot = questGiver1:FindFirstChild("HumanoidRootPart")
if not qgRoot then
	warn("❌ QuestGiver HumanoidRootPart yok!")
	return
end

local questGiverPos = qgRoot.Position
print("📍 Quest Giver pozisyonu: " .. tostring(questGiverPos))

-- Spawn ayarları
local SPAWN_OFFSET = Vector3.new(20, 0, 0)
local ENEMY_COUNT = 5
local SPAWN_RADIUS = 15
local ENEMY_LEVEL = 1

-- Spawn fonksiyonu
local function spawnPirate(index)
	print("🏴‍☠️ Korsan spawn ediliyor: " .. index)

	local pirate = pirateTemplate:Clone()
	pirate.Name = "Pirate_" .. index

	-- Pozisyon hesapla
	local angle = math.rad(index * (360 / ENEMY_COUNT))
	local spawnPos = questGiverPos + SPAWN_OFFSET
	local x = spawnPos.X + math.cos(angle) * SPAWN_RADIUS
	local z = spawnPos.Z + math.sin(angle) * SPAWN_RADIUS

	-- Pirate'i yerleştir
	pirate:SetPrimaryPartCFrame(CFrame.new(x, spawnPos.Y, z))

	-- Humanoid ayarla
	local humanoid = pirate:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.MaxHealth = 100
		humanoid.Health = 100
		humanoid.WalkSpeed = 8

		print("✅ Humanoid ayarlandı")

		-- Öldüğünde respawn
		humanoid.Died:Connect(function()
			print("☠️ " .. pirate.Name .. " öldü!")
			task.wait(10)
			pirate:Destroy()
			task.wait(1)
			spawnPirate(index)
		end)
	end

	-- İsim etiketi
	local head = pirate:FindFirstChild("Head")
	if head then
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 120, 0, 50)
		billboard.StudsOffset = Vector3.new(0, 3, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = head

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = "🏴‍☠️ Korsan"
		nameLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		nameLabel.TextSize = 16
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextStrokeTransparency = 0.5
		nameLabel.Parent = billboard

		local levelLabel = Instance.new("TextLabel")
		levelLabel.Size = UDim2.new(1, 0, 0.4, 0)
		levelLabel.Position = UDim2.new(0, 0, 0.6, 0)
		levelLabel.BackgroundTransparency = 1
		levelLabel.Text = "Lvl " .. ENEMY_LEVEL
		levelLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
		levelLabel.TextSize = 14
		levelLabel.Font = Enum.Font.Gotham
		levelLabel.TextStrokeTransparency = 0.5
		levelLabel.Parent = billboard
	end

	pirate.Parent = workspace
	print("✅ Spawn tamamlandı: " .. pirate.Name)
end

-- Tüm korsanları spawn et
print("🌍 Korsanlar spawn ediliyor...")

for i = 1, ENEMY_COUNT do
	spawnPirate(i)
	task.wait(0.2)
end

print("🎉 TÜM KORSANLAR SPAWN OLDU!")