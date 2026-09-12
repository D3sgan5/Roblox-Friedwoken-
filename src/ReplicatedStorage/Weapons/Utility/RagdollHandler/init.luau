local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Weapons = ReplicatedStorage.Weapons
local Utility = Weapons.Utility
local Events = Weapons.Events
local Offsets = require(script.Offsets)
local RagdollEvent = Events.RagdollEvent

local RagdollHandler = {RagdollTimer = {}}

function RagdollHandler.SetupHumanoid(humanoid:Humanoid)
	
	humanoid.RequiresNeck = false
	humanoid.BreakJointsOnDeath = false
	
	local Con
	Con = humanoid.Died:Connect(function()
		Con:Disconnect()
		Con = nil
		
		RagdollHandler:Ragdoll(humanoid.Parent)
	end)
end

function RagdollHandler.BuildCollisionParts(Target:Model)
	for _,Inst in pairs(Target:GetChildren()) do
		if Inst:IsA("Part") and Inst.Name ~= "HumanoidRootPart"then
			local Collision = Inst:Clone()
			Collision.Name = "Collision"
			Collision.Size = Vector3.one
			Collision.Parent = Inst
			Collision.CanCollide = false
			Collision.Massless = true
			Collision.Transparency = 1
			Collision:ClearAllChildren()
			
			local weld = Instance.new("Weld")
			weld.Parent = Collision
			weld.Part0 = Inst
			weld.Part1 = Collision
		end
	end
end

function RagdollHandler.EnableCollisionParts(Target:Model,Active:boolean)
	for _,Inst in pairs(Target:GetChildren()) do
		if Inst:IsA("Part") and Offsets[Inst.Name] then
			Inst.CanCollide = not Active
			Inst.Collision.CanCollide = Active
		end
	end
end

function RagdollHandler.EnableMotor(Target:Model,Active:boolean)
	for _,Inst in pairs(Target:GetDescendants()) do
		if Inst:IsA("Motor6D") and Inst.Name ~= "RootJoint" and Inst.Name ~= "Weld" then
			Inst.Enabled = Active
		end
	end
end

function RagdollHandler.SetupSockets(Target:Model)
	local root = Target:WaitForChild("HumanoidRootPart")
	
	for _,Inst in pairs(Target:GetChildren()) do
		if Inst:IsA("Part") then
			if not Offsets[Inst.Name] then continue end
			
			local socket = Instance.new("BallSocketConstraint")
			socket.Parent = Inst
			
			local att0,att1 = Instance.new("Attachment"),Instance.new("Attachment")
			att0.Parent,att1.Parent = Inst,root
			att0.CFrame,att1.CFrame = Offsets[Inst.Name].CFrame[2],Offsets[Inst.Name].CFrame[1]
			
			socket.Attachment0 = att0
			socket.Attachment1 = att1
			
			Inst.Massless = true
			
			CollectionService:AddTag(att0,"ToDestroy")
			CollectionService:AddTag(att1,"ToDestroy")
			CollectionService:AddTag(socket,"ToDestroy")
		end
	end
end

function RagdollHandler.DestroySockets(Target:Model)
	for _,Inst in pairs(Target:GetDescendants()) do
		if table.find(CollectionService:GetTags(Inst),"ToDestroy") then
			Inst:Destroy()
		end
	end
end

function RagdollHandler:RagdollClient(Target:Humanoid)
	Target.AutoRotate = false
	Target.PlatformStand = true
end

function RagdollHandler:UnRagdollClient(Target:Humanoid)
	if Target:GetState() == Enum.HumanoidStateType.Dead then return end
	Target.AutoRotate = true
	Target.PlatformStand = false
	Target:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
	Target:ChangeState(Enum.HumanoidStateType.GettingUp)
end

function RagdollHandler:Ragdoll(Target:Model,Duration:number)
	local player = Players:GetPlayerFromCharacter(Target)
	local humanoid:Humanoid = Target:WaitForChild("Humanoid")
	local root:Part = Target:WaitForChild("HumanoidRootPart")
	
	if Target:GetAttribute("State") == "Ragdoll" then return end
	
	self.SetupSockets(Target)
	self.EnableMotor(Target,false)
	self.EnableCollisionParts(Target,true)
	
	if player then
		RagdollEvent:FireClient(player,"Ragdoll")
	else
		root:SetNetworkOwner(nil)
		
		
		humanoid.AutoRotate = false
		humanoid.PlatformStand = true
	end
	
	Target:SetAttribute("State","Ragdoll")
	
	if not Duration then return end
	
	if self.RagdollTimer[Target] then coroutine.close(self.RagdollTimer[Target]) end
	self.RagdollTimer[Target] = coroutine.create(function()
		task.wait(Duration)
		self:UnRagdoll(Target)
	end)
	
	coroutine.resume(self.RagdollTimer[Target])
end

function RagdollHandler:UnRagdoll(Target:Model)
	local player = Players:GetPlayerFromCharacter(Target)
	local humanoid:Humanoid = Target:WaitForChild("Humanoid")
	local root:Part = Target:WaitForChild("HumanoidRootPart")
	
	if player then
		RagdollEvent:FireClient(player,"UnRagdoll")
	else
		root:SetNetworkOwner(nil)
		if humanoid:GetState() == Enum.HumanoidStateType.Dead then return end
		humanoid.PlatformStand = false
		humanoid.AutoRotate = true
		humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
	
	self.EnableMotor(Target,true)
	self.EnableCollisionParts(Target,false)
	self.DestroySockets(Target)

	Target:SetAttribute("State",nil)
end

function RagdollHandler:OnServerSetup()
	for _,Inst in pairs(workspace:GetDescendants()) do
		if Inst:IsA("Humanoid") then
			self.BuildCollisionParts(Inst.Parent)
			self.SetupHumanoid(Inst)
			self:Ragdoll(Inst.Parent)
			self:UnRagdoll(Inst.Parent)
		end
	end
	
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			local humanoid = character:WaitForChild("Humanoid")
			
			self.BuildCollisionParts(character)
			self.SetupHumanoid(humanoid)
			self:Ragdoll(character)
			self:UnRagdoll(character)
		end)
	end)
end

return RagdollHandler
