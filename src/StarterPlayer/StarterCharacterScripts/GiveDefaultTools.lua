local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
wait(1)

-- Sadece yumruk ver (block artık yumrukta)
local punch = ReplicatedStorage:FindFirstChild("Yumruk")
if punch then
	local clone = punch:Clone()
	clone.Parent = player.Backpack
	print("✅ Yumruk verildi! (F tuşu ile block)")
end