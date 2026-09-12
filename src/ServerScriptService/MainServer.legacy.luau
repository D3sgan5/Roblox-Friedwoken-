
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Weapons = ReplicatedStorage.Weapons
local Models = Weapons.Models
local Scripts = Weapons.Scripts
local Utility = Weapons.Utility

local Constants = require(Weapons.Constants)
local WeaponController = require(Scripts.WeaponController)
local RagdollHandler = require(Utility.RagdollHandler)

local WeaponsFolder = ReplicatedStorage.Weapons
local Models = WeaponsFolder.Models
local Events = WeaponsFolder.Events

local KnockbackEvent = Events.KnockbackEvent
local EquipEvent = Events.EquipEvent
local CombatEvent = Events.CombatEvent

local function OnCharacterAdded(character:Model)
	character:SetAttribute("Equipped",false)
	character:SetAttribute("BlockDurability",100)
	character:SetAttribute("Combo",0)
	
	local Weapon = Models.Mace:Clone()
	Weapon.Parent = character
	
	WeaponController.new(character,Weapon)
end

local function OnEquipEvent(player:Player,action:string)
	local character = player.Character
	
	if action == "Equip/UnEquip" then
		local Session = WeaponController.FindSession(character)
		if Session then
			Session:Enable()
		end
	end
end

local function OnCombatEvent(player:Player,action:string)
	local character = player.Character
	local Session = WeaponController.FindSession(character)
	local State = character:GetAttribute("State")
	
	if not Session then return end
	
	if action == "M1Cancel" and State == "Attacking" then
		Session:M1Cancel()
	elseif action == "UnBlock" then
		Session:UnBlock()
	elseif action == "Block/Parry" and (not State or State == "Stunned") then
		Session:BlockOParry()	
	end
	
	if State then return end
	
	if action == "M1" then
		Session:M1()
	elseif action == "Critical" then
		Session:Critical()
	end
end

function OnKnockbackEvent(player:Player,Action:string,Root:BasePart,CF:CFrame)
	if Action == "ReplicateKB" then
		for _,plr in Players:GetPlayers() do
			if plr ~= player then
				KnockbackEvent:FireClient(plr,"Knockback",Root,CF)
			end
		end
	end
end

RagdollHandler:OnServerSetup()
Players.PlayerAdded:Connect(function(player:Player)
	player.CharacterAdded:Connect(OnCharacterAdded)
end)

EquipEvent.OnServerEvent:Connect(OnEquipEvent)
CombatEvent.OnServerEvent:Connect(OnCombatEvent)
KnockbackEvent.OnServerEvent:Connect(OnKnockbackEvent)
