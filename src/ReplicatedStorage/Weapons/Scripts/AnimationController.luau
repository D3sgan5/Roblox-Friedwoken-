local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Weapons = ReplicatedStorage.Weapons
local Utility = Weapons.Utility
local Animations = Weapons.Animations
local Scripts = Weapons.Scripts
local Sound = Weapons.Sound
local VFX = Weapons.VFX

local HitService = require(Scripts.HitService)
local HitboxHandler = require(Utility.HitboxHandler)
local SoundInstance = require(Utility.PlaySound)

local AnimationController = {}
AnimationController.__index = AnimationController

function AnimationController.new(weapon:Model)
	local character = weapon.Parent
	local humanoid = character:WaitForChild("Humanoid")
	local animator = humanoid:WaitForChild("Animator")
	local holder = weapon.PrimaryPart
	local trail = holder.Trail
	
	local self = {
		weapon = weapon;
		holder = holder;
		trail = trail;
		character = character;
		humanoid = humanoid;
		animator = animator;
		animationTracks = {};
		tasks = {};
		feint = true;
	}
	
	setmetatable(self,AnimationController)
	
	self:LoadAnimations()
	
	return self
end

function AnimationController:LoadAnimations()
	local Mace = Animations.Mace
	for index,Animation in pairs(Mace.M1s:GetChildren()) do
		local Track:AnimationTrack = self.animator:LoadAnimation(Animation)
		self.animationTracks[index] = Track
		self:SetM1Events(Track)
	end
	
	for _,Animation in pairs(Mace.Others:GetChildren()) do
		local Track:AnimationTrack = self.animator:LoadAnimation(Animation)
		self.animationTracks[Animation.Name] = Track 
		
		if Track.Name == "Critical" then
			self:SetCritical(Track)
		end
	end
end

function AnimationController:EnableIdle()
	local Equip = self.animationTracks.Equip
	local Idle = self.animationTracks.Idle
	
	Equip:Play()
	Idle:Play()
	Equip:AdjustSpeed(0.5)
	Idle.Priority = Enum.AnimationPriority.Movement
end

function AnimationController:DisableIdle()
	local UnEquip = self.animationTracks.UnEquip
	local Idle = self.animationTracks.Idle
	UnEquip.Priority = Enum.AnimationPriority.Action
	
	Idle:Stop()
	
	UnEquip:Play()
	UnEquip:AdjustSpeed(0.5)
	UnEquip:GetMarkerReachedSignal("end"):Wait()
end

function AnimationController:PlayM1()
	local Combo = self.character:GetAttribute("Combo")
	local Track:AnimationTrack = self.animationTracks[Combo]
	
	if Combo ~= 4 then
		self.feint = true
	else
		local Trail = VFX["4Trail"]:Clone()
		local Weld = Instance.new("Weld")
		local LeftLeg = self.character["Left Leg"]
		Weld.Parent = Trail
		Weld.Part0 = LeftLeg
		Weld.Part1 = Trail
		Trail.Parent = LeftLeg
	end
	
	self:StopAnimations()
	Track:Play()
	Track.Priority = Enum.AnimationPriority.Action
end

function AnimationController:PlayParry()
	self:StopAnimations()
	local Track:AnimationTrack = self.animationTracks.Parry
	
	Track.Priority = Enum.AnimationPriority.Action2
	Track:Play()
end

function AnimationController:PlayBlock()
	self:StopAnimations()
	local Track = self.animationTracks["Block"]
	
	Track.Priority = Enum.AnimationPriority.Action
	Track:Play()
end

function AnimationController:StopBlock()
	local Track = self.animationTracks["Block"]
	Track:Stop()
end

function AnimationController:FeintM1()
	local Combo = self.character:GetAttribute("Combo")
	local Anim = self.animationTracks[Combo]
	
	SoundInstance.PlaySound(Sound.Feint,self.holder,3)
	Anim:Stop()
	self.feint = false
end

function AnimationController:PlayCrit()
	local Anim:AnimationTrack = self.animationTracks["Critical"]
	
	Anim.Priority = Enum.AnimationPriority.Action2
	Anim:Play()
end

function AnimationController:StopTasks()
	for _,con in pairs(self.tasks) do
		task.cancel(con)
		con = nil
	end
end

function AnimationController:StopAnimations()
	for _,Track in pairs(self.animator:GetPlayingAnimationTracks()) do
		if Track == self.animationTracks.Idle or Track == self.animationTracks.Parry then continue end
		Track:Stop()
	end
end

function AnimationController:SetM1Events(Track:AnimationTrack)
	
	Track:GetMarkerReachedSignal("swingreg"):Connect(function()
		local Combo = self.character:GetAttribute("Combo")
		local State = self.character:GetAttribute("State")
		Track:AdjustSpeed(0)
		
		if Combo == 4 then
			self.humanoid.WalkSpeed = 8
			self.humanoid.JumpHeight = 0
		end
		
		local con
		con = task.delay(0.15,function()
			self.feint = false
			Track:AdjustSpeed(1)
			
			local OddOrEven = math.abs(Combo%2 - 2)
			local Snd = Sound.SwingSnd:GetChildren()[OddOrEven]
			
			if Combo == 4 then
				local Leg = self.character["Left Leg"]
				local Part = Leg["4Trail"]
				
				Part.Trail.Enabled = true
				SoundInstance.PlaySound(Snd,self.character["Left Leg"],0.9)
			else
				self.trail.Enabled = true
				SoundInstance.PlaySound(Snd,self.holder)
			end
			
			con = nil
		end)
		
		self.tasks[con] = con
	end)
	
	Track:GetMarkerReachedSignal("hitreg"):Connect(function()
		if not self.character:GetAttribute("Equipped") or self.character:GetAttribute("State") ~= "Attacking" then return end
		
		local Combo = self.character:GetAttribute("Combo")
		local root = self.character.HumanoidRootPart
		
		local CF = root.CFrame * CFrame.new(0,0,-2)
		local Size = Vector3.new(7,7,7)
		
		local Targets = HitboxHandler.DetectHit(Size,CF,{self.character})
		
		for _,Humanoid in pairs(Targets) do
			if Combo == 4 then
				HitService:OnHit(Humanoid,self.weapon,1,true,Sound.FistHit)
			else
				HitService:OnHit(Humanoid,self.weapon,1)
			end
		end
		
		if Combo == 4 then
			self.humanoid.WalkSpeed = 14
			self.humanoid.JumpHeight = 7.2
		end
	end)
	
	Track:GetMarkerReachedSignal("end"):Connect(function()
		if self.character:GetAttribute("State") ~= "Attacking" then return end
		local Combo = self.character:GetAttribute("Combo")
		
		if Combo == 4 then
			self.character["Left Leg"]["4Trail"]:Destroy()
		end
		
		self.character:SetAttribute("State",nil)
	end)
	
	Track.Stopped:Connect(function()
		local Combo = self.character:GetAttribute("Combo")

		
		
		self.trail.Enabled = false
		self:StopTasks()
	end)
end

function AnimationController:SetCritical(Track:AnimationTrack)
	local combo = 0
	
	Track:GetMarkerReachedSignal("freeze"):Connect(function()
		Track:AdjustSpeed(0)
		SoundInstance.PlaySound(Sound.Critical,self.holder)
		
		local con
		con = task.delay(0.2,function()
			Track:AdjustSpeed(1)
			self.trail.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
			self.trail.Enabled = true
			
			con = nil
		end)

		self.tasks[con] = con
	end)
	
	Track:GetMarkerReachedSignal("swingreg"):Connect(function()
		SoundInstance.PlaySound(Sound.SwingSnd.Swing1,self.holder)
	end)
	
	Track:GetMarkerReachedSignal("hitreg"):Connect(function()
		if combo == 3 then
			combo = 1
		else
			combo += 1
		end
		
		local root = self.character.HumanoidRootPart

		local CF = root.CFrame
		local Size = Vector3.new(10,7,10)

		local Targets = HitboxHandler.DetectHit(Size,CF,{self.character})

		for _,Humanoid in pairs(Targets) do
			if combo == 3 then
				HitService:OnHit(Humanoid,self.weapon,0.5,true)
			else
				HitService:OnHit(Humanoid,self.weapon,0.4)
			end
		end
	end)
	
	Track:GetMarkerReachedSignal("end"):Connect(function()
		self.character:SetAttribute("State",nil)
		
		self.trail.Enabled = false
		self.humanoid.WalkSpeed = 14
		self.humanoid.JumpHeight = 7.2
	end)
	
	Track.Stopped:Connect(function()
		self.trail.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	end)
end

return AnimationController
