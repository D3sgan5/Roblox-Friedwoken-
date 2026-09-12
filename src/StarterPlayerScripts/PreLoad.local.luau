local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

local Animations = {}

for _,Animation in pairs(ReplicatedStorage.Weapons.Animations:GetDescendants()) do
	if Animation:IsA("Animation") then
		table.insert(Animations,Animation)
	end
end

ContentProvider:PreloadAsync(Animations)
