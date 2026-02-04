local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🟢 Stun System başlatıldı!")

-- RemoteEvent
local stunEvent = ReplicatedStorage:FindFirstChild("StunPlayer")
if not stunEvent then
	stunEvent = Instance.new("RemoteEvent")
	stunEvent.Name = "StunPlayer"
	stunEvent.Parent = ReplicatedStorage
end

-- Stun tablosu
local stunnedCharacters = {}

-- Block durumlarını kontrol için
local blockEvent = ReplicatedStorage:WaitForChild("PlayerBlock")
local blockingPlayers = {}

-- Block durumunu takip et
blockEvent.OnServerEvent:Connect(function(player, isBlocking)
	blockingPlayers[player] = isBlocking
end)

stunEvent.OnServerEvent:Connect(function(player, targetModel, stunDuration)
	if not targetModel or not targetModel:IsA("Model") then return end

	local humanoid = targetModel:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	-- BLOCK YAPIYORSA STUN VERME!
	local targetPlayer = game.Players:GetPlayerFromCharacter(targetModel)
	if targetPlayer and blockingPlayers[targetPlayer] then
		print("🛡️ " .. targetPlayer.Name .. " block yapıyor, stun verilmedi!")
		return
	end

	-- Zaten stunlu mu kontrol et
	if stunnedCharacters[targetModel] then
		print("⚠️ " .. targetModel.Name .. " zaten stunlu!")
		return
	end

	print("😵 " .. targetModel.Name .. " stunlandı! Süre: " .. stunDuration .. "s")

	stunnedCharacters[targetModel] = true

	-- Hareketi durdur
	local originalWalkSpeed = humanoid.WalkSpeed
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0

	-- Stun efekti (yıldızlar)
	local head = targetModel:FindFirstChild("Head")
	if head then
		for i = 1, 3 do
			local star = Instance.new("Part")
			star.Size = Vector3.new(0.5, 0.5, 0.5)
			star.Shape = Enum.PartType.Ball
			star.Color = Color3.fromRGB(255, 255, 0)
			star.Material = Enum.Material.Neon
			star.Anchored = true
			star.CanCollide = false
			star.Parent = workspace

			-- Yıldızları döndür
			task.spawn(function()
				local startTime = tick()
				while tick() - startTime < stunDuration and star.Parent do
					local angle = (tick() - startTime) * 5 + (i * (360/3))
					local radius = 2
					local x = head.Position.X + math.cos(math.rad(angle)) * radius
					local z = head.Position.Z + math.sin(math.rad(angle)) * radius
					star.CFrame = CFrame.new(x, head.Position.Y + 3, z)
					task.wait()
				end
				star:Destroy()
			end)
		end
	end

	-- Stun süresini bekle
	task.wait(stunDuration)

	-- Hareketi geri ver
	if humanoid and humanoid.Health > 0 then
		humanoid.WalkSpeed = originalWalkSpeed
		humanoid.JumpPower = 50
		print("✅ " .. targetModel.Name .. " stun'dan çıktı!")
	end

	stunnedCharacters[targetModel] = nil
end)

print("✅ Stun System hazır!")