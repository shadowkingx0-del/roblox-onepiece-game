local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("🟢 QUEST MANAGER BAŞLADI!")

-- RemoteEvent oluştur
local requestQuestEvent = Instance.new("RemoteEvent")
requestQuestEvent.Name = "RequestQuest"
requestQuestEvent.Parent = ReplicatedStorage
print("📡 RequestQuest RemoteEvent oluşturuldu!")

-- Görev şablonları
local QUESTS = {
	["QuestGiver_1"] = {
		Name = "Korsan Avı - Başlangıç",
		Description = "5 Korsan öldür",
		RequiredKills = 5,
		TargetEnemy = "Pirate",
		MinLevel = 0,
		MaxLevel = 10,
		RewardXP = 100,
		RewardMoney = 50
	}
	-- Daha fazla quest eklenebilir
}

-- Görev verme fonksiyonu
local function giveQuest(player, questId)
	print("📩 Görev isteği: " .. player.Name .. " → " .. questId)

	local questInfo = QUESTS[questId]
	if not questInfo then
		warn("❌ Geçersiz görev ID: " .. questId)
		return
	end

	-- Level kontrolü
	local level = player.leaderstats.Level.Value
	if level < questInfo.MinLevel then
		print("❌ Düşük seviye! Gereken: " .. questInfo.MinLevel .. ", Mevcut: " .. level)
		return
	end

	if level > questInfo.MaxLevel then
		print("❌ Yüksek seviye! Max: " .. questInfo.MaxLevel .. ", Mevcut: " .. level)
		return
	end

	-- Aktif görev var mı?
	if player:FindFirstChild("ActiveQuest") then
		print("❌ Zaten aktif görev var!")
		return
	end

	-- Görev oluştur
	local questFolder = Instance.new("Folder")
	questFolder.Name = "ActiveQuest"

	local questName = Instance.new("StringValue")
	questName.Name = "QuestName"
	questName.Value = questInfo.Name
	questName.Parent = questFolder

	local progress = Instance.new("IntValue")
	progress.Name = "Progress"
	progress.Value = 0
	progress.Parent = questFolder

	local required = Instance.new("IntValue")
	required.Name = "Required"
	required.Value = questInfo.RequiredKills
	required.Parent = questFolder

	local targetEnemy = Instance.new("StringValue")
	targetEnemy.Name = "TargetEnemy"
	targetEnemy.Value = questInfo.TargetEnemy
	targetEnemy.Parent = questFolder

	local rewardXP = Instance.new("IntValue")
	rewardXP.Name = "RewardXP"
	rewardXP.Value = questInfo.RewardXP
	rewardXP.Parent = questFolder

	local rewardMoney = Instance.new("IntValue")
	rewardMoney.Name = "RewardMoney"
	rewardMoney.Value = questInfo.RewardMoney
	rewardMoney.Parent = questFolder

	questFolder.Parent = player

	print("✅✅✅ GÖREV VERİLDİ: " .. questInfo.Name .. " ✅✅✅")
end

-- RemoteEvent dinle
requestQuestEvent.OnServerEvent:Connect(function(player, questId)
	print("🔔 SERVER'A İSTEK GELDİ: " .. player.Name .. " | Quest: " .. tostring(questId))
	giveQuest(player, questId)
end)

print("✅ Quest Manager hazır!")