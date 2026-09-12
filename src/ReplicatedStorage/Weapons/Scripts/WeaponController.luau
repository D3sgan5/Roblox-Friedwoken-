local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Weapons = ReplicatedStorage.Weapons
local Scripts = Weapons.Scripts

local AnimationController = require(Scripts.AnimationController)
local Constants = require(Weapons.Constants)

local ActiveWeapons = {}
local LastM1 = {}

local WeaponController = {}
WeaponController.__index = WeaponController

function WeaponController.FindSession(character:Model)
	if ActiveWeapons[character] then
		return ActiveWeapons[character]
	end
end

function WeaponController.new(character:Model,weapon:Model)
	local humanoid = character:WaitForChild("Humanoid")
	local animationController = AnimationController.new(weapon)
	
	local self = {
		animationController = animationController;
		character = character;
		humanoid = humanoid;
		weapon = weapon;
		connections = {};
		Corout = nil;
	}
	
	setmetatable(self,WeaponController)
	
	self:initiliaze()
	
	return self
end

function WeaponController:initiliaze()
	local torso = self.character:WaitForChild("Torso")
	local weld = self.weapon.PrimaryPart.Weld
	
	weld.Part0 = torso
	weld.C0 = Constants.IdleWeld
	
	ActiveWeapons[self.character] = self
	
	self.character:GetAttributeChangedSignal("Parried"):Connect(function()
		if self.character:GetAttribute("Parried") and self.character:GetAttribute("State") == "Parrying" then
			coroutine.close(self.Corout)
			
			self.Corout = coroutine.create(function()
				task.wait(0.5)
				
				self.character:SetAttribute("Parried",nil)
				self:ParryDuration()
			end)
			
			coroutine.resume(self.Corout)
		end
	end)
	
	self.character:GetAttributeChangedSignal("BlockDurability"):Connect(function()
		if self.character:GetAttribute("BlockDurability") == 0 and self.character:GetAttribute("State") ~= "Blocking" then
			self:BlockRegen()
			warn("someones block broke")
		end
	end)
end

function WeaponController:BlockRegen()
	local CurrentTime = 0
	local elasedTime = 0
	local regened = 0
	local BlockCon = nil
	
	BlockCon = RunService.Heartbeat:Connect(function(DT:number)
		local BlockDur = self.character:GetAttribute("BlockDurability")
		elasedTime += DT
		CurrentTime += DT
		if CurrentTime >= 0.1 and BlockDur < 100 then
			CurrentTime -= 0.1
			self.character:SetAttribute("BlockDurability",BlockDur+1)
			regened +=1
		elseif BlockDur >= 100 then
		
			BlockCon:Disconnect()
			self.connections["BlockCon"] = nil
		end
	end)
	
	self.connections["BlockCon"] = BlockCon
end

function WeaponController:Enable()
	local Active = self.character:GetAttribute("Equipped")
	local State = self.character:GetAttribute("State")
	local weld = self.weapon.PrimaryPart.Weld
	
	if Active then
		self.character:SetAttribute("Equipped",false)
		local torso = self.character:WaitForChild("Torso")
		
		if State == "Blocking" then
			self:UnBlock()
		else
			self.character:SetAttribute("State",nil)
		end
		
		self.animationController:DisableIdle()
		weld.Part0 = torso
		weld.C0 = Constants.IdleWeld
	else
		self.character:SetAttribute("Equipped",true)
		local rightArm = self.character:WaitForChild("Right Arm")
		
		self.animationController:EnableIdle()
		weld.Part0 = rightArm
		weld.C0 = Constants.EquipWeld
	end
end

function WeaponController:M1()
	if self.character:GetAttribute("State") then return end

	self.character:SetAttribute("State","Attacking")
	self:ChangeCombo()
	
	self.animationController:PlayM1()
end

function WeaponController:M1Cancel()
	local State = self.character:GetAttribute("State")
	local Combo = self.character:GetAttribute("Combo")
	if State ~= "Attacking" or self:CD("FeintCd",2) or not self.animationController.feint then return end
	
	self.character:SetAttribute("State",nil)
	self.character:SetAttribute("FeintCd",os.clock())
	self.animationController:FeintM1()
end

function WeaponController:CD(Type:string,Duration:number)
	local Cd = self.character:GetAttribute(Type)
	
	if Cd then
		if os.clock() - Cd >= Duration then
			self.character:SetAttribute(Type,nil)
		else
			return true
		end
	end
end

function WeaponController:ParryDuration()
	if self.character:GetAttribute("State") == "Parrying" then
		self.character:SetAttribute("State",nil)
	end
	
	if self.IsBlocking then
		self:Block()
	end
end

function WeaponController:BlockOParry()
	self.IsBlocking = true
	if not self:CD("ParryCd",2) then
		self:Parry()
	else
		self:Block()
	end
end

function WeaponController:Parry()
	
	self.character:SetAttribute("State","Parrying")
	self.character:SetAttribute("ParryCd",os.clock())
	self.animationController:PlayParry()
	
	self.Corout = coroutine.create(function()
		task.wait(0.25)
		self:ParryDuration()
	end)
	
	coroutine.resume(self.Corout)
end

function WeaponController:Block()
	if self.connections["BlockCon"] then
		self.connections["BlockCon"]:Disconnect()
		self.connections["BlockCon"] = nil
	end
	
	self.character:SetAttribute("State","Blocking")
	
	self.humanoid.WalkSpeed = 10
	self.animationController:PlayBlock()
end

function WeaponController:UnBlock()
	self.IsBlocking = false
	if self.character:GetAttribute("State") ~= "Blocking" then return end
	
	self.character:SetAttribute("State",nil)

	self.humanoid.WalkSpeed = 16
	self.animationController:StopBlock()
	if self.character:GetAttribute("BlockDurability") < 100 then self:BlockRegen() end 
end

function WeaponController:Critical()
	if self:CD("CritCd",6) then return end
	
	self.character:SetAttribute("State","HyperArmor")
	self.character:SetAttribute("CritCd",os.clock())
	
	self.humanoid.WalkSpeed = 6
	self.humanoid.JumpHeight = 0

	self.animationController:PlayCrit()
end

function WeaponController:ChangeCombo()
	local Combo = self.character:GetAttribute("Combo")
	
	if not LastM1[self.character] then
		LastM1[self.character] = os.clock()
	end
	
	local CurrentTime = os.clock() - LastM1[self.character]
	LastM1[self.character] = os.clock()
	
	if Combo == Constants.MaxCombo or CurrentTime >= 1.5 then
		self.character:SetAttribute("Combo",1)
	else
		self.character:SetAttribute("Combo",Combo + 1)
	end
end

return WeaponController
