local Players = game:GetService("Players")

print("👑 Admin Commands başlatıldı!")

-- Admin kullanıcıları (User ID'lerini buraya ekle)
local ADMINS = {
	640150729,
	-- Kendi User ID'ni buraya ekle!
}

-- Komut geçmişi (debug için)
local commandHistory = {}

-- Admin mi kontrol et
local function isAdmin(player)
	for _, adminId in pairs(ADMINS) do
		if player.UserId == adminId then
			return true
		end
	end
	return false
end

-- Komutu parse et
local function parseCommand(message)
	local args = {}
	for word in message:gmatch("%S+") do
		table.insert(args, word)
	end
	return args
end

-- Hata mesajı gönder
local function sendError(player, message)
	print("❌ [ADMIN HATA - " .. player.Name .. "]: " .. message)
	-- İsteğe bağlı: Oyuncuya bildirim gönder
end

-- Başarı mesajı gönder
local function sendSuccess(player, message)
	print("✅ [ADMIN] " .. message)
end

-- Oyuncu giriş yaptığında
Players.PlayerAdded:Connect(function(player)
	if not isAdmin(player) then return end

	print("👑 Admin girişi: " .. player.Name .. " (ID: " .. player.UserId .. ")")

	player.Chatted:Connect(function(message)
		-- Komut formatı kontrolü
		if not message:match("^!") then return end

		local args = parseCommand(message)
		local command = args[1]:lower()

		-- Komut geçmişine ekle
		table.insert(commandHistory, {
			admin = player.Name,
			command = message,
			time = os.time()
		})

		-- !level [miktar]
		if command == "!level" then
			if not args[2] then
				sendError(player, "Kullanım: !level [miktar]")
				return
			end

			local amount = tonumber(args[2])
			if not amount then
				sendError(player, "Miktar sayı olmalıdır!")
				return
			end

			if amount < 1 then
				sendError(player, "Level 1'den küçük olamaz!")
				return
			end

			local currentLevel = player.leaderstats.Level.Value
			player.leaderstats.Level.Value = amount

			-- Stat puanlarını hesapla
			local levelDiff = amount - currentLevel
			if levelDiff > 0 then
				player.PlayerData.StatPoints.Value = player.PlayerData.StatPoints.Value + (levelDiff * 3)
			end

			sendSuccess(player, "⚔️ " .. player.Name .. " seviyesi " .. amount .. " olarak ayarlandı (+StatPoints: " .. (levelDiff * 3) .. ")")

			-- !addlevel [miktar]
		elseif command == "!addlevel" then
			local amount = tonumber(args[2]) or 1

			if amount < 1 then
				sendError(player, "Miktar 1'den büyük olmalıdır!")
				return
			end

			player.leaderstats.Level.Value = player.leaderstats.Level.Value + amount
			player.PlayerData.StatPoints.Value = player.PlayerData.StatPoints.Value + (amount * 3)

			sendSuccess(player, "⚔️ " .. player.Name .. " 'ye +" .. amount .. " level eklendi (+StatPoints: " .. (amount * 3) .. ")")

			-- !money [miktar]
		elseif command == "!money" then
			if not args[2] then
				sendError(player, "Kullanım: !money [miktar]")
				return
			end

			local amount = tonumber(args[2])
			if not amount or amount < 0 then
				sendError(player, "Para miktarı geçersiz!")
				return
			end

			player.leaderstats["Para"].Value = amount
			sendSuccess(player, "💰 " .. player.Name .. " 'nin parası " .. amount .. " olarak ayarlandı")

			-- !addmoney [miktar]
		elseif command == "!addmoney" then
			local amount = tonumber(args[2]) or 1000

			if amount < 0 then
				sendError(player, "Para miktarı negatif olamaz!")
				return
			end

			player.leaderstats["Para"].Value = player.leaderstats["Para"].Value + amount
			sendSuccess(player, "💰 " .. player.Name .. " 'ye +" .. amount .. " para eklendi")

			-- !xp [miktar]
		elseif command == "!xp" then
			if not args[2] then
				sendError(player, "Kullanım: !xp [miktar]")
				return
			end

			local amount = tonumber(args[2])
			if not amount or amount < 0 then
				sendError(player, "XP miktarı geçersiz!")
				return
			end

			player.PlayerData.XP.Value = amount
			sendSuccess(player, "✨ " .. player.Name .. " 'nin XP'si " .. amount .. " olarak ayarlandı")

			-- !stat [stat_name] [miktar]
		elseif command == "!stat" then
			if not args[2] or not args[3] then
				sendError(player, "Kullanım: !stat [Strength/Defense/Fruit/Sword] [miktar]")
				return
			end

			local statName = args[2]
			local amount = tonumber(args[3])

			if not amount or amount < 0 then
				sendError(player, "Stat miktarı geçersiz!")
				return
			end

			local stat = player.PlayerData.Stats:FindFirstChild(statName)
			if not stat then
				sendError(player, "Stat bulunamadı: " .. statName .. " (Strength, Defense, Fruit, Sword)")
				return
			end

			stat.Value = amount
			sendSuccess(player, "📊 " .. player.Name .. " 'nin " .. statName .. " 'i " .. amount .. " olarak ayarlandı")

			-- Defense ise max health güncelle
			if statName == "Defense" then
				local character = player.Character
				if character then
					local humanoid = character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						humanoid.MaxHealth = 100 + (amount * 5)
						humanoid.Health = humanoid.MaxHealth
						sendSuccess(player, "❤️ Max Health güncellendi: " .. humanoid.MaxHealth)
					end
				end
			end

			-- !points [miktar]
		elseif command == "!points" then
			if not args[2] then
				sendError(player, "Kullanım: !points [miktar]")
				return
			end

			local amount = tonumber(args[2])
			if not amount or amount < 0 then
				sendError(player, "Puan miktarı geçersiz!")
				return
			end

			player.PlayerData.StatPoints.Value = amount
			sendSuccess(player, "⭐ " .. player.Name .. " 'nin stat puanları " .. amount .. " olarak ayarlandı")

			-- !help
		elseif command == "!help" then
			print([[
👑 ADMIN KOMUTLARI:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
!level [miktar] - Level ayarla
!addlevel [miktar] - Level ekle
!money [miktar] - Para ayarla
!addmoney [miktar] - Para ekle
!xp [miktar] - XP ayarla
!stat [Strength/Defense/Fruit/Sword] [miktar] - Stat ayarla
!points [miktar] - Stat puanları ayarla
!help - Komutları göster
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            ]])

			-- Bilinmeyen komut
		else
			sendError(player, "Bilinmeyen komut: " .. command .. " (!help yazın)")
		end
	end)
end)

print("✅ Admin Commands hazır!")
print("⚠️ UYARI: ADMINS tablosuna kendi User ID'ni ekle!")