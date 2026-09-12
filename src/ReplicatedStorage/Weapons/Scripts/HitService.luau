local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Weapons = ReplicatedStorage.Weapons
local Events = Weapons.Events
local Utility = Weapons.Utility
local Animations = Weapons.Animations
local Sound = Weapons.Sound
local HittedAnims = Animations:WaitForChild("HittedAnims")
local BlockHitAnims = Animations:WaitForChild("BlockHit")

local SoundInstance = require(Utility.PlaySound)
local RagdollHandler = require(Utility.RagdollHandler)
local StunHandler = require(Utility.StunHandler)

local HitService = {}

function HitService:PlayHitAnim(Target:Humanoid)
	if Target.Parent:GetAttribute("State") == "HyperArmor" then return end
	local Animator:Animator = Target:WaitForChild("Animator")
	
	for _,Track in pairs(Animator:GetPlayingAnimationTracks()) do
		if Track.Name == "Idle" then continue end
		Track:Stop()
	end
	
	local Track = Animator:LoadAnimation(HittedAnims:GetChildren()[math.random(1,3)])
	Track:Play()
end

function HitService.ReplicateNpcKB(TargetRoot:Part)
	TargetRoot:SetNetworkOwner(nil)
	task.spawn(function()
		local t,TimePassed,con = 0,0,nil

		con = RunService.Heartbeat:Connect(function(DT)
			if TimePassed <= 0.2 then
				t += DT
				if t >= 0.0125 then
					t %= 0.0125
					TimePassed += t
					Events.KnockbackEvent:FireAllClients("Knockback",TargetRoot,TargetRoot.CFrame)
				end
			else
				con:Disconnect()
				con = nil
			end
		end)
	end)
end

function HitService:Knockback(TargetRoot:Part,Weapon:Model)
	local Player = Players:GetPlayerFromCharacter(TargetRoot.Parent)
	local AttackerRoot = Weapon.Parent.HumanoidRootPart
	local KnockbackPower = Weapon:GetAttribute("KnockbackPower")
	local info = {
		MaxForce = Vector3.new(100000,0,100000); 
		P = 25000;
		Velocity = AttackerRoot.CFrame.LookVector * (10 * KnockbackPower);
	}
	
	if not Player then
		local att = Instance.new("Attachment")
		local vel = Instance.new("LinearVelocity")
		vel.MaxForce = 2000 * TargetRoot.AssemblyMass
		vel.VectorVelocity = info.Velocity
		vel.Attachment0 = att
		vel.Parent = att
		att.Parent = TargetRoot
		
		game.Debris:AddItem(att,0.1)
	else
		Events.KnockbackEvent:FireClient(Player,"ReplicateKB",nil,nil,info)
	end
end

function HitService:StopAnims(animator:Animator)
	if animator.Parent.Parent:GetAttribute("State") == "HyperArmor" then return end
	
	for _,Track in pairs(animator:GetPlayingAnimationTracks()) do
		if Track.Name == "Idle" or Track.Name == "Block" then continue end
		Track:Stop()
	end
end

function HitService:IfBlocking(Target:Humanoid,Damage:number)
	local Character = Target.Parent
	local Root = Character:WaitForChild("HumanoidRootPart")
	local Animator = Target:WaitForChild("Animator")
	
	local BlockDurability = Character:GetAttribute("BlockDurability")
	local BlockDmg = Damage/3
	
	if BlockDurability - Damage * 4 <= 0 then
		Target:TakeDamage(Damage)
		Character:SetAttribute("BlockDurability",0)
		StunHandler.Stun(Target,2)
		warn("BLOCK BROKEN MY GUY")
		
		SoundInstance.PlaySound(Sound.MaceHit,Target.Parent.HumanoidRootPart)
		Target:TakeDamage(Damage)
		self:PlayHitAnim(Target)
		return 
	else
		if Target.Health > BlockDmg then
			Target:TakeDamage(BlockDmg)
		end
		Character:SetAttribute("BlockDurability",BlockDurability - Damage*4)
	end
	
	local Track = Animator:LoadAnimation(BlockHitAnims:GetChildren()[math.random(1,3)])
	Track:Play()
	SoundInstance.PlaySound(Sound.BlockHit,Root)
end

function HitService:IfParrying(root:Part,humanoid:Humanoid,Attacker:Humanoid)
	local character = root.Parent
	local CharAnimator = humanoid:WaitForChild("Animator")
	local AttackAnimator = Attacker:WaitForChild("Animator")
	
	if not character:GetAttribute("Parried") then
		character:SetAttribute("Parried",true)
	end
	
	local CharParried = Animations.Parried.CharParried:GetChildren()
	
	character:SetAttribute("ParryCd",nil)
	local CharTrack = CharAnimator:LoadAnimation(CharParried[math.random(1,2)])
	local AttackTrack = AttackAnimator:LoadAnimation(Animations.Parried.AttParried)
	
	self:StopAnims(CharAnimator)
	self:StopAnims(AttackAnimator)
	StunHandler.Stun(Attacker,0.8)
	
	CharTrack:Play()
	AttackTrack:Play()
	
	SoundInstance.PlaySound(Sound.Parry,root)
end

function HitService:OnHit(Target:Humanoid,Weapon:Model,StunDuration:number,Knockback:boolean,Hitsnd:Sound)
	if Target.Health <= 0 then return end
	local character = Target.Parent
	local root = character:WaitForChild("HumanoidRootPart")
	local attacker = Weapon.Parent
	local attackerHum = attacker:WaitForChild("Humanoid")
	
	local Damage = Weapon:GetAttribute("Damage")
	local KnockbackPower = Weapon:GetAttribute("KnockbackPower")
	local State = character:GetAttribute("State")
	
	if State == "Parrying" then
		self:IfParrying(root,Target,attackerHum) return
	elseif State == "Blocking" then
		self:IfBlocking(Target,Damage) return
	end
	
	if Hitsnd then
		SoundInstance.PlaySound(Hitsnd,root,1)
	else
		SoundInstance.PlaySound(Sound.MaceHit,root,1)
	end
	
	Target:TakeDamage(Damage)
	self:PlayHitAnim(Target)
	
	StunHandler.Stun(Target,StunDuration)
	if Knockback then
		self:Knockback(root,Weapon)
	end
end

return HitService
