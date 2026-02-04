local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🤖 Enemy AI System başlatıldı!")

-- AI Ayarları
local DETECTION_RANGE = 25
local ATTACK_RANGE = 5
local CHASE_SPEED = 12
local IDLE_SPEED = 8
local COMBO_SIZE = 4  -- 4'lü kombo
local COMBO_DELAY = 0.5  -- Kombo arası bekleme
local COMBO_TIMEOUT = 2.5  -- Kombo bitince bekle

-- Düşman durumları
local enemyStates = {}

-- RemoteEvent
local enemyAttackEvent = ReplicatedStorage:FindFirstChild("EnemyAttack")
if not enemyAttackEvent then
	enemyAttackEvent = Instance.new("RemoteEvent")
	enemyAttackEvent.Name = "EnemyAttack"
	enemyAttackEvent.Parent = ReplicatedStorage
end

-- Oyuncu tespit fonksiyonu
local function findNearestPlayer(enemy)
	local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
	if not enemyRoot then return nil end

	local nearestPlayer = nil
	local shortestDistance = DETECTION_RANGE

	for _, player in pairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local playerRoot = character:FindFirstChild("HumanoidRootPart")

			if humanoid and humanoid.Health > 0 and playerRoot then
				local distance = (enemyRoot.Position - playerRoot.Position).Magnitude

				if distance < shortestDistance then
					shortestDistance = distance
					nearestPlayer = character
				end
			end
		end
	end

	return nearestPlayer, shortestDistance
end

-- Kombo saldırı fonksiyonu
local function performCombo(enemy, target)
	local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
	local targetRoot = target:FindFirstChild("HumanoidRootPart")

	if not enemyRoot or not targetRoot then return end

	-- Check if target is blocking BEFORE starting combo
	local checkBlockingFunction = ReplicatedStorage:FindFirstChild("CheckBlocking")
	if checkBlockingFunction then
		local isTargetBlocking = checkBlockingFunction:Invoke(target)
		if isTargetBlocking then
			print("🛡️ Hedef block yapıyor! Kombo iptal edildi!")
			return
		end
	end

	print("🥊 " .. enemy.Name .. " kombo başlatıyor!")

	for comboNum = 1, COMBO_SIZE do
		-- Check if target started blocking during combo
		if checkBlockingFunction then
			local isTargetBlocking = checkBlockingFunction:Invoke(target)
			if isTargetBlocking then
				print("🛡️ Hedef block başlattı! Kombo durduruluyor!")
				break
			end
		end

		-- Hedef hala menzilde mi kontrol et
		local distance = (enemyRoot.Position - targetRoot.Position).Magnitude
		if distance > ATTACK_RANGE + 2 then
			print("❌ Hedef kaçtı, kombo kesildi!")
			break
		end

		-- Hedefe bak (only rotate enemy, don't manipulate target)
		-- This prevents the character freeze issue
		enemyRoot.CFrame = CFrame.new(enemyRoot.Position, Vector3.new(targetRoot.Position.X, enemyRoot.Position.Y, targetRoot.Position.Z))

		-- Saldır
		enemyAttackEvent:FireAllClients(enemy, target, comboNum)
		print("💥 Kombo " .. comboNum .. "/" .. COMBO_SIZE)

		-- Kombo arası bekleme
		if comboNum < COMBO_SIZE then
			task.wait(COMBO_DELAY)
		end
	end

	print("✅ Kombo tamamlandı!")
end

-- Düşmanı başlat
local function initializeEnemy(enemy)
	local humanoid = enemy:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	enemyStates[enemy] = {
		target = nil,
		state = "idle",
		lastCombo = 0,
		isStunned = false,
		isAttacking = false,
		hasDetectionIcon = false,
		wasAttackedBy = nil
	}

	print("✅ AI başlatıldı: " .. enemy.Name)

	-- Ana AI döngüsü
	task.spawn(function()
		while enemy.Parent and humanoid.Health > 0 do
			local state = enemyStates[enemy]
			if not state or state.isStunned or state.isAttacking then
				task.wait(0.5)
				continue
			end

			-- Hedef bul
			local nearestTarget, distance = findNearestPlayer(enemy)

			-- Saldırıya uğradıysa o kişiyi takip et
			if state.wasAttackedBy and state.wasAttackedBy.Parent then
				nearestTarget = state.wasAttackedBy
				local attackerRoot = nearestTarget:FindFirstChild("HumanoidRootPart")
				local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
				if attackerRoot and enemyRoot then
					distance = (enemyRoot.Position - attackerRoot.Position).Magnitude
				end
			end

			local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")

			if nearestTarget and distance <= DETECTION_RANGE then
				state.target = nearestTarget
				local targetRoot = nearestTarget:FindFirstChild("HumanoidRootPart")

				if targetRoot and enemyRoot then
					-- Tespit ikonu göster
					if not state.hasDetectionIcon then
						state.hasDetectionIcon = true

						local head = enemy:FindFirstChild("Head")
						if head then
							local billboard = Instance.new("BillboardGui")
							billboard.Size = UDim2.new(0, 50, 0, 50)
							billboard.StudsOffset = Vector3.new(0, 4, 0)
							billboard.Parent = head

							local label = Instance.new("TextLabel")
							label.Size = UDim2.new(1, 0, 1, 0)
							label.BackgroundTransparency = 1
							label.Text = "❗"
							label.TextColor3 = Color3.fromRGB(255, 0, 0)
							label.TextSize = 40
							label.Font = Enum.Font.GothamBold
							label.Parent = billboard

							game:GetService("Debris"):AddItem(billboard, 0.5)
						end
					end

					-- Saldırı mesafesinde mi?
					if distance <= ATTACK_RANGE then
						local currentTime = tick()

						-- Kombo cooldown'u doldu mu?
						if currentTime - state.lastCombo >= COMBO_TIMEOUT then
							state.state = "attacking"
							state.isAttacking = true
							state.lastCombo = currentTime
							humanoid.WalkSpeed = 0

							-- Kombo yap
							performCombo(enemy, nearestTarget)

							state.isAttacking = false
						end
					else
						-- Kovala
						state.state = "chasing"
						humanoid.WalkSpeed = CHASE_SPEED
						humanoid:MoveTo(targetRoot.Position)
					end
				end
			else
				-- Hedef yok, idle
				state.state = "idle"
				state.target = nil
				state.hasDetectionIcon = false
				state.wasAttackedBy = nil
				humanoid.WalkSpeed = IDLE_SPEED
			end

			task.wait(0.3)
		end

		enemyStates[enemy] = nil
	end)
end

-- Workspace'teki tüm düşmanları tara
task.wait(3)

for _, obj in pairs(workspace:GetChildren()) do
	if obj.Name:find("Pirate") and obj:IsA("Model") then
		initializeEnemy(obj)
	end
end

workspace.ChildAdded:Connect(function(child)
	if child.Name:find("Pirate") and child:IsA("Model") then
		task.wait(0.5)
		initializeEnemy(child)
	end
end)

-- Düşmana saldırıldığında kaydet (script'in sonunda)
local stunEvent = ReplicatedStorage:WaitForChild("StunPlayer")
stunEvent.OnServerEvent:Connect(function(player, targetModel, stunDuration)
	if enemyStates[targetModel] then
		enemyStates[targetModel].wasAttackedBy = player.Character
		enemyStates[targetModel].isStunned = true
		enemyStates[targetModel].isAttacking = false  -- Saldırıyı kes!

		print("😵 " .. targetModel.Name .. " stunlandı: " .. stunDuration .. "s")

		task.wait(stunDuration)

		if enemyStates[targetModel] then
			enemyStates[targetModel].isStunned = false
		end
	end
end)

print("✅ Enemy AI hazır!")