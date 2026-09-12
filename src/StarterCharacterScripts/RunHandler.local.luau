local StarterPlayer = game:GetService("StarterPlayer")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Tween = game:GetService("TweenService")

if script.Parent == StarterPlayer.StarterCharacterScripts then return end

local Weapons = ReplicatedStorage.Weapons
local Animations = Weapons.Animations

local Camera = workspace.CurrentCamera
local Character = script.Parent
local Humanoid:Humanoid = Character:WaitForChild("Humanoid")
local Animator:Animator = Humanoid:WaitForChild("Animator")
local Root = Character:WaitForChild("HumanoidRootPart")
local RunSound = Root:WaitForChild("Running")

local RunAnim:AnimationTrack = Animator:LoadAnimation(Animations.General.Run)
local WeapRunAnim:AnimationTrack = Animator:LoadAnimation(Animations.General.WeaponRun) 
RunAnim.Priority = Enum.AnimationPriority.Action
WeapRunAnim.Priority = Enum.AnimationPriority.Action
local Info = TweenInfo.new(0.25,Enum.EasingStyle.Linear)

local LastInput,Con,Running

local function InputCheck()
	if LastInput then
		if os.clock() - LastInput < 0.3 then
			return true
		else
			LastInput = os.clock()
		end
	else
		LastInput = os.clock()
	end
end

local function RunUn()
	if Running then
		RunAnim:Stop()
		WeapRunAnim:Stop()
		
		Humanoid.WalkSpeed = 14
		RunSound.Volume = 0.65
		Tween:Create(Camera,Info,{FieldOfView = 70}):Play()
		
		Con:Disconnect()
		Con = nil
	else
		if Character:GetAttribute("Equipped") then
			WeapRunAnim:Play()
		else
			RunAnim:Play()
		end
		
		Humanoid.WalkSpeed = 22
		RunSound.Volume = 0.8
		Tween:Create(Camera,Info,{FieldOfView = 80}):Play()

		LastInput = nil
	end
	Running = not Running
end

local function CheckIfStopped()
	if Humanoid.MoveDirection.Magnitude == 0 then
		WeapRunAnim:Stop()
		RunAnim:Stop()
	elseif Humanoid.MoveDirection.Magnitude > 0 and not (WeapRunAnim.IsPlaying or RunAnim.IsPlaying) then
		if Character:GetAttribute("Equipped") then
			WeapRunAnim:Play()
		else
			RunAnim:Play()
		end
	elseif Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
		RunAnim:AdjustSpeed(0.45)
		WeapRunAnim:AdjustSpeed(0.45)
	elseif RunAnim.Speed < 1 then
		RunAnim:AdjustSpeed(1)
		WeapRunAnim:AdjustSpeed(1.05)
	end
end

UIS.InputBegan:Connect(function(Input:InputObject,GPE:boolean)
	if GPE or Character:GetAttribute("State") then return end
	if Input.KeyCode == Enum.KeyCode.W and InputCheck() then
		RunUn()
		Con = Humanoid.Changed:Connect(CheckIfStopped)
		
	end
end)

UIS.InputEnded:Connect(function(Input:InputObject,GPE:boolean)
	if Input.KeyCode == Enum.KeyCode.W and Running then
		RunUn()
	end
end)

Character:GetAttributeChangedSignal("State"):Connect(function()
	if Character:GetAttribute("State")then
		if Running then
			RunUn()
		end
		RunSound.Volume = 0
	else
		RunSound.Volume = 0.65
	end
end)

Character:GetAttributeChangedSignal("Equipped"):Connect(function()
	
	if Character:GetAttribute("Equipped") and RunAnim.IsPlaying then
		RunAnim:Stop()
		WeapRunAnim:Play()
		WeapRunAnim:AdjustSpeed(1.05)
	elseif WeapRunAnim.IsPlaying then
		for _,Track:AnimationTrack in pairs(Animator:GetPlayingAnimationTracks()) do
			if Track.Animation.AnimationId == "rbxassetid://101512549238415" then
				Track.Stopped:Wait()
			end
		end
		
		if not Running then return end
		RunAnim:Play()
		WeapRunAnim:Stop()
	end
end)