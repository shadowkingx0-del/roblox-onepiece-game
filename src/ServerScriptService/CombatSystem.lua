local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("🟢 CombatSystem başlatıldı!")

-- RemoteEvent oluştur
local dealDamageEvent = ReplicatedStorage:FindFirstChild("DealDamage")
if not dealDamageEvent then
	dealDamageEvent = Instance.new("RemoteEvent")
	dealDamageEvent.Name = "DealDamage"
	dealDamageEvent.Parent = ReplicatedStorage
	print("📡 DealDamage RemoteEvent oluşturuldu!")
end

-- Hasar sistemi
dealDamageEvent.OnServerEvent:Connect(function(player, targetModel, baseDamage)
	print("⚔️ Hasar isteği geldi: " .. player.Name .. " → " .. tostring(targetModel))

	if not targetModel or not targetModel:IsA("Model") then
		warn("❌ Geçersiz hedef!")
		return
	end

	local targetHumanoid = targetModel:FindFirstChildOfClass("Humanoid")
	if not targetHumanoid then
		warn("❌ Hedefte Humanoid yok!")
		return
	end

	-- Strength hesapla
	local finalDamage = baseDamage
	local playerData = player:FindFirstChild("PlayerData")
	if playerData then
		local stats = playerData:FindFirstChild("Stats")
		if stats then
			local strength = stats:FindFirstChild("Strength")
			if strength then
				finalDamage = finalDamage + (strength.Value * 2)
			end
		end
	end

	-- Hasar ver
	targetHumanoid.Health = targetHumanoid.Health - finalDamage
	print("💥 Hasar: " .. finalDamage .. " | Kalan can: " .. math.floor(targetHumanoid.Health))

	-- Öldüyse ödül ver
	if targetHumanoid.Health <= 0 then
		print("☠️ " .. targetModel.Name .. " öldü!")

		local xpReward = 25
		local moneyReward = 10

		if playerData then
			local xp = playerData:FindFirstChild("XP")
			if xp then
				xp.Value = xp.Value + xpReward
				print("✨ +" .. xpReward .. " XP kazanıldı!")
			end

			local money = player.leaderstats:FindFirstChild("Para")
			if money then
				money.Value = money.Value + moneyReward
				print("💰 +" .. moneyReward .. " para kazanıldı!")
			end
		end

		-- GÖREV İLERLEMESİ KONTROL ET
		local activeQuest = player:FindFirstChild("ActiveQuest")
		if activeQuest then
			local targetEnemy = activeQuest:FindFirstChild("TargetEnemy")
			local progress = activeQuest:FindFirstChild("Progress")
			local required = activeQuest:FindFirstChild("Required")

			-- Doğru düşmanı öldürdü mü?
			if targetEnemy and targetModel.Name:find(targetEnemy.Value) then
				if progress and required then
					progress.Value = progress.Value + 1
					print("📊 Görev İlerlemesi: " .. progress.Value .. "/" .. required.Value)

					-- Görev tamamlandı mı?
					if progress.Value >= required.Value then
						print("🎉 GÖREV TAMAMLANDI!")

						-- Ödülleri ver
						local rewardXP = activeQuest:FindFirstChild("RewardXP")
						local rewardMoney = activeQuest:FindFirstChild("RewardMoney")

						if rewardXP and playerData then
							local xp = playerData:FindFirstChild("XP")
							if xp then
								xp.Value = xp.Value + rewardXP.Value
								print("🎁 Görev Ödülü XP: +" .. rewardXP.Value)
							end
						end

						if rewardMoney then
							local money = player.leaderstats:FindFirstChild("Para")
							if money then
								money.Value = money.Value + rewardMoney.Value
								print("🎁 Görev Ödülü Para: +" .. rewardMoney.Value)
							end
						end

						-- Görevi sil
						activeQuest:Destroy()
						print("✅ Görev tamamlandı ve silindi!")
					end
				end
			end
		end

		-- Yeniden canlandır
		task.wait(3)
		if targetHumanoid then
			targetHumanoid.Health = targetHumanoid.MaxHealth
			print("♻️ " .. targetModel.Name .. " yeniden canlandı!")
		end
	end
end)
