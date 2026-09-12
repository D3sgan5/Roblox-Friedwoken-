local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Events = ReplicatedStorage.Weapons.Events
local RagdollEvent = Events.RagdollEvent
local RagdollHandler = require(script.Parent)

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

Player.CharacterAdded:Connect(function(character)
	Character = character
	Humanoid = Character:WaitForChild("Humanoid")
end)

RagdollEvent.OnClientEvent:Connect(function(Action:string)
	if Action == "Ragdoll" then
		RagdollHandler:RagdollClient(Humanoid)
	elseif Action == "UnRagdoll" then
		RagdollHandler:UnRagdollClient(Humanoid)
	end
end)
