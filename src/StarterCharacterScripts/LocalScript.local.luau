local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Weapons = ReplicatedStorage.Weapons
local Events = Weapons.Events
local KnockbackEvent = Events.KnockbackEvent

local Character = script.Parent
local root:BasePart = Character:WaitForChild("HumanoidRootPart")

KnockbackEvent.OnClientEvent:Connect(function(Action:string,Root:BasePart,CF:CFrame,info:SharedTable)
	if Action == "Knockback" then
		print("replicationg")
		TweenService:Create(Root,TweenInfo.new(0.05,Enum.EasingStyle.Linear),{CFrame = CF}):Play()
	elseif Action == "ReplicateKB" then
		local att = Instance.new("Attachment")
		local vel = Instance.new("LinearVelocity")
		vel.MaxForce = 2000 * root.AssemblyMass
		vel.VectorVelocity = info.Velocity
		vel.Attachment0 = att
		vel.Parent = att
		att.Parent = root
		
		game.Debris:AddItem(att,0.1)
	end
end)
